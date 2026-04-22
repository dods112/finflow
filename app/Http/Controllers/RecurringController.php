<?php

namespace App\Http\Controllers;

use App\Models\RecurringTransaction;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class RecurringController extends Controller
{
    public function index()
    {
        $recurring  = RecurringTransaction::where('user_id', Auth::id())
            ->with(['account', 'category'])
            ->orderBy('next_due')
            ->get();
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();

        return view('recurring.index', compact('recurring', 'categories', 'accounts'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'frequency'   => ['required', 'in:daily,weekly,monthly,yearly'],
            'start_date'  => ['required', 'date'],
            'end_date'    => ['nullable', 'date', 'after:start_date'],
        ]);

        $data['user_id']  = Auth::id();
        $data['next_due'] = $data['start_date'];

        RecurringTransaction::create($data);

        return redirect(route('recurring.index'))->with('success', 'Recurring transaction created!');
    }

    public function process(RecurringTransaction $recurring)
    {
        if ($recurring->user_id !== Auth::id()) abort(403);

        DB::transaction(function () use ($recurring) {
            Transaction::create([
                'account_id'  => $recurring->account_id,
                'category_id' => $recurring->category_id,
                'amount'      => $recurring->amount,
                'type'        => $recurring->type,
                'description' => $recurring->description . ' (Recurring)',
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

        return back()->with('success', 'Recurring transaction applied!');
    }

    public function destroy(RecurringTransaction $recurring)
    {
        if ($recurring->user_id !== Auth::id()) abort(403);
        $recurring->delete();
        return back()->with('success', 'Recurring transaction removed.');
    }

    public function toggle(RecurringTransaction $recurring)
    {
        if ($recurring->user_id !== Auth::id()) abort(403);
        $recurring->update(['is_active' => !$recurring->is_active]);
        return back()->with('success', $recurring->is_active ? 'Activated.' : 'Paused.');
    }
}
