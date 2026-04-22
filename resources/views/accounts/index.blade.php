@extends('layouts.app')
@section('title', 'Accounts')

@section('content')
<div class="max-w-lg mx-auto">

    <div class="px-5 pt-12 pb-4 flex items-center justify-between">
        <h1 class="text-lg font-bold text-white">Accounts</h1>
        <button onclick="document.getElementById('addAccountModal').classList.remove('hidden')"
                class="w-8 h-8 rounded-full bg-indigo-600 text-white flex items-center justify-center hover:bg-indigo-500 transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
            </svg>
        </button>
    </div>

    <div class="px-4 space-y-3 pb-8">
        @forelse($accounts as $account)
        <div class="bg-gray-900 rounded-2xl overflow-hidden border border-gray-800">
            <div class="h-px" style="background-color: {{ $account->color }}"></div>
            <div class="p-4 flex items-center gap-4">
                <div class="w-11 h-11 rounded-xl bg-gray-800 flex items-center justify-center flex-shrink-0">
                    <div class="w-3 h-3 rounded-full" style="background-color: {{ $account->color }}"></div>
                </div>
                <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                        <p class="font-semibold text-white text-sm">{{ $account->name }}</p>
                        @if($account->is_default)
                        <span class="text-[10px] bg-indigo-600/20 text-indigo-400 border border-indigo-600/30 px-2 py-0.5 rounded-full font-medium">
                            Default
                        </span>
                        @endif
                    </div>
                    <p class="text-xs text-gray-600 mt-0.5">{{ $account->type_label }} &middot; {{ $account->transactions_count }} transactions</p>
                </div>
                <div class="text-right flex-shrink-0">
                    <p class="font-bold font-mono text-white text-sm">{{ number_format($account->balance, 2) }}</p>
                    <p class="text-xs text-gray-600">{{ $account->currency }}</p>
                </div>
            </div>
            <div class="px-4 pb-3 pt-2 flex gap-4 border-t border-gray-800">
                @if(!$account->is_default)
                <form method="POST" action="{{ route('accounts.setDefault', $account) }}">
                    @csrf
                    <button type="submit" class="text-xs text-gray-600 hover:text-indigo-400 font-medium transition">
                        Set Default
                    </button>
                </form>
                @endif
                <button onclick="openEditModal({{ $account->id }}, '{{ $account->name }}', '{{ $account->account_type }}', '{{ $account->color }}')"
                        class="text-xs text-gray-600 hover:text-indigo-400 font-medium transition">Edit</button>
                @if($account->transactions_count === 0)
                <form method="POST" action="{{ route('accounts.destroy', $account) }}"
                      onsubmit="return confirm('Delete this account?')">
                    @csrf @method('DELETE')
                    <button type="submit" class="text-xs text-gray-600 hover:text-red-400 font-medium transition">Delete</button>
                </form>
                @endif
            </div>
        </div>
        @empty
        <div class="text-center py-12">
            <div class="w-12 h-12 rounded-2xl bg-gray-800 flex items-center justify-center mx-auto mb-3">
                <svg class="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                </svg>
            </div>
            <p class="text-gray-600 text-sm">No accounts yet</p>
        </div>
        @endforelse
    </div>
</div>

{{-- ADD ACCOUNT MODAL --}}
<div id="addAccountModal" class="hidden fixed inset-0 z-50 flex items-end justify-center">
    <div class="absolute inset-0 bg-black/70 backdrop-blur-sm"
         onclick="document.getElementById('addAccountModal').classList.add('hidden')"></div>
    <div class="relative bg-gray-900 border border-gray-800 rounded-t-2xl w-full max-w-lg p-6 slide-up">
        <h3 class="font-bold text-white text-lg mb-5">Add Account</h3>
        <form method="POST" action="{{ route('accounts.store') }}" class="space-y-4">
            @csrf
            <input type="text" name="name" placeholder="Account name" required
                   class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-600 transition"/>
            <select name="account_type" required
                    class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                @foreach(\App\Models\Account::TYPES as $key => $type)
                <option value="{{ $key }}">{{ $type['label'] }}</option>
                @endforeach
            </select>
            <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-600 text-sm">{{ auth()->user()->currency }}</span>
                <input type="number" name="balance" value="0" step="0.01"
                       class="w-full bg-gray-800 border border-gray-700 rounded-xl pl-14 pr-4 py-3 text-sm outline-none text-white"/>
            </div>
            <div class="flex items-center gap-3">
                <label class="text-sm text-gray-500">Color</label>
                <input type="color" name="color" value="#6366f1"
                       class="w-10 h-10 rounded-xl cursor-pointer border-0 bg-transparent"/>
            </div>
            <div class="flex gap-3 pt-1">
                <button type="button"
                        onclick="document.getElementById('addAccountModal').classList.add('hidden')"
                        class="flex-1 bg-gray-800 border border-gray-700 text-gray-400 font-semibold py-3.5 rounded-xl">Cancel</button>
                <button type="submit" class="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3.5 rounded-xl transition">Save</button>
            </div>
        </form>
    </div>
</div>

{{-- EDIT ACCOUNT MODAL --}}
<div id="editAccountModal" class="hidden fixed inset-0 z-50 flex items-end justify-center">
    <div class="absolute inset-0 bg-black/70 backdrop-blur-sm"
         onclick="document.getElementById('editAccountModal').classList.add('hidden')"></div>
    <div class="relative bg-gray-900 border border-gray-800 rounded-t-2xl w-full max-w-lg p-6 slide-up">
        <h3 class="font-bold text-white text-lg mb-5">Edit Account</h3>
        <form id="editAccountForm" method="POST" class="space-y-4">
            @csrf @method('PUT')
            <input type="text" name="name" id="editName" required
                   class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white transition"/>
            <select name="account_type" id="editType"
                    class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                @foreach(\App\Models\Account::TYPES as $key => $type)
                <option value="{{ $key }}">{{ $type['label'] }}</option>
                @endforeach
            </select>
            <div class="flex items-center gap-3">
                <label class="text-sm text-gray-500">Color</label>
                <input type="color" name="color" id="editColor"
                       class="w-10 h-10 rounded-xl cursor-pointer border-0 bg-transparent"/>
            </div>
            <div class="flex gap-3 pt-1">
                <button type="button"
                        onclick="document.getElementById('editAccountModal').classList.add('hidden')"
                        class="flex-1 bg-gray-800 border border-gray-700 text-gray-400 font-semibold py-3.5 rounded-xl">Cancel</button>
                <button type="submit" class="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3.5 rounded-xl transition">Update</button>
            </div>
        </form>
    </div>
</div>

@endsection

@push('scripts')
<script>
function openEditModal(id, name, type, color) {
    document.getElementById('editAccountForm').action = `/accounts/${id}`;
    document.getElementById('editName').value  = name;
    document.getElementById('editType').value  = type;
    document.getElementById('editColor').value = color;
    document.getElementById('editAccountModal').classList.remove('hidden');
}
</script>
@endpush