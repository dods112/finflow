@extends('layouts.app')
@section('title', 'AI Chat')

@section('content')
<div class="max-w-lg mx-auto" id="chatWrapper" style="display: flex; flex-direction: column;">

    {{-- HEADER --}}
    <div class="px-5 pt-10 pb-4 bg-gray-900 border-b border-gray-800" style="flex-shrink: 0;">
        <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center">
                    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                    </svg>
                </div>
                <div>
                    <h1 class="font-semibold text-white text-sm">FinFlow AI</h1>
                    <div class="flex items-center gap-1.5">
                        <div class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></div>
                        <span class="text-xs text-gray-600">Online</span>
                    </div>
                </div>
            </div>
            <form method="POST" action="{{ route('chat.clear') }}"
                  onsubmit="return confirm('Clear all chat history?')">
                @csrf @method('DELETE')
                <button type="submit" class="text-gray-700 hover:text-red-400 transition text-xs">Clear</button>
            </form>
        </div>
    </div>

    {{-- MESSAGES — takes all remaining space --}}
    <div id="chatMessages"
         class="bg-gray-950 px-4 py-4 space-y-4"
         style="flex: 1 1 auto; overflow-y: auto; min-height: 0;">

        {{-- Welcome message --}}
        @if($chatLogs->count() === 0)
        <div class="flex gap-3">
            <div class="w-8 h-8 rounded-xl bg-indigo-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                </svg>
            </div>
            <div class="bg-gray-900 border border-gray-800 rounded-2xl rounded-tl-none px-4 py-3 max-w-[80%]">
                <p class="text-sm text-gray-300 mb-3">Hi, I am your FinFlow AI assistant. I have access to your real financial data and can answer questions like:</p>
                <div class="space-y-1.5">
                    <p class="text-xs text-gray-600">— What is my current balance?</p>
                    <p class="text-xs text-gray-600">— How much did I spend this week?</p>
                    <p class="text-xs text-gray-600">— Am I overspending?</p>
                    <p class="text-xs text-gray-600">— Give me a savings tip</p>
                </div>
            </div>
        </div>
        @endif

        {{-- Chat history --}}
        @foreach($chatLogs as $log)
        <div class="flex justify-end gap-3">
            <div class="bg-indigo-600 text-white rounded-2xl rounded-tr-none px-4 py-3 max-w-[80%]">
                <p class="text-sm">{{ $log->message }}</p>
            </div>
            <div class="w-8 h-8 rounded-xl bg-gray-800 border border-gray-700 flex items-center justify-center flex-shrink-0 text-xs font-bold text-gray-500">
                {{ strtoupper(substr(auth()->user()->name, 0, 2)) }}
            </div>
        </div>
        <div class="flex gap-3">
            <div class="w-8 h-8 rounded-xl bg-indigo-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                </svg>
            </div>
            <div class="bg-gray-900 border border-gray-800 rounded-2xl rounded-tl-none px-4 py-3 max-w-[80%]">
                <p class="text-sm text-gray-300 whitespace-pre-line">{{ $log->response }}</p>
                <p class="text-[10px] text-gray-700 mt-2">{{ $log->created_at->diffForHumans() }}</p>
            </div>
        </div>
        @endforeach

        {{-- Typing indicator --}}
        <div id="typingIndicator" class="hidden flex gap-3">
            <div class="w-8 h-8 rounded-xl bg-indigo-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                </svg>
            </div>
            <div class="bg-gray-900 border border-gray-800 rounded-2xl rounded-tl-none px-4 py-3">
                <div class="flex gap-1.5 items-center h-5">
                    <div class="w-1.5 h-1.5 bg-gray-700 rounded-full animate-bounce" style="animation-delay:0ms"></div>
                    <div class="w-1.5 h-1.5 bg-gray-700 rounded-full animate-bounce" style="animation-delay:150ms"></div>
                    <div class="w-1.5 h-1.5 bg-gray-700 rounded-full animate-bounce" style="animation-delay:300ms"></div>
                </div>
            </div>
        </div>

        {{-- Bottom spacer so last message clears the nav --}}
        <div style="height: 8px;"></div>

    </div>

    {{-- QUICK PROMPTS --}}
    <div class="bg-gray-900 border-t border-gray-800 px-4 py-2 flex gap-2 overflow-x-auto"
         style="flex-shrink: 0; -ms-overflow-style:none; scrollbar-width:none;">
        <button onclick="setPrompt(this.getAttribute('data-prompt'))"
                data-prompt="What is my current balance?"
                class="flex-shrink-0 bg-gray-800 border border-gray-700 text-gray-500 text-xs px-3 py-1.5 rounded-lg hover:border-indigo-500 hover:text-indigo-400 transition whitespace-nowrap">
            Current balance
        </button>
        <button onclick="setPrompt(this.getAttribute('data-prompt'))"
                data-prompt="How much did I spend this week?"
                class="flex-shrink-0 bg-gray-800 border border-gray-700 text-gray-500 text-xs px-3 py-1.5 rounded-lg hover:border-indigo-500 hover:text-indigo-400 transition whitespace-nowrap">
            Spending this week
        </button>
        <button onclick="setPrompt(this.getAttribute('data-prompt'))"
                data-prompt="Am I overspending this month?"
                class="flex-shrink-0 bg-gray-800 border border-gray-700 text-gray-500 text-xs px-3 py-1.5 rounded-lg hover:border-indigo-500 hover:text-indigo-400 transition whitespace-nowrap">
            Am I overspending
        </button>
        <button onclick="setPrompt(this.getAttribute('data-prompt'))"
                data-prompt="Give me a tip to save more money"
                class="flex-shrink-0 bg-gray-800 border border-gray-700 text-gray-500 text-xs px-3 py-1.5 rounded-lg hover:border-indigo-500 hover:text-indigo-400 transition whitespace-nowrap">
            Savings tip
        </button>
        <button onclick="setPrompt(this.getAttribute('data-prompt'))"
                data-prompt="What is my top expense category this month?"
                class="flex-shrink-0 bg-gray-800 border border-gray-700 text-gray-500 text-xs px-3 py-1.5 rounded-lg hover:border-indigo-500 hover:text-indigo-400 transition whitespace-nowrap">
            Top expense
        </button>
    </div>

    {{-- INPUT BAR --}}
    <div class="bg-gray-900 border-t border-gray-800 px-4 py-3"
         style="flex-shrink: 0; padding-bottom: max(12px, env(safe-area-inset-bottom));">
        <div class="flex gap-2 items-end">
            <textarea id="messageInput"
                      placeholder="Ask about your finances..."
                      rows="1"
                      class="flex-1 bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none resize-none text-white placeholder-gray-600 max-h-32 focus:border-indigo-500 transition"
                      onkeydown="handleKeydown(event)"></textarea>
            <button id="sendBtn" onclick="sendMessage()"
                    class="w-11 h-11 rounded-xl bg-indigo-600 text-white flex items-center justify-center flex-shrink-0 hover:bg-indigo-500 active:scale-95 transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                </svg>
            </button>
        </div>
    </div>

</div>
@endsection

@push('scripts')
<script>
const chatMessages    = document.getElementById('chatMessages');
const messageInput    = document.getElementById('messageInput');
const typingIndicator = document.getElementById('typingIndicator');
const csrfToken       = document.querySelector('meta[name="csrf-token"]')?.content ?? '';
const userInitials    = @json(strtoupper(substr(auth()->user()->name, 0, 2)));

// Set chat wrapper height = viewport minus bottom nav
function setWrapperHeight() {
    const nav = document.querySelector('nav.fixed');
    const wrapper = document.getElementById('chatWrapper');
    if (nav && wrapper) {
        const navH = nav.offsetHeight;
        wrapper.style.height = (window.innerHeight - navH) + 'px';
    }
}
setWrapperHeight();
window.addEventListener('load', setWrapperHeight);
window.addEventListener('resize', setWrapperHeight);
setTimeout(setWrapperHeight, 300);

// Scroll to bottom
function scrollBottom() {
    chatMessages.scrollTop = chatMessages.scrollHeight;
}
scrollBottom();
window.addEventListener('load', scrollBottom);

function setPrompt(text) {
    messageInput.value = text;
    messageInput.focus();
}

function handleKeydown(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
}

async function sendMessage() {
    const message = messageInput.value.trim();
    if (!message) return;
    appendMessage(message, 'user');
    messageInput.value = '';
    messageInput.style.height = 'auto';
    typingIndicator.classList.remove('hidden');
    scrollBottom();
    try {
        const res = await fetch('{{ route("chat.send") }}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': csrfToken,
                'Accept': 'application/json'
            },
            body: JSON.stringify({ message })
        });
        const data = await res.json();
        typingIndicator.classList.add('hidden');
        appendMessage(data.success ? data.response : 'Something went wrong. Please try again.', 'ai', !data.success);
    } catch (err) {
        typingIndicator.classList.add('hidden');
        appendMessage('Connection error. Please try again.', 'ai', true);
    }
}

function appendMessage(text, role, isError = false) {
    const div = document.createElement('div');
    div.className = 'flex gap-3' + (role === 'user' ? ' justify-end' : '');
    const aiIcon = `<div class="w-8 h-8 rounded-xl bg-indigo-600 flex items-center justify-center flex-shrink-0"><svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/></svg></div>`;
    if (role === 'user') {
        div.innerHTML = `<div class="bg-indigo-600 text-white rounded-2xl rounded-tr-none px-4 py-3 max-w-[80%]"><p class="text-sm">${escapeHtml(text)}</p></div><div class="w-8 h-8 rounded-xl bg-gray-800 border border-gray-700 flex items-center justify-center flex-shrink-0 text-xs font-bold text-gray-500">${escapeHtml(userInitials)}</div>`;
    } else {
        div.innerHTML = `${aiIcon}<div class="${isError ? 'bg-red-900/20 border-red-800' : 'bg-gray-900 border-gray-800'} border rounded-2xl rounded-tl-none px-4 py-3 max-w-[80%]"><p class="text-sm text-gray-300 whitespace-pre-line">${escapeHtml(text)}</p></div>`;
    }
    chatMessages.insertBefore(div, typingIndicator);
    scrollBottom();
}

function escapeHtml(str) {
    const d = document.createElement('div');
    d.appendChild(document.createTextNode(str));
    return d.innerHTML;
}

messageInput.addEventListener('input', function () {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 128) + 'px';
});
</script>
@endpush