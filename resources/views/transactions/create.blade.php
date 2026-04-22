@extends('layouts.app')
@section('title', 'Add Transaction')

@section('content')
<div class="max-w-lg mx-auto lg:max-w-2xl">

    <div class="px-4 sm:px-6 pt-10 pb-4 flex items-center gap-3">
        <a href="{{ route('dashboard') }}"
           class="w-9 h-9 rounded-xl bg-gray-800 border border-gray-700 flex items-center justify-center hover:border-indigo-500 transition">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
            </svg>
        </a>
        <h1 class="text-lg font-bold text-white">Add Transaction</h1>
    </div>

    <form method="POST" action="{{ route('transactions.store') }}" id="txForm"
          class="px-4 sm:px-6 space-y-4 pb-8">
        @csrf

        @if($errors->any())
        <div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 space-y-1">
            @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
        </div>
        @endif

        {{-- Type Toggle --}}
        <div class="bg-gray-800 rounded-xl p-1 flex gap-1 border border-gray-700">
            <label class="flex-1 relative">
                <input type="radio" name="type" value="expense" class="sr-only peer"
                       {{ old('type', 'expense') === 'expense' ? 'checked' : '' }}>
                <span class="block text-center py-2.5 rounded-lg text-sm font-semibold cursor-pointer transition
                             peer-checked:bg-red-500 peer-checked:text-white text-gray-600">Expense</span>
            </label>
            <label class="flex-1 relative">
                <input type="radio" name="type" value="income" class="sr-only peer"
                       {{ old('type') === 'income' ? 'checked' : '' }}>
                <span class="block text-center py-2.5 rounded-lg text-sm font-semibold cursor-pointer transition
                             peer-checked:bg-emerald-500 peer-checked:text-white text-gray-600">Income</span>
            </label>
        </div>

        {{-- Amount --}}
        <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 text-center">
            <p class="text-gray-700 text-xs uppercase tracking-widest mb-3">Amount</p>
            <div class="flex items-center justify-center gap-2">
                <span class="text-xl font-medium text-gray-600">{{ auth()->user()->currency }}</span>
                <input type="number" name="amount" value="{{ old('amount') }}"
                       step="0.01" min="0.01" placeholder="0.00" required
                       class="text-4xl font-bold font-mono bg-transparent outline-none text-center w-48 text-white placeholder-gray-700"/>
            </div>
        </div>

        {{-- Description --}}
        <input type="text" name="description" value="{{ old('description') }}"
               placeholder="Description (optional)"
               class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3.5 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-700 transition"/>

        {{-- Account & Category --}}
        <div class="grid grid-cols-2 gap-3">
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Account</label>
                <select name="account_id" required
                        class="w-full bg-gray-900 border border-gray-800 rounded-xl px-3 py-3 text-sm outline-none focus:border-indigo-500 text-white transition">
                    @foreach($accounts as $account)
                    <option value="{{ $account->id }}"
                            {{ old('account_id') == $account->id || $account->is_default ? 'selected' : '' }}>
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
                    <option value="{{ $cat->id }}" {{ old('category_id') == $cat->id ? 'selected' : '' }}>
                        {{ $cat->name }}
                    </option>
                    @endforeach
                </select>
            </div>
        </div>

        {{-- Date --}}
        <div>
            <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Date</label>
            <input type="date" name="date" value="{{ old('date', now()->format('Y-m-d')) }}" required
                   class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white transition"/>
        </div>

        {{-- Notes --}}
        <textarea name="notes" placeholder="Notes (optional)" rows="2"
                  class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-700 resize-none transition">{{ old('notes') }}</textarea>

        {{-- Submit with loading state --}}
        <button type="submit" id="submitBtn"
                class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-4 rounded-xl transition active:scale-95 flex items-center justify-center gap-2">
            <span id="btnText">Save Transaction</span>
            <svg id="btnSpinner" class="hidden w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
            </svg>
        </button>
    </form>
</div>
@endsection

@push('scripts')
<script>
document.getElementById('txForm').addEventListener('submit', function(e) {
    const btn     = document.getElementById('submitBtn');
    const text    = document.getElementById('btnText');
    const spinner = document.getElementById('btnSpinner');
    btn.disabled  = true;
    btn.classList.add('opacity-75');
    text.textContent = 'Saving...';
    spinner.classList.remove('hidden');
});
</script>
@endpush
