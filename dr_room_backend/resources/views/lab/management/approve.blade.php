@extends('lab.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">پەسەندکردنی پشکنین (چاوەڕێکراوەکان)</h1>
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
                        <span>{{ $result->result_value ?? 'هێشتا نەنووسراوە' }}</span>
                    </td>
                    <td class="py-3 px-6 text-center">
                        <div class="flex item-center justify-center gap-4">
                            <form action="{{ route('lab.management.status', $result) }}" method="POST" class="inline-block" onsubmit="return confirm('دڵنیایت لە پەسەندکردن و تەواوکردنی ئەم پشکنینە؟');">
                                @csrf
                                @method('PATCH')
                                <input type="hidden" name="status" value="completed">
                                <button type="submit" class="bg-green-500 hover:bg-green-600 text-white py-1 px-3 rounded text-sm">
                                    پەسەندکردن
                                </button>
                            </form>
                            
                            <a href="{{ route('lab.results.edit', $result) }}" class="text-blue-500 hover:text-blue-700 mt-1 inline-block">
                                دەستکاری
                            </a>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="4" class="py-3 px-6 text-center">هیچ پشکنینێکی چاوەڕێکراو نەدۆزرایەوە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
