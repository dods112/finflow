{{--
    ─────────────────────────────────────────────────────────────────────────
    DROP THIS SECTION into your existing resources/views/profile/index.blade.php
    Place it inside the settings card section, wherever it fits best.
    ─────────────────────────────────────────────────────────────────────────
--}}

{{-- ── APPEARANCE SECTION ──────────────────────────────────────────────────── --}}
<div class="bg-gray-900 dark:bg-gray-900 rounded-2xl border border-gray-800 dark:border-gray-800 overflow-hidden">
    <div class="px-4 py-3 border-b border-gray-800 dark:border-gray-800">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-widest">Appearance</p>
    </div>

    {{-- Dark / Light Mode Toggle --}}
    <div class="px-4 py-4 flex items-center justify-between">
        <div class="flex items-center gap-3">
            {{-- Sun icon (light) --}}
            <div id="icon-light" class="hidden w-9 h-9 bg-yellow-500/10 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364-6.364l-.707.707M6.343 17.657l-.707.707M17.657 17.657l-.707-.707M6.343 6.343l-.707-.707M12 7a5 5 0 100 10A5 5 0 0012 7z"/>
                </svg>
            </div>
            {{-- Moon icon (dark) --}}
            <div id="icon-dark" class="w-9 h-9 bg-indigo-600/10 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
                </svg>
            </div>
            <div>
                <p class="text-sm font-medium dark:text-white text-gray-900" id="theme-label">Dark Mode</p>
                <p class="text-xs text-gray-500" id="theme-sublabel">Using dark theme</p>
            </div>
        </div>

        {{-- Toggle Switch --}}
        <button id="theme-toggle-btn"
            onclick="toggleTheme()"
            class="relative w-12 h-6 rounded-full transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 focus:ring-offset-gray-900"
            aria-label="Toggle theme">
            <span id="toggle-track"
                class="block w-full h-full rounded-full bg-indigo-600 transition-colors"></span>
            <span id="toggle-thumb"
                class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-300 translate-x-6">
            </span>
        </button>
    </div>
</div>

<script>
function toggleTheme() {
    window.FinFlowToggleTheme();
    updateThemeUI();
}

function updateThemeUI() {
    const theme = window.FinFlowGetTheme?.() ?? 'dark';
    const isDark = theme === 'dark';

    document.getElementById('theme-label').textContent     = isDark ? 'Dark Mode'       : 'Light Mode';
    document.getElementById('theme-sublabel').textContent  = isDark ? 'Using dark theme' : 'Using light theme';
    document.getElementById('icon-dark').classList.toggle('hidden', !isDark);
    document.getElementById('icon-light').classList.toggle('hidden', isDark);

    const track = document.getElementById('toggle-track');
    const thumb = document.getElementById('toggle-thumb');
    track.classList.toggle('bg-indigo-600', isDark);
    track.classList.toggle('bg-gray-600',   !isDark);
    thumb.classList.toggle('translate-x-6', isDark);
    thumb.classList.toggle('translate-x-0', !isDark);
}

// Sync on load
document.addEventListener('DOMContentLoaded', updateThemeUI);
</script>