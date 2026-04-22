<?php

return [

    'mailgun' => [
        'domain'   => env('MAILGUN_DOMAIN'),
        'secret'   => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme'   => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key'    => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'groq' => [
        'key' => env('OPENAI_API_KEY', ''),
    ],

    'openrouter' => [
        'key' => env('OPENROUTER_API_KEY', ''),
    ],

    'finflow_ai' => [
        'provider'     => env('FINFLOW_AI_PROVIDER', 'groq'),
        'model'        => env('FINFLOW_AI_MODEL', 'llama-3.1-8b-instant'),
        'ollama_url'   => env('OLLAMA_URL', 'http://localhost:11434'),
        'ollama_model' => env('OLLAMA_MODEL', 'phi3'),
    ],

];