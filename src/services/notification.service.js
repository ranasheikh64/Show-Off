const { getApps, initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const User = require('../models/user.model');
const fs = require('fs');
const path = require('path');

let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (e) {
        console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT from environment variables");
    }
} else {
    try {
        const filePath = path.join(__dirname, '../../show-off-ba1be-firebase-adminsdk-fbsvc-969a4ba46f.json');
        if (fs.existsSync(filePath)) {
            serviceAccount = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        } else {
            console.warn("Firebase service account JSON not found. Push notifications will be disabled.");
        }
    } catch (e) {
        console.warn("Firebase service account JSON read error. Push notifications will be disabled.");
    }
}

// Initialize Firebase Admin
if (serviceAccount && getApps().length === 0) {
    initializeApp({
        credential: cert(serviceAccount)
    });
}

/**
 * Send push notification to a user
 * @param {String} userId - The target user's ID
 * @param {String} title - Notification title
 * @param {String} body - Notification body
 * @param {Object} data - Optional extra data payload
 */
const sendPushNotification = async (userId, title, body, data = {}) => {
    try {
        if (getApps().length === 0) {
            console.log('Firebase Admin is not initialized.');
            return false;
        }

        const user = await User.findById(userId);
        if (!user || !user.fcmToken) {
            console.log(`User ${userId} does not have an FCM token.`);
            return false;
        }

        const message = {
            notification: {
                title,
                body
            },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            token: user.fcmToken
        };

        const response = await getMessaging().send(message);
        console.log('Successfully sent message:', response);
        return true;
    } catch (error) {
        console.error('Error sending push notification:', error);
        return false;
    }
};

module.exports = {
    sendPushNotification
};
