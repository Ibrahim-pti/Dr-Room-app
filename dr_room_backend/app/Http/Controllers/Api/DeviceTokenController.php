<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DeviceTokenController extends Controller
{
    /** Called by the app on launch and whenever Firebase rotates the token. */
    public function store(Request $request)
    {
        $data = $request->validate([
            'token'       => 'required|string|max:512',
            'platform'    => 'nullable|in:ios,android,web',
            'device_name' => 'nullable|string|max:120',
        ]);

        $device = DeviceToken::updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id'      => Auth::id(),
                'platform'     => $data['platform'] ?? null,
                'device_name'  => $data['device_name'] ?? null,
                'last_used_at' => now(),
            ]
        );

        return response()->json(['message' => 'تۆمارکرا.', 'id' => $device->id]);
    }

    /** Called on logout so the device stops receiving that account's pushes. */
    public function destroy(Request $request)
    {
        $request->validate(['token' => 'required|string']);

        DeviceToken::where('token', $request->token)->delete();

        return response()->json(null, 204);
    }
}
