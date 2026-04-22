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
