with open('app/Http/Controllers/Web/DoctorProfileController.php', 'r') as f:
    content = f.read()

# Update validation
val_old = """            'specialty' => 'nullable|string|max:255',
            'bio' => 'nullable|string',"""
val_new = """            'specialty' => 'nullable|string|max:255',
            'specialty_en' => 'nullable|string|max:255',
            'specialty_ar' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            'bio_en' => 'nullable|string',
            'bio_ar' => 'nullable|string',"""
content = content.replace(val_old, val_new)

# Update translation logic
trans_old = """            try {
                $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();
                if ($request->specialty) {
                    $updateData['specialty_en'] = $tr->setTarget('en')->translate($request->specialty);
                    $updateData['specialty_ar'] = $tr->setTarget('ar')->translate($request->specialty);
                }
                if ($request->bio) {
                    $updateData['bio_en'] = $tr->setTarget('en')->translate($request->bio);
                    $updateData['bio_ar'] = $tr->setTarget('ar')->translate($request->bio);
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error('Translation failed: ' . $e->getMessage());
            }"""

trans_new = """            $updateData['specialty_en'] = $request->specialty_en;
            $updateData['specialty_ar'] = $request->specialty_ar;
            $updateData['bio_en'] = $request->bio_en;
            $updateData['bio_ar'] = $request->bio_ar;
            
            try {
                $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();
                if ($request->specialty && !$request->specialty_en) {
                    $updateData['specialty_en'] = $tr->setTarget('en')->translate($request->specialty);
                }
                if ($request->specialty && !$request->specialty_ar) {
                    $updateData['specialty_ar'] = $tr->setTarget('ar')->translate($request->specialty);
                }
                if ($request->bio && !$request->bio_en) {
                    $updateData['bio_en'] = $tr->setTarget('en')->translate($request->bio);
                }
                if ($request->bio && !$request->bio_ar) {
                    $updateData['bio_ar'] = $tr->setTarget('ar')->translate($request->bio);
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error('Translation failed: ' . $e->getMessage());
            }"""

content = content.replace(trans_old, trans_new)

with open('app/Http/Controllers/Web/DoctorProfileController.php', 'w') as f:
    f.write(content)
