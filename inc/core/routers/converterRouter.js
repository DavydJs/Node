const express = require('express');
const converterRouter = express.Router();

const controllers = require('../controllers/converterController');

converterRouter.use('/', controllers.converter)

exports.converterRouter = converterRouter;
