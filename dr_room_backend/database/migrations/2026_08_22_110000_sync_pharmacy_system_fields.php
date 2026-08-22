<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Alter pharmacies table
        Schema::table('pharmacies', function (Blueprint $table) {
            if (!Schema::hasColumn('pharmacies', 'delivery_fee')) {
                $table->decimal('delivery_fee', 10, 2)->default(3000)->after('location');
            }
            if (!Schema::hasColumn('pharmacies', 'delivery_time')) {
                $table->string('delivery_time')->default('۲۰-۳۰ خولەک')->after('delivery_fee');
            }
            if (!Schema::hasColumn('pharmacies', 'city')) {
                $table->string('city')->default('هەولێر')->after('delivery_time');
            }
            if (!Schema::hasColumn('pharmacies', 'facebook_url')) {
                $table->string('facebook_url')->nullable()->after('city');
            }
            if (!Schema::hasColumn('pharmacies', 'latitude')) {
                $table->decimal('latitude', 10, 7)->nullable()->after('facebook_url');
            }
            if (!Schema::hasColumn('pharmacies', 'longitude')) {
                $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            }
            if (!Schema::hasColumn('pharmacies', 'is_open')) {
                $table->boolean('is_open')->default(true)->after('longitude');
            }
            if (!Schema::hasColumn('pharmacies', 'gallery_images')) {
                $table->json('gallery_images')->nullable()->after('is_open');
            }
        });

        // 2. Alter medications table
        Schema::table('medications', function (Blueprint $table) {
            if (!Schema::hasColumn('medications', 'category')) {
                $table->string('category')->nullable()->after('name');
            }
            if (!Schema::hasColumn('medications', 'original_price')) {
                $table->decimal('original_price', 10, 2)->nullable()->after('price');
            }
            if (!Schema::hasColumn('medications', 'discount_percent')) {
                $table->integer('discount_percent')->nullable()->after('original_price');
            }
            if (!Schema::hasColumn('medications', 'badge')) {
                $table->string('badge')->nullable()->after('discount_percent');
            }
            if (!Schema::hasColumn('medications', 'dosage_form')) {
                $table->string('dosage_form')->default('پاکەت')->after('badge');
            }
            if (!Schema::hasColumn('medications', 'requires_prescription')) {
                $table->boolean('requires_prescription')->default(false)->after('dosage_form');
            }
        });

        // 3. Alter pharmacy_offers table
        Schema::table('pharmacy_offers', function (Blueprint $table) {
            if (!Schema::hasColumn('pharmacy_offers', 'promo_code')) {
                $table->string('promo_code')->nullable()->after('title');
            }
        });

        // 4. Create pharmacy_reviews table
        if (!Schema::hasTable('pharmacy_reviews')) {
            Schema::create('pharmacy_reviews', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->foreignId('pharmacy_id')->constrained('users')->cascadeOnDelete();
                $table->decimal('rating', 2, 1)->default(5.0);
                $table->text('comment')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::table('pharmacies', function (Blueprint $table) {
            $table->dropColumn([
                'delivery_fee', 'delivery_time', 'city', 'facebook_url',
                'latitude', 'longitude', 'is_open', 'gallery_images'
            ]);
        });

        Schema::table('medications', function (Blueprint $table) {
            $table->dropColumn([
                'category', 'original_price', 'discount_percent',
                'badge', 'dosage_form', 'requires_prescription'
            ]);
        });

        Schema::table('pharmacy_offers', function (Blueprint $table) {
            $table->dropColumn(['promo_code']);
        });

        Schema::dropIfExists('pharmacy_reviews');
    }
};
