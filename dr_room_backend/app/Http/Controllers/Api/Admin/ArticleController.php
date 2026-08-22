<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Article;
use Illuminate\Support\Facades\Storage;
use Stichoza\GoogleTranslate\GoogleTranslate;

class ArticleController extends Controller
{
    /**
     * Fields sent from the admin panel as JSON strings (multipart/form-data
     * cannot carry real arrays). Decode them so the model casts store proper JSON.
     */
    private function decodeJsonFields(array $data): array
    {
        foreach (['symptoms', 'steps', 'dos', 'donts'] as $field) {
            if (!array_key_exists($field, $data)) {
                continue;
            }

            $value = $data[$field];

            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $value = json_last_error() === JSON_ERROR_NONE ? $decoded : null;
            }

            if (!is_array($value)) {
                $data[$field] = null;
                continue;
            }

            if ($field === 'steps') {
                $steps = [];
                foreach ($value as $step) {
                    if (is_array($step)) {
                        $title = trim((string)($step['title'] ?? ''));
                        $desc = trim((string)($step['desc'] ?? ''));
                    } else {
                        $title = 'هەنگاو';
                        $desc = trim((string)$step);
                    }
                    if ($title === '' && $desc === '') {
                        continue;
                    }
                    $steps[] = ['title' => $title !== '' ? $title : 'هەنگاو', 'desc' => $desc];
                }
                $data[$field] = $steps ?: null;
                continue;
            }

            $items = array_values(array_filter(
                array_map(fn ($item) => trim((string)$item), $value),
                fn ($item) => $item !== ''
            ));
            $data[$field] = $items ?: null;
        }

        return $data;
    }
    public function index()
    {
        return Article::latest()->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'category' => 'nullable|string',
            'short_desc' => 'nullable|string',
            'content' => 'required|string',
            'image' => 'nullable|image|max:8192',
            'is_published' => 'nullable|boolean',
            'symptoms' => 'nullable|string',
            'steps' => 'nullable|string',
            'dos' => 'nullable|string',
            'donts' => 'nullable|string',
            'when_to_call_ambulance' => 'nullable|string',
        ]);

        $medical = $this->decodeJsonFields($request->only(['symptoms', 'steps', 'dos', 'donts']));

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('articles', 'public');
        }

        $title_en = $request->title_en;
        $title_ar = $request->title_ar;
        $category_en = $request->category_en;
        $category_ar = $request->category_ar;
        $short_desc_en = $request->short_desc_en;
        $short_desc_ar = $request->short_desc_ar;
        $content_en = $request->content_en;
        $content_ar = $request->content_ar;

        try {
            $tr = new GoogleTranslate();
            if (!$title_en && $request->title) $title_en = $tr->setTarget('en')->translate($request->title);
            if (!$title_ar && $request->title) $title_ar = $tr->setTarget('ar')->translate($request->title);
            if (!$category_en && $request->category) $category_en = $tr->setTarget('en')->translate($request->category);
            if (!$category_ar && $request->category) $category_ar = $tr->setTarget('ar')->translate($request->category);
            if (!$short_desc_en && $request->short_desc) $short_desc_en = $tr->setTarget('en')->translate($request->short_desc);
            if (!$short_desc_ar && $request->short_desc) $short_desc_ar = $tr->setTarget('ar')->translate($request->short_desc);
            if (!$content_en && $request->content) $content_en = $tr->setTarget('en')->translate($request->content);
            if (!$content_ar && $request->content) $content_ar = $tr->setTarget('ar')->translate($request->content);
        } catch (\Exception $e) {
            \Log::error('Translation error: ' . $e->getMessage());
        }

        $article = Article::create([
            'title' => $request->title,
            'title_en' => $title_en,
            'title_ar' => $title_ar,
            'category' => $request->category ?? 'گشتی',
            'category_en' => $category_en ?? 'General',
            'category_ar' => $category_ar ?? 'عام',
            'short_desc' => $request->short_desc,
            'short_desc_en' => $short_desc_en,
            'short_desc_ar' => $short_desc_ar,
            'content' => $request->content,
            'content_en' => $content_en,
            'content_ar' => $content_ar,
            'symptoms' => $medical['symptoms'] ?? null,
            'steps' => $medical['steps'] ?? null,
            'dos' => $medical['dos'] ?? null,
            'donts' => $medical['donts'] ?? null,
            'when_to_call_ambulance' => $request->when_to_call_ambulance,
            'image_path' => $path,
            'is_published' => $request->has('is_published') ? (bool)$request->is_published : true,
        ]);

        return response()->json($article, 201);
    }

    public function show(string $id)
    {
        return Article::findOrFail($id);
    }

    public function update(Request $request, string $id)
    {
        $article = Article::findOrFail($id);
        
        $request->validate([
            'title' => 'nullable|string',
            'category' => 'nullable|string',
            'short_desc' => 'nullable|string',
            'content' => 'nullable|string',
            'image' => 'nullable|image|max:8192',
            'is_published' => 'nullable|boolean',
            'symptoms' => 'nullable|string',
            'steps' => 'nullable|string',
            'dos' => 'nullable|string',
            'donts' => 'nullable|string',
            'when_to_call_ambulance' => 'nullable|string',
        ]);

        if ($request->hasFile('image')) {
            if ($article->image_path) {
                Storage::disk('public')->delete($article->image_path);
            }
            $article->image_path = $request->file('image')->store('articles', 'public');
        }

        $data = $this->decodeJsonFields($request->except(['image', '_method']));

        if ($request->has('title') && $request->title != $article->title) {
            try {
                $tr = new GoogleTranslate();
                $data['title_en'] = $tr->setTarget('en')->translate($request->title);
                $tr2 = new GoogleTranslate();
                $data['title_ar'] = $tr2->setTarget('ar')->translate($request->title);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        if ($request->has('category') && $request->category != $article->category) {
            try {
                $tr = new GoogleTranslate();
                $data['category_en'] = $tr->setTarget('en')->translate($request->category);
                $tr2 = new GoogleTranslate();
                $data['category_ar'] = $tr2->setTarget('ar')->translate($request->category);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        if ($request->has('content') && $request->content != $article->content) {
            try {
                $tr = new GoogleTranslate();
                $data['content_en'] = $tr->setTarget('en')->translate($request->content);
                $tr2 = new GoogleTranslate();
                $data['content_ar'] = $tr2->setTarget('ar')->translate($request->content);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        $article->update($data);

        return response()->json($article);
    }

    public function destroy(string $id)
    {
        $article = Article::findOrFail($id);
        if ($article->image_path) {
            Storage::disk('public')->delete($article->image_path);
        }
        $article->delete();

        return response()->json(null, 204);
    }
}
