@extends('lab.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">دەستکاریکردنی پشکنین</h1>
        <a href="{{ route('lab.tests.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded">
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
        <form action="{{ route('lab.tests.update', $test) }}" method="POST">
            @csrf
            @method('PUT')
            
            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                    ناوی پشکنین
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="name" type="text" name="name" value="{{ old('name', $test->name) }}" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="type">
                    جۆری پشکنین
                </label>
                <select class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="type" name="type" required>
                    <option value="blood" {{ old('type', $test->type) == 'blood' ? 'selected' : '' }}>خوێن (Blood)</option>
                    <option value="urine" {{ old('type', $test->type) == 'urine' ? 'selected' : '' }}>میز (Urine)</option>
                    <option value="hormone" {{ old('type', $test->type) == 'hormone' ? 'selected' : '' }}>هۆرمۆن (Hormone)</option>
                    <option value="other" {{ old('type', $test->type) == 'other' ? 'selected' : '' }}>تر (Other)</option>
                </select>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="price">
                    نرخ
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="price" type="number" step="0.01" name="price" value="{{ old('price', $test->price) }}" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="description">
                    زانیاری زیاتر
                </label>
                <textarea class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="description" name="description" rows="3">{{ old('description', $test->description) }}</textarea>
            </div>

            <div class="mb-6">
                <label class="flex items-center">
                    <input type="checkbox" name="is_active" value="1" class="form-checkbox h-5 w-5 text-blue-600" {{ $test->is_active ? 'checked' : '' }}>
                    <span class="mr-2 text-gray-700 font-bold">چالاکە</span>
                </label>
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
