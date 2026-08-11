<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Stichoza\GoogleTranslate\GoogleTranslate;

/**
 * Medicine reference information, looked up by name.
 *
 * Backed by openFDA's drug label database, which is free, needs no API key and
 * carries the official label text — indications, dosage, warnings. That makes
 * it the counterpart to PillIdentifierController: Gemini reads a *photo* and
 * costs money per call, this reads a *name* and costs nothing, so the app has
 * a working medicine lookup with no paid key in place.
 */
class MedicineInfoController extends Controller
{
    /** openFDA allows 40 requests/minute without a key, so answers are cached. */
    private const CACHE_DAYS = 7;

    /** Label sections run to thousands of characters; the card shows a summary. */
    private const MAX_FIELD_LENGTH = 600;

    /**
     * openFDA indexes United States label names. Medicines are sold in Iraq
     * under their international names, so the common ones are translated
     * before the search rather than coming back as a weak ingredient match.
     */
    private const NAME_ALIASES = [
        'paracetamol' => 'acetaminophen',
        'panadol' => 'acetaminophen',
        'adol' => 'acetaminophen',
        'salbutamol' => 'albuterol',
        'ventolin' => 'albuterol',
        'augmentin' => 'amoxicillin and clavulanate potassium',
        'flagyl' => 'metronidazole',
        'brufen' => 'ibuprofen',
        'voltaren' => 'diclofenac',
        'zantac' => 'ranitidine',
        'glucophage' => 'metformin',
        'lipitor' => 'atorvastatin',
        'nexium' => 'esomeprazole',
        'losec' => 'omeprazole',
        'zithromax' => 'azithromycin',
        'cipro' => 'ciprofloxacin',
    ];

    public function lookup(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'query' => 'required|string|min:2|max:100',
            'lang' => 'nullable|string|in:en,ckb,ar',
        ]);

        $query = trim($validated['query']);
        $lang = $validated['lang'] ?? 'en';

        // The translated copy is cached under its own key, so the slow
        // translation runs once per medicine per language rather than on
        // every lookup.
        $cacheKey = 'medicine.info.' . $lang . '.' . md5(mb_strtolower($query));

        $result = Cache::get($cacheKey);

        if ($result === null) {
            $result = $this->fetchFromOpenFda($query);

            if ($result !== null && $lang !== 'en') {
                $result = $this->translate($result, $lang);
            }

            // Only a real answer is worth keeping for a week — a network blip
            // must not pin "not found" onto a medicine that does exist.
            if ($result !== null && $result['identified']) {
                Cache::put($cacheKey, $result, now()->addDays(self::CACHE_DAYS));
            }
        }

        if ($result === null) {
            return response()->json([
                'error' => 'Could not reach the medicine information service.',
            ], 502);
        }

        return response()->json($result);
    }

    /**
     * Translates the label text into [$lang].
     *
     * Every field goes over in a single request separated by blank lines —
     * one field at a time took roughly 2.5 seconds each, which added up to a
     * quarter of a minute for one lookup. If anything comes back malformed
     * the English payload is returned untouched: readable English beats a
     * half-translated warning on a medicine label.
     *
     * @param array<string, mixed> $result
     * @return array<string, mixed>
     */
    private function translate(array $result, string $lang): array
    {
        // The medicine's own name is deliberately excluded — "Augmentin" must
        // stay "Augmentin" on the box the patient is holding.
        $fields = [
            'category',
            'common_uses',
            'typical_dosage',
            'warnings',
            'active_ingredient',
            'side_effects',
            'storage',
        ];

        $present = array_values(array_filter(
            $fields,
            fn (string $field) => !empty($result[$field])
        ));

        if ($present === []) {
            return $result;
        }

        try {
            $translator = new GoogleTranslate();
            $translator->setSource('en')->setTarget($lang);

            $joined = implode("\n\n", array_map(
                fn (string $field) => $result[$field],
                $present
            ));

            $translated = $translator->translate($joined);
            $pieces = preg_split('/\n\s*\n/', (string) $translated);

            if (!is_array($pieces) || count($pieces) !== count($present)) {
                Log::warning('Medicine translation split mismatch', [
                    'expected' => count($present),
                    'got' => is_array($pieces) ? count($pieces) : 0,
                ]);
                return $result;
            }

            foreach ($present as $index => $field) {
                $result[$field] = trim($pieces[$index]);
            }

            $result['lang'] = $lang;
        } catch (\Throwable $e) {
            Log::error('Medicine translation failed', ['message' => $e->getMessage()]);
        }

        return $result;
    }

    /**
     * Returns the app-facing payload, or null when openFDA could not be
     * reached at all (as opposed to answering "no such medicine").
     *
     * @return array<string, mixed>|null
     */
    private function fetchFromOpenFda(string $query): ?array
    {
        $escaped = str_replace('"', '', $query);
        $alias = self::NAME_ALIASES[mb_strtolower($escaped)] ?? null;

        $byName = fn (string $name) => sprintf(
            'openfda.brand_name:"%s"+OR+openfda.generic_name:"%s"',
            $name,
            $name
        );

        // Strongest match first: the name as typed, then its US equivalent,
        // then the ingredient list — a brand sold under another name abroad
        // still matches on what is actually in it.
        $searches = [['high', $byName($escaped)]];

        if ($alias !== null) {
            $searches[] = ['high', $byName($alias)];
        }

        $searches[] = ['medium', sprintf('active_ingredient:"%s"', $escaped)];

        foreach ($searches as [$confidence, $search]) {
            try {
                $response = Http::timeout(10)->get(
                    'https://api.fda.gov/drug/label.json?search=' . $search . '&limit=1'
                );
            } catch (\Throwable $e) {
                Log::error('openFDA lookup failed', ['message' => $e->getMessage()]);
                return null;
            }

            // openFDA answers 404 for "nothing matched", which is a valid
            // answer rather than a failure — fall through to the next search.
            if ($response->status() === 404) {
                continue;
            }

            if (!$response->successful()) {
                Log::error('openFDA lookup returned an error', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
                return null;
            }

            $label = $response->json('results.0');

            if (is_array($label)) {
                return $this->normalise($label, $query, $confidence);
            }
        }

        return [
            'identified' => false,
            'name' => $query,
            'category' => '',
            'common_uses' => 'No official label was found for this name. Check the spelling, or try the active ingredient printed on the box.',
            'typical_dosage' => '',
            'warnings' => '',
            'confidence' => 'low',
            'source' => 'openFDA',
        ];
    }

    /**
     * Maps an openFDA label onto the same shape PillIdentifierController
     * returns, so the app renders both through one medicine card.
     *
     * @param array<string, mixed> $label
     * @return array<string, mixed>
     */
    private function normalise(array $label, string $query, string $confidence): array
    {
        $openfda = $label['openfda'] ?? [];

        return [
            'identified' => true,
            'name' => $this->first($openfda['brand_name'] ?? null)
                ?? $this->first($openfda['generic_name'] ?? null)
                ?? $query,
            'category' => $this->clean(
                $this->first($openfda['pharm_class_epc'] ?? null)
                    ?? $this->first($label['purpose'] ?? null)
                    ?? ''
            ),
            'common_uses' => $this->clean(
                $this->first($label['indications_and_usage'] ?? null)
                    ?? $this->first($label['purpose'] ?? null)
                    ?? ''
            ),
            'typical_dosage' => $this->clean(
                $this->first($label['dosage_and_administration'] ?? null) ?? ''
            ),
            'warnings' => $this->clean(
                $this->first($label['warnings'] ?? null)
                    ?? $this->first($label['do_not_use'] ?? null)
                    ?? ''
            ),
            'active_ingredient' => $this->clean(
                $this->first($label['active_ingredient'] ?? null) ?? ''
            ),
            'side_effects' => $this->clean(
                $this->first($label['adverse_reactions'] ?? null) ?? ''
            ),
            'storage' => $this->clean(
                $this->first($label['storage_and_handling'] ?? null) ?? ''
            ),
            'confidence' => $confidence,
            'source' => 'openFDA',
        ];
    }

    /** openFDA returns every label section as a one-element array. */
    private function first(mixed $value): ?string
    {
        if (is_array($value)) {
            $value = $value[0] ?? null;
        }

        $value = is_string($value) ? trim($value) : null;

        return ($value === null || $value === '') ? null : $value;
    }

    /**
     * Label text repeats its own heading ("Warnings Liver warning: …") and can
     * run for pages, so the heading is dropped and the rest cut at a sentence.
     */
    private function clean(string $text): string
    {
        $text = preg_replace('/\s+/', ' ', trim($text)) ?? $text;

        // Prescription labels prefix the section number too ("1 INDICATIONS
        // AND USAGE …"), so the number goes before the heading itself.
        $text = preg_replace('/^\d+(\.\d+)*\s+/', '', $text) ?? $text;

        $text = preg_replace(
            '/^(Purposes?|Warnings?|Indications? and Usage|Dosage and Administration|Directions|Uses|Active ingredients?|Adverse Reactions?|Storage and Handling)\s*:?\s*/i',
            '',
            $text
        ) ?? $text;

        if (mb_strlen($text) <= self::MAX_FIELD_LENGTH) {
            return $text;
        }

        $cut = mb_substr($text, 0, self::MAX_FIELD_LENGTH);
        $lastStop = mb_strrpos($cut, '. ');

        return $lastStop !== false && $lastStop > 200
            ? mb_substr($cut, 0, $lastStop + 1)
            : rtrim($cut) . '…';
    }
}
