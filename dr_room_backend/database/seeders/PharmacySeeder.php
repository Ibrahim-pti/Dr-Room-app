<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Medication;
use App\Models\PharmacyOffer;
use Illuminate\Support\Facades\Hash;

class PharmacySeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create a Fake Pharmacy
        $pharmacy = User::firstOrCreate([
            'email' => 'pharmacy_demo@example.com'
        ], [
            'name' => 'دەرمانخانەی نموونەیی',
            'phone' => '07501234567',
            'role' => 'pharmacy',
            'status' => 'approved',
            'password' => Hash::make('password'),
        ]);

        // 2. Create Fake Medications
        $medications = [
            ['name' => 'Panadol Extra', 'price' => 2000, 'stock' => 50, 'desc' => 'بۆ ئازار شکاندن و تای بەرز'],
            ['name' => 'Amoxicillin 500mg', 'price' => 4500, 'stock' => 120, 'desc' => 'دژە بەکتریا'],
            ['name' => 'Vitamin C 1000mg', 'price' => 6000, 'stock' => 30, 'desc' => 'بۆ بەهێزکردنی بەرگری لەش'],
            ['name' => 'Ibuprofen 400mg', 'price' => 2500, 'stock' => 80, 'desc' => 'بۆ هەوکردن و ئازار'],
            ['name' => 'Omega 3 Fish Oil', 'price' => 12000, 'stock' => 15, 'desc' => 'تەواوکەری خۆراکی'],
        ];

        foreach ($medications as $med) {
            Medication::firstOrCreate([
                'user_id' => $pharmacy->id,
                'name' => $med['name'],
            ], [
                'description' => $med['desc'],
                'price' => $med['price'],
                'stock' => $med['stock'],
                'is_active' => true,
            ]);
        }

        // 3. Create Fake Offers
        PharmacyOffer::firstOrCreate([
            'user_id' => $pharmacy->id,
            'title' => 'داشکاندنی هاوینە',
        ], [
            'description' => 'داشکاندنی تایبەت بۆ هەموو ڤیتامینەکان بە بۆنەی وەرزی هاوینەوە.',
            'discount_percentage' => 20.00,
            'is_active' => true,
            'start_date' => now(),
            'end_date' => now()->addDays(30),
        ]);

        PharmacyOffer::firstOrCreate([
            'user_id' => $pharmacy->id,
            'title' => 'ئۆفەری کڕینی دەرمانی دڵ',
        ], [
            'description' => 'داشکاندن بۆ کەسانی بەتەمەن.',
            'discount_percentage' => 15.00,
            'is_active' => true,
        ]);
        
        // Let's create a second pharmacy to make the list look good
        $pharmacy2 = User::firstOrCreate([
            'email' => 'shifa_pharmacy@example.com'
        ], [
            'name' => 'دەرمانخانەی شفا',
            'phone' => '07509876543',
            'role' => 'pharmacy',
            'status' => 'approved',
            'password' => Hash::make('password'),
        ]);
        
        Medication::firstOrCreate([
            'user_id' => $pharmacy2->id,
            'name' => 'Aspirin 100mg',
        ], [
            'description' => 'بۆ ڕێگری لە جەڵتە',
            'price' => 1500,
            'stock' => 200,
            'is_active' => true,
        ]);
    }
}
