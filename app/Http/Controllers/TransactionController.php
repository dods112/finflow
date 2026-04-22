<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTransactionRequest;
use App\Http\Requests\UpdateTransactionRequest;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Services\TransactionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TransactionController extends Controller
{
    public function __construct(private TransactionService $txService) {}

    public function index(Request $request)
    {
        $user  = Auth::user();
        $query = Transaction::forUser($user->id)->with(['category', 'account']);

        if ($request->filled('type'))        $query->where('type', $request->type);
        if ($request->filled('category_id')) $query->where('category_id', $request->category_id);
        if ($request->filled('account_id'))  $query->whereHas('account', fn($q) => $q->where('id', $request->account_id)->where('user_id', $user->id));
        if ($request->filled('date_from'))   $query->whereDate('date', '>=', $request->date_from);
        if ($request->filled('date_to'))     $query->whereDate('date', '<=', $request->date_to);
        if ($request->filled('search'))      $query->where('description', 'LIKE', '%' . $request->search . '%');

        $transactions = $query->orderByDesc('date')->orderByDesc('id')->paginate(15)->withQueryString();
        $categories   = Category::all();
        $accounts     = $user->accounts()->get();

        return view('transactions.index', compact('transactions', 'categories', 'accounts'));
    }

    public function create()
    {
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();
        return view('transactions.create', compact('categories', 'accounts'));
    }

    public function store(StoreTransactionRequest $request)
    {
        $user    = Auth::user();
        $data    = $request->validated();

        $account = Account::where('id', $data['account_id'])
            ->where('user_id', $user->id)
            ->firstOrFail();

        try {
            $transaction = $this->txService->create($data, $account);
        } catch (\RuntimeException $e) {
            if ($request->wantsJson()) {
                return response()->json(['success' => false, 'error' => $e->getMessage()], 422);
            }
            return back()->withInput()->withErrors(['amount' => $e->getMessage()]);
        }

        $this->txService->checkBudgetAlert($user->id, $data['category_id'], $data['type']);

        if ($request->wantsJson()) {
            return response()->json(['success' => true, 'transaction' => $transaction->load('category', 'account')]);
        }

        return redirect(route('dashboard'))->with('success', 'Transaction added!');
    }

    public function edit(Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();
        return view('transactions.edit', compact('transaction', 'categories', 'accounts'));
    }

    public function update(UpdateTransactionRequest $request, Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $data = $request->validated();

        $newAccount = Account::where('id', $data['account_id'])
            ->where('user_id', Auth::id())
            ->firstOrFail();

        $this->txService->update($transaction, $data, $newAccount);

        return redirect(route('transactions.index'))->with('success', 'Transaction updated!');
    }

    public function destroy(Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $this->txService->delete($transaction);
        return redirect(route('transactions.index'))->with('success', 'Transaction deleted.');
    }

    private function authorizeTransaction(Transaction $transaction): void
    {
        if ($transaction->account->user_id !== Auth::id()) abort(403);
    }
}
