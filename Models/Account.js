const {check, validationResult} = require('express-validator');

class Account {
    ID
    email
    pass
    first_name
    last_name
    date_created
    date_modified
    last_sign_in
    email_confirmed
    password_change_requested
    password_change_request_date
    is_locked_out
    lockdown_start

    constructor(ID, email, pass, first_name, last_name, date_created, date_modified, last_sign_in, email_confirmed, password_change_requested, password_change_request_date, is_locked_out, lockdown_start) {
        this.ID = ID;
        this.email = email;
        this.pass = pass;
        this.first_name = first_name;
        this.last_name = last_name;
        this.date_created = date_created;
        this.date_modified = date_modified;
        this.last_sign_in = last_sign_in;
        this.email_confirmed = email_confirmed;
        this.password_change_requested = password_change_requested;
        this.password_change_request_date = password_change_request_date;
        this.is_locked_out = is_locked_out;
        this.lockdown_start = lockdown_start;
    }
    static ErrorRequiredFields = (req, res) => {
        const errors = validationResult(req)
        if (!errors.isEmpty()) {
            return res.status(422).json({errors: errors.array()})
        }
    }
    static hashCode(input) {
        let hash = 0, i, chr;
        if (input.length === 0) return hash;
        for (i = 0; i < input.length; i++) {
            chr   = input.charCodeAt(i);
            hash  = ((hash << 5) - hash) + chr;
            hash |= 0;
        }
        return Math.abs(hash).toString(16);
    }
    static UserWithoutPassword(user) {
        const { pass, ...userWithoutPassword } = user;
        return userWithoutPassword;
    }



}

module.exports = Account