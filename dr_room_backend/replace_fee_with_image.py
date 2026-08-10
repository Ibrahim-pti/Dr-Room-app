with open('resources/views/doctor/profile/index.blade.php', 'r') as f:
    content = f.read()

old_block = """            <!-- Consultation Fee -->
            <div>
                <label for="consultation_fee" class="block text-sm font-medium text-slate-700 mb-2">نرخی بینین ($)</label>
                <input type="number" step="0.01" id="consultation_fee" name="consultation_fee" value="{{ old('consultation_fee', $doctor->consultation_fee) }}" dir="ltr"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                @error('consultation_fee') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>"""

new_block = """            <!-- Profile Image -->
            <div>
                <label for="image" class="block text-sm font-medium text-slate-700 mb-2">وێنەی پڕۆفایل</label>
                <div class="flex items-center gap-4">
                    @if($doctor->image_path)
                        <img src="{{ $doctor->image_path }}" alt="Profile Image" class="w-16 h-16 rounded-full object-cover border border-slate-200">
                    @endif
                    <input type="file" id="image" name="image" accept="image/*"
                        class="block w-full text-sm text-slate-500 file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 transition-all">
                </div>
                @error('image') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>"""

content = content.replace(old_block, new_block)

with open('resources/views/doctor/profile/index.blade.php', 'w') as f:
    f.write(content)
