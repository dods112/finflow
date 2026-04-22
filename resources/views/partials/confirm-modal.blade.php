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
