const express = require('express');
const router = express.Router();
const showOffController = require('../controllers/showoff.controller');
const { protect } = require('../middlewares/auth.middleware');

router.post('/', protect, showOffController.createPost);
router.get('/feed', protect, showOffController.getFeed);
router.post('/choose', protect, showOffController.chooseUser);
router.put('/:id', protect, showOffController.updatePost);
router.delete('/:id', protect, showOffController.deletePost);
router.post('/:id/report', protect, showOffController.reportPost);

module.exports = router;
