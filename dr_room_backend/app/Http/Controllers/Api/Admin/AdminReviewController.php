<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\DoctorReview;
use App\Models\LabReview;
use App\Models\NurseReview;
use App\Models\PharmacyReview;
use Illuminate\Http\Request;

class AdminReviewController extends Controller
{
    /** type => [model, provider relation, foreign key on the review] */
    private const TYPES = [
        'doctor'   => [DoctorReview::class,   'doctor',   'doctor_id',   'patient'],
        'lab'      => [LabReview::class,      'lab',      'lab_id',      'patient'],
        'nurse'    => [NurseReview::class,    'nurse',    'nurse_id',    'patient'],
        'pharmacy' => [PharmacyReview::class, 'pharmacy', 'pharmacy_id', 'user'],
    ];

    /**
     * One merged, newest-first feed across all four review tables, so a
     * moderator does not have to check four separate screens.
     */
    public function index(Request $request)
    {
        $wanted = $request->filled('type') && isset(self::TYPES[$request->type])
            ? [$request->type]
            : array_keys(self::TYPES);

        $rows = collect();

        foreach ($wanted as $type) {
            [$model, , $foreignKey, $author] = self::TYPES[$type];

            $query = $model::query()->with("$author:id,name,phone")->latest();

            if ($request->input('status') === 'hidden') {
                $query->where('is_hidden', true);
            } elseif ($request->input('status') === 'visible') {
                $query->where('is_hidden', false);
            }

            if ($request->filled('min_rating')) {
                $query->where('rating', '<=', (int)$request->min_rating);
            }

            if ($request->filled('search')) {
                $query->where('comment', 'like', '%' . $request->search . '%');
            }

            foreach ($query->limit(200)->get() as $review) {
                $rows->push([
                    'id'            => $review->id,
                    'type'          => $type,
                    'type_label'    => $this->typeLabel($type),
                    'provider_id'   => $review->{$foreignKey},
                    'provider_name' => $this->providerName($type, $review->{$foreignKey}),
                    'patient_name'  => $review->{$author}?->name ?? 'نەناسراو',
                    'patient_phone' => $review->{$author}?->phone,
                    'rating'        => $review->rating,
                    'comment'       => $review->comment,
                    'is_hidden'     => (bool)$review->is_hidden,
                    'hidden_reason' => $review->hidden_reason,
                    'created_at'    => $review->created_at,
                ]);
            }
        }

        return response()->json(
            $rows->sortByDesc('created_at')->values()
        );
    }

    public function hide(Request $request, string $type, string $id)
    {
        $review = $this->find($type, $id);

        $review->update([
            'is_hidden'     => true,
            'hidden_reason' => $request->input('reason'),
            'hidden_at'     => now(),
        ]);

        $this->recalculateRating($type, $review);
        ActivityLog::record('hid_review', $review, $this->label($review), [
            'reason' => $request->input('reason'),
        ]);

        return response()->json(['message' => 'هەڵسەنگاندنەکە شاردرایەوە.']);
    }

    public function restore(string $type, string $id)
    {
        $review = $this->find($type, $id);

        $review->update(['is_hidden' => false, 'hidden_reason' => null, 'hidden_at' => null]);

        $this->recalculateRating($type, $review);
        ActivityLog::record('restored_review', $review, $this->label($review));

        return response()->json(['message' => 'هەڵسەنگاندنەکە گەڕایەوە.']);
    }

    public function destroy(string $type, string $id)
    {
        $review = $this->find($type, $id);
        $label = $this->label($review);

        $review->delete();
        $this->recalculateRating($type, $review);
        ActivityLog::record('deleted_review', null, $label);

        return response()->json(null, 204);
    }

    private function find(string $type, string $id)
    {
        abort_unless(isset(self::TYPES[$type]), 404, 'جۆری هەڵسەنگاندن نەناسراوە.');

        [$model] = self::TYPES[$type];

        return $model::findOrFail($id);
    }

    /**
     * Hidden reviews must stop counting toward the provider's public average.
     */
    private function recalculateRating(string $type, $review): void
    {
        [$model, $relation, $foreignKey] = self::TYPES[$type];

        $providerId = $review->{$foreignKey};
        if (!$providerId) {
            return;
        }

        $visible = $model::where($foreignKey, $providerId)->where('is_hidden', false);

        $provider = $review->{$relation} ?? null;
        if (!$provider) {
            return;
        }

        $provider->forceFill([
            'rating'        => round((float)$visible->avg('rating'), 1),
            'total_reviews' => (clone $visible)->count(),
        ])->save();
    }

    private function label($review): string
    {
        return 'هەڵسەنگاندن #' . $review->id . ' (' . $review->rating . '★)';
    }

    private function providerName(string $type, $providerId): string
    {
        if (!$providerId) {
            return 'نەناسراو';
        }

        $model = match ($type) {
            'doctor'   => \App\Models\Doctor::class,
            'lab'      => \App\Models\Lab::class,
            'nurse'    => \App\Models\Nurse::class,
            'pharmacy' => \App\Models\Pharmacy::class,
        };

        return $model::with('user:id,name')->find($providerId)?->user?->name ?? 'نەناسراو';
    }

    private function typeLabel(string $type): string
    {
        return [
            'doctor'   => 'پزیشک',
            'lab'      => 'تاقیگە',
            'nurse'    => 'پەرستار',
            'pharmacy' => 'دەرمانخانە',
        ][$type] ?? $type;
    }
}
