@extends('layouts.app')
@section('title', 'Transactions')

@section('content')
<div class="w-full">

    {{-- HEADER --}}
    <div class="bg-gray-900 sticky top-0 z-30 px-5 pt-12 pb-4 border-b border-gray-800">
        <div class="flex items-center justify-between mb-4">
            <h1 class="text-lg font-bold text-white">Transactions</h1>
            <a href="{{ route('transactions.create') }}"
               class="w-8 h-8 rounded-full bg-indigo-600 text-white flex items-center justify-center hover:bg-indigo-500 transition shadow-lg shadow-indigo-600/30">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
            </a>
        </div>

        <form method="GET" class="space-y-2">
            <div class="flex gap-2">
                <div class="relative flex-1">
                    <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                    </svg>
                    <input type="text" name="search" value="{{ request('search') }}" placeholder="Search..."
                           class="w-full bg-gray-800 border border-gray-700 rounded-xl pl-9 pr-4 py-2.5 text-sm
                                  outline-none focus:border-indigo-500 text-white placeholder-gray-600 transition"/>
                </div>
                <button type="submit"
                        class="bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl px-4 py-2.5 text-sm font-medium transition">
                    Go
                </button>
            </div>
            <div class="flex gap-2 overflow-x-auto pb-1" style="-ms-overflow-style:none;scrollbar-width:none;">
                @foreach([''=>'All', 'income'=>'Income', 'expense'=>'Expense'] as $val => $label)
                <a href="{{ request()->fullUrlWithQuery(['type' => $val ?: null]) }}"
                   class="flex-shrink-0 px-4 py-1.5 rounded-full text-xs font-medium transition
                          {{ request('type') == $val
                              ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/30'
                              : 'bg-gray-800 text-gray-500 border border-gray-700 hover:border-indigo-500' }}">
                    {{ $label }}
                </a>
                @endforeach
                @foreach($categories->take(6) as $cat)
                <a href="{{ request()->fullUrlWithQuery(['category_id' => request('category_id') == $cat->id ? null : $cat->id]) }}"
                   class="flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-medium transition
                          {{ request('category_id') == $cat->id
                              ? 'bg-indigo-600 text-white'
                              : 'bg-gray-800 text-gray-500 border border-gray-700 hover:border-indigo-500' }}">
                    {{ $cat->name }}
                </a>
                @endforeach
            </div>
        </form>
    </div>

    {{-- LIST --}}
    <div class="px-4 sm:px-6 lg:px-8 py-4 pb-28 lg:pb-8">
        @if($transactions->count() === 0)
        <div class="text-center py-16">
            <div class="w-16 h-16 rounded-2xl bg-gray-800 flex items-center justify-center mx-auto mb-4">
                <svg class="w-8 h-8 text-gray-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                </svg>
            </div>
            <p class="text-gray-500 text-sm font-medium mb-1">No transactions found</p>
            <p class="text-gray-700 text-xs mb-4">Try adjusting your filters</p>
            <a href="{{ route('transactions.create') }}"
               class="inline-flex items-center gap-2 bg-indigo-600 text-white text-sm font-medium px-4 py-2 rounded-xl hover:bg-indigo-500 transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
                Add Transaction
            </a>
        </div>
        @else
        @php $currentDate = null; @endphp
        @foreach($transactions as $tx)
            @if($tx->date->format('Y-m-d') !== $currentDate)
                @php $currentDate = $tx->date->format('Y-m-d'); @endphp
                <div class="flex items-center gap-3 mt-4 mb-2 first:mt-0 px-1">
                    <p class="text-[10px] font-semibold text-gray-600 uppercase tracking-widest">
                        {{ $tx->date->isToday() ? 'Today' : ($tx->date->isYesterday() ? 'Yesterday' : $tx->date->format('M d, Y')) }}
                    </p>
                    <div class="flex-1 h-px bg-gray-800"></div>
                </div>
            @endif

            <div class="flex items-center gap-3 bg-gray-900 rounded-2xl px-4 py-3.5 mb-2
                        border border-gray-800 hover:border-gray-700 transition group card-hover">
                {{-- Icon --}}
                <div class="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                     style="background-color:{{ ($tx->category->color ?? '#6366f1') }}18">
                    <div class="w-3 h-3 rounded-full" style="background-color:{{ $tx->category->color ?? '#6366f1' }}"></div>
                </div>

                {{-- Details --}}
                <div class="flex-1 min-w-0">
                    <p class="text-sm text-gray-200 truncate font-medium">{{ $tx->description ?: $tx->category->name }}</p>
                    <div class="flex items-center gap-1.5 mt-0.5">
                        <span class="text-xs text-gray-600">{{ $tx->category->name }}</span>
                        <span class="text-gray-700">·</span>
                        <span class="text-xs text-gray-600">{{ $tx->account->name }}</span>
                    </div>
                </div>

                {{-- Amount + Actions --}}
                <div class="text-right flex-shrink-0">
                    <p class="font-mono font-bold text-sm {{ $tx->type === 'income' ? 'text-emerald-400' : 'text-red-400' }}">
                        {{ $tx->formatted_amount }}
                    </p>
                    <div class="flex gap-3 mt-1.5 justify-end">
                        <a href="{{ route('transactions.edit', $tx) }}"
                           class="text-[10px] text-gray-700 hover:text-indigo-400 transition font-medium">Edit</a>
                        <form method="POST" action="{{ route('transactions.destroy', $tx) }}"
                              data-confirm="Delete this transaction? This will reverse the balance change."
                              data-confirm-title="Delete Transaction"
                              data-confirm-ok="Delete">
                            @csrf @method('DELETE')
                            <button type="submit" class="text-[10px] text-gray-700 hover:text-red-400 transition font-medium">Delete</button>
                        </form>
                    </div>
                </div>
            </div>
        @endforeach

        <div class="mt-4">{{ $transactions->links('partials.pagination') }}</div>
        @endif
    </div>
</div>
@endsection
