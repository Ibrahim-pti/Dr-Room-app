with open('resources/views/doctor/profile/index.blade.php', 'r') as f:
    content = f.read()

# Add translate button near the top of the form
form_start = """<form id="profile-form" action="{{ route('doctor.profile.update') }}" method="POST" enctype="multipart/form-data" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 max-w-3xl">
    @csrf
    @method('PUT')
    
    <div class="space-y-6">"""

form_with_btn = """<form id="profile-form" action="{{ route('doctor.profile.update') }}" method="POST" enctype="multipart/form-data" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 max-w-3xl">
    @csrf
    @method('PUT')
    
    <div class="flex justify-between items-center mb-6">
        <h3 class="text-lg font-bold text-slate-800">زانیارییەکان</h3>
        <button type="button" onclick="translateAll()" id="translateBtn" class="flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-600 rounded-xl hover:bg-indigo-100 transition-colors text-sm font-medium">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18" height="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
            <span>وەرگێڕانی ئۆتۆماتیکی (Translate All)</span>
        </button>
    </div>

    <div class="space-y-6">"""

content = content.replace(form_start, form_with_btn)

# Specialty block replace
spec_old = """            <!-- Specialty -->
            <div>
                <label for="specialty" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی</label>
                <input type="text" id="specialty" name="specialty" value="{{ old('specialty', $doctor->specialty) }}"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                @error('specialty') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>"""

spec_new = """            <!-- Specialty -->
            <div class="space-y-4">
                <div>
                    <label for="specialty" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی (کوردی)</label>
                    <input type="text" id="specialty" name="specialty" value="{{ old('specialty', $doctor->specialty) }}"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    @error('specialty') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="specialty_ar" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی (عەرەبی)</label>
                    <input type="text" id="specialty_ar" name="specialty_ar" value="{{ old('specialty_ar', $doctor->specialty_ar) }}" dir="rtl"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
                <div>
                    <label for="specialty_en" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی (ئینگلیزی)</label>
                    <input type="text" id="specialty_en" name="specialty_en" value="{{ old('specialty_en', $doctor->specialty_en) }}" dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
            </div>"""

content = content.replace(spec_old, spec_new)

# Bio block replace
bio_old = """        <!-- Bio -->
        <div>
            <label for="bio" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت</label>
            <textarea id="bio" name="bio" rows="4"
                class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio', $doctor->bio) }}</textarea>
            @error('bio') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>"""

bio_new = """        <!-- Bio -->
        <div class="space-y-4">
            <div>
                <label for="bio" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت (کوردی)</label>
                <textarea id="bio" name="bio" rows="3"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio', $doctor->bio) }}</textarea>
                @error('bio') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
            <div>
                <label for="bio_ar" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت (عەرەبی)</label>
                <textarea id="bio_ar" name="bio_ar" rows="3" dir="rtl"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio_ar', $doctor->bio_ar) }}</textarea>
            </div>
            <div>
                <label for="bio_en" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت (ئینگلیزی)</label>
                <textarea id="bio_en" name="bio_en" rows="3" dir="ltr"
                    class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio_en', $doctor->bio_en) }}</textarea>
            </div>
        </div>"""

content = content.replace(bio_old, bio_new)

# Add translate function to script
script_start = """<script>
    function toggleVideoInputs(type) {"""
script_new = """<script>
    async function translateAll() {
        const btn = document.getElementById('translateBtn');
        const originalText = btn.innerHTML;
        btn.innerHTML = '<svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> <span>چاوەڕێبە...</span>';
        btn.disabled = true;

        const specialty = document.getElementById('specialty').value;
        const bio = document.getElementById('bio').value;

        try {
            if (specialty) {
                const res = await fetch(`/api/translate`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                    body: JSON.stringify({text: specialty})
                });
                const data = await res.json();
                document.getElementById('specialty_en').value = data.en || '';
                document.getElementById('specialty_ar').value = data.ar || '';
            }

            if (bio) {
                const res = await fetch(`/api/translate`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                    body: JSON.stringify({text: bio})
                });
                const data = await res.json();
                document.getElementById('bio_en').value = data.en || '';
                document.getElementById('bio_ar').value = data.ar || '';
            }
        } catch(e) {
            alert('کێشەیەک ڕوویدا لە وەرگێڕان');
        }

        btn.innerHTML = originalText;
        btn.disabled = false;
    }

    function toggleVideoInputs(type) {"""

content = content.replace(script_start, script_new)

with open('resources/views/doctor/profile/index.blade.php', 'w') as f:
    f.write(content)
