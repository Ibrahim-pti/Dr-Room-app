<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'estimated_duration_minutes')) {
                $table->unsignedInteger('estimated_duration_minutes')->nullable()->after('status');
            }
            if (!Schema::hasColumn('orders', 'estimated_ready_at')) {
                $table->timestamp('estimated_ready_at')->nullable()->after('estimated_duration_minutes');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'estimated_ready_at')) {
                $table->dropColumn('estimated_ready_at');
            }
            if (Schema::hasColumn('orders', 'estimated_duration_minutes')) {
                $table->dropColumn('estimated_duration_minutes');
            }
        });
    }
};
