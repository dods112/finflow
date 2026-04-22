<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'         => ['required', 'string', 'max:100'],
            'account_type' => ['required', 'in:cash,bank,e_wallet,credit_card,savings'],
            'balance'      => ['required', 'numeric'],
            'color'        => ['nullable', 'string', 'max:7'],
            'icon'         => ['nullable', 'string', 'max:10'],
        ];
    }
}
