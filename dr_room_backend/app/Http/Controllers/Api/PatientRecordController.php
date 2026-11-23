<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use App\Models\NurseAppointment;
use App\Models\NursePatientCare;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PatientRecordController extends Controller
{
    /**
     * Get all lab results for the authenticated patient
     */
    public function labResults(Request $request = null)
    {
        $patient = Auth::user();
        $patientId = $patient ? $patient->id : null;

        $results = LabResult::with(['lab.user', 'test'])
            ->where('patient_id', $patientId)
            ->latest()
            ->get()
            ->map(function ($result) use ($patient) {
                $labName = $result->lab?->user?->name ?? $result->lab?->name ?? 'تاقیگەی گشتی';
                return [
                    'id' => $result->id,
                    'lab_name' => $labName,
                    'lab_phone' => $result->lab?->phone ?? ($result->lab?->user?->phone ?? null),
                    'lab_location' => $result->lab?->location ?? null,
                    'patient_name' => $patient?->name ?? 'نەخۆش',
                    'patient_phone' => $patient?->phone ?? null,
                    'test_name' => $result->test?->name ?? 'پشکنینی تاقیگە',
                    'test_type' => $result->test?->type ?? null,
                    'result_value' => $result->result_value,
                    'status' => $result->status,
                    'file_url' => $result->file_path ? url('storage/' . $result->file_path) : null,
                    'official_report_url' => \Illuminate\Support\Facades\URL::signedRoute('reports.lab.official', ['result' => $result->id]),
                    'notes' => $result->notes,
                    'created_at' => $result->created_at ? $result->created_at->timezone('Asia/Baghdad')->format('Y-m-d H:i') : now('Asia/Baghdad')->format('Y-m-d H:i'),
                    'created_at_human' => $result->created_at ? $result->created_at->diffForHumans() : 'Recently',
                ];
            });

        return response()->json([
            'success' => true,
            'branding' => \App\Services\ReportBrandingService::get(),
            'data' => $results,
        ]);
    }

    /**
     * Get all nurse care records for the authenticated patient:
     * merges manual NursePatientCare clinical entries + completed nursing orders
     * and completed nurse appointments so nursing records never appear empty.
     */
    public function nurseCares(Request $request = null)
    {
        $patient = Auth::user();
        $patientId = $patient ? $patient->id : null;
        if (!$patientId) {
            return response()->json(['success' => true, 'data' => []]);
        }

        $records = collect();

        $cares = NursePatientCare::with(['nurse.user'])
            ->where('patient_id', $patientId)
            ->latest()
            ->get();

        foreach ($cares as $care) {
            $dt = $care->date
                ? (is_string($care->date) ? $care->date : $care->date->format('Y-m-d'))
                : ($care->created_at?->timezone('Asia/Baghdad')->format('Y-m-d') ?? '');
            $records->push([
                'id' => 'care_' . $care->id,
                'source' => 'care',
                'title' => 'چاودێری پەرستاری',
                'nurse_name' => $care->nurse?->user?->name ?? 'پەرستاری گەڕۆک',
                'date' => $dt,
                'symptoms' => $care->symptoms,
                'vitals' => is_array($care->vitals) ? $care->vitals : null,
                'medication_given' => $care->medication_given,
                'notes' => $care->notes,
                'status' => 'تۆمارکراو',
                'created_at' => $care->created_at?->timezone('Asia/Baghdad')->format('Y-m-d H:i') ?? now('Asia/Baghdad')->format('Y-m-d H:i'),
                '_sort' => $care->created_at?->timestamp ?? 0,
            ]);
        }

        $nursingOrders = Order::with(['items', 'assignedNurse.nurse', 'assignedDriver'])
            ->where('patient_id', $patientId)
            ->forNursing()
            ->whereIn('status', ['completed', 'delivered', 'done'])
            ->latest()
            ->get();

        foreach ($nursingOrders as $order) {
            $itemNames = $order->items?->pluck('item_name')->filter()->join('، ');
            $nurseName = $order->assignedNurse?->name
                ?? $order->assignedDriver?->name
                ?? ($order->patient_details['staff_name'] ?? 'پەرستاری گەڕۆک');
            $refDate = $order->scheduled_at ?? $order->updated_at ?? $order->created_at;

            $records->push([
                'id' => 'order_' . $order->id,
                'order_id' => $order->id,
                'source' => 'order',
                'title' => !empty($itemNames) ? $itemNames : 'خزمەتگوزاری پەرستاری',
                'nurse_name' => $nurseName,
                'date' => $refDate?->timezone('Asia/Baghdad')->format('Y-m-d H:i') ?? '',
                'symptoms' => null,
                'vitals' => null,
                'medication_given' => null,
                'notes' => $order->patient_details['notes'] ?? ($order->location_details['address'] ?? null),
                'status' => 'تەواوکراو',
                'created_at' => $order->created_at?->timezone('Asia/Baghdad')->format('Y-m-d H:i') ?? '',
                '_sort' => $order->created_at?->timestamp ?? 0,
            ]);
        }

        $linkedApptIds = $cares->pluck('appointment_id')->filter()->all();
        $nurseAppts = NurseAppointment::with(['nurse.user'])
            ->where('patient_id', $patientId)
            ->where('status', 'completed')
            ->when(!empty($linkedApptIds), fn ($q) => $q->whereNotIn('id', $linkedApptIds))
            ->latest()
            ->get();

        foreach ($nurseAppts as $appt) {
            $services = is_array($appt->services) ? implode('، ', $appt->services) : '';
            $records->push([
                'id' => 'appt_' . $appt->id,
                'source' => 'appointment',
                'title' => !empty($services) ? $services : 'سەردانی پەرستار',
                'nurse_name' => $appt->nurse?->user?->name ?? 'پەرستاری گەڕۆک',
                'date' => $appt->appointment_date ? \Carbon\Carbon::parse($appt->appointment_date)->format('Y-m-d H:i') : '',
                'symptoms' => null,
                'vitals' => null,
                'medication_given' => null,
                'notes' => $appt->notes,
                'status' => 'تەواوکراو',
                'created_at' => $appt->created_at?->timezone('Asia/Baghdad')->format('Y-m-d H:i') ?? '',
                '_sort' => $appt->created_at?->timestamp ?? 0,
            ]);
        }

        $sorted = $records->sortByDesc('_sort')
            ->map(function ($r) {
                unset($r['_sort']);
                return $r;
            })
            ->values();

        return response()->json([
            'success' => true,
            'data' => $sorted,
        ]);
    }
}
