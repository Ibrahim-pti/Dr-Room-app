with open('app/Http/Controllers/Web/DoctorProfileController.php', 'r') as f:
    content = f.read()

# Replace validation rules
val_old = """            'bio' => 'nullable|string',
            'consultation_fee' => 'nullable|numeric|min:0',
            'video_type' => 'nullable|in:youtube,uploaded',"""
val_new = """            'bio' => 'nullable|string',
            'image' => 'nullable|image|max:5120',
            'video_type' => 'nullable|in:youtube,uploaded',"""
content = content.replace(val_old, val_new)

# Replace updateData init
update_old = """            $updateData = [
                'specialty' => $request->specialty,
                'bio' => $request->bio,
                'consultation_fee' => $request->consultation_fee,
            ];"""
update_new = """            $updateData = [
                'specialty' => $request->specialty,
                'bio' => $request->bio,
            ];

            if ($request->hasFile('image')) {
                $path = $request->file('image')->store('doctor_images', 'public');
                $updateData['image_path'] = '/storage/' . $path;
            }"""
content = content.replace(update_old, update_new)

with open('app/Http/Controllers/Web/DoctorProfileController.php', 'w') as f:
    f.write(content)
