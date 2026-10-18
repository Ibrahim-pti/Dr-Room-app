<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Category;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database for production.
     * Contains only the Admin user and essential clinical categories.
     */
    public function run(): void
    {
        // 1. Primary Admin User
        User::firstOrCreate(
            ['email' => 'admin@drroom.com'],
            [
                'name' => 'بەڕێوەبەری دکتۆر ڕووم',
                'name_en' => 'DrRoom Admin',
                'name_ar' => 'مدير دكتور روم',
                'phone' => '07500000000',
                'role' => 'admin',
                'status' => 'approved',
                'password' => Hash::make('admin123456'),
            ]
        );

        // 2. Core Medical Specialties / Categories
        $categories = [
            ['name' => 'دڵ و لوولەکانی خوێن', 'name_en' => 'Cardiology', 'name_ar' => 'أمراض القلب', 'icon' => 'heart'],
            ['name' => 'پێست و جوانکاری', 'name_en' => 'Dermatology', 'name_ar' => 'الجلدية والتجميل', 'icon' => 'dermatology'],
            ['name' => 'منداڵان و ساوایان', 'name_en' => 'Pediatrics', 'name_ar' => 'طب الأطفال', 'icon' => 'child'],
            ['name' => 'ئێسک و جومگە', 'name_en' => 'Orthopedics', 'name_ar' => 'العظام والمفاصل', 'icon' => 'bone'],
            ['name' => 'مێشک و دەمار', 'name_en' => 'Neurology', 'name_ar' => 'المخ والأعصاب', 'icon' => 'brain'],
            ['name' => 'چاو و بینین', 'name_en' => 'Ophthalmology', 'name_ar' => 'طب العيون', 'icon' => 'eye'],
            ['name' => 'ددان و پووک', 'name_en' => 'Dentistry', 'name_ar' => 'طب الأسنان', 'icon' => 'tooth'],
            ['name' => 'نەشتەرگەری گشتی', 'name_en' => 'General Surgery', 'name_ar' => 'الجراحة العامة', 'icon' => 'surgery'],
        ];

        foreach ($categories as $cat) {
            Category::firstOrCreate(['name' => $cat['name']], $cat);
        }

        // 3. Service Scope Categories
        $this->call(ServiceCategorySeeder::class);
    }
}
