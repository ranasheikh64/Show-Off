const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { protect } = require('../middlewares/auth.middleware');

// Search users by username, email, or name
router.get('/search', protect, userController.search);

// Discover nearby friends with filters
router.get('/discover', protect, userController.discover);

// Get my profile
router.get('/me', protect, userController.getMyProfile);

// Update user profile
router.put('/profile', protect, userController.updateProfile);

// Accept privacy policy
router.put('/accept-privacy-policy', protect, userController.acceptPrivacyPolicy);

// Update FCM Token
router.put('/fcm-token', protect, userController.updateFcmToken);

// Delete user account
router.delete('/me', protect, userController.deleteAccount);

// Test notification with raw FCM token
router.post('/test-notification', userController.testNotification);

module.exports = router;
