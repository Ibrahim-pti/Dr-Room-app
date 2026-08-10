<?php
namespace App\Http\Controllers\Web;
use App\Http\Controllers\Controller;
class PharmacyNotificationController extends Controller {
    public function index() { return view('pharmacy.notifications.index'); }
}
