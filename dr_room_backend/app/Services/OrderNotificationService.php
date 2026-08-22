<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Order;
use Illuminate\Support\Facades\Log;

class OrderNotificationService
{
    /**
     * Send notification to the patient when order status changes (Accepted, Rejected, Completed).
     */
    public static function notifyStatusChanged(Order $order, string $newStatus, ?string $customNote = null): void
    {
        $patientId = $order->patient_id;
        if (!$patientId) {
            return;
        }

        $serviceType = strtolower($order->service_type ?? 'general');

        // Titles and messages based on status & service type
        $titleKu = '';
        $titleAr = '';
        $titleEn = '';
        $messageKu = '';
        $messageAr = '';
        $messageEn = '';

        if ($newStatus === 'processing' || $newStatus === 'accepted') {
            $titleKu = 'داواکارییەکەت قبوڵکرا ✅';
            $titleAr = 'تم قبول طلبك بنجاح ✅';
            $titleEn = 'Your Order Has Been Accepted ✅';

            if (str_contains($serviceType, 'nurse') || str_contains($serviceType, 'nursing')) {
                $messageKu = 'داواکاری پەرستارەکەت قبوڵکرا و بەم زووانە پەرستار دەگاتە لات.';
                $messageAr = 'تم قبول طلب الممرض وسيصل إليك في أقرب وقت.';
                $messageEn = 'Your nursing request was accepted. The nurse is on their way.';
            } elseif (str_contains($serviceType, 'pharmacy') || str_contains($serviceType, 'medicine')) {
                $messageKu = 'داواکاری دەرمانەکەت لە دەرمانخانە قبوڵکرا و ئێستا لە قۆناغی ئامادەکردندایە.';
                $messageAr = 'تم قبول طلب الأدوية من الصيدلية وهو قيد التحضير الآن.';
                $messageEn = 'Your medication order has been accepted by the pharmacy and is being prepared.';
            } elseif (str_contains($serviceType, 'lab')) {
                $messageKu = 'داواکاری پشکنینەکەت لە تاقیگە قبوڵکرا.';
                $messageAr = 'تم قبول طلب التحليل في المختبر.';
                $messageEn = 'Your laboratory test request has been accepted.';
            } else {
                $messageKu = "داواکاری ژمارە #{$order->id} قبوڵکرا و لە قۆناغی جێبەجێکردندایە.";
                $messageAr = "تم قبول طلبك رقم #{$order->id} وجاري معالجته.";
                $messageEn = "Your order #{$order->id} has been accepted and is processing.";
            }
        } elseif ($newStatus === 'cancelled' || $newStatus === 'rejected') {
            $titleKu = 'داواکارییەکەت ڕەتکرایەوە ❌';
            $titleAr = 'تم رفض طلبك ❌';
            $titleEn = 'Your Request Was Declined ❌';

            if (str_contains($serviceType, 'nurse') || str_contains($serviceType, 'nursing')) {
                $messageKu = 'بەداخەوە داواکاری پەرستارەکەت ڕەتکرایەوە، تکایە دووبارە کاتێکی تر تاقی بکەرەوە.';
                $messageAr = 'نعتذر، تم رفض طلب التمريض، يرجى المحاولة في وقت لاحق.';
                $messageEn = 'Unfortunately, your nursing request was declined. Please try another time.';
            } elseif (str_contains($serviceType, 'pharmacy') || str_contains($serviceType, 'medicine')) {
                $messageKu = 'بەداخەوە داواکاری دەرمانەکەت ڕەتکرایەوە یان بەردەست نییە.';
                $messageAr = 'نعتذر، تم رفض طلب الأدوية أو غير متوفر حالياً.';
                $messageEn = 'Unfortunately, your pharmacy order was declined or is out of stock.';
            } elseif (str_contains($serviceType, 'lab')) {
                $messageKu = 'بەداخەوە داواکاری پشکنینەکەت لە تاقیگە ڕەتکرایەوە.';
                $messageAr = 'نعتذر، تم رفض طلب التحليل في المختبر.';
                $messageEn = 'Unfortunately, your lab request was declined.';
            } else {
                $messageKu = "داواکاری ژمارە #{$order->id} ڕەتکرایەوە.";
                $messageAr = "تم رفض طلبك رقم #{$order->id}.";
                $messageEn = "Your order #{$order->id} has been declined.";
            }
        } elseif ($newStatus === 'completed') {
            $titleKu = 'داواکارییەکەت تەواوبوو 🎉';
            $titleAr = 'تم إكمال طلبك بنجاح 🎉';
            $titleEn = 'Your Order is Completed 🎉';

            if (str_contains($serviceType, 'lab')) {
                $messageKu = 'ئەنجامی پشکنینەکانی تاقیگەکەت ئامادەیە و تەواوبوو!';
                $messageAr = 'نتائج تحاليلك المخبرية جاهزة الآن!';
                $messageEn = 'Your lab test results are now ready!';
            } elseif (str_contains($serviceType, 'pharmacy')) {
                $messageKu = 'دەرمانەکانت بە سەرکەوتوویی گەیشتن و داواکارییەکەت تەواوبوو.';
                $messageAr = 'تم تسليم الأدوية بنجاح واكتمل طلبك.';
                $messageEn = 'Your medications were successfully delivered.';
            } else {
                $messageKu = "داواکاری ژمارە #{$order->id} بە سەرکەوتوویی تەواو کرا.";
                $messageAr = "تم إكمال طلبك رقم #{$order->id} بنجاح.";
                $messageEn = "Your order #{$order->id} was completed successfully.";
            }
        }

        if (empty($titleKu)) {
            return;
        }

        if (!empty($customNote)) {
            $messageKu .= " ({$customNote})";
            $messageAr .= " ({$customNote})";
            $messageEn .= " ({$customNote})";
        }

        // 1. Create in-app notification record
        try {
            AppNotification::create([
                'user_id'    => $patientId,
                'title'      => $titleKu,
                'title_ar'   => $titleAr,
                'title_en'   => $titleEn,
                'message'    => $messageKu,
                'message_ar' => $messageAr,
                'message_en' => $messageEn,
                'type'       => 'order_update',
            ]);
        } catch (\Exception $e) {
            Log::error('In-app notification creation failed: ' . $e->getMessage());
        }

        // 2. Send Firebase Push Notification
        try {
            app(FcmService::class)->sendToUsers(
                [$patientId],
                $titleKu,
                $messageKu,
                [
                    'order_id'     => (string) $order->id,
                    'status'       => $newStatus,
                    'service_type' => $serviceType,
                    'type'         => 'order_status_update',
                ]
            );
        } catch (\Exception $e) {
            Log::error('FCM Order Notification send failed: ' . $e->getMessage());
        }
    }
}
