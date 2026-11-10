<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Order;
use App\Models\User;
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

        if (in_array($newStatus, ['processing', 'accepted', 'approved', 'confirmed', 'in_progress'], true)) {
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

    /**
     * Notify only the nearest matched driver about an incoming delivery offer.
     */
    public static function notifyDriverOffer(Order $order, \App\Models\User $driver): void
    {
        $orderNumber = '#' . $order->id;
        $isLab = str_contains(strtolower($order->service_type ?? ''), 'lab');

        $driverTitle = $isLab ? 'ئەرکی نوێی نموونەی تاقیگە لە نزیکت 📍' : 'داواکاری گەیاندنی نوێ لە نزیکت 🛵';
        $driverMsg = $isLab
            ? "داواکاری نموونەی تاقیگە {$orderNumber} بۆ تۆ نێردراوە. تکایە لە ئەپدا قبوڵی بکە یان ڕەتی بکەرەوە."
            : "داواکاری گەیاندنی دەرمان {$orderNumber} لە نزیکتە. تکایە لە ئەپدا قبوڵی بکە یان ڕەتی بکەرەوە.";

        try {
            AppNotification::create([
                'user_id'    => $driver->id,
                'title'      => $driverTitle,
                'title_ar'   => $isLab ? 'طلب توصيل عينة قريب منك 📍' : 'طلب توصيل دواء قريب منك 🛵',
                'title_en'   => $isLab ? 'Nearby Lab Sample Offer 📍' : 'Nearby Pharmacy Delivery Offer 🛵',
                'message'    => $driverMsg,
                'message_ar' => "الطلب {$orderNumber} قريب من موقعك. يرجى القبول أو الرفض في التطبيق.",
                'message_en' => "Order {$orderNumber} is nearby. Please accept or decline in the app.",
                'type'       => 'driver_offer',
            ]);

            app(FcmService::class)->sendToUsers(
                [$driver->id],
                $driverTitle,
                $driverMsg,
                ['order_id' => (string) $order->id, 'type' => 'driver_offer']
            );
        } catch (\Throwable $e) {
            Log::error('Driver offer notification failed: ' . $e->getMessage());
        }
    }

    /**
     * Notify both the driver and patient when a driver is assigned to an order.
     */
    public static function notifyDriverAssigned(Order $order, \App\Models\User $driver): void
    {
        $orderNumber = '#' . $order->id;
        $isLab = str_contains(strtolower($order->service_type ?? ''), 'lab');

        $driverTitle = $isLab ? 'ئەرکی گواستنەوەی نموونەی تاقیگە 🚗' : 'داواکاری گەیاندنی نوێ 📦';
        $driverMsg = $isLab
            ? "داواکاری نموونەی تاقیگە {$orderNumber} بۆ تۆ دیاریکرا. تکایە لە ئەپەکە وەریبگرە."
            : "داواکاری گەیاندنی دەرمان {$orderNumber} بۆ تۆ دیاریکرا. تکایە لە ئەپەکە وەریبگرە.";

        try {
            AppNotification::create([
                'user_id'    => $driver->id,
                'title'      => $driverTitle,
                'title_ar'   => $isLab ? 'مهمة توصيل عينة مختبرية 🚗' : 'طلب توصيل جديد 📦',
                'title_en'   => $isLab ? 'New Lab Sample Pickup 🚗' : 'New Delivery Assignment 📦',
                'message'    => $driverMsg,
                'message_ar' => "تم تعيين الطلب {$orderNumber} لك. يرجى مراجعته في التطبيق.",
                'message_en' => "Order {$orderNumber} has been assigned to you.",
                'type'       => 'driver_assignment',
            ]);

            app(FcmService::class)->sendToUsers(
                [$driver->id],
                $driverTitle,
                $driverMsg,
                ['order_id' => (string) $order->id, 'type' => 'driver_assignment']
            );
        } catch (\Throwable $e) {
            Log::error('Driver assignment notification failed: ' . $e->getMessage());
        }

        if ($order->patient_id) {
            $patientTitle = 'کارمەندی گەیاندن دیاریکرا 🛵';
            $patientMsg = "کارمەندی گەیاندن ({$driver->name}) بۆ داواکارییەکەت {$orderNumber} دیاریکرا.";
            try {
                AppNotification::create([
                    'user_id'    => $order->patient_id,
                    'title'      => $patientTitle,
                    'title_ar'   => 'تم تعيين مندوب التوصيل 🛵',
                    'title_en'   => 'Delivery Driver Assigned 🛵',
                    'message'    => $patientMsg,
                    'message_ar' => "تم تعيين المندوب ({$driver->name}) لطلبك {$orderNumber}.",
                    'message_en' => "Driver {$driver->name} has been assigned to your order {$orderNumber}.",
                    'type'       => 'order_update',
                ]);

                app(FcmService::class)->sendToUsers(
                    [$order->patient_id],
                    $patientTitle,
                    $patientMsg,
                    ['order_id' => (string) $order->id, 'type' => 'delivery_status_update']
                );
            } catch (\Throwable $e) {
                Log::error('Patient driver assignment notification failed: ' . $e->getMessage());
            }
        }
    }

    /**
     * Notify patient about real-time delivery milestone updates.
     */
    public static function notifyDeliveryStage(Order $order, string $stage): void
    {
        if (!$order->patient_id) {
            return;
        }

        $isLab = str_contains(strtolower($order->service_type ?? ''), 'lab');
        $orderNumber = '#' . $order->id;

        [$titleKu, $msgKu, $titleAr, $msgAr, $titleEn, $msgEn] = match ($stage) {
            'accepted' => [
                'کارمەندی گەیاندن داواکارییەکەی وەرگرت ✅',
                "شۆفێر داواکاری {$orderNumber}ی وەرگرت و ئامادەکاری بۆ گەیشتن دەکات.",
                'قبل المندوب الطلب ✅',
                "وافق مندوب التوصيل على طلبك {$orderNumber}.",
                'Driver Accepted Order ✅',
                "Your driver has accepted order {$orderNumber}.",
            ],
            'picked_up' => $isLab ? [
                'نموونەی خوێن وەرگیرا 🧪',
                "نموونەی پشکنین بۆ داواکاری {$orderNumber} وەرگیرا و دەگەیەنرێتە تاقیگە.",
                'تم استلام العينة 🧪',
                "تم أخذ العينة المخبرية للطلب {$orderNumber} وجاري نقلها للمختبر.",
                'Sample Collected 🧪',
                "Sample for order {$orderNumber} has been collected for delivery to the lab.",
            ] : [
                'دەرمانەکان لە دەرمانخانە وەرگیران 💊',
                "کارمەندی گەیاندن داواکاری {$orderNumber}ی لە دەرمانخانە وەرگرت.",
                'تم استلام الأدوية من الصيدلية 💊',
                "استلم المندوب طلبك {$orderNumber} من الصيدلية.",
                'Order Picked Up 💊',
                "Your medication order {$orderNumber} was picked up from the pharmacy.",
            ],
            'on_the_way' => [
                'کارمەندی گەیاندن لە ڕێگادایە 🛵',
                "شۆفێر بەڕێکەوتووە و لەسەر نەخشە دەتوانیت شوێنەکەی ببینیت ({$orderNumber}).",
                'المندوب في الطريق إليك 🛵',
                "المندوب في طريقه الآن، يمكنك تتبعه مباشرة على الخريطة ({$orderNumber}).",
                'Driver On The Way 🛵',
                "Your driver is on the way for order {$orderNumber}. Track live in the app.",
            ],
            'arrived' => [
                'کارمەندی گەیاندن گەیشتە شوێنەکە 📍',
                "کارمەندی گەیاندن گەیشتە لای تۆ بۆ داواکاری {$orderNumber}.",
                'وصل المندوب إلى موقعك 📍',
                "المندوب وصل إلى العنوان للطلب {$orderNumber}.",
                'Driver Arrived 📍',
                "Your driver has arrived with order {$orderNumber}.",
            ],
            'delivered' => $isLab ? [
                'نموونە گەیەنرایە تاقیگە 🎉',
                "نموونەی داواکاری {$orderNumber} بە سەلامەتی گەیشتە تاقیگە و بە زوویی ئەنجام دەردەچێت.",
                'وصلت العينة إلى المختبر 🎉',
                "تم تسليم العينة للطلب {$orderNumber} إلى المختبر بنجاح.",
                'Sample Delivered to Lab 🎉',
                "Sample for order {$orderNumber} was delivered to the lab.",
            ] : [
                'داواکاری گەیەنرا و ڕادەستکرا 🎉',
                "داواکاری {$orderNumber} بە سەرکەوتوویی ڕادەست کرا. هیوای تەندروستی باش.",
                'تم تسليم الطلب بنجاح 🎉',
                "تم تسليم طلبك {$orderNumber} بنجاح.",
                'Order Delivered 🎉',
                "Your order {$orderNumber} has been delivered.",
            ],
            default => [null, null, null, null, null, null],
        };

        if (!$titleKu) {
            return;
        }

        try {
            AppNotification::create([
                'user_id'    => $order->patient_id,
                'title'      => $titleKu,
                'title_ar'   => $titleAr,
                'title_en'   => $titleEn,
                'message'    => $msgKu,
                'message_ar' => $msgAr,
                'message_en' => $msgEn,
                'type'       => 'order_update',
            ]);

            app(FcmService::class)->sendToUsers(
                [$order->patient_id],
                $titleKu,
                $msgKu,
                [
                    'order_id'        => (string) $order->id,
                    'delivery_status' => $stage,
                    'type'            => 'delivery_status_update',
                ]
            );
        } catch (\Throwable $e) {
            Log::error('Delivery stage notification failed: ' . $e->getMessage());
        }
    }

    /**
     * Send AppNotification rows and FCM pushes to a list of user IDs safely.
     */
    private static function sendBatch(array $userIds, array $payload, array $fcmData = []): void
    {
        $ids = array_values(array_unique(array_filter(array_map('intval', $userIds))));
        if ($ids === []) {
            return;
        }

        try {
            foreach ($ids as $uid) {
                AppNotification::create(array_merge($payload, ['user_id' => $uid]));
            }
            app(FcmService::class)->sendToUsers(
                $ids,
                (string) ($payload['title'] ?? ''),
                (string) ($payload['message'] ?? ''),
                $fcmData
            );
        } catch (\Throwable $e) {
            Log::error('Batch notification failed: ' . $e->getMessage());
        }
    }

    /**
     * Notify patient, admins/staff, and any directly assigned provider when a new order is placed.
     */
    public static function notifyOrderCreated(Order $order): void
    {
        $serviceType = strtolower(trim((string) ($order->service_type ?? '')));
        $orderNumber = '#' . $order->id;
        $isPharm = str_contains($serviceType, 'pharmac') || str_contains($serviceType, 'medic') || str_contains($serviceType, 'دەرمان');
        $isLab = str_contains($serviceType, 'lab') || str_contains($serviceType, 'تاقیگە');

        $serviceKu = $isPharm ? 'دەرمانخانە' : ($isLab ? 'پشکنینی تاقیگە' : 'پەرستاری ماڵەوە');
        $serviceAr = $isPharm ? 'الصيدلية' : ($isLab ? 'المختبر الطبي' : 'التمريض المنزلي');
        $serviceEn = $isPharm ? 'Pharmacy Order' : ($isLab ? 'Lab Test Order' : 'Home Nursing');

        // 1. Patient order receipt confirmation
        if ($order->patient_id) {
            self::sendBatch([$order->patient_id], [
                'title'      => "داواکاری {$orderNumber} تۆمارکرا ✅",
                'title_ar'   => "تم تسجيل الطلب {$orderNumber} ✅",
                'title_en'   => "Order {$orderNumber} Placed ✅",
                'message'    => "داواکارییەکەت ({$serviceKu}) بە سەرکەوتوویی گەیشت و کاری لەسەر دەکرێت.",
                'message_ar' => "تم استلام طلبك ({$serviceAr}) بنجاح وجاري متابعته.",
                'message_en' => "Your {$serviceEn} has been received successfully.",
                'type'       => 'order_update',
            ], [
                'order_id'     => (string) $order->id,
                'service_type' => $serviceType,
                'type'         => 'order_created',
            ]);
        }

        // 2. Admin & Staff alert
        $adminIds = User::whereIn('role', ['admin', 'staff'])->pluck('id')->all();
        $patientName = trim((string) ($order->patient?->name ?? ($order->patient_details['name'] ?? 'نەخۆش')));
        $totalIqd = number_format((float) $order->total_price, 0);

        self::sendBatch($adminIds, [
            'title'      => "داواکاری نوێ {$orderNumber} ({$serviceKu}) 🛎️",
            'title_ar'   => "طلب جديد {$orderNumber} ({$serviceAr}) 🛎️",
            'title_en'   => "New {$serviceEn} {$orderNumber} 🛎️",
            'message'    => "{$patientName} داواکارییەکی {$serviceKu} بە بڕی {$totalIqd} د.ع تۆمارکرد.",
            'message_ar' => "سجل {$patientName} طلباً جديداً بقيمة {$totalIqd} د.ع.",
            'message_en' => "{$patientName} placed a new {$serviceEn} totaling {$totalIqd} IQD.",
            'type'       => 'admin_notice',
        ], [
            'order_id' => (string) $order->id,
            'type'     => 'admin_new_order',
        ]);

        // 3. Assigned Provider (Pharmacy / Lab / Nurse) if selected at order creation
        $providerIds = array_values(array_diff(array_filter([
            $order->assigned_pharmacy_id,
            $order->assigned_lab_id,
            $order->assigned_nurse_id,
        ]), $adminIds));

        if ($providerIds !== []) {
            self::sendBatch($providerIds, [
                'title'      => "داواکارییەکی نوێت بۆ هات ({$orderNumber}) 📦",
                'title_ar'   => "وصلك طلب جديد ({$orderNumber}) 📦",
                'title_en'   => "New Order Received ({$orderNumber}) 📦",
                'message'    => "نەخۆش {$patientName} داواکاری {$serviceKu}ـی ناردووە.",
                'message_ar' => "أرسل المريض {$patientName} طلباً جديداً.",
                'message_en' => "Patient {$patientName} submitted a new {$serviceEn}.",
                'type'       => 'order_update',
            ], [
                'order_id' => (string) $order->id,
                'type'     => 'provider_new_order',
            ]);
        }
    }
}
