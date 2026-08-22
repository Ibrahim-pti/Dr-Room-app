<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Article;
use Illuminate\Support\Facades\Storage;
use Stichoza\GoogleTranslate\GoogleTranslate;

class ArticleController extends Controller
{
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
            'image' => 'nullable|image',
            'is_published' => 'nullable|boolean'
        ]);

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('articles', 'public');
        }

        $title_en = $request->title_en;
        $title_ar = $request->title_ar;
        $category_en = $request->category_en;
        $category_ar = $request->category_ar;
        $content_en = $request->content_en;
        $content_ar = $request->content_ar;

        try {
            $tr = new GoogleTranslate();
            if (!$title_en && $request->title) $title_en = $tr->setTarget('en')->translate($request->title);
            if (!$title_ar && $request->title) $title_ar = $tr->setTarget('ar')->translate($request->title);
            if (!$category_en && $request->category) $category_en = $tr->setTarget('en')->translate($request->category);
            if (!$category_ar && $request->category) $category_ar = $tr->setTarget('ar')->translate($request->category);
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
            'content' => $request->content,
            'content_en' => $content_en,
            'content_ar' => $content_ar,
            'symptoms' => $request->symptoms,
            'steps' => $request->steps,
            'dos' => $request->dos,
            'donts' => $request->donts,
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
            'image' => 'nullable|image',
            'is_published' => 'nullable|boolean'
        ]);

        if ($request->hasFile('image')) {
            if ($article->image_path) {
                Storage::disk('public')->delete($article->image_path);
            }
            $article->image_path = $request->file('image')->store('articles', 'public');
        }

        $data = $request->except('image');

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
