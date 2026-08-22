<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ServiceCategoryController extends Controller
{
    /** The scope list, so the admin app builds its tabs from the server. */
    public function scopes()
    {
        return response()->json(
            collect(ServiceCategory::SCOPES)
                ->map(fn ($label, $value) => [
                    'value' => $value,
                    'label' => $label,
                    'count' => ServiceCategory::ofScope($value)->count(),
                ])
                ->values()
        );
    }

    public function index(Request $request)
    {
        $query = ServiceCategory::orderBy('sort_order')->orderBy('name');

        if ($request->filled('scope')) {
            $query->ofScope($request->scope);
        }

        return $query->get();
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $data['image_path'] = $this->storeImage($request);

        $category = ServiceCategory::create($data);

        return response()->json($category, 201);
    }

    public function update(Request $request, string $id)
    {
        $category = ServiceCategory::findOrFail($id);
        $data = $this->validated($request, $category->id);

        if ($path = $this->storeImage($request)) {
            if ($category->image_path) {
                Storage::disk('public')->delete($category->image_path);
            }
            $data['image_path'] = $path;
        }

        $category->update($data);

        return response()->json($category);
    }

    public function destroy(string $id)
    {
        $category = ServiceCategory::findOrFail($id);

        if ($category->image_path) {
            Storage::disk('public')->delete($category->image_path);
        }

        $category->delete();

        return response()->json(null, 204);
    }

    /** Drag-and-drop ordering: `[{id, sort_order}, ...]`. */
    public function reorder(Request $request)
    {
        $request->validate([
            'items'              => 'required|array',
            'items.*.id'         => 'required|exists:service_categories,id',
            'items.*.sort_order' => 'required|integer|min:0',
        ]);

        foreach ($request->items as $item) {
            ServiceCategory::where('id', $item['id'])->update(['sort_order' => $item['sort_order']]);
        }

        return response()->json(['message' => 'ڕیزبەندی نوێکرایەوە.']);
    }

    private function validated(Request $request, ?int $ignoreId = null): array
    {
        $rules = [
            'scope'       => ['required', Rule::in(array_keys(ServiceCategory::SCOPES))],
            'name'        => [
                'required', 'string', 'max:255',
                Rule::unique('service_categories')
                    ->where(fn ($q) => $q->where('scope', $request->scope))
                    ->ignore($ignoreId),
            ],
            'name_en'     => 'nullable|string|max:255',
            'name_ar'     => 'nullable|string|max:255',
            'icon'        => 'nullable|string|max:80',
            'color'       => 'nullable|string|max:9',
            'description' => 'nullable|string',
            'sort_order'  => 'nullable|integer|min:0',
            'is_active'   => 'nullable|boolean',
            'image'       => 'nullable|image|max:8192',
        ];

        if ($request->isMethod('put') || $request->isMethod('patch') || $request->input('_method') === 'PUT') {
            $rules['scope'][0] = 'sometimes';
            $rules['name'][0] = 'sometimes';
        }

        $data = $request->validate($rules);
        unset($data['image']);

        if (array_key_exists('is_active', $data)) {
            $data['is_active'] = filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN);
        }

        return $data;
    }

    private function storeImage(Request $request): ?string
    {
        return $request->hasFile('image')
            ? $request->file('image')->store('categories', 'public')
            : null;
    }
}
