<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Client\Pool;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class AnatomyController extends Controller
{
    private const ORGANS_CACHE_KEY = 'anatomy.organs';

    /**
     * Map of 27 detailed anatomical body parts to Wikipedia REST API titles
     */
    private array $organWikiMap = [
        'head' => 'Human_brain',
        'face' => 'Facial_muscles',
        'jaw' => 'Human_jaw',
        'neck' => 'Neck',
        'thyroid' => 'Thyroid',
        'shoulder' => 'Deltoid_muscle',
        'chest_muscle' => 'Pectoralis_major',
        'heart' => 'Heart',
        'lungs' => 'Lung',
        'ribs' => 'Rib_cage',
        'biceps' => 'Biceps',
        'forearm' => 'Forearm',
        'liver' => 'Liver',
        'stomach' => 'Stomach',
        'pancreas' => 'Pancreas',
        'spleen' => 'Spleen',
        'gallbladder' => 'Gallbladder',
        'kidneys' => 'Kidney',
        'abs' => 'Rectus_abdominis_muscle',
        'small_intestine' => 'Small_intestine',
        'large_intestine' => 'Large_intestine',
        'pelvis' => 'Pelvis',
        'quadriceps' => 'Quadriceps_femoris_muscle',
        'knee' => 'Knee',
        'shin' => 'Tibialis_anterior_muscle',
        'calf' => 'Gastrocnemius_muscle',
        'feet' => 'Foot',
    ];

    /**
     * Fetch complete 27-part detailed doctor-grade anatomical dataset
     */
    public function organs(Request $request): JsonResponse
    {
        // The body map opens on app start, so this used to hold every other API
        // call behind ~10s of Wikipedia round trips. The summaries barely
        // change, so a warm cache serves them instantly.
        $organsData = Cache::get(self::ORGANS_CACHE_KEY);

        if ($organsData === null) {
            $organsData = $this->fetchOrgansFromWikipedia();

            // A sweep that came back empty means Wikipedia was unreachable, not
            // that there is no anatomy data — caching that would blank the body
            // map for a week.
            if ($organsData !== []) {
                Cache::put(self::ORGANS_CACHE_KEY, $organsData, now()->addWeek());
            }
        }

        return response()->json([
            'status' => 'success',
            'source' => 'Anatomy Arts USA & Wikipedia REST API (27 Detailed Parts)',
            'count' => count($organsData),
            'data' => $organsData
        ]);
    }

    /**
     * Pulls all 27 Wikipedia summaries in a single concurrent pool. Fetching
     * them one after another took roughly ten seconds; in parallel it is one.
     *
     * @return array<string, array<string, mixed>>
     */
    private function fetchOrgansFromWikipedia(): array
    {
        $responses = Http::pool(fn (Pool $pool) => collect($this->organWikiMap)
            ->map(fn (string $wikiTitle, string $key) => $pool->as($key)
                ->withHeaders([
                    'User-Agent' => 'DrRoomApp/1.0 (https://drroom.app; contact@drroom.app)'
                ])
                ->timeout(3)
                ->get("https://en.wikipedia.org/api/rest_v1/page/summary/{$wikiTitle}"))
            ->all());

        $organsData = [];

        foreach ($this->organWikiMap as $key => $wikiTitle) {
            $response = $responses[$key] ?? null;

            // A failed request comes back as the exception itself rather than a
            // response, so anything that is not a Response is simply skipped.
            if ($response instanceof Response) {
                if ($response->successful()) {
                    $data = $response->json();
                    $extract = $data['extract'] ?? '';
                    $sentences = array_values(array_filter(explode('. ', $extract)));

                    $organsData[$key] = [
                        'id' => $key,
                        'title' => $data['title'] ?? ucfirst(str_replace('_', ' ', $key)),
                        'description' => $data['description'] ?? ($sentences[0] ?? $extract),
                        'imageUrl' => $data['thumbnail']['source'] ?? ($data['originalimage']['source'] ?? ''),
                        'wikiUrl' => $data['content_urls']['desktop']['page'] ?? "https://en.wikipedia.org/wiki/{$wikiTitle}",
                        'latin' => $data['description'] ?? 'Anatomical Structure',
                        'specialist' => 'Anatomy Arts USA & Medical REST API',
                        'stats' => [
                            ['value' => 'Detailed', 'label' => 'Anatomy', 'icon' => 'medical_information'],
                            ['value' => 'Verified', 'label' => 'Clinical', 'icon' => 'verified'],
                            ['value' => 'Wikipedia', 'label' => 'Source', 'icon' => 'public'],
                            ['value' => 'REST v1', 'label' => 'API', 'icon' => 'api'],
                        ],
                        'functions' => count($sentences) > 0 ? $sentences : [$extract],
                        'fact' => $extract,
                        'anatomy_details' => [
                            'Anatomical Region' => $data['title'] ?? '',
                            'Medical Description' => $data['description'] ?? '',
                            'Detailed Extract' => $extract,
                            'Reference Link' => $data['content_urls']['desktop']['page'] ?? '',
                        ]
                    ];
                }
            }
        }

        return $organsData;
    }
}
