const admin = require('firebase-admin');
const User = require('../models/user.model');
let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (e) {
        console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT from environment variables");
    }
} else {
    try {
        serviceAccount = require('../../show-off-ba1be-firebase-adminsdk-fbsvc-969a4ba46f.json');
    } catch (e) {
        console.warn("Firebase service account JSON not found. Push notifications will be disabled.");
    }
}

// Initialize Firebase Admin
if (serviceAccount && !admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
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
        if (!admin.apps.length) {
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

        const response = await admin.messaging().send(message);
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
