const chatService = require('../../services/chat.service');
const messageService = require('../../services/message.service');

module.exports = (io, socket) => {
    
    socket.on("access_chat", async (data, callback) => {
        try {
            const { userId } = data; // the ID of the person you want to chat with
            if (!userId) throw new Error("userId is required to access a chat");
            const chat = await chatService.getOrCreateDirectChat(socket.user.id, userId);
            if (callback) callback({ success: true, chat });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("fetch_chats", async (data, callback) => {
        try {
            const page = data?.page || 1;
            const limit = data?.limit || 20;
            const searchQuery = data?.searchQuery || '';
            const result = await chatService.fetchUserChats(socket.user.id, page, limit, searchQuery);
            if (callback) callback({ success: true, chats: result.chats, hasMore: result.hasMore });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("create_group", async (data, callback) => {
        try {
            const { chatName, users } = data;
            const groupChat = await chatService.createGroupChat(socket.user.id, users, chatName);
            
            // Notify all members
            groupChat.users.forEach(user => {
                io.to(user._id.toString()).emit("new_chat_created", groupChat);
            });
            
            if (callback) callback({ success: true, chat: groupChat });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("block_user", async (data, callback) => {
        try {
            const { blockedId } = data;
            await chatService.blockUser(socket.user.id, blockedId);
            
            io.to(socket.user.id).emit("user_blocked", { blockerId: socket.user.id, blockedId });
            io.to(blockedId).emit("user_blocked", { blockerId: socket.user.id, blockedId });
            
            if (callback) callback({ success: true });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("unblock_user", async (data, callback) => {
        try {
            const { blockedId } = data;
            await chatService.unblockUser(socket.user.id, blockedId);
            
            io.to(socket.user.id).emit("user_unblocked", { blockerId: socket.user.id, blockedId });
            io.to(blockedId).emit("user_unblocked", { blockerId: socket.user.id, blockedId });
            
            if (callback) callback({ success: true });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("lock_chat", async (data, callback) => {
        try {
            const { chatId, password } = data;
            await chatService.setChatLock(chatId, socket.user.id, password);
            if (callback) callback({ success: true, message: "Chat locked successfully" });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("set_temporary_timer", async (data, callback) => {
        try {
            const { chatId, seconds } = data;
            console.log(`[Disappearing Messages] User ${socket.user.id} turning on/off timer for chat ${chatId} (${seconds}s)`);
            await chatService.setDisappearingTimer(chatId, seconds, socket.user.id);
            
            // Create a system message
            const content = seconds === 0 ? "timer_off" : `timer_on_${seconds}`;
            const sysMsg = await messageService.saveSystemMessage(chatId, socket.user.id, content);
            
            // Emit timer update
            io.to(chatId).emit("timer_updated", { chatId, seconds, setBy: socket.user.id });
            
            // Emit the system message so clients render the bubble
            io.to(chatId).emit("new_message", sysMsg);
            
            console.log(`[Disappearing Messages] Timer updated and event emitted to chat ${chatId}`);
            if (callback) callback({ success: true });
        } catch (error) {
            console.error(`[Disappearing Messages] Error: ${error.message}`);
            if (callback) callback({ success: false, message: error.message });
        }
    });
    socket.on("mute_chat", async (data, callback) => {
        try {
            const { chatId, durationInHours } = data;
            await chatService.muteChat(chatId, socket.user.id, durationInHours);
            if (callback) callback({ success: true, message: "Chat muted successfully" });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("unmute_chat", async (data, callback) => {
        try {
            const { chatId } = data;
            await chatService.unmuteChat(chatId, socket.user.id);
            if (callback) callback({ success: true, message: "Chat unmuted successfully" });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("toggle_chat_action", async (data, callback) => {
        try {
            const { chatId, action } = data; // 'pin', 'favourite', or 'archive'
            const chat = await chatService.toggleChatAction(chatId, socket.user.id, action);
            if (callback) callback({ success: true, chat });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("reorder_pinned_chats", async (data, callback) => {
        try {
            const { chatIds } = data; // array of chat IDs in new order
            await chatService.reorderPinnedChats(socket.user.id, chatIds);
            if (callback) callback({ success: true, message: "Order updated" });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("delete_chat", async (data, callback) => {
        try {
            const { chatId } = data;
            await chatService.deleteChatForUser(chatId, socket.user.id);
            if (callback) callback({ success: true, message: "Chat deleted" });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("clear_history", async (data, callback) => {
        try {
            const { chatId } = data;
            await chatService.clearChatHistoryForUser(chatId, socket.user.id);
            if (callback) callback({ success: true, message: "Chat history cleared" });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });

    socket.on("toggle_pin_message", async (data, callback) => {
        try {
            const { chatId, messageId } = data;
            const chat = await chatService.togglePinMessage(chatId, messageId, socket.user.id);
            
            // Notify room that pinned messages changed
            io.to(chatId).emit("pinned_messages_updated", chat.pinnedMessages);
            if (callback) callback({ success: true, pinnedMessages: chat.pinnedMessages });
        } catch (error) {
            if (callback) callback({ success: false, message: error.message });
        }
    });


}
