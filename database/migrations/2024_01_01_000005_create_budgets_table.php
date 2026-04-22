<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('budgets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained();
            $table->decimal('limit_amount', 15, 2);
            $table->integer('month'); // 1-12
            $table->integer('year');
            $table->boolean('alert_sent')->default(false);
            $table->timestamps();

            $table->unique(['user_id', 'category_id', 'month', 'year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('budgets');
    }
};