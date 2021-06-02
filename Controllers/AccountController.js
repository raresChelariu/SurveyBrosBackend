const express = require('express');
const router = express.Router();
const AccountRepository = require('../Repositories/AccountRepository');
const GenericRepository = require("../Repositories/GenericRepository");

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