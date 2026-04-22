<?php

namespace App\Http\Controllers;

use App\Models\Budget;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BudgetController extends Controller
{
    public function index()
    {
        $user    = Auth::user();
        $month   = request('month', now()->month);
        $year    = request('year', now()->year);

        $budgets = Budget::where('user_id', $user->id)
            ->where('month', $month)
            ->where('year', $year)
            ->with('category')
            ->get();

        $categories = Category::where('type', '!=', 'income')->get();

        // Monthly total spent vs budgeted
        $totalBudgeted = $budgets->sum('limit_amount');
        $totalSpent    = $budgets->sum(fn($b) => $b->spent);

        return view('budgets.index', compact('budgets', 'categories', 'totalBudgeted', 'totalSpent', 'month', 'year'));
    }

    public function store(Request $request)
    {
        $user = Auth::user();

        $data = $request->validate([
            'category_id'  => ['required', 'exists:categories,id'],
            'limit_amount' => ['required', 'numeric', 'min:1'],
            'month'        => ['required', 'integer', 'between:1,12'],
            'year'         => ['required', 'integer', 'min:2020'],
        ]);

        Budget::updateOrCreate(
            [
                'user_id'     => $user->id,
                'category_id' => $data['category_id'],
                'month'       => $data['month'],
                'year'        => $data['year'],
            ],
            [
                'limit_amount' => $data['limit_amount'],
                'alert_sent'   => false,
            ]
        );

        return redirect(route('budgets.index'))->with('success', 'Budget saved!');
    }

    public function destroy(Budget $budget)
    {
        if ($budget->user_id !== Auth::id()) abort(403);
        $budget->delete();
        return redirect(route('budgets.index'))->with('success', 'Budget removed.');
    }
}