<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use App\Models\TicketMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminTicketController extends Controller
{
    public function index(Request $request)
    {
        $query = SupportTicket::with(['user:id,name,phone,role,profile_image', 'assignedStaff:id,name']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('priority')) {
            $query->where('priority', $request->priority);
        }

        $tickets = $query->latest()->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $tickets,
        ]);
    }

    public function show($id)
    {
        $ticket = SupportTicket::with([
            'user:id,name,phone,email,profile_image',
            'assignedStaff:id,name',
            'relatedOrder',
            'messages.user:id,name,role,profile_image'
        ])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $ticket,
        ]);
    }

    public function reply(Request $request, $id)
    {
        $ticket = SupportTicket::findOrFail($id);

        $request->validate([
            'message' => 'required|string',
            'status' => 'nullable|string|in:open,in_progress,resolved,closed',
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
            'is_admin_reply' => true,
            'is_read' => false,
        ]);

        if ($request->filled('status')) {
            $ticket->status = $request->status;
        } else {
            $ticket->status = 'in_progress';
        }
        $ticket->assigned_staff_id = Auth::id();
        $ticket->save();

        return response()->json([
            'success' => true,
            'message' => 'وەڵامەکەت بە سەرکەوتوویی بۆ نەخۆش نێردرا',
            'data' => $message->load('user:id,name,role,profile_image'),
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $ticket = SupportTicket::findOrFail($id);

        $request->validate([
            'status' => 'required|string|in:open,in_progress,resolved,closed',
        ]);

        $ticket->status = $request->status;
        $ticket->save();

        return response()->json([
            'success' => true,
            'message' => 'دۆخی تیکێت نوێکرایەوە',
            'status' => $ticket->status,
        ]);
    }

    public function destroy($id)
    {
        $ticket = SupportTicket::findOrFail($id);
        $ticket->delete();

        return response()->json([
            'success' => true,
            'message' => 'تیکێت سڕایەوە',
        ]);
    }
}
