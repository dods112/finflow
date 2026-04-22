<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     * NOTE: Chat routes are handled via X-CSRF-TOKEN header in JS fetch,
     * so no exemption is needed here.
     *
     * @var array<int, string>
     */
    protected $except = [
        //
    ];
}
