const express = require('express');
const router = express.Router();
const SurveyRepository = require('../Repositories/SurveyRepository');
const GenericRepository = require("../Repositories/GenericRepository");
const {checkSchema} = require("express-validator");

GenericRepository.EstablishConnection()

const RequestSchemas = {
    GetByIDWithQuestions: checkSchema({
        survey_ID: {
            in: ['params'],
            isInt: true,
            errorMessage: 'Invalid id'
        }
    }),
    CreateSurvey: checkSchema({
        user_id: {
            in: ['body'],
            isInt: true,
            errorMessage: 'Invalid user id'
        },
        survey_title: {
            in: ['body'],
            isLength: {min: 3, max: 64},
            errorMessage: 'Invalid survey title'
        },
        survey_questions: {
            in: ['body']
        }
    })
}

router.get('/:survey_ID', RequestSchemas.GetByIDWithQuestions, (req, res) => {
    let survey_ID = req.params.survey_ID
    SurveyRepository.GetSurveyWithQuestionsById(survey_ID)
        .then(survey => res.json(survey))
        .catch(err => res.json(err))
})
router.post('', RequestSchemas.CreateSurvey, (req, res) => {
    SurveyRepository.CreateSurvey(req.body)
        .then(survey => res.json(survey))
        .catch(err => res.json(err))
})

module.exports = router;
