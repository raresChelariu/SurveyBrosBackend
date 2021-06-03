const {check} = require('express-validator');

class Survey {
    ID
    date_created
    subscription_used

    constructor(date_created, subscription_used, ID) {
        this.ID = ID;
        this.date_created = date_created;
        this.subscription_used = subscription_used;
    }

    static RequestSchemas = {
        Create: [
            check('email').isEmail(),
            check('pass').isLength({min: 3})
        ],

        UserAuthenticate: [
            check('email').isEmail().isLength({min: 5, max : 128}),
            check('pass').isLength({min: 5, max : 256}),
            check('first_name').isLength({min: 3, max : 128}),
            check('last_name').isLength({min: 3, max : 64})
        ]
    }
}
module.exports = Survey