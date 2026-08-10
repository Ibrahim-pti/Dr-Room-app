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
            'content' => 'required|string',
            'image' => 'nullable|image',
            'is_published' => 'boolean'
        ]);

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('articles', 'public');
        }

        $title_en = null;
        $title_ar = null;
        $content_en = null;
        $content_ar = null;

        try {
            $tr = new GoogleTranslate();
            $title_en = $tr->setTarget('en')->translate($request->title);
            $tr2 = new GoogleTranslate();
            $title_ar = $tr2->setTarget('ar')->translate($request->title);
            
            $tr3 = new GoogleTranslate();
            $content_en = $tr3->setTarget('en')->translate($request->content);
            $tr4 = new GoogleTranslate();
            $content_ar = $tr4->setTarget('ar')->translate($request->content);
        } catch (\Exception $e) {
            \Log::error('Translation error: ' . $e->getMessage());
        }

        $article = Article::create([
            'title' => $request->title,
            'title_en' => $title_en,
            'title_ar' => $title_ar,
            'content' => $request->content,
            'content_en' => $content_en,
            'content_ar' => $content_ar,
            'image_path' => $path,
            'is_published' => $request->is_published ?? true,
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
            'content' => 'nullable|string',
            'image' => 'nullable|image',
            'is_published' => 'boolean'
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
