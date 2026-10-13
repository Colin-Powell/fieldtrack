
$content = Get-Content -Raw "d:\fieldtrack\backend\src\activities\activity.service.ts"

$content = $content -replace "import \{ reverseGeocode \} from '../utils/geocoder.js';", "import { reverseGeocode } from '../utils/geocoder.js';`nimport { ReadinessService } from './readiness.service.js';"

$content = $content -replace "return prisma.fieldLog.findMany\(\{`n      where: whereClause,", "const activities = await prisma.fieldLog.findMany({`n      where: whereClause,"

$content = $content -replace "orderBy: \{ timestamp: 'desc' \},`n    \}\);`n  \}", "orderBy: { timestamp: 'desc' },`n    });`n    return activities.map(act => ({...act, readiness: ReadinessService.evaluate(act as any)}));`n  }"

$content = $content -replace "return prisma.fieldLog.findUnique\(\{`n      where: \{ id \},", "const activity = await prisma.fieldLog.findUnique({`n      where: { id },"

$content = $content -replace "user: \{ select: \{ id: true, name: true, email: true \} \},`n      \}`n    \}\);`n  \}", "user: { select: { id: true, name: true, email: true } },`n      }`n    });`n    if (!activity) return null;`n    return { ...activity, readiness: ReadinessService.evaluate(activity as any) };`n  }"

Set-Content -Path "d:\fieldtrack\backend\src\activities\activity.service.ts" -Value $content

