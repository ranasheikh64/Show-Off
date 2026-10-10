const messageService = require('../../services/message.service');
const chatService = require('../../services/chat.service');
const notificationService = require('../../services/notification.service');

module.exports = (io, socket) => {
    
    socket.on("send_message", async (data, callback) => {
        try {
            console.log(`[Socket] Received send_message from ${socket.user.id}:`, data);
            const { chatId, content, replyTo, duration } = data; // replyTo and duration are optional
            
            const { message, promptMatch } = await messageService.saveMessage(chatId, socket.user.id, content, replyTo, duration);
            console.log(`[Socket] Message saved to DB. ID: ${message._id}`);
            
            // Emit to the specific chat room (for users who have the chat screen open)
            io.to(chatId).emit("new_message", message);
            console.log(`[Socket] Emitted new_message to room: ${chatId}`);
            
            // Emit match prompt if thresholds are reached
            if (promptMatch) {
                io.to(chatId).emit("match_prompt_ready", { chatId });
            }
            
            // Emit a global notification to all other users in the chat
            // so they receive it even if they haven't opened this specific chat
            if (message.chat && message.chat.users) {
                message.chat.users.forEach(userId => {
                    if (userId && userId.toString() !== socket.user.id) {
                        io.to(userId.toString()).emit("new_message_notification", message);
                        console.log(`[Socket] Emitted new_message_notification to user room: ${userId}`);
                        
                        // Send Push Notification
                        notificationService.sendPushNotification(
                            userId.toString(),
                            message.sender.name || 'New Message',
                            'Sent a message 💬', // Do not show raw encrypted content in push notifications
                            { type: 'CHAT', chatId: chatId.toString() }
                        );
                    }
                });
            }
            
            if (callback) callback({ success: true, message });
        } catch (error) {
            console.error(`[Socket] Error in send_message: ${error.message}`);
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("fetch_messages", async (data, callback) => {
        try {
            const { chatId, page, limit, password } = data;
            
            // Verify lock if any
            const isVerified = await chatService.verifyChatLock(chatId, socket.user.id, password);
            if (!isVerified) {
                return callback({ success: false, message: "Invalid chat password" });
            }

            const messages = await messageService.fetchMessages(chatId, socket.user.id, page, limit);
            if (callback) callback({ success: true, messages });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("mark_as_read", async (data, callback) => {
        try {
            const { messageId, chatId } = data;
            const updatedMessage = await messageService.markAsRead(messageId, socket.user.id);
            
            if (updatedMessage) {
                // Emit seen status to everyone in the room
                io.to(chatId).emit("message_seen", updatedMessage);
            }
            if (callback) callback({ success: true });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("mark_as_delivered", async (data, callback) => {
        try {
            const { messageId, chatId } = data;
            const updatedMessage = await messageService.markAsDelivered(messageId, socket.user.id);
            
            if (updatedMessage) {
                io.to(chatId).emit("message_delivered", updatedMessage);
            }
            if (callback) callback({ success: true });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("react_to_message", async (data, callback) => {
        try {
            const { messageId, chatId, emoji } = data;
            const updatedMessage = await messageService.reactToMessage(messageId, socket.user.id, emoji);
            
            io.to(chatId).emit("message_reacted", updatedMessage);
            if (callback) callback({ success: true, message: updatedMessage });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("delete_message", async (data, callback) => {
        try {
            const { messageId, chatId, forEveryone } = data;
            await messageService.deleteMessage(messageId, socket.user.id, forEveryone);
            
            if (forEveryone) {
                // Notify everyone in the room that the message was deleted
                io.to(chatId).emit("message_deleted_for_everyone", { messageId, chatId });
            }
            
            if (callback) callback({ success: true });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });
};
