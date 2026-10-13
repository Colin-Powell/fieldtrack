
$content = Get-Content -Raw "d:\fieldtrack\backend\src\activities\activity.service.ts"

$content = $content -replace "import \{ ReadinessService \} from './readiness.service.js';", "import { ReadinessService } from './readiness.service.js';`nimport { NotificationService } from '../notifications/notification.service.js';`nconst notificationService = new NotificationService();"

$content = $content -replace "const newStatus = activity.status === 'REVISION_REQUESTED' \? 'RESUBMITTED' : 'SUBMITTED';`n`n    return prisma.fieldLog.update\(\{`n      where: \{ id \},`n      data: \{ status: newStatus \},`n    \}\);", "const newStatus = activity.status === 'REVISION_REQUESTED' ? 'RESUBMITTED' : 'SUBMITTED';`n`n    const updated = await prisma.fieldLog.update({`n      where: { id },`n      data: { status: newStatus },`n      include: { user: { include: { studentProfile: true } } }`n    });`n`n    const supervisorId = updated.user.studentProfile?.supervisorId;`n    if (supervisorId) {`n      const supervisorProf = await prisma.supervisorProfile.findUnique({ where: { id: supervisorId } });`n      if (supervisorProf) {`n        await notificationService.sendNotification({`n          recipientId: supervisorProf.userId,`n          title: 'New activity submitted',`n          message: `${updated.user.name} submitted ${updated.title} for review.`,`n          type: 'NEW_SUBMISSION',`n          entityType: 'FIELD_LOG',`n          entityId: id`n        });`n      }`n    }`n`n    return updated;"

Set-Content -Path "d:\fieldtrack\backend\src\activities\activity.service.ts" -Value $content

