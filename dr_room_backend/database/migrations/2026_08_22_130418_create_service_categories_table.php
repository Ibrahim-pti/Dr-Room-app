<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * One table for every kind of category the app filters by — nursing
     * specialties, lab test groups, pharmacy sections, doctor specialties,
     * first-aid topics. `scope` says which list a row belongs to, so adding a
     * new nursing category never needs an app rebuild.
     */
    public function up(): void
    {
        Schema::create('service_categories', function (Blueprint $table) {
            $table->id();
            $table->string('scope')->index();   // nursing | lab | pharmacy | doctor | first_aid | xray
            $table->string('name');
            $table->string('name_en')->nullable();
            $table->string('name_ar')->nullable();
            $table->string('slug')->nullable();
            $table->string('icon')->nullable();      // material/iconsax code point name
            $table->string('color', 9)->nullable();  // #RRGGBB
            $table->string('image_path')->nullable();
            $table->text('description')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['scope', 'name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_categories');
    }
};
