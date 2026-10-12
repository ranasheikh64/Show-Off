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
        console.log(`[Push Notification] Initiating send to User: ${userId} | Title: "${title}"`);
        if (getApps().length === 0) {
            console.log('[Push Notification] Error: Firebase Admin is not initialized.');
            return false;
        }

        const user = await User.findById(userId);
        if (!user || !user.fcmToken) {
            console.log(`[Push Notification] Failed: User ${userId} does not have an FCM token.`);
            return false;
        }

        if (user.notificationsEnabled === false) {
            console.log(`[Push Notification] Skipped: User ${userId} has notifications disabled.`);
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
        console.log(`[Push Notification] Success! Sent to User: ${userId} | Token: ${user.fcmToken.substring(0, 15)}... | Response:`, response);
        return true;
    } catch (error) {
        console.error(`[Push Notification] Exception while sending to User ${userId}:`, error);
        return false;
    }
};

/**
 * Send High Priority Call Push Notification
 */
const sendCallPushNotification = async (userId, callData) => {
    try {
        console.log(`[Call Push Notification] Initiating for User: ${userId}`);
        if (getApps().length === 0) {
            console.log('[Call Push Notification] Firebase Admin not initialized.');
            return false;
        }

        const user = await User.findById(userId);
        if (!user || !user.fcmToken) {
            console.log(`[Call Push Notification] User ${userId} has no FCM token.`);
            return false;
        }

        const title = callData.callType === 'audio' ? 'Incoming Audio Call' : 'Incoming Video Call';
        const body = `${callData.callerName || 'Someone'} is calling you...`;

        const message = {
            notification: {
                title,
                body
            },
            data: {
                type: 'CALL_INCOMING',
                callerId: String(callData.callerId || ''),
                callerName: String(callData.callerName || ''),
                callerAvatar: String(callData.callerAvatar || ''),
                callType: String(callData.callType || 'video'),
                offer: typeof callData.offer === 'object' ? JSON.stringify(callData.offer) : String(callData.offer || ''),
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                priority: 'high',
                ttl: 30000 // 30 seconds expiration
            },
            apns: {
                headers: {
                    'apns-priority': '10'
                }
            },
            token: user.fcmToken
        };

        const response = await getMessaging().send(message);
        console.log(`✅ [Call Push Notification] Sent to User: ${userId} | Response:`, response);
        return true;
    } catch (error) {
        console.error(`❌ [Call Push Notification] Failed for User ${userId}:`, error);
        return false;
    }
};

module.exports = {
    sendPushNotification,
    sendCallPushNotification
};
