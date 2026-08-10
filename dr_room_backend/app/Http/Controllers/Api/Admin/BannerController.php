<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Banner;
use Illuminate\Support\Facades\Storage;
use Stichoza\GoogleTranslate\GoogleTranslate;

class BannerController extends Controller
{
    public function index()
    {
        return Banner::orderBy('sort_order')->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'nullable|string',
            'image' => 'required|image',
            'link_url' => 'nullable|url',
            'is_active' => 'boolean',
            'sort_order' => 'integer'
        ]);

        $path = $request->file('image')->store('banners', 'public');

        $title_en = null;
        $title_ar = null;
        if ($request->title) {
            try {
                $tr = new GoogleTranslate();
                $title_en = $tr->setTarget('en')->translate($request->title);
                $tr2 = new GoogleTranslate();
                $title_ar = $tr2->setTarget('ar')->translate($request->title);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        $banner = Banner::create([
            'title' => $request->title,
            'title_en' => $title_en,
            'title_ar' => $title_ar,
            'image_path' => $path,
            'link_url' => $request->link_url,
            'is_active' => $request->is_active ?? true,
            'sort_order' => $request->sort_order ?? 0,
        ]);

        return response()->json($banner, 201);
    }

    public function show(string $id)
    {
        return Banner::findOrFail($id);
    }

    public function update(Request $request, string $id)
    {
        $banner = Banner::findOrFail($id);
        
        $request->validate([
            'title' => 'nullable|string',
            'image' => 'nullable|image',
            'link_url' => 'nullable|url',
            'is_active' => 'boolean',
            'sort_order' => 'integer'
        ]);

        if ($request->hasFile('image')) {
            if ($banner->image_path) {
                Storage::disk('public')->delete($banner->image_path);
            }
            $banner->image_path = $request->file('image')->store('banners', 'public');
        }

        $data = $request->except('image');

        if ($request->has('title') && $request->title && $request->title != $banner->title) {
            try {
                $tr = new GoogleTranslate();
                $data['title_en'] = $tr->setTarget('en')->translate($request->title);
                $tr2 = new GoogleTranslate();
                $data['title_ar'] = $tr2->setTarget('ar')->translate($request->title);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        $banner->update($data);

        return response()->json($banner);
    }

    public function destroy(string $id)
    {
        $banner = Banner::findOrFail($id);
        Storage::disk('public')->delete($banner->image_path);
        $banner->delete();

        return response()->json(null, 204);
    }
}
