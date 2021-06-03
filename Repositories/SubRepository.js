const DBTableNames = require("./DBTableNames");
const GenericRepository = require("./GenericRepository");
const PredefinedResponses = require("../PredefinedResponses");

class SubRepository {

    static async GetSubIDByUserId(user_id) {
        let command = 'select ID from Active_Subscription s join Active_Member_Subscription ms on s.ID = ms.subscription_ID where ms.account_ID = ?;'
        let values = ['account.ID']
        let rows = await GenericRepository.Query(command, values)
        return rows[0]
    }

    static async CheckActiveSubBySubId(sub_id) {
        let command = 'select ID from Active_Subscription where ID = ?'
        let values = ['sub_id']
        let rows = await GenericRepository.Query(command, values)
        return rows.length > 0
    }


}

module.exports = SubRepository