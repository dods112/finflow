<?php

namespace App\Http\Controllers;

use App\Models\ChatLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatController extends Controller
{
    public function index()
    {
        $user     = Auth::user();
        $chatLogs = ChatLog::where('user_id', $user->id)
            ->where('message', 'NOT LIKE', '%auto_insight%')
            ->orderBy('created_at')
            ->get();

        return view('chat.index', compact('chatLogs'));
    }

    public function send(Request $request)
    {
        $request->validate([
            'message' => ['required', 'string', 'max:500'],
        ]);

        $user    = Auth::user();
        $message = strip_tags($request->message);

        // ── Grab config values ────────────────────────────────
        $provider = config('services.finflow_ai.provider',
                    env('FINFLOW_AI_PROVIDER', 'groq'));

        $apiKey   = env('OPENAI_API_KEY', '');
        $model    = 'llama-3.1-8b-instant';
        $baseUrl  = 'https://api.groq.com/openai/v1/chat/completions';

        // ── Validate key exists ───────────────────────────────
        if (empty($apiKey)) {
            return response()->json([
                'success' => false,
                'error'   => 'AI Error: OPENAI_API_KEY is not set in environment variables.',
            ], 503);
        }

        // ── Build simple prompt ───────────────────────────────
        $systemPrompt = "You are FinFlow AI, a friendly personal finance assistant for {$user->name}. Be helpful and concise.";

        // ── Call Groq API ─────────────────────────────────────
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type'  => 'application/json',
            ])
            ->timeout(30)
            ->post($baseUrl, [
                'model'       => $model,
                'max_tokens'  => 500,
                'temperature' => 0.7,
                'messages'    => [
                    ['role' => 'system', 'content' => $systemPrompt],
                    ['role' => 'user',   'content' => $message],
                ],
            ]);

            // ── Show exact error if failed ────────────────────
            if ($response->failed()) {
                $errorBody = $response->json();
                $errorMsg  = $errorBody['error']['message']
                             ?? $response->body();

                Log::error('Groq API Failed', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);

                return response()->json([
                    'success' => false,
                    'error'   => 'Groq API Error (' . $response->status() . '): ' . $errorMsg,
                ], 503);
            }

            $data         = $response->json();
            $responseText = $data['choices'][0]['message']['content']
                            ?? 'Sorry, I could not generate a response.';
            $tokens       = $data['usage']['completion_tokens'] ?? 0;

            $log = ChatLog::create([
                'user_id'     => $user->id,
                'message'     => $message,
                'response'    => $responseText,
                'context'     => null,
                'tokens_used' => $tokens,
            ]);

            return response()->json([
                'success'  => true,
                'response' => $responseText,
                'log_id'   => $log->id,
            ]);

        } catch (\Exception $e) {
            Log::error('Groq Exception: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'error'   => 'Exception: ' . $e->getMessage(),
            ], 503);
        }
    }

    public function clearHistory()
    {
        ChatLog::where('user_id', Auth::id())
            ->where('message', 'NOT LIKE', '%auto_insight%')
            ->delete();

        return redirect(route('chat.index'))->with('success', 'Chat history cleared.');
    }
}