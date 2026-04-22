#!/bin/bash

# ============================================================
#  FinFlow Full Upgrade Script — UI + Features
#  Run from your project root:
#  bash finflow-upgrade.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC} $1"; }
info()  { echo -e "${BLUE}[..]${NC} $1"; }
error() { echo -e "${RED}[ERR]${NC} $1"; }
head()  { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   FinFlow Full Upgrade — UI + Features v2.0   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "artisan" ]; then
  error "Run this from your Laravel project root (where artisan is)."
  exit 1
fi

# ─────────────────────────────────────────────────────────────
head "1. TOAST NOTIFICATIONS"
# ─────────────────────────────────────────────────────────────
info "Creating toast partial..."

mkdir -p resources/views/partials

cat > resources/views/partials/toast.blade.php << 'BLADE'
{{-- Toast Notification System --}}
<div id="toast-container"
     class="fixed top-4 right-4 z-[999] flex flex-col gap-2 pointer-events-none max-w-sm w-full px-4">
</div>

@if(session('success') || session('error') || session('budget_alert') || session('logout'))
<script>
document.addEventListener('DOMContentLoaded', function () {
    @if(session('success'))
        showToast('{{ addslashes(session('success')) }}', 'success');
    @endif
    @if(session('error'))
        showToast('{{ addslashes(session('error')) }}', 'error');
    @endif
    @if(session('budget_alert'))
        showToast('{{ addslashes(session('budget_alert')) }}', 'warning');
    @endif
    @if(session('logout'))
        showToast('You have been signed out.', 'info');
    @endif
});
</script>
@endif

<script>
function showToast(message, type = 'success', duration = 4000) {
    const colors = {
        success: 'bg-emerald-500/20 border-emerald-500/40 text-emerald-300',
        error:   'bg-red-500/20 border-red-500/40 text-red-300',
        warning: 'bg-amber-500/20 border-amber-500/40 text-amber-300',
        info:    'bg-indigo-500/20 border-indigo-500/40 text-indigo-300',
    };
    const icons = {
        success: `<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>`,
        error:   `<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>`,
        warning: `<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/></svg>`,
        info:    `<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>`,
    };

    const container = document.getElementById('toast-container');
    const toast     = document.createElement('div');

    toast.className = `pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-2xl border
                       backdrop-blur-sm shadow-2xl text-sm font-medium
                       ${colors[type] ?? colors.info}
                       translate-x-full opacity-0 transition-all duration-300`;

    toast.innerHTML = `
        ${icons[type] ?? icons.info}
        <span class="flex-1">${message}</span>
        <button onclick="this.closest('[data-toast]').remove()"
                class="opacity-50 hover:opacity-100 transition ml-1">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
        </button>`;

    toast.dataset.toast = '1';
    container.appendChild(toast);

    // Animate in
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            toast.classList.remove('translate-x-full', 'opacity-0');
        });
    });

    // Auto dismiss
    setTimeout(() => {
        toast.classList.add('translate-x-full', 'opacity-0');
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

// Make globally available
window.showToast = showToast;
</script>
BLADE
log "Toast partial created."

# ─────────────────────────────────────────────────────────────
head "2. CUSTOM CONFIRM MODAL"
# ─────────────────────────────────────────────────────────────
info "Creating confirm modal partial..."

cat > resources/views/partials/confirm-modal.blade.php << 'BLADE'
{{-- Custom Confirm Modal (replaces browser confirm()) --}}
<div id="confirmModal"
     class="hidden fixed inset-0 z-[998] flex items-center justify-center px-4">
    <div class="absolute inset-0 bg-black/70 backdrop-blur-sm" id="confirmOverlay"></div>
    <div class="relative bg-gray-900 border border-gray-700 rounded-2xl w-full max-w-sm p-6 shadow-2xl
                scale-95 opacity-0 transition-all duration-200" id="confirmBox">
        <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center shrink-0">
                <svg class="w-5 h-5 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
                </svg>
            </div>
            <div>
                <h3 class="text-white font-semibold text-sm" id="confirmTitle">Are you sure?</h3>
                <p class="text-gray-500 text-xs mt-0.5" id="confirmMessage">This action cannot be undone.</p>
            </div>
        </div>
        <div class="flex gap-3">
            <button id="confirmCancel"
                    class="flex-1 bg-gray-800 border border-gray-700 text-gray-400 font-semibold
                           py-2.5 rounded-xl text-sm hover:border-gray-600 transition">
                Cancel
            </button>
            <button id="confirmOk"
                    class="flex-1 bg-red-600 hover:bg-red-500 text-white font-semibold
                           py-2.5 rounded-xl text-sm transition">
                Delete
            </button>
        </div>
    </div>
</div>

<script>
(function () {
    let resolvePromise = null;

    const modal   = document.getElementById('confirmModal');
    const box     = document.getElementById('confirmBox');
    const overlay = document.getElementById('confirmOverlay');
    const titleEl = document.getElementById('confirmTitle');
    const msgEl   = document.getElementById('confirmMessage');
    const okBtn   = document.getElementById('confirmOk');
    const cancelBtn = document.getElementById('confirmCancel');

    function openModal(title, message, okLabel = 'Delete') {
        titleEl.textContent = title;
        msgEl.textContent   = message;
        okBtn.textContent   = okLabel;
        modal.classList.remove('hidden');
        requestAnimationFrame(() => requestAnimationFrame(() => {
            box.classList.remove('scale-95', 'opacity-0');
        }));
        return new Promise(resolve => { resolvePromise = resolve; });
    }

    function closeModal(result) {
        box.classList.add('scale-95', 'opacity-0');
        setTimeout(() => modal.classList.add('hidden'), 200);
        if (resolvePromise) { resolvePromise(result); resolvePromise = null; }
    }

    okBtn.addEventListener('click',     () => closeModal(true));
    cancelBtn.addEventListener('click', () => closeModal(false));
    overlay.addEventListener('click',   () => closeModal(false));

    // Global helper — use instead of confirm()
    window.confirmAction = openModal;

    // Intercept all forms that use onsubmit="return confirm(...)"
    document.addEventListener('DOMContentLoaded', () => {
        document.querySelectorAll('form[data-confirm]').forEach(form => {
            form.addEventListener('submit', async function (e) {
                e.preventDefault();
                const msg    = this.dataset.confirm || 'Are you sure?';
                const title  = this.dataset.confirmTitle || 'Confirm Action';
                const label  = this.dataset.confirmOk || 'Confirm';
                const result = await confirmAction(title, msg, label);
                if (result) this.submit();
            });
        });
    });
})();
</script>
BLADE
log "Confirm modal partial created."

# ─────────────────────────────────────────────────────────────
head "3. UPDATE LAYOUTS/APP.BLADE.PHP"
# ─────────────────────────────────────────────────────────────
info "Injecting toast + modal into main layout..."

cat > resources/views/layouts/app.blade.php << 'BLADE'
<!DOCTYPE html>
<html lang="en" id="html-root" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#4f46e5" id="theme-color-meta">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="FinFlow">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="description" content="AI-powered personal finance tracker">

    <link rel="manifest" href="/manifest.json">
    <link rel="apple-touch-icon" href="/icons/icon-192.png">
    <link rel="icon" type="image/png" sizes="192x192" href="/icons/icon-192.png">

    <title>@yield('title', 'FinFlow') – FinFlow</title>

    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: { gray: { 950: '#030712' } },
                    animation: {
                        'slide-up':   'slideUp 0.3s ease-out',
                        'fade-in':    'fadeIn 0.4s ease-out',
                        'scale-in':   'scaleIn 0.2s ease-out',
                    },
                    keyframes: {
                        slideUp:  { '0%': { transform: 'translateY(100%)', opacity: 0 }, '100%': { transform: 'translateY(0)', opacity: 1 } },
                        fadeIn:   { '0%': { opacity: 0 }, '100%': { opacity: 1 } },
                        scaleIn:  { '0%': { transform: 'scale(0.95)', opacity: 0 }, '100%': { transform: 'scale(1)', opacity: 1 } },
                    }
                }
            }
        }
    </script>

    <style>
        .pb-safe { padding-bottom: max(1.75rem, env(safe-area-inset-bottom)); }

        /* Smooth transitions */
        *, *::before, *::after {
            transition-property: background-color, border-color, color;
            transition-duration: 200ms;
            transition-timing-function: ease;
        }

        /* Scrollbar */
        ::-webkit-scrollbar { width: 4px; height: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #374151; border-radius: 2px; }

        /* Drawer */
        #side-drawer {
            transform: translateX(-100%);
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        #side-drawer.open { transform: translateX(0); }
        #drawer-overlay {
            opacity: 0; pointer-events: none;
            transition: opacity 0.3s ease;
        }
        #drawer-overlay.open { opacity: 1; pointer-events: all; }

        /* Drawer link */
        .drawer-link { transition: background-color 0.15s ease, color 0.15s ease; }
        .drawer-link:hover { background-color: rgba(99,102,241,0.08); }
        .drawer-link.active { background-color: rgba(99,102,241,0.12); color: #818cf8; }

        /* Progress bar animation */
        @keyframes progressFill {
            from { width: 0%; }
        }
        .progress-bar { animation: progressFill 0.8s ease-out; }

        /* Skeleton loader */
        @keyframes shimmer {
            0% { background-position: -200% 0; }
            100% { background-position: 200% 0; }
        }
        .skeleton {
            background: linear-gradient(90deg, #1f2937 25%, #374151 50%, #1f2937 75%);
            background-size: 200% 100%;
            animation: shimmer 1.5s infinite;
            border-radius: 0.5rem;
        }

        /* Swipe delete */
        .swipe-item { transition: transform 0.2s ease; }
        .swipe-item.swiped { transform: translateX(-80px); }

        /* Nav active dot */
        .nav-active-dot {
            width: 4px; height: 4px;
            background: #6366f1;
            border-radius: 50%;
            position: absolute;
            bottom: 2px;
            left: 50%;
            transform: translateX(-50%);
        }

        /* Card hover */
        .card-hover {
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .card-hover:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.3);
        }
    </style>

    @yield('head')
</head>
<body class="dark:bg-gray-950 bg-slate-100 dark:text-white text-gray-900 min-h-screen antialiased">

    {{-- Toast Notifications --}}
    @include('partials.toast')

    {{-- Confirm Modal --}}
    @include('partials.confirm-modal')

    {{-- Drawer Overlay --}}
    <div id="drawer-overlay" onclick="closeDrawer()"
         class="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm"></div>

    {{-- Side Drawer --}}
    <aside id="side-drawer"
           class="fixed top-0 left-0 h-full w-72 z-50 dark:bg-gray-900 bg-white
                  border-r dark:border-gray-800 border-gray-200 flex flex-col shadow-2xl">

        <div class="flex items-center justify-between px-5 pt-12 pb-5 border-b dark:border-gray-800 border-gray-200">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 bg-indigo-600 rounded-xl flex items-center justify-center font-bold text-white text-sm shadow-lg shadow-indigo-600/30">
                    FF
                </div>
                <div>
                    <p class="font-bold text-sm dark:text-white text-gray-900">FinFlow</p>
                    <p class="text-xs dark:text-gray-500 text-gray-400">{{ auth()->user()->name ?? 'User' }}</p>
                </div>
            </div>
            <button onclick="closeDrawer()"
                class="w-8 h-8 flex items-center justify-center rounded-lg dark:text-gray-500 text-gray-400
                       dark:hover:text-white hover:text-gray-900 dark:hover:bg-gray-800 hover:bg-gray-100 transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1">
            <p class="text-[10px] font-semibold dark:text-gray-600 text-gray-400 uppercase tracking-widest px-3 mb-2">Main</p>

            @php
                $navItems = [
                    ['route' => 'dashboard',        'label' => 'Dashboard',     'icon' => 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'],
                    ['route' => 'transactions.*',   'label' => 'Transactions',  'icon' => 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'],
                    ['route' => 'budgets.*',        'label' => 'Budgets',       'icon' => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'],
                    ['route' => 'accounts.*',       'label' => 'Accounts',      'icon' => 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z'],
                    ['route' => 'chat.*',           'label' => 'AI Chat',       'icon' => 'M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z'],
                ];
                $toolItems = [
                    ['route' => 'transfers.*', 'label' => 'Transfers',      'badge' => null, 'icon' => 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4'],
                    ['route' => 'reports.*',   'label' => 'Monthly Report', 'badge' => null, 'icon' => 'M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z'],
                    ['route' => 'profile.*',   'label' => 'Profile',        'badge' => null, 'icon' => 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z'],
                ];
            @endphp

            @foreach($navItems as $item)
            @php $active = request()->routeIs($item['route']); @endphp
            <a href="{{ route(rtrim($item['route'], '.*')) }}"
               class="drawer-link flex items-center gap-3 px-3 py-2.5 rounded-xl {{ $active ? 'active' : 'dark:text-gray-300 text-gray-600' }}">
                <div class="w-8 h-8 rounded-lg {{ $active ? 'bg-indigo-600 shadow-lg shadow-indigo-600/30' : 'dark:bg-gray-800 bg-gray-100' }} flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4 {{ $active ? 'text-white' : 'dark:text-gray-400 text-gray-500' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $item['icon'] }}"/>
                    </svg>
                </div>
                <span class="text-sm font-medium">{{ $item['label'] }}</span>
            </a>
            @endforeach

            <div class="pt-3 pb-1">
                <p class="text-[10px] font-semibold dark:text-gray-600 text-gray-400 uppercase tracking-widest px-3 mb-2">Tools</p>
            </div>

            @foreach($toolItems as $item)
            @php $active = request()->routeIs($item['route']); @endphp
            <a href="{{ route(rtrim($item['route'], '.*')) }}"
               class="drawer-link flex items-center gap-3 px-3 py-2.5 rounded-xl {{ $active ? 'active' : 'dark:text-gray-300 text-gray-600' }}">
                <div class="w-8 h-8 rounded-lg {{ $active ? 'bg-indigo-600 shadow-lg shadow-indigo-600/30' : 'dark:bg-gray-800 bg-gray-100' }} flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4 {{ $active ? 'text-white' : 'dark:text-gray-400 text-gray-500' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $item['icon'] }}"/>
                    </svg>
                </div>
                <div class="flex-1"><span class="text-sm font-medium">{{ $item['label'] }}</span></div>
            </a>
            @endforeach
        </nav>

        <div class="px-3 py-4 border-t dark:border-gray-800 border-gray-200">
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit"
                    class="drawer-link w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-red-500 dark:hover:bg-red-500/10 hover:bg-red-50">
                    <div class="w-8 h-8 rounded-lg bg-red-500/10 flex items-center justify-center shrink-0">
                        <svg class="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                        </svg>
                    </div>
                    <span class="text-sm font-medium">Sign Out</span>
                </button>
            </form>
        </div>
    </aside>

    {{-- Main Content --}}
    <main class="max-w-lg mx-auto relative">
        @yield('content')
    </main>

    {{-- Bottom Navigation --}}
    <nav class="fixed bottom-0 left-0 right-0 z-30 dark:bg-gray-900/95 bg-white/95
                backdrop-blur border-t dark:border-gray-800 border-gray-200 pb-safe">
        <div class="max-w-lg mx-auto flex items-center justify-around px-2 pt-2 pb-1">

            @php
                $bottomNav = [
                    ['route' => 'dashboard',      'label' => 'Home',         'icon' => 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'],
                    ['route' => 'transactions.*', 'label' => 'Transactions', 'icon' => 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'],
                    ['route' => 'budgets.*',      'label' => 'Budget',       'icon' => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'],
                ];
            @endphp

            @foreach($bottomNav as $item)
            @php $active = request()->routeIs($item['route']); @endphp
            <a href="{{ route(rtrim($item['route'], '.*')) }}"
               class="relative flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors
                      {{ $active ? 'text-indigo-500' : 'dark:text-gray-500 text-gray-400 hover:text-indigo-500' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="{{ $item['icon'] }}"/>
                </svg>
                <span class="text-[10px] font-medium">{{ $item['label'] }}</span>
                @if($active)<span class="nav-active-dot"></span>@endif
            </a>
            @endforeach

            {{-- FAB --}}
            <a href="{{ route('transactions.create') }}"
               class="flex items-center justify-center w-12 h-12 bg-indigo-600 hover:bg-indigo-500
                      text-white rounded-2xl shadow-lg shadow-indigo-600/40 transition-all active:scale-95 -mt-4">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
            </a>

            @php $moreActive = request()->routeIs('transfers.*') || request()->routeIs('reports.*') || request()->routeIs('accounts.*') || request()->routeIs('chat.*') || request()->routeIs('profile.*'); @endphp
            <button onclick="openDrawer()"
               class="relative flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors
                      {{ $moreActive ? 'text-indigo-500' : 'dark:text-gray-500 text-gray-400 hover:text-indigo-500' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
                </svg>
                <span class="text-[10px] font-medium">More</span>
                @if($moreActive)<span class="nav-active-dot"></span>@endif
            </button>

        </div>
    </nav>

    {{-- PWA Install Banner --}}
    <div id="pwa-install-banner" class="hidden fixed top-0 left-0 right-0 z-50 max-w-lg mx-auto">
        <div class="m-3 dark:bg-gray-900 bg-white border dark:border-gray-700 border-gray-200 rounded-2xl p-4 shadow-2xl flex items-center gap-3">
            <div class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shrink-0">
                <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                </svg>
            </div>
            <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold dark:text-white text-gray-900">Install FinFlow</p>
                <p class="text-xs dark:text-gray-400 text-gray-500">Add to home screen for the best experience</p>
            </div>
            <div class="flex gap-2">
                <button id="pwa-install-btn" class="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold px-3 py-1.5 rounded-lg transition-colors">Install</button>
                <button id="pwa-dismiss-btn" class="dark:text-gray-500 text-gray-400 text-xs px-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
        </div>
    </div>

    <script>
    // Dark / Light Mode
    (function () {
        const root        = document.getElementById('html-root');
        const stored      = localStorage.getItem('finflow-theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const theme       = stored ?? (prefersDark ? 'dark' : 'light');
        applyTheme(theme);
        function applyTheme(t) {
            root.classList.toggle('dark',  t === 'dark');
            root.classList.toggle('light', t !== 'dark');
            localStorage.setItem('finflow-theme', t);
            document.getElementById('theme-color-meta')?.setAttribute('content', t === 'dark' ? '#4f46e5' : '#ffffff');
        }
        window.FinFlowToggleTheme = function () { applyTheme(localStorage.getItem('finflow-theme') === 'dark' ? 'light' : 'dark'); };
        window.FinFlowGetTheme    = function () { return localStorage.getItem('finflow-theme') ?? 'dark'; };
    })();

    // Drawer
    function openDrawer() {
        document.getElementById('side-drawer').classList.add('open');
        document.getElementById('drawer-overlay').classList.add('open');
        document.body.style.overflow = 'hidden';
    }
    function closeDrawer() {
        document.getElementById('side-drawer').classList.remove('open');
        document.getElementById('drawer-overlay').classList.remove('open');
        document.body.style.overflow = '';
    }
    let touchStartX = 0;
    document.getElementById('side-drawer').addEventListener('touchstart', e => { touchStartX = e.touches[0].clientX; });
    document.getElementById('side-drawer').addEventListener('touchend',   e => { if (touchStartX - e.changedTouches[0].clientX > 60) closeDrawer(); });

    // PWA
    let deferredPrompt = null;
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => { navigator.serviceWorker.register('/sw.js').catch(() => {}); });
    }
    window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        deferredPrompt = e;
        const dismissed = localStorage.getItem('pwa-banner-dismissed');
        if (dismissed && Date.now() - parseInt(dismissed) < 7*24*60*60*1000) return;
        if (window.matchMedia('(display-mode: standalone)').matches) return;
        document.getElementById('pwa-install-banner').classList.remove('hidden');
    });
    document.getElementById('pwa-install-btn')?.addEventListener('click', async () => {
        if (!deferredPrompt) return;
        deferredPrompt.prompt();
        await deferredPrompt.userChoice;
        deferredPrompt = null;
        document.getElementById('pwa-install-banner').classList.add('hidden');
    });
    document.getElementById('pwa-dismiss-btn')?.addEventListener('click', () => {
        document.getElementById('pwa-install-banner').classList.add('hidden');
        localStorage.setItem('pwa-banner-dismissed', Date.now());
    });
    </script>

    @yield('scripts')
    @stack('scripts')
</body>
</html>
BLADE
log "layouts/app.blade.php upgraded."

# ─────────────────────────────────────────────────────────────
head "4. ONBOARDING SCREEN"
# ─────────────────────────────────────────────────────────────
info "Creating onboarding view..."

cat > resources/views/onboarding/index.blade.php << 'BLADE'
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>Welcome to FinFlow</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @keyframes float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-10px)} }
        @keyframes fadeUp { from{opacity:0;transform:translateY(20px)} to{opacity:1;transform:translateY(0)} }
        .float { animation: float 3s ease-in-out infinite; }
        .fade-up { animation: fadeUp 0.5s ease-out forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }
        .delay-3 { animation-delay: 0.3s; }
    </style>
</head>
<body class="bg-gray-950 min-h-screen flex items-center justify-center">
<div class="w-full max-w-sm mx-auto px-6 py-10">

    {{-- Slides --}}
    <div id="slides" class="relative overflow-hidden">

        {{-- Slide 1 --}}
        <div class="slide text-center" id="slide-0">
            <div class="w-24 h-24 bg-indigo-600 rounded-3xl flex items-center justify-center mx-auto mb-8 float shadow-2xl shadow-indigo-600/40">
                <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <h1 class="text-2xl font-bold text-white mb-3 fade-up">Welcome to FinFlow</h1>
            <p class="text-gray-500 text-sm leading-relaxed fade-up delay-1">
                Your smart personal finance tracker. Track income, expenses, and budgets all in one place.
            </p>
        </div>

        {{-- Slide 2 --}}
        <div class="slide hidden text-center" id="slide-1">
            <div class="w-24 h-24 bg-emerald-600 rounded-3xl flex items-center justify-center mx-auto mb-8 float shadow-2xl shadow-emerald-600/40">
                <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                </svg>
            </div>
            <h1 class="text-2xl font-bold text-white mb-3">Smart Budgeting</h1>
            <p class="text-gray-500 text-sm leading-relaxed">
                Set monthly budgets per category and get alerts before you overspend. Stay in control always.
            </p>
        </div>

        {{-- Slide 3 --}}
        <div class="slide hidden text-center" id="slide-2">
            <div class="w-24 h-24 bg-purple-600 rounded-3xl flex items-center justify-center mx-auto mb-8 float shadow-2xl shadow-purple-600/40">
                <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                </svg>
            </div>
            <h1 class="text-2xl font-bold text-white mb-3">AI-Powered Insights</h1>
            <p class="text-gray-500 text-sm leading-relaxed">
                Chat with your personal AI financial advisor. Get real tips based on your actual spending data.
            </p>
        </div>

    </div>

    {{-- Dots --}}
    <div class="flex justify-center gap-2 mt-10 mb-8">
        <div class="dot w-6 h-1.5 bg-indigo-500 rounded-full transition-all" data-index="0"></div>
        <div class="dot w-1.5 h-1.5 bg-gray-700 rounded-full transition-all" data-index="1"></div>
        <div class="dot w-1.5 h-1.5 bg-gray-700 rounded-full transition-all" data-index="2"></div>
    </div>

    {{-- Buttons --}}
    <button id="nextBtn"
            onclick="nextSlide()"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-4 rounded-2xl transition active:scale-95 mb-3">
        Continue
    </button>
    <a href="{{ route('dashboard') }}"
       class="block text-center text-gray-600 text-sm hover:text-gray-400 transition py-2">
        Skip
    </a>

</div>

<script>
let current = 0;
const total = 3;

function nextSlide() {
    if (current < total - 1) {
        document.getElementById('slide-' + current).classList.add('hidden');
        current++;
        document.getElementById('slide-' + current).classList.remove('hidden');
        updateDots();
        if (current === total - 1) {
            document.getElementById('nextBtn').textContent = "Get Started";
            document.getElementById('nextBtn').onclick = () => {
                window.location.href = "{{ route('dashboard') }}";
            };
        }
    }
}

function updateDots() {
    document.querySelectorAll('.dot').forEach((dot, i) => {
        dot.classList.toggle('w-6', i === current);
        dot.classList.toggle('w-1.5', i !== current);
        dot.classList.toggle('bg-indigo-500', i === current);
        dot.classList.toggle('bg-gray-700', i !== current);
    });
}
</script>
</body>
</html>
BLADE
log "Onboarding view created."

# Add onboarding route
if ! grep -q "onboarding" routes/web.php; then
cat >> routes/web.php << 'PHP'

// Onboarding
Route::get('/onboarding', function () {
    return view('onboarding.index');
})->name('onboarding')->middleware('auth');
PHP
log "Onboarding route added."
fi

# ─────────────────────────────────────────────────────────────
head "5. IMPROVED DASHBOARD"
# ─────────────────────────────────────────────────────────────
info "Upgrading dashboard view..."

cat > resources/views/dashboard/index.blade.php << 'BLADE'
@extends('layouts.app')
@section('title', 'Dashboard')

@section('content')
<div class="max-w-lg mx-auto pb-28">

    {{-- HERO --}}
    <div class="relative bg-gray-900 border-b border-gray-800 px-5 pt-12 pb-8 overflow-hidden">
        {{-- Background decoration --}}
        <div class="absolute top-0 right-0 w-48 h-48 bg-indigo-600/10 rounded-full blur-3xl pointer-events-none -translate-y-1/2 translate-x-1/4"></div>
        <div class="absolute bottom-0 left-0 w-32 h-32 bg-purple-600/10 rounded-full blur-2xl pointer-events-none"></div>

        {{-- Top row --}}
        <div class="relative flex items-center justify-between mb-8">
            <div>
                <p class="text-gray-600 text-xs uppercase tracking-widest">{{ now()->format('l, M d') }}</p>
                <h1 class="text-white text-lg font-semibold mt-0.5">Hi, {{ auth()->user()->name }} 👋</h1>
            </div>
            <a href="{{ route('profile.index') }}"
               class="w-10 h-10 rounded-2xl bg-indigo-600 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-indigo-600/30">
                {{ strtoupper(substr(auth()->user()->name, 0, 2)) }}
            </a>
        </div>

        {{-- Balance --}}
        <div class="relative mb-2">
            <p class="text-gray-600 text-xs uppercase tracking-widest mb-1">Total Balance</p>
            <h2 class="text-4xl font-bold text-white font-mono tracking-tight">
                {{ auth()->user()->currency }} {{ number_format($totalBalance, 2) }}
            </h2>
        </div>

        {{-- Sparkline --}}
        @if(count($dailySpending) > 0)
        <div class="relative h-10 mb-4">
            <canvas id="sparklineChart"></canvas>
        </div>
        @endif

        {{-- Income / Expenses --}}
        <div class="relative flex gap-3 mt-4">
            <div class="flex-1 bg-gray-800/80 rounded-2xl px-4 py-3 border border-gray-700/50">
                <div class="flex items-center gap-1.5 mb-1">
                    <div class="w-2 h-2 rounded-full bg-emerald-400"></div>
                    <p class="text-gray-500 text-[10px] uppercase tracking-wide">Income</p>
                </div>
                <p class="text-emerald-400 font-bold text-sm font-mono">+ {{ number_format($monthlyIncome, 2) }}</p>
            </div>
            <div class="flex-1 bg-gray-800/80 rounded-2xl px-4 py-3 border border-gray-700/50">
                <div class="flex items-center gap-1.5 mb-1">
                    <div class="w-2 h-2 rounded-full bg-red-400"></div>
                    <p class="text-gray-500 text-[10px] uppercase tracking-wide">Expenses</p>
                </div>
                <p class="text-red-400 font-bold text-sm font-mono">- {{ number_format($monthlyExpense, 2) }}</p>
            </div>
        </div>
    </div>

    <div class="px-4 pt-4 space-y-3">

        {{-- AI Insight --}}
        <div class="bg-gray-900 rounded-2xl p-4 border border-indigo-500/20 card-hover">
            <div class="flex items-start gap-3">
                <div class="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center flex-shrink-0 mt-0.5 shadow-lg shadow-indigo-600/30">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-indigo-400 text-[10px] font-semibold uppercase tracking-widest mb-1">AI Insight</p>
                    @php $net = $monthlyIncome - $monthlyExpense; $sr = $monthlyIncome > 0 ? round(($net / $monthlyIncome) * 100) : 0; @endphp
                    <p class="text-gray-400 text-sm leading-relaxed">
                        @if($monthlyExpense == 0) Add your first transaction to get personalized insights.
                        @elseif($monthlyExpense > $monthlyIncome && $monthlyIncome > 0) ⚠️ You're spending more than you earn this month.
                        @elseif($sr > 20) 🎉 You're saving {{ $sr }}% of your income this month. Great work!
                        @else Net savings: {{ auth()->user()->currency }} {{ number_format($net, 2) }} — {{ $sr }}% savings rate.
                        @endif
                    </p>
                </div>
                <a href="{{ route('chat.index') }}" class="text-indigo-400 text-xs shrink-0 hover:text-indigo-300 transition">Ask AI →</a>
            </div>
        </div>

        {{-- Accounts --}}
        @if($accounts->count() > 0)
        <div>
            <div class="flex items-center justify-between mb-2 px-1">
                <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Accounts</p>
                <a href="{{ route('accounts.index') }}" class="text-indigo-400 text-xs">Manage →</a>
            </div>
            <div class="flex gap-3 overflow-x-auto pb-1" style="-ms-overflow-style:none;scrollbar-width:none;">
                @foreach($accounts as $account)
                <div class="flex-shrink-0 w-44 bg-gray-900 rounded-2xl p-4 border border-gray-800 card-hover relative overflow-hidden">
                    <div class="absolute top-0 right-0 w-16 h-16 rounded-full opacity-10" style="background-color:{{ $account->color }};transform:translate(30%,-30%)"></div>
                    <div class="w-8 h-8 rounded-xl mb-3 flex items-center justify-center" style="background-color:{{ $account->color }}22">
                        <div class="w-3 h-3 rounded-full" style="background-color:{{ $account->color }}"></div>
                    </div>
                    <p class="text-gray-600 text-[10px] uppercase tracking-wide">{{ $account->type_label }}</p>
                    <p class="text-white font-bold text-base font-mono mt-0.5">{{ number_format($account->balance, 2) }}</p>
                    <p class="text-gray-600 text-xs mt-1 truncate">{{ $account->name }}</p>
                </div>
                @endforeach
                <a href="{{ route('accounts.index') }}"
                   class="flex-shrink-0 w-44 bg-gray-900 rounded-2xl border border-dashed border-gray-800
                          flex flex-col items-center justify-center gap-2 text-gray-700
                          hover:border-indigo-500 hover:text-indigo-400 transition min-h-[120px]">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                    </svg>
                    <span class="text-xs">Add Account</span>
                </a>
            </div>
        </div>
        @endif

        {{-- Spending Donut --}}
        @if($spendingByCategory->count() > 0)
        <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
            <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest mb-4">Spending This Month</p>
            <div class="flex items-center gap-4">
                <div class="w-28 h-28 flex-shrink-0 relative">
                    <canvas id="donutChart"></canvas>
                    <div class="absolute inset-0 flex items-center justify-center">
                        <div class="text-center">
                            <p class="text-white font-bold text-xs font-mono">{{ number_format($monthlyExpense, 0) }}</p>
                            <p class="text-gray-600 text-[9px]">total</p>
                        </div>
                    </div>
                </div>
                <div class="flex-1 space-y-2">
                    @foreach($spendingByCategory->take(4) as $cat)
                    <div class="flex items-center justify-between gap-2">
                        <div class="flex items-center gap-2 min-w-0">
                            <div class="w-2 h-2 rounded-full flex-shrink-0" style="background-color:{{ $cat['color'] }}"></div>
                            <span class="text-xs text-gray-500 truncate">{{ $cat['name'] }}</span>
                        </div>
                        <span class="text-xs font-mono text-gray-300 flex-shrink-0">{{ number_format($cat['total'], 0) }}</span>
                    </div>
                    @endforeach
                </div>
            </div>
        </div>
        @endif

        {{-- Budgets --}}
        @if($budgets->count() > 0)
        <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
            <div class="flex items-center justify-between mb-4">
                <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Budgets</p>
                <a href="{{ route('budgets.index') }}" class="text-indigo-400 text-xs">See all →</a>
            </div>
            <div class="space-y-3">
                @foreach($budgets->take(3) as $budget)
                @php
                    $pct   = $budget->percentage;
                    $color = $budget->status_color;
                    $bar   = match($color) { 'red' => 'bg-red-500', 'amber' => 'bg-amber-500', default => 'bg-emerald-500' };
                    $txt   = match($color) { 'red' => 'text-red-400', 'amber' => 'text-amber-400', default => 'text-emerald-400' };
                @endphp
                <div>
                    <div class="flex items-center justify-between mb-1.5">
                        <span class="text-sm text-gray-300">{{ $budget->category->name }}</span>
                        <span class="text-xs font-mono {{ $txt }}">{{ $pct }}%</span>
                    </div>
                    <div class="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                        <div class="{{ $bar }} h-full rounded-full progress-bar" style="width:{{ $pct }}%"></div>
                    </div>
                    <div class="flex justify-between mt-1">
                        <span class="text-[10px] text-gray-700">{{ number_format($budget->spent, 0) }} spent</span>
                        <span class="text-[10px] text-gray-700">{{ number_format($budget->limit_amount, 0) }} limit</span>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Recent Transactions --}}
        <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
            <div class="flex items-center justify-between mb-4">
                <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Recent Transactions</p>
                <a href="{{ route('transactions.index') }}" class="text-indigo-400 text-xs">See all →</a>
            </div>
            @if($recentTransactions->count() === 0)
            <div class="text-center py-8">
                <div class="w-12 h-12 rounded-2xl bg-gray-800 flex items-center justify-center mx-auto mb-3">
                    <svg class="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                    </svg>
                </div>
                <p class="text-gray-700 text-sm mb-1">No transactions yet</p>
                <a href="{{ route('transactions.create') }}" class="text-indigo-400 text-xs">Add your first one →</a>
            </div>
            @else
            <div class="space-y-3">
                @foreach($recentTransactions as $tx)
                <div class="flex items-center gap-3 group">
                    <div class="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                         style="background-color:{{ ($tx->category->color ?? '#6366f1') }}22">
                        <div class="w-3 h-3 rounded-full" style="background-color:{{ $tx->category->color ?? '#6366f1' }}"></div>
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-sm text-gray-200 truncate font-medium">{{ $tx->description ?: $tx->category->name }}</p>
                        <p class="text-xs text-gray-600">{{ $tx->date->format('M d') }} · {{ $tx->account->name }}</p>
                    </div>
                    <div class="text-right flex-shrink-0">
                        <span class="font-mono font-semibold text-sm {{ $tx->type === 'income' ? 'text-emerald-400' : 'text-red-400' }}">
                            {{ $tx->formatted_amount }}
                        </span>
                    </div>
                </div>
                @endforeach
            </div>
            @endif
        </div>

    </div>
</div>
@endsection

@push('scripts')
{{-- Donut chart --}}
@if($spendingByCategory->count() > 0)
<script>
const ctx = document.getElementById('donutChart')?.getContext('2d');
if (ctx) {
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: {!! json_encode($spendingByCategory->pluck('name')) !!},
            datasets: [{
                data: {!! json_encode($spendingByCategory->pluck('total')) !!},
                backgroundColor: {!! json_encode($spendingByCategory->pluck('color')) !!},
                borderWidth: 0, hoverOffset: 4,
            }]
        },
        options: {
            cutout: '75%',
            plugins: { legend: { display: false }, tooltip: { enabled: false } },
            animation: { animateRotate: true, duration: 900 },
        }
    });
}
</script>
@endif

{{-- Sparkline --}}
@if(count($dailySpending) > 0)
<script>
const spCtx = document.getElementById('sparklineChart')?.getContext('2d');
if (spCtx) {
    const days   = {!! json_encode(array_keys($dailySpending->toArray())) !!};
    const values = {!! json_encode(array_values($dailySpending->toArray())) !!};
    const grad   = spCtx.createLinearGradient(0, 0, 0, 40);
    grad.addColorStop(0, 'rgba(99,102,241,0.4)');
    grad.addColorStop(1, 'rgba(99,102,241,0)');
    new Chart(spCtx, {
        type: 'line',
        data: {
            labels: days,
            datasets: [{
                data: values,
                borderColor: '#6366f1',
                backgroundColor: grad,
                borderWidth: 1.5,
                fill: true,
                tension: 0.4,
                pointRadius: 0,
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false }, tooltip: { enabled: false } },
            scales: { x: { display: false }, y: { display: false, beginAtZero: true } },
            animation: { duration: 800 }
        }
    });
}
</script>
@endif
@endpush
BLADE
log "Dashboard upgraded."

# ─────────────────────────────────────────────────────────────
head "6. UPGRADED TRANSACTION LIST"
# ─────────────────────────────────────────────────────────────
info "Upgrading transactions index view..."

cat > resources/views/transactions/index.blade.php << 'BLADE'
@extends('layouts.app')
@section('title', 'Transactions')

@section('content')
<div class="max-w-lg mx-auto">

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
    <div class="px-4 py-4 pb-28">
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
BLADE
log "Transactions index upgraded."

# ─────────────────────────────────────────────────────────────
head "7. DARK MODE SYNC TO DATABASE"
# ─────────────────────────────────────────────────────────────
info "Adding dark mode sync route + controller method..."

cat >> app/Http/Controllers/ProfileController.php << 'PHP'

    public function toggleDarkMode()
    {
        $user = Auth::user();
        $user->update(['dark_mode' => ! $user->dark_mode]);
        return response()->json(['dark_mode' => $user->dark_mode]);
    }
PHP

if ! grep -q "profile.darkmode" routes/web.php; then
cat >> routes/web.php << 'PHP'

// Dark mode sync
Route::post('/profile/dark-mode', [App\Http\Controllers\ProfileController::class, 'toggleDarkMode'])->name('profile.darkmode')->middleware('auth');
PHP
log "Dark mode sync route added."
fi

# ─────────────────────────────────────────────────────────────
head "8. TRANSFERS — ADD SEARCH"
# ─────────────────────────────────────────────────────────────
info "Upgrading TransferController with search..."

cat > app/Http/Controllers/TransferController.php << 'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\Account;
use App\Models\Transfer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransferController extends Controller
{
    public function index(Request $request)
    {
        $query = Transfer::with(['fromAccount', 'toAccount'])
            ->where('user_id', auth()->id())
            ->orderByDesc('transfer_date')
            ->orderByDesc('created_at');

        // Search filter
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('note', 'LIKE', "%{$search}%")
                  ->orWhereHas('fromAccount', fn($q2) => $q2->where('name', 'LIKE', "%{$search}%"))
                  ->orWhereHas('toAccount',   fn($q2) => $q2->where('name', 'LIKE', "%{$search}%"));
            });
        }

        // Date filter
        if ($request->filled('date_from')) {
            $query->whereDate('transfer_date', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('transfer_date', '<=', $request->date_to);
        }

        $transfers = $query->paginate(15)->withQueryString();
        $accounts  = Account::where('user_id', auth()->id())->orderBy('name')->get();

        return view('transfers.index', compact('transfers', 'accounts'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'from_account_id' => ['required', 'exists:accounts,id'],
            'to_account_id'   => ['required', 'exists:accounts,id', 'different:from_account_id'],
            'amount'          => ['required', 'numeric', 'min:0.01'],
            'note'            => ['nullable', 'string', 'max:255'],
            'transfer_date'   => ['required', 'date'],
        ]);

        $fromAccount = Account::where('id', $validated['from_account_id'])
            ->where('user_id', auth()->id())->firstOrFail();
        $toAccount   = Account::where('id', $validated['to_account_id'])
            ->where('user_id', auth()->id())->firstOrFail();

        if ($fromAccount->balance < $validated['amount']) {
            return back()->withInput()
                ->withErrors(['amount' => 'Insufficient balance in the source account.']);
        }

        DB::transaction(function () use ($validated, $fromAccount, $toAccount) {
            $fromAccount->decrement('balance', $validated['amount']);
            $toAccount->increment('balance', $validated['amount']);
            Transfer::create([
                'user_id'         => auth()->id(),
                'from_account_id' => $fromAccount->id,
                'to_account_id'   => $toAccount->id,
                'amount'          => $validated['amount'],
                'note'            => $validated['note'] ?? null,
                'transfer_date'   => $validated['transfer_date'],
            ]);
        });

        return redirect()->route('transfers.index')->with('success', 'Transfer completed!');
    }

    public function destroy(Transfer $transfer)
    {
        abort_if($transfer->user_id !== auth()->id(), 403);

        DB::transaction(function () use ($transfer) {
            $transfer->fromAccount->increment('balance', $transfer->amount);
            $transfer->toAccount->decrement('balance', $transfer->amount);
            $transfer->delete();
        });

        return back()->with('success', 'Transfer reversed and deleted.');
    }
}
PHP
log "TransferController upgraded with search."

# ─────────────────────────────────────────────────────────────
head "9. REPORTS — ADD EXPORT CSV"
# ─────────────────────────────────────────────────────────────
info "Adding export to ReportController..."

cat >> app/Http/Controllers/ReportController.php << 'PHP'

    public function exportCsv(Request $request)
    {
        $userId    = auth()->id();
        $year      = (int) $request->get('year',  now()->year);
        $month     = (int) $request->get('month', now()->month);
        $startDate = \Carbon\Carbon::create($year, $month, 1)->startOfMonth();
        $endDate   = $startDate->copy()->endOfMonth();

        $accountIds   = \App\Models\Account::where('user_id', $userId)->pluck('id');
        $transactions = \App\Models\Transaction::with(['category', 'account'])
            ->whereIn('account_id', $accountIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->orderByDesc('date')
            ->get();

        $csv  = "Date,Account,Category,Type,Amount,Description\n";
        foreach ($transactions as $t) {
            $csv .= implode(',', [
                $t->date->format('Y-m-d'),
                '"' . $t->account->name . '"',
                '"' . $t->category->name . '"',
                $t->type,
                $t->amount,
                '"' . ($t->description ?? '') . '"',
            ]) . "\n";
        }

        $filename = "finflow-report-{$year}-{$month}.csv";
        return response($csv, 200, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
PHP

if ! grep -q "reports.export" routes/web.php; then
cat >> routes/web.php << 'PHP'

// Report export
Route::get('/reports/export', [App\Http\Controllers\ReportController::class, 'exportCsv'])->name('reports.export')->middleware('auth');
PHP
log "Report export route added."
fi

# ─────────────────────────────────────────────────────────────
head "10. FINAL ARTISAN CLEANUP"
# ─────────────────────────────────────────────────────────────
info "Clearing all caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
log "All caches cleared."

# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        🎉 All Upgrades Applied!                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}What was upgraded:${NC}"
echo "  1.  ✅ Toast notifications (all pages)"
echo "  2.  ✅ Custom confirm/delete modal"
echo "  3.  ✅ Main layout (Chart.js, animations, nav dots)"
echo "  4.  ✅ Onboarding screen (/onboarding)"
echo "  5.  ✅ Dashboard hero + sparkline + card hover effects"
echo "  6.  ✅ Transactions list redesign"
echo "  7.  ✅ Dark mode syncs to database"
echo "  8.  ✅ Transfers — search + date filter"
echo "  9.  ✅ Reports — CSV export button"
echo "  10. ✅ All caches cleared"
echo ""
echo -e "  ${BLUE}Visit these new pages:${NC}"
echo "  → /onboarding       — show to new users after register"
echo "  → /reports/export   — download CSV report"
echo "  → /transfers        — now has search bar"
echo ""
echo -e "  ${YELLOW}Tip:${NC} In AuthController register(), redirect to /onboarding instead of /dashboard"
echo ""
