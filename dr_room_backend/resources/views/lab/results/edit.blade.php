@extends('lab.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">دەستکاریکردنی ئەنجام</h1>
        <a href="{{ route('lab.results.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded">
            گەڕانەوە
        </a>
    </div>

    @if($errors->any())
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <ul>
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="bg-white shadow-md rounded p-6">
        <form action="{{ route('lab.results.update', $result) }}" method="POST" enctype="multipart/form-data">
            @csrf
            @method('PUT')
            
            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2">
                    نەخۆش
                </label>
                <!-- Usually patient is not changed on edit, just displayed -->
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-500 bg-gray-100 leading-tight" type="text" value="{{ $result->patient->name ?? 'نەخۆش نەدۆزرایەوە' }}" readonly disabled>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="test_id">
                    پشکنین
                </label>
                <select class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="test_id" name="test_id" required>
                    @foreach($tests as $test)
                        <option value="{{ $test->id }}" {{ old('test_id', $result->test_id) == $test->id ? 'selected' : '' }}>{{ $test->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="result_value">
                    ئەنجام
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="result_value" type="text" name="result_value" value="{{ old('result_value', $result->result_value) }}">
            </div>
            
            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="status">
                    حاڵەت
                </label>
                <select class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="status" name="status" required>
                    <option value="pending" {{ old('status', $result->status) == 'pending' ? 'selected' : '' }}>چاوەڕێ (Pending)</option>
                    <option value="completed" {{ old('status', $result->status) == 'completed' ? 'selected' : '' }}>تەواوبووە (Completed)</option>
                </select>
            </div>
            
            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="file">
                    فایلی ئەنجام (نوێکردنەوە)
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="file" type="file" name="file">
                @if($result->file_path)
                    <p class="text-sm text-gray-500 mt-1">لە ئێستادا فایلێکی هەیە. <a href="{{ Storage::url($result->file_path) }}" target="_blank" class="text-blue-500">بینین</a></p>
                @endif
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="notes">
                    تێبینی زیاتر
                </label>
                <textarea class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="notes" name="notes" rows="3">{{ old('notes', $result->notes) }}</textarea>
            </div>

            <div class="flex items-center justify-end">
                <button class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" type="submit">
                    نوێکردنەوە
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
