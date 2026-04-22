@extends('layouts.app')

@section('title', 'Transfers')

@section('content')
<div class="min-h-screen bg-gray-950 pb-28">

    {{-- Header --}}
    <div class="sticky top-0 z-30 bg-gray-950/90 backdrop-blur border-b border-gray-800 px-4 py-4">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-lg font-bold text-white">Transfers</h1>
                <p class="text-xs text-gray-400">Move funds between accounts</p>
            </div>
            <button onclick="document.getElementById('transferModal').classList.remove('hidden')"
                class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                New Transfer
            </button>
        </div>
    </div>

    <div class="px-4 py-4 space-y-4">

        {{-- Flash messages --}}
        @if(session('success'))
        <div class="bg-green-500/10 border border-green-500/30 text-green-400 text-sm rounded-xl px-4 py-3 flex items-center gap-2">
            <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
            {{ session('success') }}
        </div>
        @endif

        @if($errors->any())
        <div class="bg-red-500/10 border border-red-500/30 text-red-400 text-sm rounded-xl px-4 py-3">
            @foreach($errors->all() as $error)
                <p>{{ $error }}</p>
            @endforeach
        </div>
        @endif

        {{-- Account Balances Summary --}}
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3">Your Accounts</p>
            <div class="space-y-2">
                @foreach($accounts as $account)
                <div class="flex items-center justify-between py-2 border-b border-gray-800 last:border-0">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded-full bg-indigo-600/20 flex items-center justify-center">
                            @if($account->type === 'cash')
                            <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2z"/>
                            </svg>
                            @elseif($account->type === 'bank')
                            <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z"/>
                            </svg>
                            @elseif($account->type === 'credit_card')
                            <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                            </svg>
                            @else
                            <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                            </svg>
                            @endif
                        </div>
                        <div>
                            <p class="text-sm font-medium text-white">{{ $account->name }}</p>
                            <p class="text-xs text-gray-500 capitalize">{{ str_replace('_', ' ', $account->type) }}</p>
                        </div>
                    </div>
                    <p class="text-sm font-semibold {{ $account->balance < 0 ? 'text-red-400' : 'text-white' }}">
                        {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($account->balance, 2) }}
                    </p>
                </div>
                @endforeach
            </div>
        </div>

        {{-- Transfer History --}}
        <div>
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3">Transfer History</p>

            @if($transfers->isEmpty())
            <div class="bg-gray-900 rounded-2xl border border-gray-800 p-8 text-center">
                <div class="w-12 h-12 bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-3">
                    <svg class="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
                    </svg>
                </div>
                <p class="text-gray-400 text-sm font-medium">No transfers yet</p>
                <p class="text-gray-600 text-xs mt-1">Create your first transfer above</p>
            </div>
            @else
            <div class="space-y-3">
                @foreach($transfers as $transfer)
                <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
                    <div class="flex items-start justify-between gap-3">
                        <div class="flex items-center gap-3 flex-1 min-w-0">
                            <div class="w-10 h-10 rounded-full bg-indigo-600/20 flex items-center justify-center shrink-0">
                                <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
                                </svg>
                            </div>
                            <div class="min-w-0">
                                <div class="flex items-center gap-2 flex-wrap">
                                    <span class="text-sm font-medium text-white truncate">{{ $transfer->fromAccount->name }}</span>
                                    <svg class="w-3 h-3 text-indigo-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"/>
                                    </svg>
                                    <span class="text-sm font-medium text-white truncate">{{ $transfer->toAccount->name }}</span>
                                </div>
                                @if($transfer->note)
                                <p class="text-xs text-gray-500 mt-0.5 truncate">{{ $transfer->note }}</p>
                                @endif
                                <p class="text-xs text-gray-600 mt-0.5">{{ $transfer->transfer_date->format('M d, Y') }}</p>
                            </div>
                        </div>
                        <div class="flex items-center gap-3 shrink-0">
                            <p class="text-sm font-bold text-indigo-400">
                                {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($transfer->amount, 2) }}
                            </p>
                            <form method="POST" action="{{ route('transfers.destroy', $transfer) }}"
                                onsubmit="return confirm('Reverse and delete this transfer?')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="text-gray-600 hover:text-red-400 transition-colors">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                    </svg>
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
                @endforeach
            </div>

            {{-- Pagination --}}
            @if($transfers->hasPages())
            <div class="mt-4">
                @include('partials.pagination', ['paginator' => $transfers])
            </div>
            @endif
            @endif
        </div>

    </div>
</div>

{{-- New Transfer Modal --}}
<div id="transferModal" class="hidden fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-end justify-center">
    <div class="bg-gray-900 border border-gray-800 rounded-t-3xl w-full max-w-lg p-6 pb-10 animate-slide-up">

        <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg font-bold text-white">New Transfer</h2>
            <button onclick="document.getElementById('transferModal').classList.add('hidden')"
                class="text-gray-500 hover:text-white transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        <form method="POST" action="{{ route('transfers.store') }}" class="space-y-4">
            @csrf

            {{-- From Account --}}
            <div>
                <label class="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">From Account</label>
                <select name="from_account_id" required
                    class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent">
                    <option value="" disabled selected>Select source account</option>
                    @foreach($accounts as $account)
                    <option value="{{ $account->id }}" {{ old('from_account_id') == $account->id ? 'selected' : '' }}>
                        {{ $account->name }} — {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($account->balance, 2) }}
                    </option>
                    @endforeach
                </select>
            </div>

            {{-- Arrow visual --}}
            <div class="flex justify-center">
                <div class="w-8 h-8 rounded-full bg-indigo-600/20 flex items-center justify-center">
                    <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
                    </svg>
                </div>
            </div>

            {{-- To Account --}}
            <div>
                <label class="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">To Account</label>
                <select name="to_account_id" required
                    class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent">
                    <option value="" disabled selected>Select destination account</option>
                    @foreach($accounts as $account)
                    <option value="{{ $account->id }}" {{ old('to_account_id') == $account->id ? 'selected' : '' }}>
                        {{ $account->name }} — {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($account->balance, 2) }}
                    </option>
                    @endforeach
                </select>
            </div>

            {{-- Amount --}}
            <div>
                <label class="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">Amount</label>
                <div class="relative">
                    <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">
                        {{ auth()->user()->currency ?? 'PHP' }}
                    </span>
                    <input type="number" name="amount" step="0.01" min="0.01"
                        value="{{ old('amount') }}"
                        placeholder="0.00"
                        class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl pl-14 pr-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                        required>
                </div>
            </div>

            {{-- Date --}}
            <div>
                <label class="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">Date</label>
                <input type="date" name="transfer_date"
                    value="{{ old('transfer_date', date('Y-m-d')) }}"
                    class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    required>
            </div>

            {{-- Note --}}
            <div>
                <label class="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">Note <span class="text-gray-600 normal-case font-normal">(optional)</span></label>
                <input type="text" name="note" maxlength="255"
                    value="{{ old('note') }}"
                    placeholder="e.g. Monthly savings transfer"
                    class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent placeholder-gray-600">
            </div>

            <button type="submit"
                class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3.5 rounded-xl transition-colors mt-2">
                Transfer Funds
            </button>
        </form>
    </div>
</div>

@if($errors->any())
<script>
    document.addEventListener('DOMContentLoaded', function () {
        document.getElementById('transferModal').classList.remove('hidden');
    });
</script>
@endif

<style>
@keyframes slide-up {
    from { transform: translateY(100%); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
}
.animate-slide-up { animation: slide-up 0.3s ease-out; }
</style>
@endsection