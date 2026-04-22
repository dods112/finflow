@extends('layouts.auth')
@section('title', 'Login')
@section('content')

<div class="text-center mb-6">
    <h2 class="text-xl font-bold text-white">Welcome back</h2>
    <p class="text-gray-600 text-sm mt-1">Sign in to your FinFlow account</p>
</div>

@if(session('success'))
<div class="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm rounded-xl px-4 py-3 mb-4">
    {{ session('success') }}
</div>
@endif

@if(session('logout'))
<div class="bg-gray-800 border border-gray-700 text-gray-400 text-sm rounded-xl px-4 py-3 mb-4 text-center">
    You have been signed out successfully.
</div>
@endif

@if($errors->any())
<div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 mb-4">
    {{ $errors->first() }}
</div>
@endif

<form method="POST" action="{{ route('login') }}" class="space-y-4">
    @csrf

    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Email</label>
        <input type="email" name="email" value="{{ old('email') }}" required autofocus
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition text-sm"
               placeholder="you@example.com"/>
    </div>

    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Password</label>
        <input type="password" name="password" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition text-sm"
               placeholder="••••••••"/>
    </div>

    <div class="flex items-center gap-2">
        <input type="checkbox" name="remember" id="remember"
               class="rounded bg-gray-800 border-gray-700 accent-indigo-500">
        <label for="remember" class="text-sm text-gray-500">Remember me</label>
    </div>
    <div class="text-right">
        <a href="{{ route('password.request') }}" class="text-xs text-indigo-400 hover:text-indigo-300">Forgot password?</a>
    </div>

    <button type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 rounded-xl transition active:scale-95 text-sm">
        Sign In
    </button>
</form>

<div class="mt-6 pt-5 border-t border-gray-800 text-center">
    <p class="text-gray-600 text-xs mb-3">Don't have an account yet?</p>
    <a href="{{ route('register') }}"
       class="block w-full py-3 rounded-xl border border-gray-700 text-gray-400 text-sm font-medium hover:border-indigo-500 hover:text-indigo-400 transition">
        Create an account
    </a>
</div>

@endsection