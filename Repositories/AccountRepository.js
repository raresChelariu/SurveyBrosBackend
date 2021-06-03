const GenericRepository = require('./GenericRepository')
const Account = require('./../Models/Account')
const PredefinedResponses = require('../PredefinedResponses')
const jwt = require('jsonwebtoken')
const config = require('../config')
const SubRepository = require('./SubRepository')

class AccountRepository {

    static async authenticate({email, pass}) {
        let values = [email, Account.hashCode(pass)]
        let command = 'SELECT * FROM account where email=? and pass=?'
        return new Promise((resolve, reject) => {
            GenericRepository.pool.query(command, values).then((rows) => {
                if (0 === rows.length) {
                    reject(PredefinedResponses.ERRORS.INVALID_CREDENTIALS)
                    return
                }
                let user = rows[0]
                const token = jwt.sign({sub: user.ID}, config.secret, {expiresIn: '7d'})
                resolve({...Account.UserWithoutPassword(user), token})
            })
        })
    }

    static async register({email, pass, first_name, last_name, subscription_type}) {
        let values = [email, Account.hashCode(pass), first_name, last_name]
        let command = 'INSERT INTO account (email, pass, first_name, last_name) values (?, ?, ?, ?)'

        let result = await GenericRepository.Query(command, values)
        let user_id = result.insertId

        await SubRepository.AddSubscriptionToUser(user_id, subscription_type)

        return await this.authenticate({email, pass})
    }

    static async getAll() {
        let command = 'SELECT * FROM account'
        return await GenericRepository.Query(command)
    }
}

module.exports = AccountRepository