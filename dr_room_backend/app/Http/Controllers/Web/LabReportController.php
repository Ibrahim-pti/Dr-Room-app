<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\ProviderReportService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabReportController extends Controller
{
    public function index(Request $request, ProviderReportService $reports)
    {
        $user = Auth::user();
        $report = $reports->buildForLab(
            (int) $user->id,
            $user->lab?->id,
            $request->query('month')
        );

        return view('shared.provider_reports', array_merge($report, [
            'layout' => 'lab.layouts.app',
            'routeName' => 'lab.reports.index',
        ]));
    }
}
