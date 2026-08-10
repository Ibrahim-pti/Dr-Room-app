<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('users')->onDelete('cascade');
            $table->string('service_type'); // lab, pharmacy, nursing
            $table->decimal('subtotal', 10, 2)->default(0);
            $table->decimal('extra_fee', 10, 2)->default(0);
            $table->decimal('total_price', 10, 2)->default(0);
            $table->string('status')->default('pending'); // pending, accepted, completed, cancelled
            $table->string('payment_method')->default('Cash on Delivery');
            $table->text('patient_details')->nullable(); // JSON of name, phone, age, gender etc.
            $table->text('location_details')->nullable(); // Address/LatLng string
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
