<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('articles', function (Blueprint $table) {
            $table->string('category')->nullable()->after('title');
            $table->string('category_en')->nullable()->after('category');
            $table->string('category_ar')->nullable()->after('category_en');
            $table->text('short_desc')->nullable()->after('category_ar');
            $table->text('short_desc_en')->nullable()->after('short_desc');
            $table->text('short_desc_ar')->nullable()->after('short_desc_en');
            $table->json('symptoms')->nullable()->after('content');
            $table->json('steps')->nullable()->after('symptoms');
            $table->json('dos')->nullable()->after('steps');
            $table->json('donts')->nullable()->after('dos');
            $table->text('when_to_call_ambulance')->nullable()->after('donts');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('articles', function (Blueprint $table) {
            $table->dropColumn([
                'category', 'category_en', 'category_ar',
                'short_desc', 'short_desc_en', 'short_desc_ar',
                'symptoms', 'steps', 'dos', 'donts', 'when_to_call_ambulance'
            ]);
        });
    }
};
