#!/bin/bash

# ============================================================
#  FinFlow — Responsive UI Improvement Script
#  Run from: C:\laragon\www\Phone-app
#  Usage: bash finflow-improve.sh
# ============================================================

set -e
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "  ███████╗██╗███╗   ██╗███████╗██╗      ██████╗ ██╗    ██╗"
echo "  ██╔════╝██║████╗  ██║██╔════╝██║     ██╔═══██╗██║    ██║"
echo "  █████╗  ██║██╔██╗ ██║█████╗  ██║     ██║   ██║██║ █╗ ██║"
echo "  ██╔══╝  ██║██║╚██╗██║██╔══╝  ██║     ██║   ██║██║███╗██║"
echo "  ██║     ██║██║ ╚████║██║     ███████╗╚██████╔╝╚███╔███╔╝"
echo "  ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ "
echo -e "${NC}"
echo -e "${GREEN}  Responsive UI Upgrade — All Devices Supported${NC}"
echo "  --------------------------------------------------------"
echo ""

# ── 1. MAIN LAYOUT — app.blade.php ───────────────────────────
echo -e "${YELLOW}[1/6] Patching layouts/app.blade.php ...${NC}"
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
                    screens: {
                        'xs': '375px',
                    },
                    animation: {
                        'slide-up': 'slideUp 0.3s ease-out',
                        'fade-in':  'fadeIn 0.4s ease-out',
                        'scale-in': 'scaleIn 0.2s ease-out',
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
        /* ── Safe area / PWA ───────────────────────────────────── */
        .pb-safe { padding-bottom: max(1.75rem, env(safe-area-inset-bottom)); }

        /* ── Smooth transitions ────────────────────────────────── */
        *, *::before, *::after {
            transition-property: background-color, border-color, color;
            transition-duration: 200ms;
            transition-timing-function: ease;
        }

        /* ── Scrollbar ─────────────────────────────────────────── */
        ::-webkit-scrollbar { width: 4px; height: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #374151; border-radius: 2px; }

        /* ── Drawer ────────────────────────────────────────────── */
        #side-drawer {
            transform: translateX(-100%);
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        #side-drawer.open { transform: translateX(0); }
        #drawer-overlay { opacity: 0; pointer-events: none; transition: opacity 0.3s ease; }
        #drawer-overlay.open { opacity: 1; pointer-events: all; }

        .drawer-link { transition: background-color 0.15s ease, color 0.15s ease; }
        .drawer-link:hover { background-color: rgba(99,102,241,0.08); }
        .drawer-link.active { background-color: rgba(99,102,241,0.12); color: #818cf8; }

        /* ── Progress bar ──────────────────────────────────────── */
        @keyframes progressFill { from { width: 0%; } }
        .progress-bar { animation: progressFill 0.8s ease-out; }

        /* ── Skeleton ──────────────────────────────────────────── */
        @keyframes shimmer {
            0%   { background-position: -200% 0; }
            100% { background-position:  200% 0; }
        }
        .skeleton {
            background: linear-gradient(90deg, #1f2937 25%, #374151 50%, #1f2937 75%);
            background-size: 200% 100%;
            animation: shimmer 1.5s infinite;
            border-radius: 0.5rem;
        }

        /* ── Nav dot ───────────────────────────────────────────── */
        .nav-active-dot {
            width: 4px; height: 4px; background: #6366f1;
            border-radius: 50%; position: absolute;
            bottom: 2px; left: 50%; transform: translateX(-50%);
        }

        /* ── Card hover ────────────────────────────────────────── */
        .card-hover { transition: transform 0.2s ease, box-shadow 0.2s ease; }
        .card-hover:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.3); }

        /* ════════════════════════════════════════════════════════
           RESPONSIVE — Desktop sidebar layout
           ════════════════════════════════════════════════════════ */

        /* Desktop: show persistent sidebar, hide bottom nav */
        @media (min-width: 1024px) {
            #desktop-sidebar   { display: flex !important; }
            #bottom-nav        { display: none !important; }
            #drawer-overlay    { display: none !important; }
            #side-drawer       { display: none !important; }
            #main-content-wrap {
                margin-left: 260px;
                max-width: none;
                padding: 0 2rem;
            }
            .page-inner {
                max-width: 900px;
                margin: 0 auto;
            }
        }

        /* Tablet: wider card area, keep bottom nav */
        @media (min-width: 640px) and (max-width: 1023px) {
            #main-content-wrap { max-width: 720px; margin: 0 auto; padding: 0 1.5rem; }
        }

        /* Desktop sidebar */
        #desktop-sidebar {
            display: none;
            position: fixed;
            top: 0; left: 0;
            width: 260px; height: 100vh;
            flex-direction: column;
            background: #111827;
            border-right: 1px solid #1f2937;
            z-index: 40;
            overflow-y: auto;
        }
    </style>

    @yield('head')
</head>
<body class="dark:bg-gray-950 bg-slate-100 dark:text-white text-gray-900 min-h-screen antialiased">

    {{-- Toast --}}
    @include('partials.toast')

    {{-- Confirm Modal --}}
    @include('partials.confirm-modal')

    {{-- ══════════════════════════════════════════════════════
         DESKTOP SIDEBAR (lg+)
         ══════════════════════════════════════════════════════ --}}
    <aside id="desktop-sidebar">
        <div class="px-5 pt-8 pb-5 border-b border-gray-800 flex items-center gap-3">
            <div class="w-9 h-9 bg-indigo-600 rounded-xl flex items-center justify-center font-bold text-white text-sm shadow-lg shadow-indigo-600/30">FF</div>
            <div>
                <p class="font-bold text-sm text-white">FinFlow</p>
                <p class="text-xs text-gray-500">{{ auth()->user()->name ?? 'User' }}</p>
            </div>
        </div>

        <nav class="flex-1 px-3 py-4 space-y-1">
            <p class="text-[10px] font-semibold text-gray-600 uppercase tracking-widest px-3 mb-2">Main</p>
            @php
                $allNav = [
                    ['route' => 'dashboard',       'match' => 'dashboard',       'label' => 'Dashboard',    'icon' => 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'],
                    ['route' => 'transactions.index','match' => 'transactions.*', 'label' => 'Transactions', 'icon' => 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'],
                    ['route' => 'budgets.index',   'match' => 'budgets.*',       'label' => 'Budgets',      'icon' => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'],
                    ['route' => 'accounts.index',  'match' => 'accounts.*',      'label' => 'Accounts',     'icon' => 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z'],
                    ['route' => 'chat.index',      'match' => 'chat.*',          'label' => 'AI Chat',      'icon' => 'M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z'],
                    ['route' => 'transfers.index', 'match' => 'transfers.*',     'label' => 'Transfers',    'icon' => 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4'],
                    ['route' => 'reports.index',   'match' => 'reports.*',       'label' => 'Reports',      'icon' => 'M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z'],
                    ['route' => 'profile.index',   'match' => 'profile.*',       'label' => 'Profile',      'icon' => 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z'],
                ];
            @endphp
            @foreach($allNav as $item)
            @php $active = request()->routeIs($item['match']); @endphp
            <a href="{{ route($item['route']) }}"
               class="drawer-link flex items-center gap-3 px-3 py-2.5 rounded-xl {{ $active ? 'active' : 'text-gray-300' }}">
                <div class="w-8 h-8 rounded-lg {{ $active ? 'bg-indigo-600' : 'bg-gray-800' }} flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4 {{ $active ? 'text-white' : 'text-gray-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $item['icon'] }}"/>
                    </svg>
                </div>
                <span class="text-sm font-medium">{{ $item['label'] }}</span>
            </a>
            @endforeach
        </nav>

        <div class="px-3 py-4 border-t border-gray-800">
            <a href="{{ route('transactions.create') }}"
               class="flex items-center gap-3 px-3 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white transition mb-3">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
                <span class="text-sm font-semibold">Add Transaction</span>
            </a>
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit"
                    class="drawer-link w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-red-500 hover:bg-red-500/10">
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

    {{-- ══════════════════════════════════════════════════════
         MOBILE DRAWER (hidden on lg+)
         ══════════════════════════════════════════════════════ --}}
    <div id="drawer-overlay" onclick="closeDrawer()"
         class="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"></div>

    <aside id="side-drawer"
           class="fixed top-0 left-0 h-full w-72 z-50 bg-gray-900
                  border-r border-gray-800 flex flex-col shadow-2xl lg:hidden">
        <div class="flex items-center justify-between px-5 pt-12 pb-5 border-b border-gray-800">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 bg-indigo-600 rounded-xl flex items-center justify-center font-bold text-white text-sm">FF</div>
                <div>
                    <p class="font-bold text-sm text-white">FinFlow</p>
                    <p class="text-xs text-gray-500">{{ auth()->user()->name ?? 'User' }}</p>
                </div>
            </div>
            <button onclick="closeDrawer()" class="w-8 h-8 flex items-center justify-center rounded-lg text-gray-500 hover:text-white hover:bg-gray-800 transition">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1">
            @php
                $navItems = [
                    ['route' => 'dashboard',        'match' => 'dashboard',       'label' => 'Dashboard',    'icon' => 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'],
                    ['route' => 'transactions.index','match' => 'transactions.*', 'label' => 'Transactions', 'icon' => 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'],
                    ['route' => 'budgets.index',    'match' => 'budgets.*',       'label' => 'Budgets',      'icon' => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'],
                    ['route' => 'accounts.index',   'match' => 'accounts.*',      'label' => 'Accounts',     'icon' => 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z'],
                    ['route' => 'chat.index',       'match' => 'chat.*',          'label' => 'AI Chat',      'icon' => 'M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z'],
                    ['route' => 'transfers.index',  'match' => 'transfers.*',     'label' => 'Transfers',    'icon' => 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4'],
                    ['route' => 'reports.index',    'match' => 'reports.*',       'label' => 'Reports',      'icon' => 'M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z'],
                    ['route' => 'profile.index',    'match' => 'profile.*',       'label' => 'Profile',      'icon' => 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z'],
                ];
            @endphp
            @foreach($navItems as $item)
            @php $active = request()->routeIs($item['match']); @endphp
            <a href="{{ route($item['route']) }}"
               class="drawer-link flex items-center gap-3 px-3 py-2.5 rounded-xl {{ $active ? 'active' : 'text-gray-300' }}">
                <div class="w-8 h-8 rounded-lg {{ $active ? 'bg-indigo-600' : 'bg-gray-800' }} flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4 {{ $active ? 'text-white' : 'text-gray-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $item['icon'] }}"/>
                    </svg>
                </div>
                <span class="text-sm font-medium">{{ $item['label'] }}</span>
            </a>
            @endforeach
        </nav>

        <div class="px-3 py-4 border-t border-gray-800">
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit"
                    class="drawer-link w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-red-500 hover:bg-red-500/10">
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

    {{-- ══════════════════════════════════════════════════════
         MAIN CONTENT
         ══════════════════════════════════════════════════════ --}}
    <div id="main-content-wrap" class="max-w-lg mx-auto relative transition-all duration-300">
        <div class="page-inner">
            @yield('content')
        </div>
    </div>

    {{-- ══════════════════════════════════════════════════════
         BOTTOM NAV — mobile/tablet only (hidden lg+)
         ══════════════════════════════════════════════════════ --}}
    <nav id="bottom-nav"
         class="fixed bottom-0 left-0 right-0 z-30 bg-gray-900/95
                backdrop-blur border-t border-gray-800 pb-safe lg:hidden">
        <div class="max-w-lg mx-auto flex items-center justify-around px-2 pt-2 pb-1">
            @php
                $bottomNav = [
                    ['route' => 'dashboard',        'match' => 'dashboard',      'label' => 'Home',         'icon' => 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'],
                    ['route' => 'transactions.index','match' => 'transactions.*', 'label' => 'Transactions', 'icon' => 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'],
                    ['route' => 'budgets.index',    'match' => 'budgets.*',      'label' => 'Budget',       'icon' => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'],
                ];
            @endphp
            @foreach($bottomNav as $item)
            @php $active = request()->routeIs($item['match']); @endphp
            <a href="{{ route($item['route']) }}"
               class="relative flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors
                      {{ $active ? 'text-indigo-500' : 'text-gray-500 hover:text-indigo-500' }}">
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

            @php $moreActive = request()->routeIs('transfers.*','reports.*','accounts.*','chat.*','profile.*'); @endphp
            <button onclick="openDrawer()"
               class="relative flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors
                      {{ $moreActive ? 'text-indigo-500' : 'text-gray-500 hover:text-indigo-500' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
                </svg>
                <span class="text-[10px] font-medium">More</span>
                @if($moreActive)<span class="nav-active-dot"></span>@endif
            </button>
        </div>
    </nav>

    {{-- PWA Install Banner --}}
    <div id="pwa-install-banner" class="hidden fixed top-0 left-0 right-0 z-50 max-w-lg mx-auto lg:max-w-sm lg:left-auto lg:right-4 lg:top-4">
        <div class="m-3 bg-gray-900 border border-gray-700 rounded-2xl p-4 shadow-2xl flex items-center gap-3">
            <div class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shrink-0">
                <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                </svg>
            </div>
            <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-white">Install FinFlow</p>
                <p class="text-xs text-gray-400">Add to home screen</p>
            </div>
            <div class="flex gap-2">
                <button id="pwa-install-btn" class="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold px-3 py-1.5 rounded-lg transition">Install</button>
                <button id="pwa-dismiss-btn" class="text-gray-500 text-xs px-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
        </div>
    </div>

    <script>
    // Dark / Light Mode
    (function () {
        const root = document.getElementById('html-root');
        const stored = localStorage.getItem('finflow-theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const theme = stored ?? (prefersDark ? 'dark' : 'light');
        applyTheme(theme);
        function applyTheme(t) {
            root.classList.toggle('dark', t === 'dark');
            root.classList.toggle('light', t !== 'dark');
            localStorage.setItem('finflow-theme', t);
            document.getElementById('theme-color-meta')?.setAttribute('content', t === 'dark' ? '#4f46e5' : '#ffffff');
        }
        window.FinFlowToggleTheme = function () { applyTheme(localStorage.getItem('finflow-theme') === 'dark' ? 'light' : 'dark'); };
        window.FinFlowGetTheme    = function () { return localStorage.getItem('finflow-theme') ?? 'dark'; };
    })();

    // Mobile Drawer
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
        e.preventDefault(); deferredPrompt = e;
        const dismissed = localStorage.getItem('pwa-banner-dismissed');
        if (dismissed && Date.now() - parseInt(dismissed) < 7*24*60*60*1000) return;
        if (window.matchMedia('(display-mode: standalone)').matches) return;
        document.getElementById('pwa-install-banner').classList.remove('hidden');
    });
    document.getElementById('pwa-install-btn')?.addEventListener('click', async () => {
        if (!deferredPrompt) return;
        deferredPrompt.prompt(); await deferredPrompt.userChoice;
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
echo -e "${GREEN}  ✓ layouts/app.blade.php updated${NC}"

# ── 2. DASHBOARD ─────────────────────────────────────────────
echo -e "${YELLOW}[2/6] Patching dashboard/index.blade.php ...${NC}"
cat > resources/views/dashboard/index.blade.php << 'BLADE'
@extends('layouts.app')
@section('title', 'Dashboard')

@section('content')
<div class="pb-28 lg:pb-8">

    {{-- HERO --}}
    <div class="relative bg-gray-900 border-b border-gray-800 px-4 sm:px-6 lg:px-8 pt-10 lg:pt-8 pb-8 overflow-hidden">
        <div class="absolute top-0 right-0 w-48 h-48 bg-indigo-600/10 rounded-full blur-3xl pointer-events-none -translate-y-1/2 translate-x-1/4"></div>
        <div class="absolute bottom-0 left-0 w-32 h-32 bg-purple-600/10 rounded-full blur-2xl pointer-events-none"></div>

        <div class="relative flex items-center justify-between mb-6">
            <div>
                <p class="text-gray-600 text-xs uppercase tracking-widest">{{ now()->format('l, M d') }}</p>
                <h1 class="text-white text-lg font-semibold mt-0.5">Hi, {{ auth()->user()->name }} 👋</h1>
            </div>
            <a href="{{ route('profile.index') }}"
               class="w-10 h-10 rounded-2xl bg-indigo-600 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-indigo-600/30">
                {{ strtoupper(substr(auth()->user()->name, 0, 2)) }}
            </a>
        </div>

        <div class="relative mb-2">
            <p class="text-gray-600 text-xs uppercase tracking-widest mb-1">Total Balance</p>
            <h2 class="text-3xl sm:text-4xl font-bold text-white font-mono tracking-tight">
                {{ auth()->user()->currency }} {{ number_format($totalBalance, 2) }}
            </h2>
        </div>

        @if(count($dailySpending) > 0)
        <div class="relative h-10 mb-4">
            <canvas id="sparklineChart"></canvas>
        </div>
        @endif

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

    <div class="px-4 sm:px-6 lg:px-8 pt-4 space-y-4">

        {{-- Desktop: 2-col grid for cards --}}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {{-- AI Insight --}}
            <div class="bg-gray-900 rounded-2xl p-4 border border-indigo-500/20 card-hover">
                <div class="flex items-start gap-3">
                    <div class="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center flex-shrink-0 mt-0.5">
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
        </div>

        {{-- Accounts --}}
        @if($accounts->count() > 0)
        <div>
            <div class="flex items-center justify-between mb-2 px-1">
                <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Accounts</p>
                <a href="{{ route('accounts.index') }}" class="text-indigo-400 text-xs">Manage →</a>
            </div>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                @foreach($accounts as $account)
                <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800 card-hover relative overflow-hidden">
                    <div class="absolute top-0 right-0 w-16 h-16 rounded-full opacity-10" style="background-color:{{ $account->color }};transform:translate(30%,-30%)"></div>
                    <div class="w-8 h-8 rounded-xl mb-3 flex items-center justify-center" style="background-color:{{ $account->color }}22">
                        <div class="w-3 h-3 rounded-full" style="background-color:{{ $account->color }}"></div>
                    </div>
                    <p class="text-gray-600 text-[10px] uppercase tracking-wide">{{ $account->type_label }}</p>
                    <p class="text-white font-bold text-base font-mono mt-0.5">{{ number_format($account->balance, 2) }}</p>
                    <p class="text-gray-600 text-xs mt-1 truncate">{{ $account->name }}</p>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Desktop 2-col: Budgets + Recent Transactions --}}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {{-- Budgets --}}
            @if($budgets->count() > 0)
            <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
                <div class="flex items-center justify-between mb-4">
                    <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Budgets</p>
                    <a href="{{ route('budgets.index') }}" class="text-indigo-400 text-xs">See all →</a>
                </div>
                <div class="space-y-3">
                    @foreach($budgets->take(4) as $budget)
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
                    <p class="text-gray-700 text-sm mb-1">No transactions yet</p>
                    <a href="{{ route('transactions.create') }}" class="text-indigo-400 text-xs">Add your first one →</a>
                </div>
                @else
                <div class="space-y-3">
                    @foreach($recentTransactions as $tx)
                    <div class="flex items-center gap-3">
                        <div class="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                             style="background-color:{{ ($tx->category->color ?? '#6366f1') }}18">
                            <div class="w-3 h-3 rounded-full" style="background-color:{{ $tx->category->color ?? '#6366f1' }}"></div>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm text-gray-200 truncate font-medium">{{ $tx->description ?: $tx->category->name }}</p>
                            <p class="text-xs text-gray-600">{{ $tx->date->format('M d') }} · {{ $tx->account->name }}</p>
                        </div>
                        <span class="font-mono font-bold text-sm {{ $tx->type === 'income' ? 'text-emerald-400' : 'text-red-400' }}">
                            {{ $tx->formatted_amount }}
                        </span>
                    </div>
                    @endforeach
                </div>
                @endif
            </div>

        </div>
    </div>
</div>
@endsection

@push('scripts')
@if($spendingByCategory->count() > 0)
<script>
const ctx = document.getElementById('donutChart')?.getContext('2d');
if (ctx) {
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: {!! json_encode($spendingByCategory->pluck('name')) !!},
            datasets: [{ data: {!! json_encode($spendingByCategory->pluck('total')) !!}, backgroundColor: {!! json_encode($spendingByCategory->pluck('color')) !!}, borderWidth: 0, hoverOffset: 4 }]
        },
        options: { cutout: '75%', plugins: { legend: { display: false }, tooltip: { enabled: false } }, animation: { animateRotate: true, duration: 900 } }
    });
}
</script>
@endif
@if(count($dailySpending) > 0)
<script>
const spCtx = document.getElementById('sparklineChart')?.getContext('2d');
if (spCtx) {
    const grad = spCtx.createLinearGradient(0, 0, 0, 40);
    grad.addColorStop(0, 'rgba(99,102,241,0.4)');
    grad.addColorStop(1, 'rgba(99,102,241,0)');
    new Chart(spCtx, {
        type: 'line',
        data: { labels: {!! json_encode(array_keys($dailySpending->toArray())) !!}, datasets: [{ data: {!! json_encode(array_values($dailySpending->toArray())) !!}, borderColor: '#6366f1', backgroundColor: grad, borderWidth: 1.5, fill: true, tension: 0.4, pointRadius: 0 }] },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { enabled: false } }, scales: { x: { display: false }, y: { display: false, beginAtZero: true } }, animation: { duration: 800 } }
    });
}
</script>
@endif
@endpush
BLADE
echo -e "${GREEN}  ✓ dashboard/index.blade.php updated${NC}"

# ── 3. AUTH LAYOUT ───────────────────────────────────────────
echo -e "${YELLOW}[3/6] Patching layouts/auth.blade.php ...${NC}"
cat > resources/views/layouts/auth.blade.php << 'BLADE'
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>@yield('title', 'FinFlow') – FinFlow</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="min-h-screen bg-gray-950 flex items-center justify-center p-4">
    <div class="w-full max-w-sm">
        <div class="text-center mb-8">
            <div class="inline-flex items-center justify-center w-14 h-14 bg-indigo-600 rounded-2xl mb-4">
                <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <h1 class="text-2xl font-bold text-white">FinFlow</h1>
            <p class="text-gray-600 text-sm mt-1">Smart money management</p>
        </div>
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-6">
            @yield('content')
        </div>
    </div>
</body>
</html>
BLADE
echo -e "${GREEN}  ✓ layouts/auth.blade.php updated${NC}"

# ── 4. TRANSACTIONS INDEX ─────────────────────────────────────
echo -e "${YELLOW}[4/6] Patching transactions/index.blade.php ...${NC}"
sed -i 's/class="max-w-lg mx-auto"/class="w-full"/' resources/views/transactions/index.blade.php 2>/dev/null || true
sed -i 's/class="px-4 py-4 pb-28"/class="px-4 sm:px-6 lg:px-8 py-4 pb-28 lg:pb-8"/' resources/views/transactions/index.blade.php 2>/dev/null || true
echo -e "${GREEN}  ✓ transactions/index.blade.php updated${NC}"

# ── 5. CLEAR CACHES ──────────────────────────────────────────
echo -e "${YELLOW}[5/6] Clearing caches ...${NC}"
php artisan view:clear
php artisan cache:clear
php artisan config:clear
echo -e "${GREEN}  ✓ Caches cleared${NC}"

# ── 6. DONE ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅  FinFlow Responsive Upgrade Complete!   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "  📱 Mobile  → Bottom nav + hamburger drawer"
echo "  💻 Tablet  → Wider cards, same bottom nav"
echo "  🖥️  Desktop → Persistent left sidebar, 2-col grid"
echo ""
echo "  Refresh your browser to see the changes!"
echo ""
