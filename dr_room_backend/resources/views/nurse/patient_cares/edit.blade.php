@extends('nurse.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">دەستکاریکردنی چاودێری</h1>
        <a href="{{ route('nurse.patient_cares.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded">
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
        <form action="{{ route('nurse.patient_cares.update', $care) }}" method="POST">
            @csrf
            @method('PUT')
            
            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2">
                    نەخۆش
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-500 bg-gray-100 leading-tight focus:outline-none focus:shadow-outline" type="text" value="{{ $care->patient->name ?? 'نەخۆش نەدۆزرایەوە' }}" readonly disabled>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="date">
                    بەروار
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="date" type="date" name="date" value="{{ old('date', $care->date ? $care->date->format('Y-m-d') : '') }}" required>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="blood_pressure">
                        پەستانی خوێن
                    </label>
                    <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="blood_pressure" type="text" name="blood_pressure" value="{{ old('blood_pressure', $care->vitals['blood_pressure'] ?? '') }}">
                </div>
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="heart_rate">
                        لێدانی دڵ
                    </label>
                    <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="heart_rate" type="text" name="heart_rate" value="{{ old('heart_rate', $care->vitals['heart_rate'] ?? '') }}">
                </div>
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="temperature">
                        پلەی گەرمی
                    </label>
                    <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="temperature" type="text" name="temperature" value="{{ old('temperature', $care->vitals['temperature'] ?? '') }}">
                </div>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="symptoms">
                    نیشانەکان
                </label>
                <textarea class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="symptoms" name="symptoms" rows="3">{{ old('symptoms', $care->symptoms) }}</textarea>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="medication_given">
                    پێدانی دەرمان
                </label>
                <textarea class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="medication_given" name="medication_given" rows="3">{{ old('medication_given', $care->medication_given) }}</textarea>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="notes">
                    تێبینی ڕۆژانە
                </label>
                <textarea class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="notes" name="notes" rows="3">{{ old('notes', $care->notes) }}</textarea>
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
