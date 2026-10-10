const userService = require('../services/user.service');

const search = async (req, res) => {
    try {
        const { q } = req.query;
        if (!q) {
            return res.status(400).json({ success: false, message: "Search query 'q' is required." });
        }

        const users = await userService.searchUsers(q, req.user.id);
        
        res.status(200).json({
            success: true,
            message: 'Users fetched successfully',
            users
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

const discover = async (req, res) => {
    try {
        const users = await userService.discoverUsers(req.user.id, req.query);
        res.status(200).json({
            success: true,
            message: 'Nearby users fetched successfully',
            users
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

const updateProfile = async (req, res) => {
    try {
        const user = await userService.updateProfile(req.user.id, req.body);
        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            user
        });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

module.exports = { search, discover, updateProfile };

const getMyProfile = async (req, res) => {
    try {
        const user = await userService.getProfileWithStats(req.user.id);
        res.status(200).json({
            success: true,
            message: 'Profile fetched successfully',
            user
        });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

const updateFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;
        if (!fcmToken) return res.status(400).json({ success: false, message: 'Token is required' });
        
        await userService.updateProfile(req.user.id, { fcmToken });
        res.status(200).json({ success: true, message: 'FCM Token updated' });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

module.exports.getMyProfile = getMyProfile;
module.exports.updateFcmToken = updateFcmToken;

const deleteAccount = async (req, res) => {
    try {
        await userService.deleteAccount(req.user.id);
        res.status(200).json({ success: true, message: 'Account deleted successfully' });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

module.exports.deleteAccount = deleteAccount;
