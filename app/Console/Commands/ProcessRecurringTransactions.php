<?php

namespace App\Console\Commands;

use App\Models\RecurringTransaction;
use App\Models\Transaction;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessRecurringTransactions extends Command
{
    protected $signature   = 'finflow:process-recurring
                                {--dry-run : Show what would be processed without actually doing it}';

    protected $description = 'Process all due recurring transactions automatically';

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');

        $due = RecurringTransaction::with(['account', 'category', 'user'])
            ->where('is_active', true)
            ->where('next_due', '<=', now()->toDateString())
            ->where(function ($q) {
                $q->whereNull('end_date')
                  ->orWhere('end_date', '>=', now()->toDateString());
            })
            ->get();

        if ($due->isEmpty()) {
            $this->info('No recurring transactions due today.');
            return self::SUCCESS;
        }

        $this->info("Found {$due->count()} recurring transaction(s) to process.");

        $processed = 0;
        $failed    = 0;

        foreach ($due as $recurring) {
            $label = "[#{$recurring->id}] {$recurring->description} — {$recurring->user->name}";

            if ($dryRun) {
                $this->line("  DRY-RUN: Would process {$label}");
                continue;
            }

            try {
                DB::transaction(function () use ($recurring) {
                    Transaction::create([
                        'account_id'  => $recurring->account_id,
                        'category_id' => $recurring->category_id,
                        'amount'      => $recurring->amount,
                        'type'        => $recurring->type,
                        'description' => ($recurring->description ?? $recurring->category->name) . ' (Auto)',
                        'date'        => now()->toDateString(),
                    ]);

                    $account = $recurring->account;
                    if ($recurring->type === 'income') {
                        $account->increment('balance', $recurring->amount);
                    } else {
                        $account->decrement('balance', $recurring->amount);
                    }

                    $recurring->advanceNextDue();
                });

                $this->line("  <fg=green>✔</> Processed {$label}");
                $processed++;

            } catch (\Throwable $e) {
                Log::error("Failed to process recurring #{$recurring->id}: " . $e->getMessage());
                $this->line("  <fg=red>✘</> Failed {$label}: {$e->getMessage()}");
                $failed++;
            }
        }

        $this->newLine();
        $this->info("Done. Processed: {$processed} | Failed: {$failed}");

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }
}
