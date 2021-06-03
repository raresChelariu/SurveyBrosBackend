const GenericRepository = require("./GenericRepository");

class SubRepository {

    static async GetSubIDByUserId(user_id) {
        let command = 'select s.ID from Active_Subscription s join Active_Member_Subscription ms on s.ID = ms.subscription_ID where ms.account_ID = ?;'
        let values = [user_id]
        let rows = await GenericRepository.Query(command, values)
        return rows[0].ID
    }

    static async CheckActiveSubBySubId(sub_id) {
        let command = 'select ID from Active_Subscription where ID=?'
        let values = [sub_id]
        let rows = await GenericRepository.Query(command, values)
        return rows.length > 0
    }
    static async AddSubscriptionToUser(user_id, subscription_type_ID) {
        let command = 'insert into active_subscription (subscription_type_ID) values (?)'
        let values = [subscription_type_ID]
        let result = await GenericRepository.Query(command, values)
        let sub_id = result.insertId

        command = 'insert into Active_Member_Subscription (account_ID, subscription_ID) values (?, ?)'
        values = [user_id, sub_id]
        await GenericRepository.Query(command, values)

        return { ID : sub_id }
    }

}

module.exports = SubRepository