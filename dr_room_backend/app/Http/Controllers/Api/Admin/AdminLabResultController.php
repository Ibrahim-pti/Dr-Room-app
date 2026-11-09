<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use Illuminate\Http\Request;

class AdminLabResultController extends Controller
{
    public function index(Request $request)
    {
        $query = LabResult::with([
            'lab:id,name,phone,image_path',
            'patient:id,name,phone',
            'test:id,name,name_en,name_ar,price,category_id'
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('lab_id')) {
            $query->where('lab_id', $request->lab_id);
        }

        if ($request->get('missing_file') == '1') {
            $query->whereNull('file_path');
        }

        $results = $query->latest()->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $results,
        ]);
    }

    public function show($id)
    {
        $result = LabResult::with([
            'lab',
            'patient',
            'test'
        ])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }

    public function verify($id)
    {
        $result = LabResult::findOrFail($id);
        $result->status = 'completed';
        $result->save();

        return response()->json([
            'success' => true,
            'message' => 'ئەنجامی پشکنینەکە بە سەرکەوتوویی پشتڕاستکرایەوە',
            'data' => $result,
        ]);
    }
}

