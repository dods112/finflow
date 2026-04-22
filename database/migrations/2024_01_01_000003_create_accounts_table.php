<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->enum('account_type', ['cash', 'bank', 'e_wallet', 'credit_card', 'savings'])->default('bank');
            $table->decimal('balance', 15, 2)->default(0);
            $table->string('currency', 3)->default('USD');
            $table->string('color', 7)->default('#6366f1');
            $table->string('icon')->default('🏦');
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('accounts');
    }
};