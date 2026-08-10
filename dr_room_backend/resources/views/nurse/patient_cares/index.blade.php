@extends('nurse.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">چاودێری نەخۆشەکان</h1>
        <a href="{{ route('nurse.patient_cares.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            تۆمارکردنی نوێ
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
                    <th class="py-3 px-6 text-right">بەروار</th>
                    <th class="py-3 px-6 text-right">نیشانەکان</th>
                    <th class="py-3 px-6 text-right">دەرمانەکان</th>
                    <th class="py-3 px-6 text-center">کردارەکان</th>
                </tr>
            </thead>
            <tbody class="text-gray-600 text-sm font-light">
                @forelse($cares as $care)
                <tr class="border-b border-gray-200 hover:bg-gray-100">
                    <td class="py-3 px-6 text-right whitespace-nowrap">
                        <span class="font-medium">{{ $care->patient->name ?? 'نەخۆش سڕاوەتەوە' }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ $care->date ? $care->date->format('Y-m-d') : '-' }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ Str::limit($care->symptoms, 30) }}</span>
                    </td>
                    <td class="py-3 px-6 text-right">
                        <span>{{ Str::limit($care->medication_given, 30) }}</span>
                    </td>
                    <td class="py-3 px-6 text-center">
                        <div class="flex item-center justify-center gap-4">
                            <a href="{{ route('nurse.patient_cares.edit', $care) }}" class="text-blue-500 hover:text-blue-700">
                                دەستکاری
                            </a>
                            <form action="{{ route('nurse.patient_cares.destroy', $care) }}" method="POST" class="inline-block" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم تۆمارە؟');">
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
                    <td colspan="5" class="py-3 px-6 text-center">هیچ تۆمارێک نەدۆزرایەوە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
