@extends('layouts.auth')
@section('title', 'Forgot Password')
@section('content')

<div class="text-center mb-6">
    <h2 class="text-xl font-bold text-white">Reset Password</h2>
    <p class="text-gray-600 text-sm mt-1">Enter your email and we'll send a reset link.</p>
</div>

@if(session('success'))
<div class="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm rounded-xl px-4 py-3 mb-4">
    {{ session('success') }}
</div>
@endif

@if($errors->any())
<div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 mb-4">
    {{ $errors->first() }}
</div>
@endif

<form method="POST" action="{{ route('password.email') }}" class="space-y-4">
    @csrf
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Email</label>
        <input type="email" name="email" value="{{ old('email') }}" required autofocus
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="you@example.com"/>
    </div>
    <button type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 rounded-xl transition text-sm">
        Send Reset Link
    </button>
</form>

<p class="text-center text-sm text-gray-600 mt-5">
    Remembered it?
    <a href="{{ route('login') }}" class="text-indigo-400 font-semibold hover:text-indigo-300">Sign in</a>
</p>

@endsection
