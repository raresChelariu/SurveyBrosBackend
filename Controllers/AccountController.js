const express = require('express');
const router = express.Router();
const AccountRepository = require('../Repositories/AccountRepository');
const GenericRepository = require("../Repositories/GenericRepository");
const {check} = require("express-validator");

const RequestSchemas = {
    UserRegister: [
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
GenericRepository.EstablishConnection()
router.post('/authenticate', (req, res) => {
    AccountRepository.authenticate(req.body)
        .then(user => res.json(user))
        .catch(err => res.json(err))
})

router.get('/', (req, res) => {
    AccountRepository.getAll()
        .then(users => res.json(users))
        .catch(err => res.json(err))
})
router.post('/register', (req, res) => {
    AccountRepository.register(req.body).then(user => res.json(user)).catch(err => res.json(err))
})

module.exports = router;