<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'notes'       => ['nullable', 'string', 'max:1000'],
            'date'        => ['required', 'date'],
        ];
    }

    public function messages(): array
    {
        return [
            'account_id.required'  => 'Please select an account.',
            'category_id.required' => 'Please select a category.',
            'amount.min'           => 'Amount must be greater than zero.',
        ];
    }
}
