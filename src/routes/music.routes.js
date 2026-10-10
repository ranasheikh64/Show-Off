const express = require('express');
const musicController = require('../controllers/music.controller');
const { protect } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/search', musicController.searchMusic);

module.exports = router;
