<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\RecruitmentOption;
use App\Services\TranslationService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RecruitmentOptionController extends Controller
{
    public function index(Request $request)
    {
        $query = RecruitmentOption::query()
            ->orderBy('sort_order')
            ->orderBy('id');

        if ($request->filled('type')) {
            $query->where('type', $request->string('type')->toString());
        }

        if ($request->filled('role_scope')) {
            $query->where('role_scope', $request->string('role_scope')->toString());
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type'       => ['required', Rule::in([RecruitmentOption::TYPE_EDUCATION, RecruitmentOption::TYPE_SKILL])],
            'role_scope' => ['nullable', Rule::in(RecruitmentOption::ROLE_SCOPES)],
            'option_key' => 'nullable|string|max:80',
            'label_ckb'  => 'required|string|max:255',
            'label_kmr'  => 'nullable|string|max:255',
            'label_ar'   => 'nullable|string|max:255',
            'label_en'   => 'nullable|string|max:255',
            'sort_order' => 'nullable|integer|min:0',
            'is_active'  => 'nullable|boolean',
        ]);

        $data['role_scope'] = $data['role_scope'] ?? RecruitmentOption::ROLE_ALL;

        $ckb = trim($data['label_ckb']);
        $data['label_ckb'] = $ckb;
        $data['label_kmr'] = $this->fillTranslation($data['label_kmr'] ?? null, $ckb, 'kmr');
        $data['label_ar']  = $this->fillTranslation($data['label_ar'] ?? null, $ckb, 'ar');
        $data['label_en']  = $this->fillTranslation($data['label_en'] ?? null, $ckb, 'en');

        $data['option_key'] = RecruitmentOption::generateUniqueKey(
            $data['type'],
            $data['option_key'] ?? $data['label_en'],
            $ckb
        );

        if (!isset($data['sort_order'])) {
            $maxOrder = (int) RecruitmentOption::where('type', $data['type'])->max('sort_order');
            $data['sort_order'] = $maxOrder + 1;
        }

        $data['is_active'] = array_key_exists('is_active', $data)
            ? filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN)
            : true;

        $option = RecruitmentOption::create($data);

        return response()->json($option, 201);
    }

    public function update(Request $request, string $id)
    {
        $option = RecruitmentOption::findOrFail($id);

        $data = $request->validate([
            'role_scope' => ['nullable', Rule::in(RecruitmentOption::ROLE_SCOPES)],
            'label_ckb'  => 'sometimes|required|string|max:255',
            'label_kmr'  => 'nullable|string|max:255',
            'label_ar'   => 'nullable|string|max:255',
            'label_en'   => 'nullable|string|max:255',
            'sort_order' => 'nullable|integer|min:0',
            'is_active'  => 'nullable|boolean',
        ]);

        if (array_key_exists('label_ckb', $data)) {
            $ckb = trim($data['label_ckb']);
            $data['label_ckb'] = $ckb;

            if (array_key_exists('label_kmr', $data)) {
                $data['label_kmr'] = $this->fillTranslation($data['label_kmr'], $ckb, 'kmr');
            }
            if (array_key_exists('label_ar', $data)) {
                $data['label_ar'] = $this->fillTranslation($data['label_ar'], $ckb, 'ar');
            }
            if (array_key_exists('label_en', $data)) {
                $data['label_en'] = $this->fillTranslation($data['label_en'], $ckb, 'en');
            }
        }

        if (array_key_exists('is_active', $data)) {
            $data['is_active'] = filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN);
        }

        $option->update($data);

        return response()->json($option->fresh());
    }

    public function destroy(string $id)
    {
        $option = RecruitmentOption::findOrFail($id);
        $option->delete();

        return response()->json(null, 204);
    }

    public function reorder(Request $request)
    {
        $request->validate([
            'items'              => 'required|array',
            'items.*.id'         => 'required|exists:recruitment_options,id',
            'items.*.sort_order' => 'required|integer|min:0',
        ]);

        foreach ($request->items as $item) {
            RecruitmentOption::where('id', $item['id'])->update([
                'sort_order' => (int) $item['sort_order'],
            ]);
        }

        return response()->json(['message' => 'ڕیزبەندی نوێکرایەوە.']);
    }

    private function fillTranslation(?string $current, string $sourceCkb, string $target): string
    {
        $trimmed = trim((string) $current);
        if ($trimmed !== '') {
            return $trimmed;
        }

        try {
            return TranslationService::translate($sourceCkb, $target, 'ckb');
        } catch (\Throwable $e) {
            return $sourceCkb;
        }
    }
}
