<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Barryvdh\DomPDF\Facade\Pdf;
use League\Csv\Writer;

class ProfileController extends Controller
{
    public function index()
    {
        $user  = Auth::user();
        $stats = [
            'total_transactions' => Transaction::forUser($user->id)->count(),
            'total_income'       => Transaction::forUser($user->id)->where('type', 'income')->sum('amount'),
            'total_expenses'     => Transaction::forUser($user->id)->where('type', 'expense')->sum('amount'),
            'accounts_count'     => $user->accounts()->count(),
        ];
        return view('profile.index', compact('user', 'stats'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();
        $data = $request->validate([
            'name'      => ['required', 'string', 'max:255'],
            'currency'  => ['required', 'string', 'size:3'],
            'dark_mode' => ['nullable', 'boolean'],
        ]);

        $user->update($data);
        return redirect(route('profile.index'))->with('success', 'Profile updated!');
    }

    public function updatePassword(Request $request)
    {
        $request->validate([
            'current_password' => ['required'],
            'password'         => ['required', Password::defaults(), 'confirmed'],
        ]);

        $user = Auth::user();

        if (!Hash::check($request->current_password, $user->password)) {
            return back()->withErrors(['current_password' => 'Incorrect current password.']);
        }

        $user->update(['password' => Hash::make($request->password)]);
        return back()->with('success', 'Password changed!');
    }

    public function exportCsv()
    {
        $user         = Auth::user();
        $transactions = Transaction::forUser($user->id)
            ->with(['category', 'account'])
            ->orderByDesc('date')
            ->get();

        $csv = Writer::createFromString('');
        $csv->insertOne(['Date', 'Account', 'Category', 'Type', 'Amount', 'Description']);

        foreach ($transactions as $t) {
            $csv->insertOne([
                $t->date->format('Y-m-d'),
                $t->account->name,
                $t->category->name,
                $t->type,
                $t->amount,
                $t->description,
            ]);
        }

        return response($csv->toString(), 200, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => 'attachment; filename="finflow-transactions.csv"',
        ]);
    }

    public function exportPdf()
    {
        $user         = Auth::user();
        $transactions = Transaction::forUser($user->id)
            ->with(['category', 'account'])
            ->orderByDesc('date')
            ->limit(100)
            ->get();

        $totalIncome  = Transaction::forUser($user->id)->where('type', 'income')->sum('amount');
        $totalExpense = Transaction::forUser($user->id)->where('type', 'expense')->sum('amount');

        $pdf = Pdf::loadView('exports.transactions-pdf', compact('user', 'transactions', 'totalIncome', 'totalExpense'));

        return $pdf->download('finflow-report.pdf');
    }

    public function toggleDarkMode()
    {
        $user = Auth::user();
        $user->update(['dark_mode' => ! $user->dark_mode]);
        return response()->json(['dark_mode' => $user->dark_mode]);
    }


}
