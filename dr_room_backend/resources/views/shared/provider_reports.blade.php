@extends($layout)

@section('title', $meta['page_title'] . ' - DrRoom')

@section('content')
@php
    $isViolet = ($meta['accent'] ?? 'teal') === 'violet';
    $theme = $isViolet
        ? [
            'badgeBg' => 'bg-violet-50 text-violet-700 border-violet-100',
            'btnBg' => 'bg-violet-600 hover:bg-violet-700 text-white',
            'softBg' => 'bg-violet-50 text-violet-700',
            'iconBg' => 'bg-violet-50 text-violet-600',
            'barHex' => '#7c3aed',
            'barSoftHex' => 'rgba(124, 58, 237, 0.18)',
            'lineHex' => '#10b981',
            'ringFocus' => 'focus:border-violet-400 focus:ring-violet-100',
        ]
        : [
            'badgeBg' => 'bg-teal-50 text-teal-700 border-teal-100',
            'btnBg' => 'bg-teal-600 hover:bg-teal-700 text-white',
            'softBg' => 'bg-teal-50 text-teal-700',
            'iconBg' => 'bg-teal-50 text-teal-600',
            'barHex' => '#0d9488',
            'barSoftHex' => 'rgba(13, 148, 136, 0.18)',
            'lineHex' => '#0284c7',
            'ringFocus' => 'focus:border-teal-400 focus:ring-teal-100',
        ];

    $periodLabel = $selectedMonth === 'all' ? 'هەموو کاتەکان' : $selectedMonth;

    $statusLabels = [
        'pending' => ['label' => 'چاوەڕوانی', 'class' => 'bg-amber-50 text-amber-700 border-amber-200'],
        'accepted' => ['label' => 'قبوڵکراو', 'class' => 'bg-sky-50 text-sky-700 border-sky-200'],
        'confirmed' => ['label' => 'پەسەندکراو', 'class' => 'bg-sky-50 text-sky-700 border-sky-200'],
        'on_the_way' => ['label' => 'لە ڕێگادایە', 'class' => 'bg-indigo-50 text-indigo-700 border-indigo-200'],
        'in_progress' => ['label' => 'لە کاردایە', 'class' => 'bg-indigo-50 text-indigo-700 border-indigo-200'],
        'completed' => ['label' => 'تەواوکراو', 'class' => 'bg-emerald-50 text-emerald-700 border-emerald-200'],
        'cancelled' => ['label' => 'ڕەتکراوە', 'class' => 'bg-rose-50 text-rose-700 border-rose-200'],
        'rejected' => ['label' => 'ڕەتکراوە', 'class' => 'bg-rose-50 text-rose-700 border-rose-200'],
    ];
@endphp

<div class="max-w-7xl mx-auto space-y-6">
    <!-- Header & Month Filter -->
    <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div class="text-right">
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold border {{ $theme['badgeBg'] }} mb-2">
                <span>حسابات و ژمێریاری</span>
                <span>•</span>
                <span dir="ltr" class="inline-block">{{ $periodLabel }}</span>
            </div>
            <h1 class="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">{{ $meta['page_title'] }}</h1>
            <p class="text-sm text-slate-500 mt-1">{{ $meta['page_subtitle'] }}</p>
        </div>

        <div class="flex flex-wrap items-center gap-2.5 print:hidden">
            <form method="GET" action="{{ route($routeName) }}" class="flex items-center gap-2">
                <label for="monthFilter" class="text-xs font-semibold text-slate-500">مانگ:</label>
                <select
                    id="monthFilter"
                    name="month"
                    onchange="this.form.submit()"
                    class="rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-sm font-semibold text-slate-700 shadow-xs outline-none transition {{ $theme['ringFocus'] }}"
                >
                    <option value="all" {{ $selectedMonth === 'all' ? 'selected' : '' }}>هەموو مانگەکان</option>
                    @foreach($months as $monthOption)
                        <option value="{{ $monthOption }}" {{ $selectedMonth === $monthOption ? 'selected' : '' }}>
                            {{ $monthOption }} {{ $monthOption === $currentMonth ? '(ئەم مانگە)' : '' }}
                        </option>
                    @endforeach
                </select>
            </form>

            @if($selectedMonth !== $currentMonth)
                <a
                    href="{{ route($routeName, ['month' => $currentMonth]) }}"
                    class="px-3.5 py-2 rounded-xl border border-slate-200 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-50 transition"
                >
                    ئەم مانگە
                </a>
            @endif

            <button
                type="button"
                onclick="window.print()"
                class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold shadow-xs transition {{ $theme['btnBg'] }}"
            >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
                </svg>
                <span>چاپکردنی ڕاپۆرت</span>
            </button>
        </div>
    </div>

    <!-- Primary KPI Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Net & Gross Revenue -->
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-5 text-right">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="text-xs font-semibold text-slate-400">داهاتی پوخت ({{ $periodLabel }})</p>
                    <p class="text-2xl font-extrabold text-slate-900 mt-1.5">
                        <span dir="ltr" class="inline-block">{{ number_format($summary['net_revenue'], 0) }}</span>
                        <span class="text-xs font-semibold text-slate-400">د.ع</span>
                    </p>
                </div>
                <div class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 {{ $theme['iconBg'] }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                <span>کۆی گشتی: <strong class="text-slate-700" dir="ltr">{{ number_format($summary['gross_revenue'], 0) }}</strong></span>
                <span>کۆمیشن: <strong class="text-rose-600" dir="ltr">{{ number_format($summary['commission_total'], 0) }}</strong></span>
            </div>
        </div>

        <!-- Completed & Total Orders (Work Done) -->
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-5 text-right">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="text-xs font-semibold text-slate-400">{{ $meta['work_label'] }}</p>
                    <p class="text-2xl font-extrabold text-slate-900 mt-1.5">
                        <span dir="ltr" class="inline-block">{{ number_format($summary['completed_orders']) }}</span>
                        <span class="text-xs font-semibold text-slate-400">/ <span dir="ltr" class="inline-block">{{ number_format($summary['total_orders']) }}</span></span>
                    </p>
                </div>
                <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                <span>چالاک: <strong class="text-amber-600">{{ number_format($summary['active_orders']) }}</strong></span>
                <span>ڕەتکراو: <strong class="text-rose-600">{{ number_format($summary['cancelled_orders']) }}</strong></span>
            </div>
        </div>

        <!-- Items / Tests Performed -->
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-5 text-right">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="text-xs font-semibold text-slate-400">{{ $meta['items_label'] }}</p>
                    <p class="text-2xl font-extrabold text-slate-900 mt-1.5" dir="ltr">{{ number_format($summary['items_performed']) }}</p>
                </div>
                <div class="w-10 h-10 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                <span>لە داواکاری تەواوکراوەکان</span>
                @if(!is_null($meta['extra_results_count'] ?? null))
                    <span>ئەنجامی تۆمارکراو: <strong class="text-slate-700">{{ number_format($meta['extra_results_count']) }}</strong></span>
                @else
                    <span>کۆی گشتی کارەکان: <strong class="text-slate-700">{{ number_format($overall['items_performed']) }}</strong></span>
                @endif
            </div>
        </div>

        <!-- Unique Patients -->
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-5 text-right">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="text-xs font-semibold text-slate-400">ژمارەی نەخۆشەکان</p>
                    <p class="text-2xl font-extrabold text-slate-900 mt-1.5" dir="ltr">{{ number_format($summary['unique_patients']) }}</p>
                </div>
                <div class="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                <span>نەخۆشی تەواوکراو: <strong class="text-slate-700">{{ number_format($summary['completed_patients']) }}</strong></span>
                <span>هەموو کات: <strong class="text-slate-700">{{ number_format($overall['unique_patients']) }}</strong></span>
            </div>
        </div>
    </div>

    <!-- Payment Split & All-Time Strip -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-4 flex items-center justify-between text-right">
            <div>
                <p class="text-xs font-medium text-slate-400">داهاتی کاش (Cash)</p>
                <p class="text-lg font-bold text-slate-800 mt-0.5"><span dir="ltr" class="inline-block">{{ number_format($summary['cash_revenue'], 0) }}</span> د.ع</p>
            </div>
            <span class="px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-50 text-emerald-700">کاش</span>
        </div>
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-4 flex items-center justify-between text-right">
            <div>
                <p class="text-xs font-medium text-slate-400">داهاتی ئۆنلاین / کارت</p>
                <p class="text-lg font-bold text-slate-800 mt-0.5"><span dir="ltr" class="inline-block">{{ number_format($summary['online_revenue'], 0) }}</span> د.ع</p>
            </div>
            <span class="px-2.5 py-1 rounded-lg text-xs font-semibold bg-sky-50 text-sky-700">ئۆنلاین</span>
        </div>
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-4 flex items-center justify-between text-right">
            <div>
                <p class="text-xs font-medium text-slate-400">داهاتی گشتی (هەموو کات)</p>
                <p class="text-lg font-bold text-slate-800 mt-0.5"><span dir="ltr" class="inline-block">{{ number_format($overall['net_revenue'], 0) }}</span> د.ع</p>
            </div>
            <span class="px-2.5 py-1 rounded-lg text-xs font-semibold {{ $theme['softBg'] }}">کۆی گشتی</span>
        </div>
    </div>

    <!-- Chart + Top Items -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <!-- 6-Month Chart -->
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-100 shadow-xs p-5">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-4 text-right">
                <div>
                    <h2 class="text-base font-bold text-slate-900">چالاکی و داهاتی ٦ مانگی ڕابردوو</h2>
                    <p class="text-xs text-slate-400 mt-0.5">بەراوردکردنی داهاتی پوخت (د.ع) و ژمارەی {{ $meta['items_label'] }}</p>
                </div>
            </div>
            <div class="h-64 w-full">
                <canvas id="monthlyAccountingChart"></canvas>
            </div>
        </div>

        <!-- Top Items / Tests -->
        <div class="bg-white rounded-2xl border border-slate-100 shadow-xs p-5 text-right">
            <h2 class="text-base font-bold text-slate-900">{{ $meta['top_items_title'] }}</h2>
            <p class="text-xs text-slate-400 mt-0.5 mb-4">زۆرترین داواکاری تەواوکراو لەم ماوەیەدا</p>

            @if($topItems->isEmpty())
                <div class="py-10 text-center text-sm text-slate-400">
                    هیچ داتایەکی تەواوکراو بۆ ئەم ماوەیە نییە.
                </div>
            @else
                <div class="space-y-3">
                    @foreach($topItems as $index => $item)
                        <div class="flex items-center justify-between gap-3 p-3 rounded-xl bg-slate-50/80 border border-slate-100">
                            <div class="flex items-center gap-2.5 min-w-0">
                                <span class="w-6 h-6 rounded-lg text-xs font-bold flex items-center justify-center shrink-0 {{ $theme['softBg'] }}">
                                    {{ $index + 1 }}
                                </span>
                                <div class="min-w-0">
                                    <p class="text-sm font-semibold text-slate-800 truncate">{{ $item['name'] }}</p>
                                    <p class="text-xs text-slate-400">
                                        <span dir="ltr" class="inline-block">{{ number_format($item['revenue'], 0) }}</span> د.ع
                                    </p>
                                </div>
                            </div>
                            <span class="px-2.5 py-1 rounded-lg bg-white border border-slate-200 text-xs font-bold text-slate-700 shrink-0" dir="ltr">
                                {{ $item['count'] }}×
                            </span>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    </div>

    <!-- Monthly Breakdown Table & Mobile Cards -->
    <div class="bg-white rounded-2xl border border-slate-100 shadow-xs overflow-hidden">
        <div class="p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 text-right">
            <div>
                <h2 class="text-base font-bold text-slate-900">خشتەی ڕاپۆرتی مانگانە</h2>
                <p class="text-xs text-slate-400 mt-0.5">وردەکاری هەموو مانگەکان (کرتە لەسەر هەر مانگێک بکە بۆ بینینی وردەکاری)</p>
            </div>
            <span class="text-xs font-semibold text-slate-500">{{ $monthlyRows->count() }} مانگ</span>
        </div>

        @if($monthlyRows->isEmpty())
            <div class="p-10 text-center text-sm text-slate-400">هێشتا هیچ داواکارییەک تۆمار نەکراوە.</div>
        @else
            <!-- Desktop Table -->
            <div class="hidden md:block overflow-x-auto">
                <table class="w-full text-right text-sm">
                    <thead class="bg-slate-50/80 text-xs font-semibold text-slate-500 border-b border-slate-100">
                        <tr>
                            <th class="px-4 py-3">مانگ</th>
                            <th class="px-4 py-3">کۆی داواکاری</th>
                            <th class="px-4 py-3">تەواوکراو</th>
                            <th class="px-4 py-3">{{ $meta['items_label'] }}</th>
                            <th class="px-4 py-3">نەخۆشەکان</th>
                            <th class="px-4 py-3">کۆی گشتی</th>
                            <th class="px-4 py-3">کۆمیشن</th>
                            <th class="px-4 py-3">داهاتی پوخت</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($monthlyRows as $row)
                            <tr class="hover:bg-slate-50/70 transition {{ $selectedMonth === $row['month'] ? 'bg-slate-50' : '' }}">
                                <td class="px-4 py-3 font-bold">
                                    <a href="{{ route($routeName, ['month' => $row['month']]) }}" class="inline-flex items-center gap-1.5 text-slate-800 hover:underline">
                                        <span dir="ltr" class="inline-block">{{ $row['month'] }}</span>
                                        @if($row['month'] === $currentMonth)
                                            <span class="px-2 py-0.5 rounded-full text-[11px] font-semibold {{ $theme['softBg'] }}">ئێستا</span>
                                        @endif
                                    </a>
                                </td>
                                <td class="px-4 py-3 text-slate-700" dir="ltr">{{ number_format($row['total_orders']) }}</td>
                                <td class="px-4 py-3 font-semibold text-emerald-700" dir="ltr">{{ number_format($row['completed_orders']) }}</td>
                                <td class="px-4 py-3 text-slate-700" dir="ltr">{{ number_format($row['items_performed']) }}</td>
                                <td class="px-4 py-3 text-slate-700" dir="ltr">{{ number_format($row['unique_patients']) }}</td>
                                <td class="px-4 py-3 text-slate-700"><span dir="ltr" class="inline-block">{{ number_format($row['gross_revenue'], 0) }}</span> د.ع</td>
                                <td class="px-4 py-3 text-rose-600"><span dir="ltr" class="inline-block">{{ number_format($row['commission_total'], 0) }}</span> د.ع</td>
                                <td class="px-4 py-3 font-extrabold text-slate-900"><span dir="ltr" class="inline-block">{{ number_format($row['net_revenue'], 0) }}</span> د.ع</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <!-- Mobile Cards -->
            <div class="md:hidden divide-y divide-slate-100">
                @foreach($monthlyRows as $row)
                    <a href="{{ route($routeName, ['month' => $row['month']]) }}" class="block p-4 space-y-2.5 text-right hover:bg-slate-50 transition">
                        <div class="flex items-center justify-between">
                            <span class="text-sm font-extrabold text-slate-900" dir="ltr">{{ $row['month'] }}</span>
                            <span class="text-sm font-extrabold text-emerald-700"><span dir="ltr" class="inline-block">{{ number_format($row['net_revenue'], 0) }}</span> د.ع</span>
                        </div>
                        <div class="grid grid-cols-3 gap-2 text-xs text-slate-600">
                            <div class="bg-slate-50 rounded-lg p-2">
                                <span class="block text-slate-400 text-[11px]">تەواوکراو</span>
                                <strong class="text-slate-800">{{ $row['completed_orders'] }} / {{ $row['total_orders'] }}</strong>
                            </div>
                            <div class="bg-slate-50 rounded-lg p-2">
                                <span class="block text-slate-400 text-[11px]">{{ $meta['items_label'] }}</span>
                                <strong class="text-slate-800">{{ $row['items_performed'] }}</strong>
                            </div>
                            <div class="bg-slate-50 rounded-lg p-2">
                                <span class="block text-slate-400 text-[11px]">نەخۆش</span>
                                <strong class="text-slate-800">{{ $row['unique_patients'] }}</strong>
                            </div>
                        </div>
                    </a>
                @endforeach
            </div>
        @endif
    </div>

    <!-- Period Ledger (Up to 50 Orders) -->
    <div class="bg-white rounded-2xl border border-slate-100 shadow-xs overflow-hidden">
        <div class="p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 text-right">
            <div>
                <h2 class="text-base font-bold text-slate-900">تۆماری داواکارییەکانی ماوەکە ({{ $periodLabel }})</h2>
                <p class="text-xs text-slate-400 mt-0.5">دوایین ٥٠ داواکاری بە پێی کاتی ناوخۆی هەولێر</p>
            </div>
            <span class="text-xs font-semibold text-slate-500">{{ $ledgerOrders->count() }} تۆمار</span>
        </div>

        @if($ledgerOrders->isEmpty())
            <div class="p-10 text-center text-sm text-slate-400">لەم ماوەیەدا هیچ داواکارییەک نییە.</div>
        @else
            <!-- Desktop Table -->
            <div class="hidden md:block overflow-x-auto">
                <table class="w-full text-right text-sm">
                    <thead class="bg-slate-50/80 text-xs font-semibold text-slate-500 border-b border-slate-100">
                        <tr>
                            <th class="px-4 py-3">#</th>
                            <th class="px-4 py-3">نەخۆش</th>
                            <th class="px-4 py-3">{{ $meta['item_col_label'] }}</th>
                            <th class="px-4 py-3">بەروار و کات</th>
                            <th class="px-4 py-3">شێوازی پارەدان</th>
                            <th class="px-4 py-3">دۆخ</th>
                            <th class="px-4 py-3">کۆی گشتی</th>
                            <th class="px-4 py-3">داهاتی پوخت</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($ledgerOrders as $order)
                            @php
                                $badge = $statusLabels[$order->status] ?? ['label' => $order->status, 'class' => 'bg-slate-50 text-slate-700 border-slate-200'];
                                $gross = (float) ($order->total_price ?? 0);
                                $net = $order->provider_net_amount !== null ? (float) $order->provider_net_amount : max(0, $gross - (float) ($order->commission_amount ?? 0));
                                $payMethod = strtolower((string) ($order->payment_method ?? 'cash'));
                                $payLabel = $payMethod === 'cash' ? 'کاش' : 'ئۆنلاین';
                                $localTime = $order->created_at?->timezone('Asia/Baghdad');
                            @endphp
                            <tr class="hover:bg-slate-50/70 transition">
                                <td class="px-4 py-3 font-semibold text-slate-500" dir="ltr">#{{ $order->id }}</td>
                                <td class="px-4 py-3">
                                    <p class="font-semibold text-slate-800">{{ $order->patient->name ?? 'نەخۆش' }}</p>
                                    @if(!empty($order->patient?->phone))
                                        <p class="text-xs text-slate-400" dir="ltr">{{ $order->patient->phone }}</p>
                                    @endif
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex flex-wrap gap-1">
                                        @forelse($order->items as $item)
                                            <span class="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 text-xs">
                                                {{ $item->item_name }}@if(($item->quantity ?? 1) > 1) ×{{ $item->quantity }}@endif
                                            </span>
                                        @empty
                                            <span class="text-xs text-slate-400">—</span>
                                        @endforelse
                                    </div>
                                </td>
                                <td class="px-4 py-3 text-xs text-slate-600">
                                    <span dir="ltr" class="inline-block font-semibold text-slate-800">{{ $localTime?->format('Y-m-d') ?? '-' }}</span>
                                    <span dir="ltr" class="block text-slate-400">{{ $localTime?->format('h:i A') ?? '' }}</span>
                                </td>
                                <td class="px-4 py-3 text-xs font-semibold text-slate-600">{{ $payLabel }}</td>
                                <td class="px-4 py-3">
                                    <span class="inline-flex px-2.5 py-1 rounded-full text-xs font-semibold border {{ $badge['class'] }}">
                                        {{ $badge['label'] }}
                                    </span>
                                </td>
                                <td class="px-4 py-3 text-slate-700"><span dir="ltr" class="inline-block">{{ number_format($gross, 0) }}</span> د.ع</td>
                                <td class="px-4 py-3 font-bold text-slate-900"><span dir="ltr" class="inline-block">{{ number_format($net, 0) }}</span> د.ع</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <!-- Mobile Cards -->
            <div class="md:hidden divide-y divide-slate-100">
                @foreach($ledgerOrders as $order)
                    @php
                        $badge = $statusLabels[$order->status] ?? ['label' => $order->status, 'class' => 'bg-slate-50 text-slate-700 border-slate-200'];
                        $gross = (float) ($order->total_price ?? 0);
                        $net = $order->provider_net_amount !== null ? (float) $order->provider_net_amount : max(0, $gross - (float) ($order->commission_amount ?? 0));
                        $localTime = $order->created_at?->timezone('Asia/Baghdad');
                    @endphp
                    <div class="p-4 space-y-2.5 text-right">
                        <div class="flex items-center justify-between gap-2">
                            <div>
                                <p class="font-bold text-slate-900">{{ $order->patient->name ?? 'نەخۆش' }}</p>
                                <p class="text-xs text-slate-400" dir="ltr">#{{ $order->id }} • {{ $localTime?->format('Y-m-d h:i A') ?? '-' }}</p>
                            </div>
                            <span class="inline-flex px-2.5 py-1 rounded-full text-xs font-semibold border {{ $badge['class'] }}">
                                {{ $badge['label'] }}
                            </span>
                        </div>
                        <div class="flex flex-wrap gap-1">
                            @foreach($order->items as $item)
                                <span class="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 text-xs">
                                    {{ $item->item_name }}@if(($item->quantity ?? 1) > 1) ×{{ $item->quantity }}@endif
                                </span>
                            @endforeach
                        </div>
                        <div class="flex items-center justify-between text-xs pt-1 border-t border-slate-100">
                            <span class="text-slate-500">کۆی گشتی: <strong class="text-slate-700" dir="ltr">{{ number_format($gross, 0) }}</strong> د.ع</span>
                            <span class="text-slate-500">داهاتی پوخت: <strong class="text-slate-900" dir="ltr">{{ number_format($net, 0) }}</strong> د.ع</span>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    const canvas = document.getElementById('monthlyAccountingChart');
    if (!canvas || typeof Chart === 'undefined') return;

    const series = @json($chartSeries);
    const labels = series.map(item => item.month);
    const netRevenues = series.map(item => Number(item.net_revenue || 0));
    const itemsPerformed = series.map(item => Number(item.items_performed || 0));

    new Chart(canvas.getContext('2d'), {
        data: {
            labels: labels,
            datasets: [
                {
                    type: 'bar',
                    label: 'داهاتی پوخت (د.ع)',
                    data: netRevenues,
                    backgroundColor: @json($theme['barSoftHex']),
                    borderColor: @json($theme['barHex']),
                    borderWidth: 2,
                    borderRadius: 8,
                    yAxisID: 'y',
                },
                {
                    type: 'line',
                    label: @json($meta['items_label']),
                    data: itemsPerformed,
                    borderColor: @json($theme['lineHex']),
                    backgroundColor: @json($theme['lineHex']),
                    borderWidth: 2.5,
                    tension: 0.35,
                    pointRadius: 4,
                    yAxisID: 'y1',
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { usePointStyle: true, boxWidth: 8 }
                }
            },
            scales: {
                y: {
                    type: 'linear',
                    position: 'right',
                    beginAtZero: true,
                    ticks: {
                        callback: function (value) {
                            return Number(value).toLocaleString();
                        }
                    },
                    grid: { color: 'rgba(148, 163, 184, 0.14)' }
                },
                y1: {
                    type: 'linear',
                    position: 'left',
                    beginAtZero: true,
                    ticks: { precision: 0 },
                    grid: { drawOnChartArea: false }
                },
                x: {
                    grid: { display: false }
                }
            }
        }
    });
});
</script>
@endpush
