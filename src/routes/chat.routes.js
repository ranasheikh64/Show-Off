const express = require('express');
const router = express.Router();
const chatService = require('../services/chat.service');
const { protect } = require('../middlewares/auth.middleware');

router.get('/', protect, async (req, res) => {
    try {
        const chats = await chatService.fetchUserChats(req.user.id);
        res.json(chats);
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;
