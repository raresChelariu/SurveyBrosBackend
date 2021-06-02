const GenericRepository = require('./GenericRepository')
const DBTableNames = require('./DBTableNames')
const Account = require('./../Models/Account')
const PredefinedResponses = require('../PredefinedResponses')
const jwt = require('jsonwebtoken')
const config = require('../config')

class AccountRepository extends GenericRepository {
    constructor() {
        super(DBTableNames.Account);
        GenericRepository.EstablishConnection()
    }

    static COMMANDS = {
        Authenticate: 'SELECT * FROM account where email=? and pass=?',
        Register: 'INSERT INTO account (email, pass, first_name, last_name) values (?, ?, ?, ?)',
        GetAll: 'SELECT * FROM account'
    }

    static async authenticate({email, pass}) {
        let values = [email, Account.hashCode(pass)]
        let command = AccountRepository.COMMANDS.Authenticate
        return new Promise((resolve, reject) => {
            GenericRepository.pool.query(command, values).then((rows) => {
                if (0 === rows.length) {
                    reject(PredefinedResponses.ERRORS.INVALID_CREDENTIALS)
                    return
                }
                let user = rows[0]
                const token = jwt.sign({sub: user.ID}, config.secret, {expiresIn: '7d'});
                resolve({...Account.UserWithoutPassword(user), token})
            })
        })
    }

    static async register({email, pass, first_name, last_name}) {
        let values = [email, Account.hashCode(pass), first_name, last_name]
        let command = AccountRepository.COMMANDS.Register
        return await GenericRepository.pool.query(command, values).then(async res => {
            if (0 === res.affectedRows) {
                throw PredefinedResponses.ERRORS.EMAIL_ALREADY_IN_USE
            }
            return await this.authenticate({email, pass})
        })
    }

    static async getAll() {
        let command = AccountRepository.COMMANDS.GetAll
        return await GenericRepository.pool.query(command)
    }
}

module.exports = AccountRepository