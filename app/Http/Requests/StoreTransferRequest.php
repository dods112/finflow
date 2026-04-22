<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'from_account_id' => ['required', 'exists:accounts,id'],
            'to_account_id'   => ['required', 'exists:accounts,id', 'different:from_account_id'],
            'amount'          => ['required', 'numeric', 'min:0.01'],
            'note'            => ['nullable', 'string', 'max:255'],
            'transfer_date'   => ['required', 'date'],
        ];
    }

    public function messages(): array
    {
        return [
            'to_account_id.different' => 'Source and destination accounts must be different.',
        ];
    }
}
