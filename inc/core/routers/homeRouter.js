const express = require('express');
const homeRouter = express.Router();

const homeController = require('../controllers/homeController');

homeRouter.use('/', homeController.home)

exports.homeRouter = homeRouter;
