@if ($paginator->hasPages())
<div class="flex items-center justify-center gap-2 py-2">

    @if ($paginator->onFirstPage())
        <span class="w-8 h-8 flex items-center justify-center rounded-lg text-gray-700">‹</span>
    @else
        <a href="{{ $paginator->previousPageUrl() }}"
           class="w-8 h-8 flex items-center justify-center rounded-lg bg-gray-800 text-gray-400 hover:bg-indigo-600 hover:text-white transition text-sm">‹</a>
    @endif

    @foreach ($elements as $element)
        @if (is_string($element))
            <span class="w-8 h-8 flex items-center justify-center text-gray-700 text-sm">…</span>
        @endif
        @if (is_array($element))
            @foreach ($element as $page => $url)
                @if ($page == $paginator->currentPage())
                    <span class="w-8 h-8 flex items-center justify-center rounded-lg bg-indigo-600 text-white text-sm font-medium">{{ $page }}</span>
                @else
                    <a href="{{ $url }}"
                       class="w-8 h-8 flex items-center justify-center rounded-lg bg-gray-800 text-gray-400 text-sm hover:bg-indigo-600 hover:text-white transition">{{ $page }}</a>
                @endif
            @endforeach
        @endif
    @endforeach

    @if ($paginator->hasMorePages())
        <a href="{{ $paginator->nextPageUrl() }}"
           class="w-8 h-8 flex items-center justify-center rounded-lg bg-gray-800 text-gray-400 hover:bg-indigo-600 hover:text-white transition text-sm">›</a>
    @else
        <span class="w-8 h-8 flex items-center justify-center rounded-lg text-gray-700">›</span>
    @endif

</div>
@endif