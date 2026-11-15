<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\ProviderReportService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseReportController extends Controller
{
    public function index(Request $request, ProviderReportService $reports)
    {
        $selectedMonth = $request->query('month');
        $report = $reports->buildForNurse((int) Auth::id(), $selectedMonth);

        return view('shared.provider_reports', array_merge($report, [
            'layout' => 'nurse.layouts.app',
            'routeName' => 'nurse.reports.index',
        ]));
    }
}
