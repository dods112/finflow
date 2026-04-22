<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRecurringRequest extends FormRequest
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
            'frequency'   => ['required', 'in:daily,weekly,monthly,yearly'],
            'start_date'  => ['required', 'date'],
            'end_date'    => ['nullable', 'date', 'after:start_date'],
        ];
    }
}
