<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use App\Models\TicketMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class SupportTicketController extends Controller
{
    public function index()
    {
        $userId = Auth::id();
        $tickets = SupportTicket::where('user_id', $userId)
            ->withCount(['messages as unread_messages_count' => function ($q) {
                $q->where('is_admin_reply', true)->where('is_read', false);
            }])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $tickets,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'category' => 'required|string|in:general,lab,nurse,order,payment,complaint',
            'subject' => 'required|string|max:255',
            'description' => 'required|string',
            'priority' => 'nullable|string|in:low,normal,high,urgent',
            'related_order_id' => 'nullable|exists:orders,id',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:10240',
        ]);

        $ticket = SupportTicket::create([
            'ticket_number' => SupportTicket::generateTicketNumber(),
            'user_id' => Auth::id(),
            'category' => $request->category,
            'subject' => $request->subject,
            'description' => $request->description,
            'priority' => $request->priority ?? 'normal',
            'related_order_id' => $request->related_order_id,
            'status' => 'open',
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('support_attachments', 'public');
        }

        TicketMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => Auth::id(),
            'message' => $request->description,
            'attachment_path' => $attachmentPath,
            'is_admin_reply' => false,
            'is_read' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تیکێتەکەت بە سەرکەوتوویی نێردرا',
            'data' => $ticket->load('messages'),
        ], 201);
    }

    public function show($id)
    {
        $ticket = SupportTicket::where('user_id', Auth::id())
            ->with(['messages.user:id,name,role,profile_image', 'relatedOrder'])
            ->findOrFail($id);

        // Mark admin replies as read
        $ticket->messages()->where('is_admin_reply', true)->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'data' => $ticket,
        ]);
    }

    public function reply(Request $request, $id)
    {
        $ticket = SupportTicket::where('user_id', Auth::id())->findOrFail($id);

        $request->validate([
            'message' => 'required|string',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:10240',
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('support_attachments', 'public');
        }

        $message = TicketMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => Auth::id(),
            'message' => $request->message,
            'attachment_path' => $attachmentPath,
            'is_admin_reply' => false,
            'is_read' => false,
        ]);

        // Reopen ticket if it was resolved
        if (in_array($ticket->status, ['resolved', 'closed'])) {
            $ticket->update(['status' => 'open']);
        }

        return response()->json([
            'success' => true,
            'message' => 'وەڵامەکەت نێردرا',
            'data' => $message->load('user:id,name,role,profile_image'),
        ]);
    }
}
