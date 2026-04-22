<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TransferController;
use App\Http\Controllers\ReportController;
use Illuminate\Support\Facades\Route;

// Auth routes
Route::middleware('guest')->group(function () {
    Route::get('/login',            [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login',           [AuthController::class, 'login']);
    Route::get('/register',         [AuthController::class, 'showRegister'])->name('register');
    Route::post('/register',        [AuthController::class, 'register']);
});

Route::post('/logout', [AuthController::class, 'logout'])->name('logout')->middleware('auth');

// PWA Offline fallback (no auth needed)
Route::get('/offline', function () {
    return response()->file(public_path('offline.html'));
});

// Protected routes
Route::middleware('auth')->group(function () {
    // Dashboard
    Route::get('/',          [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Transactions
    Route::resource('transactions', TransactionController::class)->except(['show']);

    // Budgets
    Route::get('/budgets',              [BudgetController::class, 'index'])->name('budgets.index');
    Route::post('/budgets',             [BudgetController::class, 'store'])->name('budgets.store');
    Route::delete('/budgets/{budget}',  [BudgetController::class, 'destroy'])->name('budgets.destroy');

    // Accounts
    Route::get('/accounts',                         [AccountController::class, 'index'])->name('accounts.index');
    Route::post('/accounts',                        [AccountController::class, 'store'])->name('accounts.store');
    Route::put('/accounts/{account}',               [AccountController::class, 'update'])->name('accounts.update');
    Route::post('/accounts/{account}/set-default',  [AccountController::class, 'setDefault'])->name('accounts.setDefault');
    Route::delete('/accounts/{account}',            [AccountController::class, 'destroy'])->name('accounts.destroy');

    // AI Chat
    Route::get('/chat',             [ChatController::class, 'index'])->name('chat.index');
    Route::post('/chat/send',       [ChatController::class, 'send'])->name('chat.send');
    Route::delete('/chat/history',  [ChatController::class, 'clearHistory'])->name('chat.clear');

    // Profile
    Route::get('/profile',                  [ProfileController::class, 'index'])->name('profile.index');
    Route::put('/profile',                  [ProfileController::class, 'update'])->name('profile.update');
    Route::put('/profile/password',         [ProfileController::class, 'updatePassword'])->name('profile.password');
    Route::get('/profile/export/csv',       [ProfileController::class, 'exportCsv'])->name('profile.export.csv');
    Route::get('/profile/export/pdf',       [ProfileController::class, 'exportPdf'])->name('profile.export.pdf');

    // Transfers
    Route::get('/transfers',                    [TransferController::class, 'index'])->name('transfers.index');
    Route::post('/transfers',                   [TransferController::class, 'store'])->name('transfers.store');
    Route::delete('/transfers/{transfer}',      [TransferController::class, 'destroy'])->name('transfers.destroy');

    // Monthly Reports
    Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');
});
// ── Password Reset ────────────────────────────────────────────
Route::middleware('guest')->group(function () {
    Route::get('/forgot-password',        [App\Http\Controllers\PasswordResetController::class, 'showForgot'])->name('password.request');
    Route::post('/forgot-password',       [App\Http\Controllers\PasswordResetController::class, 'sendLink'])->name('password.email');
    Route::get('/reset-password/{token}', [App\Http\Controllers\PasswordResetController::class, 'showReset'])->name('password.reset');
    Route::post('/reset-password',        [App\Http\Controllers\PasswordResetController::class, 'reset'])->name('password.update');
});

// Onboarding
Route::get('/onboarding', function () {
    return view('onboarding.index');
})->name('onboarding')->middleware('auth');

// Dark mode sync
Route::post('/profile/dark-mode', [App\Http\Controllers\ProfileController::class, 'toggleDarkMode'])->name('profile.darkmode')->middleware('auth');

// Report export
Route::get('/reports/export', [App\Http\Controllers\ReportController::class, 'exportCsv'])->name('reports.export')->middleware('auth');

// Recurring Transactions
Route::middleware('auth')->group(function () {
    Route::get('/recurring',                        [App\Http\Controllers\RecurringController::class, 'index'])->name('recurring.index');
    Route::post('/recurring',                       [App\Http\Controllers\RecurringController::class, 'store'])->name('recurring.store');
    Route::post('/recurring/{recurring}/process',   [App\Http\Controllers\RecurringController::class, 'process'])->name('recurring.process');
    Route::post('/recurring/{recurring}/toggle',    [App\Http\Controllers\RecurringController::class, 'toggle'])->name('recurring.toggle');
    Route::delete('/recurring/{recurring}',         [App\Http\Controllers\RecurringController::class, 'destroy'])->name('recurring.destroy');
});
