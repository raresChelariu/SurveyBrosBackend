const express = require('express');
const router = express.Router();
const SurveyRepository = require('../Repositories/SurveyRepository');
const GenericRepository = require("../Repositories/GenericRepository");

GenericRepository.EstablishConnection()


router.get('/:survey_ID', (req, res) => {
    let survey_ID = req.params.survey_ID
    SurveyRepository.GetSurveyWithQuestionsById(survey_ID)
        .then(survey => res.json(survey))
        .catch(err => res.json(err))
})
router.post('', (req, res) => {
    SurveyRepository.CreateSurvey(req.body)
        .then(survey => res.json(survey))
        .catch(err => res.json(err))
})
router.
module.exports = router;
