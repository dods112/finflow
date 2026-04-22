@extends('layouts.app')
@section('title', 'Edit Transaction')

@section('content')
<div class="max-w-lg mx-auto">

    <div class="px-5 pt-12 pb-4 flex items-center gap-3">
        <a href="{{ route('transactions.index') }}"
           class="w-9 h-9 rounded-xl bg-gray-800 border border-gray-700 flex items-center justify-center hover:border-indigo-500 transition">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
            </svg>
        </a>
        <h1 class="text-lg font-bold text-white">Edit Transaction</h1>
    </div>

    <form method="POST" action="{{ route('transactions.update', $transaction) }}" class="px-4 space-y-4 pb-8">
        @csrf @method('PUT')

        @if($errors->any())
        <div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 space-y-1">
            @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
        </div>
        @endif

        <div class="bg-gray-800 rounded-xl p-1 flex gap-1 border border-gray-700">
            @foreach(['expense' => 'Expense', 'income' => 'Income'] as $val => $label)
            <label class="flex-1 relative">
                <input type="radio" name="type" value="{{ $val }}" class="sr-only peer"
                       {{ old('type', $transaction->type) === $val ? 'checked' : '' }}>
                <span class="block text-center py-2.5 rounded-lg text-sm font-semibold cursor-pointer transition
                             {{ $val === 'expense' ? 'peer-checked:bg-red-500' : 'peer-checked:bg-emerald-500' }}
                             peer-checked:text-white text-gray-600">
                    {{ $label }}
                </span>
            </label>
            @endforeach
        </div>

        <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 text-center">
            <p class="text-gray-700 text-xs uppercase tracking-widest mb-3">Amount</p>
            <div class="flex items-center justify-center gap-2">
                <span class="text-xl font-medium text-gray-600">{{ auth()->user()->currency }}</span>
                <input type="number" name="amount" value="{{ old('amount', $transaction->amount) }}"
                       step="0.01" min="0.01" required
                       class="text-4xl font-bold font-mono bg-transparent outline-none text-center w-48 text-white"/>
            </div>
        </div>

        <input type="text" name="description" value="{{ old('description', $transaction->description) }}"
               placeholder="Description (optional)"
               class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3.5 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-700 transition"/>

        <div class="grid grid-cols-2 gap-3">
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Account</label>
                <select name="account_id" required
                        class="w-full bg-gray-900 border border-gray-800 rounded-xl px-3 py-3 text-sm outline-none focus:border-indigo-500 text-white transition">
                    @foreach($accounts as $account)
                    <option value="{{ $account->id }}"
                            {{ old('account_id', $transaction->account_id) == $account->id ? 'selected' : '' }}>
                        {{ $account->name }}
                    </option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Category</label>
                <select name="category_id" required
                        class="w-full bg-gray-900 border border-gray-800 rounded-xl px-3 py-3 text-sm outline-none focus:border-indigo-500 text-white transition">
                    @foreach($categories as $cat)
                    <option value="{{ $cat->id }}"
                            {{ old('category_id', $transaction->category_id) == $cat->id ? 'selected' : '' }}>
                        {{ $cat->name }}
                    </option>
                    @endforeach
                </select>
            </div>
        </div>

        <div>
            <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Date</label>
            <input type="date" name="date" value="{{ old('date', $transaction->date->format('Y-m-d')) }}" required
                   class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white transition"/>
        </div>

        <button type="submit"
                class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-4 rounded-xl transition active:scale-95">
            Update Transaction
        </button>
    </form>

</div>
@endsection