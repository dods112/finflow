@extends('layouts.app')
@section('title', 'Profile')

@section('content')
<div class="max-w-lg mx-auto pb-28">

    {{-- HERO --}}
    <div class="bg-gray-900 border-b border-gray-800 px-5 pt-12 pb-8">
        <div class="flex items-center gap-4 mb-6">
            <div class="w-14 h-14 rounded-2xl bg-indigo-600 flex items-center justify-center text-xl font-bold text-white">
                {{ strtoupper(substr($user->name, 0, 2)) }}
            </div>
            <div>
                <h1 class="text-lg font-bold text-white">{{ $user->name }}</h1>
                <p class="text-gray-600 text-sm">{{ $user->email }}</p>
            </div>
        </div>
        <div class="grid grid-cols-3 gap-3">
            <div class="bg-gray-800 rounded-xl p-3 text-center border border-gray-700">
                <p class="text-white font-bold text-lg">{{ $stats['total_transactions'] }}</p>
                <p class="text-gray-600 text-[10px] uppercase tracking-wide mt-0.5">Transactions</p>
            </div>
            <div class="bg-gray-800 rounded-xl p-3 text-center border border-gray-700">
                <p class="text-white font-bold text-lg">{{ $stats['accounts_count'] }}</p>
                <p class="text-gray-600 text-[10px] uppercase tracking-wide mt-0.5">Accounts</p>
            </div>
            <div class="bg-gray-800 rounded-xl p-3 text-center border border-gray-700">
                <p class="text-white font-bold text-sm font-mono">
                    {{ number_format($stats['total_income'] - $stats['total_expenses'], 0) }}
                </p>
                <p class="text-gray-600 text-[10px] uppercase tracking-wide mt-0.5">Net Saved</p>
            </div>
        </div>
    </div>

    <div class="px-4 py-4 space-y-3">

        {{-- Edit Profile --}}
        <div class="bg-gray-900 rounded-2xl p-5 border border-gray-800">
            <h3 class="font-semibold text-white mb-4 text-sm uppercase tracking-wide">Edit Profile</h3>

            {{-- Success / Error messages --}}
            @if(session('success'))
            <div class="mb-3 bg-green-500/10 border border-green-500/30 text-green-400 text-xs rounded-xl px-3 py-2">
                {{ session('success') }}
            </div>
            @endif
            @if($errors->any())
            <div class="mb-3 bg-red-500/10 border border-red-500/30 text-red-400 text-xs rounded-xl px-3 py-2">
                @foreach($errors->all() as $error)
                    <p>{{ $error }}</p>
                @endforeach
            </div>
            @endif

            <form method="POST" action="{{ route('profile.update') }}" class="space-y-3">
                @csrf @method('PUT')
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Name</label>
                    <input type="text" name="name" value="{{ $user->name }}" required
                           class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white transition"/>
                </div>
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Currency</label>
                    <select name="currency" class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                        @foreach(['USD','EUR','GBP','PHP','JPY','AUD','CAD','SGD','INR','MYR'] as $cur)
                        <option value="{{ $cur }}" {{ $user->currency === $cur ? 'selected' : '' }}>{{ $cur }}</option>
                        @endforeach
                    </select>
                </div>
                <button type="submit"
                        class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 rounded-xl transition active:scale-95 text-sm">
                    Save Changes
                </button>
            </form>
        </div>

        {{-- Change Password --}}
        <div class="bg-gray-900 rounded-2xl p-5 border border-gray-800">
            <h3 class="font-semibold text-white mb-4 text-sm uppercase tracking-wide">Change Password</h3>
            <form method="POST" action="{{ route('profile.password') }}" class="space-y-3">
                @csrf @method('PUT')
                <input type="password" name="current_password" placeholder="Current password" required
                       class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-600 transition"/>
                <input type="password" name="password" placeholder="New password" required
                       class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-600 transition"/>
                <input type="password" name="password_confirmation" placeholder="Confirm new password" required
                       class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-600 transition"/>
                <button type="submit"
                        class="w-full bg-gray-800 border border-gray-700 hover:border-indigo-500 text-white font-semibold py-3 rounded-xl transition text-sm">
                    Update Password
                </button>
            </form>
        </div>

        {{-- Export --}}
        <div class="bg-gray-900 rounded-2xl p-5 border border-gray-800">
            <h3 class="font-semibold text-white mb-4 text-sm uppercase tracking-wide">Export Data</h3>
            <div class="grid grid-cols-2 gap-3">
                <a href="{{ route('profile.export.csv') }}"
                   class="flex items-center justify-center gap-2 bg-emerald-600 hover:bg-emerald-500 text-white font-medium py-3 rounded-xl text-sm transition active:scale-95">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                    Export CSV
                </a>
                <a href="{{ route('profile.export.pdf') }}"
                   class="flex items-center justify-center gap-2 bg-red-600 hover:bg-red-500 text-white font-medium py-3 rounded-xl text-sm transition active:scale-95">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                    </svg>
                    Export PDF
                </a>
            </div>
        </div>

        {{-- Appearance / Theme Toggle --}}
        @include('profile._theme_toggle')

        {{-- Logout --}}
        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button type="submit"
                    class="w-full bg-gray-900 border border-red-900 text-red-500 font-semibold py-3.5 rounded-xl hover:bg-red-900/20 transition text-sm active:scale-95">
                Sign Out
            </button>
        </form>

    </div>
</div>
@endsection