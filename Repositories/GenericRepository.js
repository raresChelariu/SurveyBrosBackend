export

const mariadb = require('mariadb')

// noinspection SqlResolve
class GenericRepository {
    tableName
    constructor(tableName) {
        GenericRepository.EstablishConnection()
        this.tableName = tableName
    }
    static EstablishConnection() {
        if (!GenericRepository.pool) {
            GenericRepository.pool = mariadb.createPool({
                host: 'localhost',
                database : 'surveybrosapitables',
                user: 'root',
                password: 'rares123',
                connectionLimit: 5
            })
        }
    }

    static async Query(sqlCommand, values) {
        try {
            return await GenericRepository.pool.query(sqlCommand, values)
        } catch (DbError) {
            throw DbError
        }
    }
    static getConnection() {
        return GenericRepository.pool.getConnection()
    }
    static pool = undefined

}
module.exports = GenericRepository