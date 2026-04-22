<?php

namespace App\Http\Controllers;

use App\Models\Account;
use App\Models\Transfer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransferController extends Controller
{
    public function index(Request $request)
    {
        $query = Transfer::with(['fromAccount', 'toAccount'])
            ->where('user_id', auth()->id())
            ->orderByDesc('transfer_date')
            ->orderByDesc('created_at');

        // Search filter
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('note', 'LIKE', "%{$search}%")
                  ->orWhereHas('fromAccount', fn($q2) => $q2->where('name', 'LIKE', "%{$search}%"))
                  ->orWhereHas('toAccount',   fn($q2) => $q2->where('name', 'LIKE', "%{$search}%"));
            });
        }

        // Date filter
        if ($request->filled('date_from')) {
            $query->whereDate('transfer_date', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('transfer_date', '<=', $request->date_to);
        }

        $transfers = $query->paginate(15)->withQueryString();
        $accounts  = Account::where('user_id', auth()->id())->orderBy('name')->get();

        return view('transfers.index', compact('transfers', 'accounts'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'from_account_id' => ['required', 'exists:accounts,id'],
            'to_account_id'   => ['required', 'exists:accounts,id', 'different:from_account_id'],
            'amount'          => ['required', 'numeric', 'min:0.01'],
            'note'            => ['nullable', 'string', 'max:255'],
            'transfer_date'   => ['required', 'date'],
        ]);

        $fromAccount = Account::where('id', $validated['from_account_id'])
            ->where('user_id', auth()->id())->firstOrFail();
        $toAccount   = Account::where('id', $validated['to_account_id'])
            ->where('user_id', auth()->id())->firstOrFail();

        if ($fromAccount->balance < $validated['amount']) {
            return back()->withInput()
                ->withErrors(['amount' => 'Insufficient balance in the source account.']);
        }

        DB::transaction(function () use ($validated, $fromAccount, $toAccount) {
            $fromAccount->decrement('balance', $validated['amount']);
            $toAccount->increment('balance', $validated['amount']);
            Transfer::create([
                'user_id'         => auth()->id(),
                'from_account_id' => $fromAccount->id,
                'to_account_id'   => $toAccount->id,
                'amount'          => $validated['amount'],
                'note'            => $validated['note'] ?? null,
                'transfer_date'   => $validated['transfer_date'],
            ]);
        });

        return redirect()->route('transfers.index')->with('success', 'Transfer completed!');
    }

    public function destroy(Transfer $transfer)
    {
        abort_if($transfer->user_id !== auth()->id(), 403);

        DB::transaction(function () use ($transfer) {
            $transfer->fromAccount->increment('balance', $transfer->amount);
            $transfer->toAccount->decrement('balance', $transfer->amount);
            $transfer->delete();
        });

        return back()->with('success', 'Transfer reversed and deleted.');
    }
}
