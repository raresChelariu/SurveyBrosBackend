class PredefinedResponses {
    static errorObject = (message) => {
        return { error : message }
    }
    static ERRORS = {
        INVALID_CREDENTIALS : PredefinedResponses.errorObject('Invalid credentials'),
        EMAIL_ALREADY_IN_USE: PredefinedResponses.errorObject('Email already in use'),
        NONEXISTENT_ID: PredefinedResponses.errorObject('Nonexistent id'),
        DATABASE_ERROR: PredefinedResponses.errorObject('Database error'),
        INVALID_SUBSCRIPTION_ID: PredefinedResponses.errorObject('Invalid subscription id'),
        FAILED_INSERT: PredefinedResponses.errorObject('Failed insert'),
        INVALID_QUESTION_TYPE: PredefinedResponses.errorObject('Invalid question type'),
        INVALID_QUESTION_ID: PredefinedResponses.errorObject('Invalid question id'),
        INVALID_QUESTION_TYPE_ID: PredefinedResponses.errorObject('Invalid question type id')
    }
}
module.exports = PredefinedResponses