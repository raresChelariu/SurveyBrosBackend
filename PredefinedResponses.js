class PredefinedResponses {
    static errorObject = (message) => {
        return { error : message }
    }
    static ERRORS = {
        INVALID_CREDENTIALS : PredefinedResponses.errorObject('Invalid credentials'),
        EMAIL_ALREADY_IN_USE: PredefinedResponses.errorObject('Email already in use')
    }
}
module.exports = PredefinedResponses