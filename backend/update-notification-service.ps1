
$content = Get-Content -Raw "d:\fieldtrack\backend\src\notifications\notification.service.ts"

$newMethod = @"

  /**
   * Prevents sending duplicate notifications within a given timeframe for the same entity and type.
   */
  async hasRecentNotification(recipientId: string, title: string, entityId: string, hours: number = 24): Promise<boolean> {
    const cutoff = new Date(Date.now() - hours * 60 * 60 * 1000);
    const existing = await prisma.notification.findFirst({
      where: {
        recipientId,
        title,
        entityId,
        createdAt: { gte: cutoff }
      }
    });
    return !!existing;
  }
"@

$content = $content -replace "export class NotificationService \{", "export class NotificationService {`n$newMethod"

Set-Content -Path "d:\fieldtrack\backend\src\notifications\notification.service.ts" -Value $content

