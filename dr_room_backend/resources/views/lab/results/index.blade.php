@extends('lab.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">لێستی ئەنجامەکان</h1>
        <a href="{{ route('lab.results.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            زیادکردنی ئەنجام
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
                    <th class="py-3 px-6 text-right">نەخۆش</th>
                    <th class="py-3 px-6 text-right">پشکنین</th>
                    <th class="py-3 px-6 text-right">ئەنجام</th>
                    <th class="py-3 px-6 text-right">حاڵەت</th>
                    <th class="py-3 px-6 text-center">فایل</th>
                    <th class="py-3 px-6 text-center">کردارەکان</th>
                </tr>
            </thead>
            <tbody class="text-gray-600 text-sm font-light">
                @forelse($results as $result)
                <tr class="border-b border-gray-200 hover:bg-gray-100">
                    <td class="py-3 px-6 text-right whitespace-nowrap">
                        <span class="font-medium">{{ $result->patient->name ?? 'نەخۆش سڕاوەتەوە' }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ $result->test->name ?? 'پشکنین سڕاوەتەوە' }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ $result->result_value ?? '-' }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        @if($result->status == 'completed')
                            <span class="bg-green-200 text-green-600 py-1 px-3 rounded-full text-xs">تەواوبووە</span>
                        @else
                            <span class="bg-yellow-200 text-yellow-600 py-1 px-3 rounded-full text-xs">چاوەڕێ</span>
                        @endif
                    </td>
                    <td class="py-3 px-6 text-center">
                        @if($result->file_path)
                            <a href="{{ Storage::url($result->file_path) }}" target="_blank" class="text-blue-500 hover:underline">بینین</a>
                        @else
                            -
                        @endif
                    </td>
                    <td class="py-3 px-6 text-center">
                        <div class="flex item-center justify-center gap-4">
                            <a href="{{ route('lab.results.edit', $result) }}" class="text-blue-500 hover:text-blue-700">
                                دەستکاری
                            </a>
                            <form action="{{ route('lab.results.destroy', $result) }}" method="POST" class="inline-block" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم ئەنجامە؟');">
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
                    <td colspan="6" class="py-3 px-6 text-center">هیچ ئەنجامێک نەدۆزرایەوە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
