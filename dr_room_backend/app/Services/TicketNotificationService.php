<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class TicketNotificationService
{
    /**
     * Notify Admins that a patient opened a new ticket or sent a reply message.
     */
    public static function notifyAdminsNewMessage(SupportTicket $ticket, string $messageText, bool $isNewTicket = false): void
    {
        try {
            $patient = $ticket->user;
            $patientName = $patient ? $patient->name : 'نەخۆش';

            $titleKu = $isNewTicket
                ? "تیکێتی نوێ لەلایەن {$patientName} 📩"
                : "پەیامی نوێ لە تیکێتی #{$ticket->ticket_number}";
            $titleAr = $isNewTicket
                ? "تذكرة دعم جديدة من {$patientName} 📩"
                : "رسالة جديدة في التذكرة #{$ticket->ticket_number}";
            $titleEn = $isNewTicket
                ? "New Support Ticket from {$patientName} 📩"
                : "New Message on Ticket #{$ticket->ticket_number}";

            $bodyKu = "تیکێتی #{$ticket->ticket_number}: " . mb_substr($messageText, 0, 80);

            // 1. Get all admin user IDs
            $adminIds = User::where('role', 'admin')->pluck('id')->toArray();
            if (empty($adminIds)) {
                return;
            }

            // 2. Insert AppNotification for all admins
            foreach ($adminIds as $adminId) {
                AppNotification::create([
                    'user_id' => $adminId,
                    'title' => $titleKu,
                    'title_ar' => $titleAr,
                    'title_en' => $titleEn,
                    'message' => $bodyKu,
                    'message_ar' => $bodyKu,
                    'message_en' => $bodyKu,
                    'type' => 'ticket_message',
                ]);
            }

            // 3. Send Push Notification via FCM
            app(FcmService::class)->sendToUsers(
                $adminIds,
                $titleKu,
                $bodyKu,
                [
                    'ticket_id' => (string) $ticket->id,
                    'ticket_number' => (string) $ticket->ticket_number,
                    'type' => 'support_ticket',
                ]
            );
        } catch (\Throwable $e) {
            Log::error('Ticket notification to admins failed: ' . $e->getMessage());
        }
    }

    /**
     * Notify Patient that an Admin replied to their ticket.
     */
    public static function notifyPatientAdminReply(SupportTicket $ticket, string $replyText): void
    {
        try {
            $patientId = $ticket->user_id;
            if (!$patientId) {
                return;
            }

            $titleKu = "وەڵامی نوێ بۆ تیکێتی #{$ticket->ticket_number} 💬";
            $titleAr = "رد جديد على تذكرتك #{$ticket->ticket_number} 💬";
            $titleEn = "New Reply on Ticket #{$ticket->ticket_number} 💬";

            $bodyKu = "پشتیوانی دکتۆر ڕۆم: " . mb_substr($replyText, 0, 80);
            $bodyAr = "الدعم الفني: " . mb_substr($replyText, 0, 80);
            $bodyEn = "Support: " . mb_substr($replyText, 0, 80);

            // 1. In-app notification
            AppNotification::create([
                'user_id' => $patientId,
                'title' => $titleKu,
                'title_ar' => $titleAr,
                'title_en' => $titleEn,
                'message' => $bodyKu,
                'message_ar' => $bodyAr,
                'message_en' => $bodyEn,
                'type' => 'ticket_reply',
            ]);

            // 2. FCM Push notification
            app(FcmService::class)->sendToUsers(
                [$patientId],
                $titleKu,
                $bodyKu,
                [
                    'ticket_id' => (string) $ticket->id,
                    'ticket_number' => (string) $ticket->ticket_number,
                    'type' => 'support_ticket_reply',
                ]
            );
        } catch (\Throwable $e) {
            Log::error('Ticket notification to patient failed: ' . $e->getMessage());
        }
    }

    /**
     * Notify Patient when ticket status changes (e.g. resolved, closed).
     */
    public static function notifyPatientStatusChanged(SupportTicket $ticket, string $newStatus): void
    {
        try {
            $patientId = $ticket->user_id;
            if (!$patientId) {
                return;
            }

            $statusLabels = [
                'resolved' => ['ku' => 'چارەسەرکرا ✅', 'ar' => 'تم الحل ✅', 'en' => 'Resolved ✅'],
                'closed' => ['ku' => 'داخرا 🔒', 'ar' => 'مغلقة 🔒', 'en' => 'Closed 🔒'],
                'in_progress' => ['ku' => 'لە ژێر کاردایە ⏳', 'ar' => 'قيد المعالجة ⏳', 'en' => 'In Progress ⏳'],
            ];

            $label = $statusLabels[$newStatus] ?? ['ku' => $newStatus, 'ar' => $newStatus, 'en' => $newStatus];

            $titleKu = "بارودۆخی تیکێتی #{$ticket->ticket_number} گۆڕدرا بۆ {$label['ku']}";
            $titleAr = "حالة التذكرة #{$ticket->ticket_number} أصبحت {$label['ar']}";
            $titleEn = "Ticket #{$ticket->ticket_number} status changed to {$label['en']}";

            $bodyKu = "تیکێتەکەت سەبارەت بە ({$ticket->subject}) خرایە دۆخی {$label['ku']}.";

            AppNotification::create([
                'user_id' => $patientId,
                'title' => $titleKu,
                'title_ar' => $titleAr,
                'title_en' => $titleEn,
                'message' => $bodyKu,
                'message_ar' => $bodyKu,
                'message_en' => $bodyKu,
                'type' => 'ticket_status',
            ]);

            app(FcmService::class)->sendToUsers(
                [$patientId],
                $titleKu,
                $bodyKu,
                [
                    'ticket_id' => (string) $ticket->id,
                    'status' => $newStatus,
                    'type' => 'support_ticket_status',
                ]
            );
        } catch (\Throwable $e) {
            Log::error('Ticket status notification failed: ' . $e->getMessage());
        }
    }
}

