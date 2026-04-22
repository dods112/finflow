<?php

namespace App\Http\Controllers;

use App\Models\Account;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AccountController extends Controller
{
    public function index()
    {
        $accounts = Auth::user()->accounts()->withCount('transactions')->get();
        return view('accounts.index', compact('accounts'));
    }

    public function store(Request $request)
    {
        $user = Auth::user();

        $data = $request->validate([
            'name'         => ['required', 'string', 'max:100'],
            'account_type' => ['required', 'in:cash,bank,e_wallet,credit_card,savings'],
            'balance'      => ['required', 'numeric'],
            'color'        => ['nullable', 'string', 'max:7'],
            'icon'         => ['nullable', 'string', 'max:10'],
        ]);

        $data['user_id'] = $user->id;

        // If first account, make it default
        if ($user->accounts()->count() === 0) {
            $data['is_default'] = true;
        }

        Account::create($data);

        return redirect(route('accounts.index'))->with('success', 'Account created!');
    }

    public function update(Request $request, Account $account)
    {
        if ($account->user_id !== Auth::id()) abort(403);

        $data = $request->validate([
            'name'         => ['required', 'string', 'max:100'],
            'account_type' => ['required', 'in:cash,bank,e_wallet,credit_card,savings'],
            'color'        => ['nullable', 'string', 'max:7'],
            'icon'         => ['nullable', 'string', 'max:10'],
        ]);

        $account->update($data);

        return redirect(route('accounts.index'))->with('success', 'Account updated!');
    }

    public function setDefault(Account $account)
    {
        if ($account->user_id !== Auth::id()) abort(403);

        Auth::user()->accounts()->update(['is_default' => false]);
        $account->update(['is_default' => true]);

        return redirect(route('accounts.index'))->with('success', 'Default account updated.');
    }

    public function destroy(Account $account)
    {
        if ($account->user_id !== Auth::id()) abort(403);

        if ($account->transactions()->count() > 0) {
            return redirect(route('accounts.index'))
                ->with('error', 'Cannot delete account with transactions.');
        }

        $account->delete();
        return redirect(route('accounts.index'))->with('success', 'Account deleted.');
    }
}