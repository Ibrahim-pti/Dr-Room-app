<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('drivers')) {
            return;
        }

        Schema::table('drivers', function (Blueprint $table) {
            if (!Schema::hasColumn('drivers', 'earnings_reset_at')) {
                $table->timestamp('earnings_reset_at')->nullable()->after('total_earnings');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('drivers')) {
            return;
        }

        Schema::table('drivers', function (Blueprint $table) {
            if (Schema::hasColumn('drivers', 'earnings_reset_at')) {
                $table->dropColumn('earnings_reset_at');
            }
        });
    }
};
