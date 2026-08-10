@extends('lab.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">لێستی پشکنینەکان</h1>
        <a href="{{ route('lab.tests.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            زیادکردنی پشکنین
        </a>
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            {{ session('success') }}
        </div>
    @endif

    <div class="bg-white shadow-md rounded my-6 overflow-x-auto">
        <table class="min-w-full table-auto">
            <thead>
                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                    <th class="py-3 px-6 text-right">ناو</th>
                    <th class="py-3 px-6 text-right">جۆر</th>
                    <th class="py-3 px-6 text-right">نرخ</th>
                    <th class="py-3 px-6 text-right">حاڵەت</th>
                    <th class="py-3 px-6 text-center">کردارەکان</th>
                </tr>
            </thead>
            <tbody class="text-gray-600 text-sm font-light">
                @forelse($tests as $test)
                <tr class="border-b border-gray-200 hover:bg-gray-100">
                    <td class="py-3 px-6 text-right whitespace-nowrap">
                        <span class="font-medium">{{ $test->name }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ ucfirst($test->type) }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ number_format($test->price, 2) }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        @if($test->is_active)
                            <span class="bg-green-200 text-green-600 py-1 px-3 rounded-full text-xs">چالاکە</span>
                        @else
                            <span class="bg-red-200 text-red-600 py-1 px-3 rounded-full text-xs">ناچالاکە</span>
                        @endif
                    </td>
                    <td class="py-3 px-6 text-center">
                        <div class="flex item-center justify-center gap-4">
                            <a href="{{ route('lab.tests.edit', $test) }}" class="text-blue-500 hover:text-blue-700">
                                دەستکاری
                            </a>
                            <form action="{{ route('lab.tests.destroy', $test) }}" method="POST" class="inline-block" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم پشکنینە؟');">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="text-red-500 hover:text-red-700">
                                    سڕینەوە
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" class="py-3 px-6 text-center">هیچ پشکنینێک نەدۆزرایەوە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
