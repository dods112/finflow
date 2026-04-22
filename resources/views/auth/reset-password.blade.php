@extends('layouts.auth')
@section('title', 'Set New Password')
@section('content')

<div class="text-center mb-6">
    <h2 class="text-xl font-bold text-white">Set New Password</h2>
    <p class="text-gray-600 text-sm mt-1">Choose a strong new password.</p>
</div>

@if($errors->any())
<div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 mb-4">
    @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
</div>
@endif

<form method="POST" action="{{ route('password.update') }}" class="space-y-4">
    @csrf
    <input type="hidden" name="token" value="{{ $token }}">
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Email</label>
        <input type="email" name="email" value="{{ old('email') }}" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="you@example.com"/>
    </div>
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">New Password</label>
        <input type="password" name="password" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="Min. 8 characters"/>
    </div>
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Confirm Password</label>
        <input type="password" name="password_confirmation" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="Repeat password"/>
    </div>
    <button type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 rounded-xl transition text-sm">
        Reset Password
    </button>
</form>

@endsection
