<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Stichoza\GoogleTranslate\GoogleTranslate;

class DoctorServiceController extends Controller
{
    public function index()
    {
        $doctor = Auth::user()->doctor;
        $services = $doctor->services()->latest()->get();

        return view('doctor.services.index', compact('services'));
    }

    public function store(Request $request)
    {
        $doctor = Auth::user()->doctor;

        $doctor->services()->create($this->validated($request) + ['is_active' => true]);

        return back()->with('success', 'خزمەتگوزاری نوێ بە سەرکەوتوویی زیادکرا.');
    }

    public function update(Request $request, $id)
    {
        $service = Auth::user()->doctor->services()->findOrFail($id);
        $service->update($this->validated($request));

        return back()->with('success', 'خزمەتگوزارییەکە نوێکرایەوە.');
    }

    /** Hides a service from the app without losing its history. */
    public function toggle($id)
    {
        $service = Auth::user()->doctor->services()->findOrFail($id);
        $service->update(['is_active' => ! $service->is_active]);

        return back()->with(
            'success',
            $service->is_active ? 'خزمەتگوزارییەکە چالاک کرایەوە.' : 'خزمەتگوزارییەکە شاردرایەوە.',
        );
    }

    public function destroy($id)
    {
        Auth::user()->doctor->services()->findOrFail($id)->delete();

        return back()->with('success', 'خزمەتگوزاریەکە سڕایەوە.');
    }

    /**
     * Shared rules for create and edit, including the auto-translation the
     * doctor gets when they leave the English/Arabic names blank.
     */
    private function validated(Request $request): array
    {
        $request->validate([
            'name_ckb' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'price' => 'required|numeric|min:0',
            // Must beat the current price, or it is not a discount.
            'old_price' => 'nullable|numeric|min:0|gt:price',
            'discount_until' => 'nullable|date|after_or_equal:today',
        ], [
            'old_price.gt' => 'نرخی پێشوو دەبێت لە نرخی ئێستا زیاتر بێت.',
            'discount_until.after_or_equal' => 'بەرواری کۆتایی داشکان نابێت ڕابردوو بێت.',
        ]);

        $nameCkb = $request->name_ckb;
        $nameEn = $request->name_en;
        $nameAr = $request->name_ar;

        if (! $nameEn || ! $nameAr) {
            try {
                $tr = new GoogleTranslate();
                if (! $nameEn) $nameEn = $tr->setTarget('en')->translate($nameCkb);
                if (! $nameAr) $nameAr = $tr->setTarget('ar')->translate($nameCkb);
            } catch (\Exception $e) {
                Log::error('Service translation failed: ' . $e->getMessage());
            }
        }

        return [
            'name_ckb' => $nameCkb,
            'name_en' => $nameEn,
            'name_ar' => $nameAr,
            'price' => $request->price,
            'old_price' => $request->filled('old_price') ? $request->old_price : null,
            'discount_until' => $request->filled('discount_until') ? $request->discount_until : null,
        ];
    }
}
