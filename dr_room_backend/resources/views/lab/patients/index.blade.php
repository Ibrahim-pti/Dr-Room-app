@extends('lab.layouts.app')
@section('header_title', 'داواکارییەکانی پشکنین و نەخۆشەکان')

@section('content')
<div class="space-y-6">
    <!-- Header with Clean Filter Dropdown -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-5">
            <!-- Title & Subtitle -->
            <div>
                <div class="flex items-center gap-3">
                    <h2 class="text-xl font-bold text-slate-800">داواکارییەکانی پشکنینی تاقیگە</h2>
                    <span class="px-3 py-1 bg-blue-50 text-blue-600 rounded-full text-xs font-bold border border-blue-100">
                        کۆی گشتی: {{ $counts['all'] ?? $orders->total() ?? 0 }} داواکاری
                    </span>
                </div>
                <p class="text-sm text-slate-500 mt-1">سەرجەم داواکارییە نێردراوەکانی نەخۆش لە ڕێگەی ئەپڵیکەیشنەوە لەگەڵ پرۆفایل و وردەکاری تەواو.</p>
            </div>

            <!-- Sleek Styled Filter Dropdown -->
            <div class="flex items-center gap-2 self-start lg:self-auto">
                <div class="relative">
                    <select onchange="location = this.value;" 
                            class="appearance-none bg-slate-50 hover:bg-slate-100/80 border border-slate-200 text-slate-700 font-bold text-xs rounded-2xl pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all cursor-pointer shadow-sm min-w-[220px]">
                        <option value="{{ route('lab.patients.index') }}" {{ !$status || $status == 'all' ? 'selected' : '' }}>
                            🔍 هەموو داواکارییەکان ({{ $counts['all'] ?? 0 }})
                        </option>
                        <option value="{{ route('lab.patients.index', ['status' => 'pending']) }}" {{ $status == 'pending' ? 'selected' : '' }}>
                            ⏳ لە چاوەڕوانیدا ({{ $counts['pending'] ?? 0 }})
                        </option>
                        <option value="{{ route('lab.patients.index', ['status' => 'approved']) }}" {{ $status == 'approved' ? 'selected' : '' }}>
                            🔬 نموونە وەرگیرا / لە کاردایە ({{ $counts['approved'] ?? 0 }})
                        </option>
                        <option value="{{ route('lab.patients.index', ['status' => 'completed']) }}" {{ $status == 'completed' ? 'selected' : '' }}>
                            ✅ تەواوکراو و ئەنجام ئامادەیە ({{ $counts['completed'] ?? 0 }})
                        </option>
                    </select>
                    <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center px-3 text-slate-400">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-2xl font-bold flex items-center gap-3 shadow-sm">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    <!-- Orders List Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
                <thead class="bg-slate-50/80 border-b border-slate-100 text-slate-500 font-bold text-xs uppercase tracking-wider">
                    <tr>
                        <th class="px-6 py-4">داواکاری & کات</th>
                        <th class="px-6 py-4">پرۆفایلی نەخۆش</th>
                        <th class="px-6 py-4">وەرگرتنی نموونە & شوێن</th>
                        <th class="px-6 py-4">پشکنینەکان</th>
                        <th class="px-6 py-4">بڕی پارە & شێواز</th>
                        <th class="px-6 py-4">بارودۆخ</th>
                        <th class="px-6 py-4 text-center">کردارەکان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($orders as $order)
                        @php
                            $details = is_array($order->patient_details) ? $order->patient_details : (json_decode($order->patient_details, true) ?? []);
                            $loc = is_array($order->location_details) ? $order->location_details : (json_decode($order->location_details, true) ?? []);
                            $patientName = $details['full_name'] ?? $details['name'] ?? $order->patient?->name ?? 'نەخۆش';
                            $patientPhone = $details['phone'] ?? $order->patient?->phone ?? 'نەزانراو';
                            $patientAge = $details['age'] ?? $details['patient_age'] ?? null;
                            $patientGender = $details['gender'] ?? null;
                            $collectionMethod = $details['sample_collection_method'] ?? ($order->extra_fee > 0 ? 'home' : 'lab');
                            $address = $details['address'] ?? $details['location_name'] ?? $loc['address'] ?? 'هەولێر';
                            $initial = mb_substr($patientName, 0, 1);
                        @endphp
                        <tr class="hover:bg-slate-50/70 transition-colors">
                            <!-- Order ID & Date -->
                            <td class="px-6 py-4">
                                <div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-100 text-slate-800 font-black text-xs" dir="ltr">
                                    #ORD-{{ $order->id }}
                                </div>
                                <div class="text-[11px] text-slate-400 mt-1 flex items-center gap-1" dir="ltr">
                                    <svg class="w-3.5 h-3.5 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                    {{ $order->created_at->format('Y-m-d H:i') }}
                                </div>
                            </td>

                            <!-- Patient Profile Card -->
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <!-- Avatar -->
                                    <div class="w-10 h-10 rounded-full {{ $patientGender == 'female' ? 'bg-pink-100 text-pink-700 border-pink-200' : 'bg-blue-100 text-blue-700 border-blue-200' }} border-2 flex items-center justify-center font-bold text-sm shadow-sm flex-shrink-0">
                                        {{ $initial }}
                                    </div>
                                    <div class="space-y-0.5">
                                        <div class="font-bold text-slate-800 text-sm flex items-center gap-2">
                                            <span>{{ $patientName }}</span>
                                            @if($patientGender)
                                                <span class="text-[10px] px-2 py-0.5 rounded-full font-bold {{ $patientGender == 'female' ? 'bg-pink-50 text-pink-600 border border-pink-200/60' : 'bg-blue-50 text-blue-600 border border-blue-200/60' }}">
                                                    {{ $patientGender == 'female' ? 'مێ' : 'نێر' }}
                                                </span>
                                            @endif
                                        </div>
                                        <div class="flex items-center gap-2 text-xs text-slate-500">
                                            <a href="tel:{{ $patientPhone }}" class="font-semibold text-blue-600 hover:underline flex items-center gap-1" dir="ltr">
                                                <svg class="w-3 h-3 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                                                {{ $patientPhone }}
                                            </a>
                                            @if($patientAge)
                                                <span class="text-slate-300">•</span>
                                                <span class="text-slate-500 font-medium">{{ $patientAge }} ساڵ</span>
                                            @endif
                                        </div>
                                    </div>
                                </div>
                            </td>

                            <!-- Sample Collection & Location -->
                            <td class="px-6 py-4">
                                @if($collectionMethod == 'home')
                                    <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-purple-50 text-purple-700 font-bold text-xs border border-purple-200/60 shadow-xs">
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                                        لە ماڵەوە (Home Sample)
                                    </div>
                                @else
                                    <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-cyan-50 text-cyan-700 font-bold text-xs border border-cyan-200/60 shadow-xs">
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                                        لە تاقیگە (Lab Visit)
                                    </div>
                                @endif
                                <div class="text-xs text-slate-500 mt-1 flex items-center gap-1 max-w-[200px] truncate" title="{{ $address }}">
                                    <svg class="w-3.5 h-3.5 text-rose-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                                    <span class="truncate">{{ $address }}</span>
                                </div>
                            </td>

                            <!-- Ordered Tests Items -->
                            <td class="px-6 py-4">
                                <div class="space-y-1.5 max-w-xs">
                                    @forelse($order->items as $item)
                                        <div class="text-xs text-slate-700 font-bold flex items-center justify-between gap-2 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200/60">
                                            <span class="truncate">{{ $item->item_name }}</span>
                                            <span class="text-blue-600 font-semibold flex-shrink-0" dir="ltr">{{ number_format($item->price) }} د.ع</span>
                                        </div>
                                    @empty
                                        <span class="text-xs text-slate-400">پشکنینی گشتی تاقیگە</span>
                                    @endforelse
                                </div>
                            </td>

                            <!-- Price & Payment -->
                            <td class="px-6 py-4">
                                <div class="font-black text-slate-800 text-sm" dir="ltr">
                                    {{ number_format($order->total_price) }} IQD
                                </div>
                                <div class="text-[11px] text-slate-500 mt-0.5 flex items-center gap-1 font-medium">
                                    <svg class="w-3 h-3 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                                    {{ $order->payment_method ?? 'کاش لەکاتی وەرگرتن' }}
                                </div>
                            </td>

                            <!-- Status Selector -->
                            <td class="px-6 py-4">
                                <form action="{{ route('lab.orders.update_status', $order) }}" method="POST">
                                    @csrf
                                    @method('PATCH')
                                    <select name="status" onchange="this.form.submit()" 
                                            class="text-xs font-bold rounded-xl px-3 py-1.5 border transition-all cursor-pointer outline-none shadow-xs
                                            @if($order->status == 'pending') bg-amber-50 text-amber-700 border-amber-200
                                            @elseif(in_array($order->status, ['approved', 'confirmed', 'in_progress'])) bg-blue-50 text-blue-700 border-blue-200
                                            @elseif($order->status == 'completed') bg-emerald-50 text-emerald-700 border-emerald-200
                                            @else bg-rose-50 text-rose-700 border-rose-200 @endif">
                                        <option value="pending" {{ $order->status == 'pending' ? 'selected' : '' }}>⏳ چاوەڕوانە</option>
                                        <option value="in_progress" {{ in_array($order->status, ['in_progress', 'approved', 'confirmed']) ? 'selected' : '' }}>🔬 نموونە وەرگیرا / لە کاردایە</option>
                                        <option value="completed" {{ $order->status == 'completed' ? 'selected' : '' }}>✅ ئەنجام ئامادەیە (تەواو)</option>
                                        <option value="cancelled" {{ $order->status == 'cancelled' ? 'selected' : '' }}>❌ ڕەتکرایەوە</option>
                                    </select>
                                </form>
                            </td>

                            <!-- Action Modal Button -->
                            <td class="px-6 py-4 text-center">
                                <button type="button" onclick="openOrderModal({{ json_encode($order) }}, {{ json_encode($details) }}, {{ json_encode($loc) }}, {{ json_encode($order->items) }})" 
                                        class="px-3.5 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-600 hover:text-white rounded-xl font-bold text-xs transition-all flex items-center gap-1.5 mx-auto shadow-xs border border-blue-100">
                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                    وردەکاری فۆڕم
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-16 text-center text-slate-500">
                                <div class="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-3 text-slate-300">
                                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                                </div>
                                <div class="font-bold text-slate-700 text-base">هیچ داواکارییەکی پشکنین نەدۆزرایەوە</div>
                                <div class="text-xs text-slate-400 mt-1">کاتێک نەخۆش لە ئەپەکەوە داواکاری دەنێرێت لێرە بە وردەکارییەوە دەردەکەوێت.</div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination Footer -->
        <div class="px-6 py-4 bg-slate-50/70 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
            <div class="font-medium">
                پیشاندانی <span class="font-bold text-slate-800">{{ $orders->firstItem() ?? 0 }}</span> بۆ <span class="font-bold text-slate-800">{{ $orders->lastItem() ?? 0 }}</span> لە کۆی <span class="font-bold text-blue-600">{{ $orders->total() }}</span> داواکاری
            </div>

            <div>
                {{ $orders->links() }}
            </div>
        </div>
    </div>
</div>

<!-- Detailed Form Modal -->
<div id="orderModal" class="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-sm hidden flex items-center justify-center p-4">
    <div class="bg-white rounded-3xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-100 p-6 space-y-6">
        <div class="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
                <h3 class="text-lg font-black text-slate-800" id="modalTitle">وردەکاری تەواوی داواکاری</h3>
                <p class="text-xs text-slate-400 mt-0.5" id="modalSubtitle">فۆڕمی پڕکراوە لەلایەن نەخۆشەوە</p>
            </div>
            <button type="button" onclick="closeOrderModal()" class="w-8 h-8 rounded-full bg-slate-100 text-slate-400 hover:text-slate-700 flex items-center justify-center transition-colors">
                ✕
            </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm" id="modalContent">
            <!-- Dynamic Content Injected By JS -->
        </div>

        <div class="border-t border-slate-100 pt-4 flex items-center justify-end gap-3">
            <button type="button" onclick="closeOrderModal()" class="px-6 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
                داخستن
            </button>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
function openOrderModal(order, details, loc, items) {
    const modal = document.getElementById('orderModal');
    const content = document.getElementById('modalContent');
    const title = document.getElementById('modalTitle');
    const subtitle = document.getElementById('modalSubtitle');

    title.textContent = `داواکاری #ORD-${order.id}`;
    subtitle.textContent = `بەرواری تۆمارکردن: ${order.created_at}`;

    const patientName = details.full_name || details.name || (order.patient ? order.patient.name : 'نەخۆش');
    const patientPhone = details.phone || (order.patient ? order.patient.phone : 'نەزانراو');
    const patientAge = details.age || details.patient_age || 'دیارینەکراو';
    const gender = details.gender === 'female' ? 'مێ (Female)' : (details.gender === 'male' ? 'نێر (Male)' : 'دیارینەکراو');
    const collectionMethod = details.sample_collection_method === 'home' ? 'لە ماڵەوە (Home Sample)' : 'لە تاقیگە (Lab Visit)';
    const address = details.address || details.location_name || (loc ? loc.address : 'هەولێر');
    const notes = details.notes || details.description || 'تێبینی نییە';

    let itemsHtml = '';
    if (items && items.length > 0) {
        itemsHtml = items.map(it => `
            <div class="flex items-center justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-100 text-xs">
                <span class="font-bold text-slate-800">${it.item_name}</span>
                <span class="font-bold text-blue-600" dir="ltr">${Number(it.price).toLocaleString()} IQD</span>
            </div>
        `).join('');
    } else {
        itemsHtml = '<div class="text-xs text-slate-400 p-2">پشکنینی گشتی</div>';
    }

    content.innerHTML = `
        <div class="bg-blue-50/50 p-4 rounded-2xl border border-blue-100/60 space-y-2 md:col-span-2">
            <div class="text-xs font-bold text-blue-800 uppercase tracking-wider">👤 زانیارییەکانی نەخۆش</div>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-1">
                <div>
                    <span class="text-[11px] text-slate-400 block">ناوی نەخۆش:</span>
                    <span class="font-bold text-slate-800">${patientName}</span>
                </div>
                <div>
                    <span class="text-[11px] text-slate-400 block">ژمارەی مۆبایل:</span>
                    <a href="tel:${patientPhone}" class="font-bold text-blue-600 hover:underline" dir="ltr">${patientPhone}</a>
                </div>
                <div>
                    <span class="text-[11px] text-slate-400 block">تەمەن:</span>
                    <span class="font-bold text-slate-800">${patientAge} ساڵ</span>
                </div>
                <div>
                    <span class="text-[11px] text-slate-400 block">ڕەگەز:</span>
                    <span class="font-bold text-slate-800">${gender}</span>
                </div>
            </div>
        </div>

        <div class="bg-slate-50 p-4 rounded-2xl border border-slate-100 space-y-2">
            <div class="text-xs font-bold text-slate-700">📍 شوێن و شێوازی وەرگرتن</div>
            <div class="text-xs text-slate-600 space-y-1">
                <div><strong>شێواز:</strong> <span class="text-purple-700 font-bold">${collectionMethod}</span></div>
                <div><strong>ناونیشان:</strong> ${address}</div>
                <div><strong>تێبینی نەخۆش:</strong> ${notes}</div>
            </div>
        </div>

        <div class="bg-slate-50 p-4 rounded-2xl border border-slate-100 space-y-2">
            <div class="text-xs font-bold text-slate-700">💳 پارەدان و کۆی گشتی</div>
            <div class="text-xs text-slate-600 space-y-1">
                <div><strong>شێوازی پارەدان:</strong> ${order.payment_method || 'کاش'}</div>
                <div><strong>کۆی گشتی:</strong> <span class="font-black text-emerald-600 text-sm" dir="ltr">${Number(order.total_price).toLocaleString()} IQD</span></div>
                <div><strong>بارودۆخ:</strong> <span class="font-bold text-blue-600">${order.status}</span></div>
            </div>
        </div>

        <div class="space-y-2 md:col-span-2">
            <div class="text-xs font-bold text-slate-700">🧪 لیستی پشکنینە هەڵبژێردراوەکان</div>
            <div class="space-y-1.5">
                ${itemsHtml}
            </div>
        </div>
    `;

    modal.classList.remove('hidden');
}

function closeOrderModal() {
    document.getElementById('orderModal').classList.add('hidden');
}
</script>
@endsection
