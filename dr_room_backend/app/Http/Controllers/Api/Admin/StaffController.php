<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\User;
use App\Support\Permissions;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StaffController extends Controller
{
    /** Roles and permission labels, so the app never hardcodes them. */
    public function meta()
    {
        return response()->json([
            'roles' => collect(Permissions::STAFF_ROLES)->map(fn ($role) => [
                'value' => $role,
                'label' => Permissions::ROLE_LABELS[$role] ?? $role,
                'default_permissions' => Permissions::defaultsFor($role),
            ])->values(),
            'permissions' => collect(Permissions::ALL)->map(fn ($p) => [
                'value' => $p,
                'label' => Permissions::LABELS[$p] ?? $p,
            ])->values(),
        ]);
    }

    public function index()
    {
        return User::whereIn('role', Permissions::STAFF_ROLES)
            ->latest()
            ->get()
            ->map(fn (User $u) => $this->present($u));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'phone'    => 'nullable|string|max:30',
            'password' => 'required|string|min:6',
            'role'     => ['required', Rule::in(Permissions::STAFF_ROLES)],
            'permissions'   => 'nullable|array',
            'permissions.*' => ['string', Rule::in(Permissions::ALL)],
        ]);

        $staff = User::create([
            'name'        => $data['name'],
            'email'       => $data['email'],
            'phone'       => $data['phone'] ?? null,
            'password'    => Hash::make($data['password']),
            'role'        => $data['role'],
            'status'      => 'approved',
            'permissions' => $data['permissions'] ?? null,
        ]);

        ActivityLog::record('created', $staff, "ستافی نوێ: {$staff->name}", ['role' => $staff->role]);

        return response()->json($this->present($staff), 201);
    }

    public function update(Request $request, string $id)
    {
        $staff = User::whereIn('role', Permissions::STAFF_ROLES)->findOrFail($id);
        $this->guardLastAdmin($request, $staff);

        $data = $request->validate([
            'name'     => 'nullable|string|max:255',
            'email'    => ['nullable', 'email', Rule::unique('users', 'email')->ignore($staff->id)],
            'phone'    => 'nullable|string|max:30',
            'password' => 'nullable|string|min:6',
            'role'     => ['nullable', Rule::in(Permissions::STAFF_ROLES)],
            'status'   => ['nullable', Rule::in(['approved', 'blocked'])],
            'permissions'   => 'nullable|array',
            'permissions.*' => ['string', Rule::in(Permissions::ALL)],
        ]);

        $before = $staff->only(['role', 'status']);

        $staff->fill(array_filter([
            'name'   => $data['name'] ?? null,
            'email'  => $data['email'] ?? null,
            'phone'  => $data['phone'] ?? null,
            'role'   => $data['role'] ?? null,
            'status' => $data['status'] ?? null,
        ], fn ($v) => $v !== null));

        if (!empty($data['password'])) {
            $staff->password = Hash::make($data['password']);
        }

        // An explicitly sent empty array resets the user back to role defaults.
        if ($request->has('permissions')) {
            $staff->permissions = $data['permissions'] ?: null;
        }

        $staff->save();

        ActivityLog::record('updated', $staff, "ستاف: {$staff->name}", [
            'before' => $before,
            'after'  => $staff->only(['role', 'status']),
        ]);

        return response()->json($this->present($staff));
    }

    public function destroy(Request $request, string $id)
    {
        $staff = User::whereIn('role', Permissions::STAFF_ROLES)->findOrFail($id);
        $this->guardLastAdmin($request, $staff);

        $name = $staff->name;
        $staff->delete();

        ActivityLog::record('deleted', null, "ستاف سڕایەوە: {$name}");

        return response()->json(null, 204);
    }

    /** Nobody may delete or demote themselves, or remove the last admin. */
    private function guardLastAdmin(Request $request, User $staff): void
    {
        if ($request->user()->id === $staff->id) {
            abort(422, 'ناتوانیت هەژماری خۆت بگۆڕیت یان بسڕیتەوە.');
        }

        if ($staff->role === 'admin' && User::where('role', 'admin')->count() <= 1) {
            abort(422, 'ناتوانیت تاکە ئەدمینی سەرەکی لاببەیت.');
        }
    }

    private function present(User $u): array
    {
        return [
            'id'            => $u->id,
            'name'          => $u->name,
            'email'         => $u->email,
            'phone'         => $u->phone,
            'role'          => $u->role,
            'role_label'    => Permissions::ROLE_LABELS[$u->role] ?? $u->role,
            'status'        => $u->status,
            'permissions'   => $u->permission_list,
            'is_custom'     => is_array($u->permissions) && $u->permissions !== [],
            'last_login_at' => $u->last_login_at,
            'created_at'    => $u->created_at,
        ];
    }
}
