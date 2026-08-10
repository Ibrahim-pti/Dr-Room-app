<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AppNotification;
use Stichoza\GoogleTranslate\GoogleTranslate;

class NotificationController extends Controller
{
    public function index()
    {
        return AppNotification::latest()->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'message' => 'required|string',
            'type' => 'nullable|string',
            'user_id' => 'nullable|exists:users,id',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        $data = [
            'title' => $request->title,
            'message' => $request->message,
            'type' => $request->type ?? 'general',
            'user_id' => $request->user_id,
        ];

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('notifications', 'public');
        }

        try {
            $tr = new GoogleTranslate();
            $data['title_en'] = $tr->setTarget('en')->translate($request->title);
            $tr2 = new GoogleTranslate();
            $data['title_ar'] = $tr2->setTarget('ar')->translate($request->title);
            
            $tr3 = new GoogleTranslate();
            $data['message_en'] = $tr3->setTarget('en')->translate($request->message);
            $tr4 = new GoogleTranslate();
            $data['message_ar'] = $tr4->setTarget('ar')->translate($request->message);
        } catch (\Exception $e) {
            \Log::error('Translation error: ' . $e->getMessage());
        }

        $notification = AppNotification::create($data);

        // Here we would trigger Firebase Cloud Messaging (FCM) or APNS to send the push notification to mobile devices.

        return response()->json($notification, 201);
    }

    public function show(string $id)
    {
        return AppNotification::findOrFail($id);
    }

    public function update(Request $request, string $id)
    {
        $notification = AppNotification::findOrFail($id);
        
        $request->validate([
            'title' => 'nullable|string',
            'message' => 'nullable|string',
            'type' => 'nullable|string',
            'user_id' => 'nullable|exists:users,id'
        ]);

        $data = $request->all();

        if ($request->has('title') && $request->title != $notification->title) {
            try {
                $tr = new GoogleTranslate();
                $data['title_en'] = $tr->setTarget('en')->translate($request->title);
                $tr2 = new GoogleTranslate();
                $data['title_ar'] = $tr2->setTarget('ar')->translate($request->title);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        if ($request->has('message') && $request->message != $notification->message) {
            try {
                $tr = new GoogleTranslate();
                $data['message_en'] = $tr->setTarget('en')->translate($request->message);
                $tr2 = new GoogleTranslate();
                $data['message_ar'] = $tr2->setTarget('ar')->translate($request->message);
            } catch (\Exception $e) {
                \Log::error('Translation error: ' . $e->getMessage());
            }
        }

        $notification->update($data);

        return response()->json($notification);
    }

    public function destroy(string $id)
    {
        $notification = AppNotification::findOrFail($id);
        $notification->delete();

        return response()->json(null, 204);
    }
}
