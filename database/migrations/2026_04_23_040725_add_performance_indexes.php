<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            // Speed up dashboard/report queries dramatically
            $table->index(['account_id', 'type', 'date'], 'tx_account_type_date');
            $table->index('date', 'tx_date');
            $table->index('category_id', 'tx_category');
        });

        Schema::table('budgets', function (Blueprint $table) {
            $table->index(['user_id', 'month', 'year'], 'budgets_user_month_year');
        });

        Schema::table('chat_logs', function (Blueprint $table) {
            $table->index(['user_id', 'created_at'], 'chat_logs_user_created');
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropIndex('tx_account_type_date');
            $table->dropIndex('tx_date');
            $table->dropIndex('tx_category');
        });

        Schema::table('budgets', function (Blueprint $table) {
            $table->dropIndex('budgets_user_month_year');
        });

        Schema::table('chat_logs', function (Blueprint $table) {
            $table->dropIndex('chat_logs_user_created');
        });
    }
};
