const Message = require('../models/message.model');
const Chat = require('../models/chat.model');
const chatService = require('./chat.service');

const saveMessage = async (chatId, senderId, content, replyTo = null, duration = null) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    if (!chat.isGroupChat) {
        const otherUserId = chat.users.find(u => u && u.toString() !== senderId.toString());
        if (otherUserId) {
            const blocked = await chatService.isBlocked(senderId, otherUserId);
            if (blocked) throw new Error("Cannot send message. User is blocked.");
        }
    }

    let expiresAt = null;
    if (chat.disappearingTimer && chat.disappearingTimer > 0) {
        expiresAt = new Date(Date.now() + chat.disappearingTimer * 1000);
    }

    const newMessage = new Message({
        chat: chatId,
        sender: senderId,
        content,
        replyTo,
        duration,
        expiresAt
    });

    await newMessage.save();

    // Update the latest message of the chat and clear deletedBy so it reappears
    await Chat.findByIdAndUpdate(chatId, { 
        latestMessage: newMessage._id,
        $set: { deletedBy: [] } 
    });

    return await Message.findById(newMessage._id)
        .populate('sender', 'name username email')
        .populate('chat')
        .populate({
            path: 'replyTo',
            populate: { path: 'sender', select: 'name username email' }
        });
};

const fetchMessages = async (chatId, userId, page = 1, limit = 20) => {
    const chat = await Chat.findById(chatId);
    let clearedAt = new Date(0);
    if (chat) {
        const history = chat.clearedHistory.find(ch => ch.user.toString() === userId.toString());
        if (history) clearedAt = history.timestamp;
    }

    const skip = (page - 1) * limit;

    const messages = await Message.find({ 
        chat: chatId,
        createdAt: { $gt: clearedAt },
        deletedFor: { $ne: userId }
    })
        .populate('sender', 'name username email')
        .populate('readBy', 'name username email')
        .populate({
            path: 'replyTo',
            populate: { path: 'sender', select: 'name username email' }
        })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

    return messages;
};

const markAsRead = async (messageId, userId) => {
    const message = await Message.findById(messageId);
    if (!message) return null;

    if (!message.readBy.includes(userId)) {
        message.readBy.push(userId);
        await message.save();
    }
    
    return await Message.findById(messageId)
        .populate('sender', 'name username email')
        .populate('readBy', 'name username email')
        .populate({
            path: 'replyTo',
            populate: { path: 'sender', select: 'name username email' }
        });
};

const reactToMessage = async (messageId, userId, emoji) => {
    const message = await Message.findById(messageId);
    if (!message) throw new Error("Message not found");

    const existingReactIndex = message.reactions.findIndex(r => r.user.toString() === userId.toString());
    
    if (existingReactIndex > -1) {
        if (message.reactions[existingReactIndex].emoji === emoji) {
            // Remove reaction if same emoji is tapped again
            message.reactions.splice(existingReactIndex, 1);
        } else {
            // Update emoji if different
            message.reactions[existingReactIndex].emoji = emoji;
        }
    } else {
        // Add new reaction
        message.reactions.push({ user: userId, emoji });
    }

    await message.save();
    return await Message.findById(messageId)
        .populate('sender', 'name username email')
        .populate('readBy', 'name username email')
        .populate({
            path: 'replyTo',
            populate: { path: 'sender', select: 'name username email' }
        });
};

const deleteMessage = async (messageId, userId, forEveryone = false) => {
    const message = await Message.findById(messageId);
    if (!message) throw new Error("Message not found");

    if (forEveryone) {
        if (message.sender.toString() !== userId.toString()) {
            throw new Error("Only the sender can delete the message for everyone");
        }
        message.isDeletedForEveryone = true;
        message.content = "This message was deleted"; // Overwrite content
    } else {
        if (!message.deletedFor.includes(userId)) {
            message.deletedFor.push(userId);
        }
    }

    await message.save();
    return message;
};

module.exports = {
    saveMessage,
    fetchMessages,
    markAsRead,
    reactToMessage,
    deleteMessage
};

const saveSystemMessage = async (chatId, senderId, content) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    const newMessage = new Message({
        chat: chatId,
        sender: senderId,
        content,
        isSystemMessage: true
    });

    await newMessage.save();
    
    chat.latestMessage = newMessage._id;
    await chat.save();
    
    return await Message.findById(newMessage._id)
        .populate('sender', 'name username email avatar');
};

module.exports.saveSystemMessage = saveSystemMessage;
