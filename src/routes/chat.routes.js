const express = require('express');
const router = express.Router();
const chatService = require('../services/chat.service');
const { protect } = require('../middlewares/auth.middleware');

router.get('/', protect, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const searchQuery = req.query.searchQuery || '';
        const result = await chatService.fetchUserChats(req.user.id, page, limit, searchQuery);
        res.json({ chats: result.chats, hasMore: result.hasMore });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});
router.post('/:chatId/match-decision', protect, async (req, res) => {
    try {
        const { decision } = req.body;
        const chat = await chatService.processMatchDecision(req.params.chatId, req.user.id, decision);
        res.json({ success: true, chat });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;
