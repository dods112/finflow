<?php

namespace App\Notifications;

use App\Models\Budget;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BudgetExceededNotification extends Notification
{
    use Queueable;

    public function __construct(private Budget $budget) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $currency  = $notifiable->currency ?? 'USD';
        $category  = $this->budget->category->name;
        $spent     = number_format($this->budget->spent, 2);
        $limit     = number_format($this->budget->limit_amount, 2);
        $overage   = number_format($this->budget->spent - $this->budget->limit_amount, 2);
        $monthYear = date('F Y', mktime(0, 0, 0, $this->budget->month, 1, $this->budget->year));

        return (new MailMessage)
            ->subject("⚠️ Budget Exceeded: {$category} — {$monthYear}")
            ->greeting("Hi {$notifiable->name}!")
            ->line("Your **{$category}** budget has been exceeded for {$monthYear}.")
            ->line("- **Limit:** {$currency} {$limit}")
            ->line("- **Spent:** {$currency} {$spent}")
            ->line("- **Over by:** {$currency} {$overage}")
            ->action('View Budgets', url('/budgets'))
            ->line('Consider reviewing your spending or adjusting your budget.')
            ->salutation('— FinFlow');
    }
}
