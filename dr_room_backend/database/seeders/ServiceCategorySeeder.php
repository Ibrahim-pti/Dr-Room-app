<?php

namespace Database\Seeders;

use App\Models\Nurse;
use App\Models\ServiceCategory;
use Illuminate\Database\Seeder;

class ServiceCategorySeeder extends Seeder
{
    /**
     * Seeds the lists the app previously hardcoded in Dart, plus whatever
     * specialties existing nurses already carry.
     */
    public function run(): void
    {
        $defaults = [
            'nursing' => [
                'فریاکەوتن و برین', 'چاودێری ماڵەوە', 'دەرزی و سیرەم',
                'چاودێری بەتەمەنان', 'چاودێری منداڵ', 'فیزیۆتێراپی',
            ],
            'lab' => [
                'شیکاری خوێن', 'هۆرمۆن', 'میکرۆب', 'ڤایرۆس', 'شەکرە', 'دڵ و سووڕی خوێن',
            ],
            'pharmacy' => [
                'دەرمانی گشتی', 'ڤیتامین و زیادکەر', 'جوانکاری', 'پێداویستی منداڵ', 'ئامێری پزیشکی',
            ],
            'first_aid' => [
                'هەناسەدان', 'پێست و برین', 'دڵ و سووڕی خوێن', 'ئێسک و شکان', 'ژەهراویبوون', 'گشتی',
            ],
            'xray' => [
                'تیشکی ئاسایی', 'سۆنار', 'CT Scan', 'MRI', 'ماموگرافی',
            ],
        ];

        foreach ($defaults as $scope => $names) {
            foreach ($names as $index => $name) {
                ServiceCategory::firstOrCreate(
                    ['scope' => $scope, 'name' => $name],
                    ['sort_order' => $index, 'is_active' => true]
                );
            }
        }

        // Doctor specialties come from the records that already exist.
        \App\Models\Doctor::query()
            ->whereNotNull('specialty')
            ->distinct()
            ->pluck('specialty')
            ->filter()
            ->values()
            ->each(fn ($name, $i) => ServiceCategory::firstOrCreate(
                ['scope' => 'doctor', 'name' => $name],
                ['sort_order' => $i, 'is_active' => true]
            ));

        // Same for nursing specialties that are already in use.
        Nurse::query()
            ->whereNotNull('specialty')
            ->distinct()
            ->pluck('specialty')
            ->filter()
            ->each(fn ($name) => ServiceCategory::firstOrCreate(
                ['scope' => 'nursing', 'name' => $name],
                ['sort_order' => 99, 'is_active' => true]
            ));
    }
}
