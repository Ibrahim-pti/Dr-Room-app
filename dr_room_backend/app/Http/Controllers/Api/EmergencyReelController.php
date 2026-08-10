<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class EmergencyReelController extends Controller
{
    /** کەناڵی ReViva First Aid Training لە YouTube */
    private const YOUTUBE_CHANNEL_ID = 'UCaZ3x21S2edj4tX2HGos7Jw';

    private const FEED_CACHE_KEY = 'emergency_reels.youtube_feed';
    private const FEED_CACHE_TTL = 21600; // ٦ کاتژمێر

    /**
     * لیستی یەدەگ — ئەگەر feed ـەکە نەگەیشت (ئینتەرنێت/YouTube).
     * ئەمانە هەموو ڤیدیۆکانی کەناڵەکەن وەک لە 2023-01-15.
     */
    private const YOUTUBE_FALLBACK = [
        ['id' => 'mO8V9ZOg7iU', 'title' => 'Recovery Position'],
        ['id' => '7Xp8SmdmedE', 'title' => 'Head to Toe Assessment'],
        ['id' => 'wrwGOfoGyx0', 'title' => 'Asthma Puffer and Spacer'],
        ['id' => 'DMjsZ4mh45Q', 'title' => 'How to use an EpiPen'],
        ['id' => 'AaAHVhmuLSE', 'title' => 'Everything In A First Aid Kit'],
        ['id' => 'WdYSDeSBS6s', 'title' => 'Arm Sling'],
        ['id' => 'kg6srXn_VrU', 'title' => 'External Bleed'],
        ['id' => 'BxrSR1VvJeA', 'title' => 'PIB PIT'],
        ['id' => 'cPQigeFoUlI', 'title' => 'Asthma'],
    ];

    /**
     * ڤیدیۆی ستۆکی خۆماڵی/mp4 — بە `video_player` لێدەدرێن.
     *
     * 'file'         : ناوی فایل لە public/videos/reels/ (ئەگەر هەبوو، پێشەنگە)
     * 'fallback_url' : لینکی ڕاستەوخۆی .mp4 لە Pexels
     */
    private const MP4_CATALOG = [
        [
            'id' => 'cpr-chest-compressions',
            'title' => 'CPR Chest Compressions',
            'description' => 'How to perform Hands-Only CPR on an adult — correct hand position and compression depth.',
            'file' => 'cpr-chest-compressions.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/3981773/3981773-hd_1920_1080_30fps.mp4',
            'attribution' => 'Video by Gustavo Fring on Pexels',
            'likes' => 1240,
            'shares' => 300,
        ],
        [
            'id' => 'cpr-bag-valve-mask',
            'title' => 'CPR With a Bag Valve Mask',
            'description' => 'Close-up of assisted ventilation during CPR using a bag valve mask.',
            'file' => 'cpr-bag-valve-mask.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/6531400/6531400-hd_1920_1080_30fps.mp4',
            'attribution' => 'Video by CESAR CASANOVA on Pexels',
            'likes' => 892,
            'shares' => 150,
        ],
        [
            'id' => 'rescue-breathing',
            'title' => 'Rescue Breathing',
            'description' => 'Mouth-to-mouth resuscitation: opening the airway and delivering rescue breaths.',
            'file' => 'rescue-breathing.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/3981865/3981865-hd_1920_1080_30fps.mp4',
            'attribution' => 'Video by Gustavo Fring on Pexels',
            'likes' => 2050,
            'shares' => 420,
        ],
        [
            'id' => 'wound-bandaging',
            'title' => 'Wound Care & Bandaging',
            'description' => 'Cleaning a wound and applying a bandage to the wrist correctly.',
            'file' => 'wound-bandaging.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/3981834/3981834-hd_1920_1080_30fps.mp4',
            'attribution' => 'Video by Gustavo Fring on Pexels',
            'likes' => 1580,
            'shares' => 260,
        ],
        [
            'id' => 'cpr-mannequin',
            'title' => 'CPR on a Training Mannequin',
            'description' => 'Full CPR cycle demonstrated on a training mannequin — compressions and breaths.',
            'file' => 'cpr-mannequin.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/855480/855480-hd_1920_1080_25fps.mp4',
            'attribution' => 'Video by Pixabay on Pexels',
            'likes' => 3120,
            'shares' => 640,
        ],
        [
            'id' => 'first-aid-class',
            'title' => 'First Aid Training Class',
            'description' => 'A group practising lifesaving CPR techniques with an instructor.',
            'file' => 'first-aid-class.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/3981828/3981828-hd_1920_1080_30fps.mp4',
            'attribution' => 'Video by Gustavo Fring on Pexels',
            'likes' => 970,
            'shares' => 180,
        ],
        [
            'id' => 'human-dummy-practice',
            'title' => 'Practising on a Human Dummy',
            'description' => 'Medical students rehearsing emergency response on a resuscitation dummy.',
            'file' => 'human-dummy-practice.mp4',
            'fallback_url' => 'https://videos.pexels.com/video-files/3981832/3981832-hd_1920_1080_30fps.mp4',
            'attribution' => 'Video by Gustavo Fring on Pexels',
            'likes' => 1410,
            'shares' => 230,
        ],
    ];

    public function index(): JsonResponse
    {
        return response()->json(array_merge($this->youtubeReels(), $this->mp4Reels()));
    }

    /**
     * هەموو ڤیدیۆکانی کەناڵەکە لە RSS feed ـی YouTube (بێ API key).
     * feed ـەکە خۆکارانە نوێ دەبێتەوە، بۆیە ڤیدیۆی نوێ خۆی زیاد دەبێت.
     */
    private function youtubeReels(): array
    {
        $videos = Cache::remember(
            self::FEED_CACHE_KEY,
            self::FEED_CACHE_TTL,
            fn () => $this->fetchChannelFeed()
        );

        if (empty($videos)) {
            Cache::forget(self::FEED_CACHE_KEY); // نەیهێڵە یەدەگەکە ٦ کاتژمێر بمێنێتەوە
            $videos = array_map(fn ($v) => $v + [
                'description' => '',
                'views' => 0,
                'likes' => 0,
                'published' => null,
            ], self::YOUTUBE_FALLBACK);
        }

        return array_map(fn (array $v) => [
            'id' => 'yt-' . $v['id'],
            'type' => 'youtube',
            'youtube_id' => $v['id'],
            'title' => $v['title'],
            'description' => $v['description'],
            'video_url' => 'https://www.youtube.com/watch?v=' . $v['id'],
            'thumbnail_url' => 'https://i.ytimg.com/vi/' . $v['id'] . '/hqdefault.jpg',
            'author' => 'ReViva First Aid Training',
            'attribution' => 'YouTube · ReViva First Aid Training',
            'views' => $v['views'],
            'likes' => $v['likes'],
            'shares' => 0,
            'published' => $v['published'],
        ], $videos);
    }

    /**
     * @return array<int, array{id: string, title: string, description: string, views: int, likes: int, published: ?string}>
     */
    private function fetchChannelFeed(): array
    {
        try {
            $response = Http::timeout(6)->get(
                'https://www.youtube.com/feeds/videos.xml',
                ['channel_id' => self::YOUTUBE_CHANNEL_ID]
            );

            if (! $response->successful()) {
                return [];
            }

            $xml = @simplexml_load_string($response->body());

            if ($xml === false) {
                return [];
            }

            $videos = [];

            foreach ($xml->entry as $entry) {
                $yt = $entry->children('http://www.youtube.com/xml/schemas/2015');
                $group = $entry->children('http://search.yahoo.com/mrss/')->group;

                $videoId = (string) $yt->videoId;

                if ($videoId === '') {
                    continue;
                }

                $community = $group->community ?? null;

                $videos[] = [
                    'id' => $videoId,
                    'title' => trim((string) $entry->title),
                    'description' => $this->firstLine((string) ($group->description ?? '')),
                    'views' => (int) ($community?->statistics->attributes()->views ?? 0),
                    'likes' => (int) ($community?->starRating->attributes()->count ?? 0),
                    'published' => substr((string) $entry->published, 0, 10) ?: null,
                ];
            }

            return $videos;
        } catch (\Throwable $e) {
            Log::warning('Emergency reels: YouTube feed fetch failed', ['error' => $e->getMessage()]);

            return [];
        }
    }

    /**
     * وەسفی YouTube زۆرجار لینکی حجزکردنی خۆی تێدایە — تەنها ڕستەی سەرەکی وەردەگرین.
     */
    private function firstLine(string $description): string
    {
        foreach (preg_split('/\R/', trim($description)) ?: [] as $line) {
            $line = trim($line);

            if ($line !== '' && ! str_starts_with($line, 'Book a First Aid Training course')) {
                return $line;
            }
        }

        return '';
    }

    private function mp4Reels(): array
    {
        return array_map(function (array $reel) {
            $localPath = public_path('videos/reels/' . $reel['file']);

            return [
                'id' => $reel['id'],
                'type' => 'mp4',
                'youtube_id' => null,
                'title' => $reel['title'],
                'description' => $reel['description'],
                'video_url' => is_file($localPath)
                    ? asset('videos/reels/' . $reel['file'])
                    : $reel['fallback_url'],
                'thumbnail_url' => null,
                'author' => 'Dr. Room First Aid',
                'attribution' => $reel['attribution'],
                'views' => null,
                'likes' => $reel['likes'],
                'shares' => $reel['shares'],
                'published' => null,
            ];
        }, self::MP4_CATALOG);
    }
}
