const express = require('express')
const router = express.Router()
const AccountRepository = require('../Repositories/AccountRepository')
const GenericRepository = require("../Repositories/GenericRepository")
const {checkSchema} = require("express-validator")

const RequestSchemas = {
    UserRegister: checkSchema({
        email: {
            in: ['body'],
            errorMessage: 'Invalid email',
            isEmail: true,
            isLength: {min: 5, max: 128}
        },
        pass: {
            in: ['body'],
            errorMessage: 'Invalid pass',
            isLength: {min: 5, max: 256}
        },
        first_name: {
            in: ['body'],
            errorMessage: 'Invalid first_name',
            isLength: {min: 3, max: 128}
        },
        last_name: {
            in: ['body'],
            errorMessage: 'Invalid first_name',
            isLength: {min: 3, max: 64}
        },
        subscription_type: {
            in: ['body'],
            isInt: true,
            errorMessage: 'Invalid subscription type'
        }
    }),
    UserAuthenticate: checkSchema({
        email: {
            in: ['body'],
            errorMessage: 'Invalid email',
            isEmail: true,
            isLength: {min: 5, max: 128}
        },
        pass: {
            in: ['body'],
            errorMessage: 'Invalid pass',
            isLength: {min: 5, max: 256}
        }
    })
}
GenericRepository.EstablishConnection()
router.post('/authenticate', RequestSchemas.UserAuthenticate, (req, res) => {
    AccountRepository.authenticate(req.body)
        .then(user => res.json(user))
        .catch(err => res.json(err))
})

router.post('/register', RequestSchemas.UserRegister, (req, res) => {
    AccountRepository.register(req.body).then(user => res.json(user)).catch(err => res.json(err))
})

router.get('/', (req, res) => {
    AccountRepository.getAll()
        .then(users => res.json(users))
        .catch(err => res.json(err))
})
module.exports = router;