const DBTableNames = require("./DBTableNames")
const GenericRepository = require("./GenericRepository")
const PredefinedResponses = require("../PredefinedResponses")
const SubRepository = require("../Repositories/SubRepository")

class SurveyRepository extends GenericRepository {

    static async GetSurveyById(survey_id) {
        let command = 'SELECT * FROM survey where ID=?'
        let queryValues = [survey_id]
        let rows = await GenericRepository.Query(command, queryValues)
        if (rows.length === 0) {
            throw PredefinedResponses.ERRORS.NONEXISTENT_ID
        }
        return rows[0]
    }

    static async GetSurveyWithQuestionsById(survey_ID) {
        let result = await SurveyRepository.GetSurveyById(survey_ID)
        result.questions = await SurveyRepository.GetQuestionsBySurveyId(survey_ID)
        return result
    }
    static async GetAll() {
        let command = 'SELECT * FROM survey'
        let rows = await GenericRepository.Query(command, [])
        if (!rows)
            throw PredefinedResponses.ERRORS.DATABASE_ERROR
        return rows
    }

    static async CreateSurvey({user_id, survey_title, survey_questions}) {
        let sub_id = SubRepository.GetSubIDByUserId(user_id)
        let isValidSub = SubRepository.CheckActiveSubBySubId(sub_id)
        if (false === isValidSub) {
            throw PredefinedResponses.ERRORS.INVALID_SUBSCRIPTION_ID
        }

        let command = 'insert into Survey (name, subscription_used) values (?, ?);'
        let values = [survey_title, sub_id]

        let result = await GenericRepository.Query(command, values)
        if (1 !== result.affectedRows) {
            throw PredefinedResponses.ERRORS.FAILED_INSERT
        }
        let survey_id = result.insertId
        for (let i = 0; i < survey_questions.length; i++) {
            await this.AddQuestionToSurvey(survey_id, survey_questions[i])
        }
        return survey_id
    }

    static async AddQuestionToSurvey(survey_id, survey_question) {
        await SurveyRepository.GetSurveyById(survey_id)

        let command = 'insert into Survey_Question (survey_ID, question_text) values  (?, ?)'
        let values = [survey_id, survey_question.question_text]

        let surveyInsert = await GenericRepository.Query(command, values)
        let question_id = surveyInsert.insertId
        let answerTypeID = await this.GetQuestionTypeIDbyQuestionTypeString(survey_question.question_type)

        command = 'insert into Survey_Question_Answer_Type_Association (survey_question_ID, survey_question_answer_type_ID, option_names) values ($questionID, $answerTypeID $option_names)'
        values = [question_id, answerTypeID, survey_question.option_names]

        await GenericRepository.Query(command, values)
    }

    static async GetQuestionTypeIDbyQuestionTypeString(question_type) {
        let command = 'select ID from Survey_Question_Answer_Type where type=?'
        let values = [question_type]
        let rows = await GenericRepository.Query(command, values)
        if (0 === rows.length) {
            throw PredefinedResponses.ERRORS.INVALID_QUESTION_TYPE
        }
        return rows[0].ID

    }
    static async GetQuestionTypeStringByQuestionTypeId(question_type_id) {
        let command = 'select ID from Survey_Question_Answer_Type where ID=?'
        let values = [question_type_id]
        let rows = await GenericRepository.Query(command, values)
        if (0 === rows.length) {
            throw PredefinedResponses.ERRORS.INVALID_QUESTION_TYPE_ID
        }
        return rows[0].type
    }
    static async GetQuestionsBySurveyId(survey_id) {
        await SurveyRepository.GetSurveyById(survey_id)
        let command = 'select ID, question_number, question_text from survey_question where survey_ID=?'
        let values = [survey_id]

        let questions = await GenericRepository.Query(command, values)
        for (let i = 0; i < questions.length; i++) {
            let typeAssociation = await this.GetQuestionAssociationByQuestionID(questions[i].ID)

            let questionTypeID = typeAssociation.survey_question_answer_type_id
            questions[i].survey_question_answer_type = await this.GetQuestionTypeStringByQuestionTypeId(questionTypeID)

            questions[i].option_names = typeAssociation.option_names
        }
        return questions
    }

    static async GetQuestionAssociationByQuestionID(question_id) {
        let command = 'select * from survey_question_answer_type_association where survey_question_ID=?'
        let values = [question_id]
        let rows = await GenericRepository.Query(command, values)
        if (0 === rows.length) {
            throw PredefinedResponses.ERRORS.INVALID_QUESTION_ID
        }
        let {survey_question_answer_type_id, option_names} = rows[0]
        return {survey_question_answer_type_id, option_names}
    }
}

module.exports = SurveyRepository