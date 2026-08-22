<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AppNotification;
use App\Services\FcmService;
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

        $data['title_en'] = $request->title_en ?: null;
        $data['title_ar'] = $request->title_ar ?: null;
        $data['message_en'] = $request->message_en ?: null;
        $data['message_ar'] = $request->message_ar ?: null;

        if (empty($data['title_en']) || empty($data['title_ar']) || empty($data['message_en']) || empty($data['message_ar'])) {
            try {
                $tr = new GoogleTranslate();
                if (empty($data['title_en'])) $data['title_en'] = $tr->setTarget('en')->translate($request->title);
                if (empty($data['title_ar'])) $data['title_ar'] = $tr->setTarget('ar')->translate($request->title);
                if (empty($data['message_en'])) $data['message_en'] = $tr->setTarget('en')->translate($request->message);
                if (empty($data['message_ar'])) $data['message_ar'] = $tr->setTarget('ar')->translate($request->message);
            } catch (\Throwable $e) {
                \Log::warning('Translation error: ' . $e->getMessage());
                // Fallback to original text if translation service fails
                $data['title_en'] = $data['title_en'] ?: $request->title;
                $data['title_ar'] = $data['title_ar'] ?: $request->title;
                $data['message_en'] = $data['message_en'] ?: $request->message;
                $data['message_ar'] = $data['message_ar'] ?: $request->message;
            }
        }

        $notification = AppNotification::create($data);


        $imageUrl = null;
        if (!empty($notification->image_path)) {
            $imageUrl = url('storage/' . $notification->image_path);
        }

        // Null user_id means a broadcast; otherwise it targets one account.
        $delivery = app(FcmService::class)->sendToUsers(
            $request->user_id ? [$request->user_id] : null,
            $notification->title,
            $notification->message,
            [
                'notification_id' => $notification->id,
                'type' => $notification->type,
                'image_path' => $notification->image_path ?? '',
            ],
            $imageUrl
        );

        return response()->json([
            'notification' => $notification,
            'push' => $delivery,
        ], 201);
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
