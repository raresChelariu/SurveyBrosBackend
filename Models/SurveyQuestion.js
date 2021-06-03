class SurveyQuestion {
    ID
    survey_ID
    question_text
    question_type
    option_names

    constructor(survey_ID, question_text, question_type, option_names, ID) {
        this.survey_ID = survey_ID;
        this.question_text = question_text;
        this.question_type = question_type;
        this.option_names = option_names;
        this.ID = ID;
    }
}
module.exports = SurveyQuestion