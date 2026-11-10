<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'assigned_driver_id')) {
                $table->foreignId('assigned_driver_id')->nullable()->after('assigned_lab_id')->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('orders', 'delivery_status')) {
                $table->string('delivery_status')->default('unassigned')->after('status');
            }
            if (!Schema::hasColumn('orders', 'driver_assigned_at')) {
                $table->timestamp('driver_assigned_at')->nullable()->after('delivery_status');
            }
            if (!Schema::hasColumn('orders', 'driver_picked_up_at')) {
                $table->timestamp('driver_picked_up_at')->nullable()->after('driver_assigned_at');
            }
            if (!Schema::hasColumn('orders', 'driver_delivered_at')) {
                $table->timestamp('driver_delivered_at')->nullable()->after('driver_picked_up_at');
            }
            if (!Schema::hasColumn('orders', 'delivery_fee')) {
                $table->decimal('delivery_fee', 10, 2)->default(0)->after('driver_delivered_at');
            }
            if (!Schema::hasColumn('orders', 'driver_notes')) {
                $table->text('driver_notes')->nullable()->after('delivery_fee');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'assigned_driver_id')) {
                $table->dropConstrainedForeignId('assigned_driver_id');
            }
            $columns = array_filter([
                Schema::hasColumn('orders', 'delivery_status') ? 'delivery_status' : null,
                Schema::hasColumn('orders', 'driver_assigned_at') ? 'driver_assigned_at' : null,
                Schema::hasColumn('orders', 'driver_picked_up_at') ? 'driver_picked_up_at' : null,
                Schema::hasColumn('orders', 'driver_delivered_at') ? 'driver_delivered_at' : null,
                Schema::hasColumn('orders', 'delivery_fee') ? 'delivery_fee' : null,
                Schema::hasColumn('orders', 'driver_notes') ? 'driver_notes' : null,
            ]);
            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
