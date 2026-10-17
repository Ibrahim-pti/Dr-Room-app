<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmergencyContact;
use Illuminate\Http\Request;

class EmergencyContactController extends Controller
{
    /**
     * Public API for user app
     */
    public function index()
    {
        $contacts = EmergencyContact::active()
            ->orderBy('is_primary', 'desc')
            ->orderBy('sort_order', 'asc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $contacts,
        ]);
    }

    /**
     * Admin: List all contacts
     */
    public function adminIndex()
    {
        $contacts = EmergencyContact::orderBy('is_primary', 'desc')
            ->orderBy('sort_order', 'asc')
            ->orderBy('id', 'asc')
            ->get();

        return response()->json($contacts);
    }

    /**
     * Admin: Store new contact
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'subtitle' => 'nullable|string|max:255',
            'phone' => 'required|string|max:50',
            'icon_type' => 'nullable|string|in:ambulance,hospital,blood_bank,general',
            'is_primary' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $contact = EmergencyContact::create([
            'title' => $validated['title'],
            'subtitle' => $validated['subtitle'] ?? null,
            'phone' => $validated['phone'],
            'icon_type' => $validated['icon_type'] ?? 'hospital',
            'is_primary' => $request->boolean('is_primary'),
            'is_active' => $request->has('is_active') ? $request->boolean('is_active') : true,
            'sort_order' => $validated['sort_order'] ?? 0,
        ]);

        return response()->json($contact, 201);
    }

    /**
     * Admin: Update contact
     */
    public function update(Request $request, $id)
    {
        $contact = EmergencyContact::findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'subtitle' => 'nullable|string|max:255',
            'phone' => 'sometimes|required|string|max:50',
            'icon_type' => 'nullable|string|in:ambulance,hospital,blood_bank,general',
            'is_primary' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $contact->update($validated);

        return response()->json($contact);
    }

    /**
     * Admin: Quick Toggle Active Status
     */
    public function toggle($id)
    {
        $contact = EmergencyContact::findOrFail($id);
        $contact->is_active = !$contact->is_active;
        $contact->save();

        return response()->json([
            'message' => 'Status toggled successfully',
            'contact' => $contact,
        ]);
    }

    /**
     * Admin: Delete contact
     */
    public function destroy($id)
    {
        $contact = EmergencyContact::findOrFail($id);
        $contact->delete();

        return response()->json(['message' => 'Deleted successfully'], 200);
    }
}
