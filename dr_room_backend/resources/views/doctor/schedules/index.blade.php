@extends('doctor.layouts.app')
@section('header_title', 'خشتەی کارکردن')

@section('content')

@if(session('success'))
    <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-xl">
        {{ session('success') }}
    </div>
@endif

@if(session('error'))
    <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl font-medium">
        {{ session('error') }}
    </div>
@endif

<div class="mb-6">
    <h2 class="text-xl font-bold text-slate-800">کاتەکانی کارکردن</h2>
    <p class="text-sm text-slate-500 mt-1">ئەو کاتانە دیاری بکە کە نەخۆشەکان دەتوانن نۆرەت لێ بگرن.</p>
</div>

<!-- Add New Schedule Form -->
<form action="{{ route('doctor.schedules.store') }}" method="POST" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 mb-8 max-w-5xl">
    @csrf
    
    <div class="mb-6">
        <label class="block text-sm font-medium text-slate-700 mb-3">ڕۆژەکان (دەتوانیت چەند ڕۆژێک بەیەکەوە هەڵبژێریت)</label>
        <div class="flex flex-wrap gap-4">
            @php
                $days = [
                    'Saturday' => 'شەممە',
                    'Sunday' => 'یەکشەممە',
                    'Monday' => 'دووشەممە',
                    'Tuesday' => 'سێشەممە',
                    'Wednesday' => 'چوارشەممە',
                    'Thursday' => 'پێنجشەممە',
                    'Friday' => 'هەینی'
                ];
            @endphp
            @foreach($days as $en => $ku)
            <label class="inline-flex items-center bg-slate-50 border border-slate-200 rounded-xl px-4 py-2 cursor-pointer hover:bg-slate-100 transition-colors">
                <input type="checkbox" name="days[]" value="{{ $en }}" class="w-4 h-4 text-blue-600 bg-white border-slate-300 rounded focus:ring-blue-500 focus:ring-2">
                <span class="mr-2 text-sm font-medium text-slate-700">{{ $ku }}</span>
            </label>
            @endforeach
        </div>
        @error('days') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div>
            <label for="start_time" class="block text-sm font-medium text-slate-700 mb-2">کاتی دەستپێکردن</label>
            <input type="time" id="start_time" name="start_time" required
                class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700">
            @error('start_time') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="end_time" class="block text-sm font-medium text-slate-700 mb-2">کاتی کۆتایهاتن</label>
            <input type="time" id="end_time" name="end_time" required
                class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700">
            @error('end_time') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="slot_minutes" class="block text-sm font-medium text-slate-700 mb-2">ماوەی هەر نۆرەیەک</label>
            <select id="slot_minutes" name="slot_minutes" required
                class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700">
                @foreach([10, 15, 20, 30, 45, 60] as $minutes)
                    <option value="{{ $minutes }}" {{ old('slot_minutes', 30) == $minutes ? 'selected' : '' }}>{{ $minutes }} خولەک</option>
                @endforeach
            </select>
            <p class="text-xs text-slate-400 mt-1">کاتەکە بەم ماوەیە دابەش دەکرێت.</p>
            @error('slot_minutes') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>
    </div>

    <div class="flex justify-end">
        <button type="submit" class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium transition-colors shadow-lg shadow-blue-500/30">
            زیادکردنی کاتەکان
        </button>
    </div>
</form>

<!-- Existing Schedules List -->
<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden max-w-5xl mb-12">
    <table class="w-full text-right text-sm">
        <thead class="bg-slate-50 text-slate-600 font-medium">
            <tr>
                <th class="py-4 px-6 border-b border-slate-200">ڕۆژ</th>
                <th class="py-4 px-6 border-b border-slate-200">کاتی دەستپێکردن</th>
                <th class="py-4 px-6 border-b border-slate-200">کاتی کۆتایهاتن</th>
                <th class="py-4 px-6 border-b border-slate-200">ماوەی نۆرە</th>
                <th class="py-4 px-6 border-b border-slate-200">ژمارەی نۆرە</th>
                <th class="py-4 px-6 border-b border-slate-200">کردارەکان</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-slate-100 text-slate-700">
            @forelse($schedules as $schedule)
            <tr class="hover:bg-slate-50/50 transition-colors {{ !$schedule->is_available ? 'bg-red-50/30' : '' }}">
                <td class="py-4 px-6 font-medium text-slate-800">
                    {{ __('days.' . $schedule->day_of_week) ?? $schedule->day_of_week }}
                    @if(!$schedule->is_available)
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800 mr-2">
                            داخراوە
                        </span>
                        @if($schedule->reason)
                            <p class="text-xs text-red-500 mt-1">{{ $schedule->reason }}</p>
                        @endif
                    @endif
                </td>
                <td class="py-4 px-6 text-slate-600" dir="ltr">{{ \Carbon\Carbon::parse($schedule->start_time)->format('h:i A') }}</td>
                <td class="py-4 px-6 text-slate-600" dir="ltr">{{ \Carbon\Carbon::parse($schedule->end_time)->format('h:i A') }}</td>
                @php
                    $slotLength = $schedule->slot_minutes ?: 30;
                    $spanMinutes = \Carbon\Carbon::parse($schedule->start_time)
                        ->diffInMinutes(\Carbon\Carbon::parse($schedule->end_time));
                @endphp
                <td class="py-4 px-6 text-slate-600">{{ $slotLength }} خولەک</td>
                <td class="py-4 px-6 text-slate-600">{{ intdiv($spanMinutes, $slotLength) }} نۆرە</td>
                <td class="py-4 px-6">
                    <div class="flex items-center gap-2">
                        <!-- Edit Button -->
                        <button type="button" onclick="openEditModal({{ $schedule->id }}, '{{ $schedule->start_time }}', '{{ $schedule->end_time }}', {{ $schedule->slot_minutes }}, {{ $schedule->is_available ? 'true' : 'false' }}, '{{ $schedule->reason ?? '' }}')" class="text-blue-500 hover:text-blue-700 p-2 rounded-lg hover:bg-blue-50 transition-colors">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                        </button>
                        
                        <!-- Delete Button -->
                        <form action="{{ route('doctor.schedules.destroy', $schedule->id) }}" method="POST" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم کاتە؟');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="text-red-500 hover:text-red-700 p-2 rounded-lg hover:bg-red-50 transition-colors">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                </svg>
                            </button>
                        </form>
                    </div>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="6" class="py-8 px-6 text-center text-slate-500">
                    هیچ کاتێک دیاری نەکراوە.
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Edit Schedule Modal -->
<div id="editModal" class="fixed inset-0 z-50 hidden overflow-y-auto bg-slate-900/50 backdrop-blur-sm" aria-labelledby="modal-title" role="dialog" aria-modal="true">
    <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0">
        <div class="relative bg-white rounded-2xl shadow-xl border border-slate-200 w-full max-w-lg p-6 text-right">
            <div class="flex justify-between items-center mb-5">
                <h3 class="text-xl font-bold text-slate-800" id="modal-title">دەستکاریکردنی کات</h3>
                <button type="button" onclick="closeEditModal()" class="text-slate-400 hover:text-slate-600 transition-colors">
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
            
            <form id="editForm" method="POST">
                @csrf
                @method('PUT')
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                    <div>
                        <label for="edit_start_time" class="block text-sm font-medium text-slate-700 mb-2">کاتی دەستپێکردن</label>
                        <input type="time" id="edit_start_time" name="start_time" required
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700">
                    </div>

                    <div>
                        <label for="edit_end_time" class="block text-sm font-medium text-slate-700 mb-2">کاتی کۆتایهاتن</label>
                        <input type="time" id="edit_end_time" name="end_time" required
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700">
                    </div>
                </div>

                <div class="mb-6">
                    <label for="edit_slot_minutes" class="block text-sm font-medium text-slate-700 mb-2">ماوەی هەر نۆرەیەک</label>
                    <select id="edit_slot_minutes" name="slot_minutes" required
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700">
                        @foreach([10, 15, 20, 30, 45, 60] as $minutes)
                            <option value="{{ $minutes }}">{{ $minutes }} خولەک</option>
                        @endforeach
                    </select>
                </div>
                
                <div class="border-t border-slate-200 pt-6 mb-6">
                    <div class="flex items-center mb-4">
                        <input id="edit_is_available" name="is_available" type="checkbox" value="1" onchange="toggleReasonField()"
                            class="w-4 h-4 text-blue-600 bg-slate-100 border-slate-300 rounded focus:ring-blue-500 focus:ring-2">
                        <label for="edit_is_available" class="mr-2 text-sm font-medium text-slate-800">
                            لەم کاتەدا بەردەستم (نەخۆش دەتوانێت نۆرە بگرێت)
                        </label>
                    </div>
                    
                    <div id="reason_container" class="hidden">
                        <label for="edit_reason" class="block text-sm font-medium text-slate-700 mb-2">هۆکاری ئامادەنەبوون (بۆ ئەوەی نەخۆشەکان بیبینن)</label>
                        <input type="text" id="edit_reason" name="reason" placeholder="نموونە: کۆبوونەوە، سەفەر..."
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-700">
                    </div>
                </div>

                <div class="flex justify-end gap-3 mt-8">
                    <button type="button" onclick="closeEditModal()" class="px-6 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl font-medium transition-colors">
                        پاشگەزبوونەوە
                    </button>
                    <button type="submit" class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium transition-colors shadow-lg shadow-blue-500/30">
                        پاشەکەوتکردن
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openEditModal(id, startTime, endTime, slotMinutes, isAvailable, reason) {
    document.getElementById('editForm').action = `/doctor/schedules/${id}`;
    
    // Format times to HH:mm for the time input
    const formattedStartTime = startTime.substring(0, 5);
    const formattedEndTime = endTime.substring(0, 5);
    
    document.getElementById('edit_start_time').value = formattedStartTime;
    document.getElementById('edit_end_time').value = formattedEndTime;
    document.getElementById('edit_slot_minutes').value = slotMinutes;
    
    document.getElementById('edit_is_available').checked = isAvailable;
    document.getElementById('edit_reason').value = reason;
    
    toggleReasonField();
    
    document.getElementById('editModal').classList.remove('hidden');
}

function closeEditModal() {
    document.getElementById('editModal').classList.add('hidden');
}

function toggleReasonField() {
    const isAvailable = document.getElementById('edit_is_available').checked;
    const reasonContainer = document.getElementById('reason_container');
    
    if (isAvailable) {
        reasonContainer.classList.add('hidden');
    } else {
        reasonContainer.classList.remove('hidden');
    }
}
</script>

@endsection
