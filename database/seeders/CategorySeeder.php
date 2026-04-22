<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            // Expense categories
            ['name' => 'Food & Dining',     'icon' => '🍔', 'color' => '#f59e0b', 'type' => 'expense'],
            ['name' => 'Groceries',         'icon' => '🛒', 'color' => '#10b981', 'type' => 'expense'],
            ['name' => 'Transportation',    'icon' => '🚗', 'color' => '#3b82f6', 'type' => 'expense'],
            ['name' => 'Shopping',          'icon' => '🛍️', 'color' => '#ec4899', 'type' => 'expense'],
            ['name' => 'Entertainment',     'icon' => '🎬', 'color' => '#8b5cf6', 'type' => 'expense'],
            ['name' => 'Bills & Utilities', 'icon' => '⚡', 'color' => '#f97316', 'type' => 'expense'],
            ['name' => 'Healthcare',        'icon' => '🏥', 'color' => '#ef4444', 'type' => 'expense'],
            ['name' => 'Education',         'icon' => '📚', 'color' => '#0ea5e9', 'type' => 'expense'],
            ['name' => 'Housing / Rent',    'icon' => '🏠', 'color' => '#64748b', 'type' => 'expense'],
            ['name' => 'Subscriptions',     'icon' => '📱', 'color' => '#6366f1', 'type' => 'expense'],
            ['name' => 'Travel',            'icon' => '✈️', 'color' => '#06b6d4', 'type' => 'expense'],
            ['name' => 'Personal Care',     'icon' => '💄', 'color' => '#d946ef', 'type' => 'expense'],
            ['name' => 'Other Expense',     'icon' => '💸', 'color' => '#94a3b8', 'type' => 'expense'],

            // Income categories
            ['name' => 'Salary',            'icon' => '💼', 'color' => '#10b981', 'type' => 'income'],
            ['name' => 'Freelance',         'icon' => '💻', 'color' => '#3b82f6', 'type' => 'income'],
            ['name' => 'Business',          'icon' => '🏢', 'color' => '#f59e0b', 'type' => 'income'],
            ['name' => 'Investment',        'icon' => '📈', 'color' => '#6366f1', 'type' => 'income'],
            ['name' => 'Gift / Bonus',      'icon' => '🎁', 'color' => '#ec4899', 'type' => 'income'],
            ['name' => 'Other Income',      'icon' => '💰', 'color' => '#94a3b8', 'type' => 'income'],
        ];

        foreach ($categories as $cat) {
            Category::firstOrCreate(['name' => $cat['name']], $cat);
        }
    }
}