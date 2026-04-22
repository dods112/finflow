<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id'  => ['required', 'exists:categories,id'],
            'limit_amount' => ['required', 'numeric', 'min:1'],
            'month'        => ['required', 'integer', 'between:1,12'],
            'year'         => ['required', 'integer', 'min:2020'],
        ];
    }
}
