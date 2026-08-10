@extends('nurse.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">خشتەی کارکردن</h1>
    </div>

    <div class="bg-white shadow-md rounded p-6">
        <div class="flex items-center mb-4">
            <div class="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-2xl font-bold ml-4">
                {{ substr($nurse->user->name ?? 'N', 0, 1) }}
            </div>
            <div>
                <h2 class="text-xl font-bold">{{ $nurse->user->name ?? 'ناو نەدۆزرایەوە' }}</h2>
                <p class="text-gray-600">پەرستار</p>
            </div>
        </div>

        <hr class="my-4">

        <h3 class="text-lg font-bold mb-4">زانیاری کارکردن</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-gray-50 p-4 rounded border">
                <span class="text-gray-500 block mb-1">ڕۆژانی کارکردن</span>
                <span class="font-semibold block">{{ $nurse->work_days ?? 'دیارینەکراوە' }}</span>
            </div>
            <div class="bg-gray-50 p-4 rounded border">
                <span class="text-gray-500 block mb-1">کاتی دەوام</span>
                <span class="font-semibold block">
                    {{ $nurse->shift_start ? date('h:i A', strtotime($nurse->shift_start)) : 'دیارینەکراوە' }} - 
                    {{ $nurse->shift_end ? date('h:i A', strtotime($nurse->shift_end)) : 'دیارینەکراوە' }}
                </span>
            </div>
        </div>
        
        <div class="mt-6 text-center text-gray-500 text-sm">
            <p>بۆ گۆڕانکاری لە خشتەی کارکردن، تکایە پەیوەندی بە بەڕێوەبەرایەتی بکە.</p>
        </div>
    </div>
</div>
@endsection
