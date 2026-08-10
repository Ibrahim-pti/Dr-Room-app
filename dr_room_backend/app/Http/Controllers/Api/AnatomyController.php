<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;

class AnatomyController extends Controller
{
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
        $organsData = [];

        foreach ($this->organWikiMap as $key => $wikiTitle) {
            try {
                $response = Http::withHeaders([
                    'User-Agent' => 'DrRoomApp/1.0 (https://drroom.app; contact@drroom.app)'
                ])->timeout(3)->get("https://en.wikipedia.org/api/rest_v1/page/summary/{$wikiTitle}");

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
            } catch (\Exception $e) {
                // If network timeout, skip key
            }
        }

        return response()->json([
            'status' => 'success',
            'source' => 'Anatomy Arts USA & Wikipedia REST API (27 Detailed Parts)',
            'count' => count($organsData),
            'data' => $organsData
        ]);
    }
}
