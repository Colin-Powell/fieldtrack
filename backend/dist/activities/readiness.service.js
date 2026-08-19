export class ReadinessService {
    static evaluate(activity) {
        const missing = [];
        if (!activity.title || activity.title.trim().length === 0) {
            missing.push('Title is required');
        }
        if (!activity.description || activity.description.trim().length === 0) {
            missing.push('Description is required');
        }
        if (!activity.evidence || activity.evidence.length === 0) {
            missing.push('At least one evidence photo or file is required');
        }
        return {
            isReady: missing.length === 0,
            missingRequirements: missing,
        };
    }
}
