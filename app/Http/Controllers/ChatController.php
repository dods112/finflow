<?php

namespace App\Http\Controllers;

use App\Models\ChatLog;
use App\Services\FinancialAIService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    public function __construct(private FinancialAIService $aiService) {}

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

        try {
            $result = $this->aiService->chat($user, $message);

            $log = ChatLog::create([
                'user_id'     => $user->id,
                'message'     => $message,
                'response'    => $result['response'],
                'context'     => $result['context'],
                'tokens_used' => $result['tokens'] ?? 0,
            ]);

            return response()->json([
                'success'  => true,
                'response' => $result['response'],
                'log_id'   => $log->id,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error'   => 'AI service unavailable. Please try again later.',
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