const express = require('express');
const musicController = require('../controllers/music.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/search', musicController.searchMusic);

module.exports = router;
