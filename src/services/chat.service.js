const Chat = require('../models/chat.model');
const Block = require('../models/block.model');
const bcrypt = require('bcryptjs');

const getOrCreateDirectChat = async (userId, otherUserId) => {
    let chat = await Chat.findOne({
        isGroupChat: false,
        $and: [
            { users: { $elemMatch: { $eq: userId } } },
            { users: { $elemMatch: { $eq: otherUserId } } }
        ]
    }).populate('users', '-password');

    if (chat) return formatChatsForUser([chat], userId)[0];

    const newChat = new Chat({
        isGroupChat: false,
        users: [userId, otherUserId]
    });
    await newChat.save();
    chat = await Chat.findById(newChat._id).populate('users', '-password');
    return formatChatsForUser([chat], userId)[0];
};

const createGroupChat = async (adminId, users, chatName) => {
    if (users.length < 2) {
        throw new Error("More than 2 users are required to form a group chat");
    }
    users.push(adminId); // Add admin

    const groupChat = new Chat({
        isGroupChat: true,
        chatName,
        users,
        admin: adminId
    });
    
    await groupChat.save();
    const chat = await Chat.findById(groupChat._id).populate('users', '-password');
    return formatChatsForUser([chat], adminId)[0];
};

const User = require('../models/user.model');

const blockUser = async (blockerId, blockedId) => {
    const blocker = await User.findById(blockerId);
    const blocked = await User.findById(blockedId);

    if (!blocker || !blocked) throw new Error("User not found");

    if (!blocker.blockedUsers.includes(blockedId)) {
        blocker.blockedUsers.push(blockedId);
        await blocker.save();
    }
    if (!blocked.blockedBy.includes(blockerId)) {
        blocked.blockedBy.push(blockerId);
        await blocked.save();
    }

    return { success: true };
};

const unblockUser = async (blockerId, blockedId) => {
    await User.findByIdAndUpdate(blockerId, { $pull: { blockedUsers: blockedId } });
    await User.findByIdAndUpdate(blockedId, { $pull: { blockedBy: blockerId } });
    return true;
};

const isBlocked = async (userId1, userId2) => {
    const user1 = await User.findById(userId1);
    if (!user1) return false;
    return user1.blockedUsers.includes(userId2) || user1.blockedBy.includes(userId2);
};

const setChatLock = async (chatId, userId, password) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    if (!password) {
        await Chat.findByIdAndUpdate(chatId, { $pull: { lockedBy: { user: userId } } });
        return await Chat.findById(chatId);
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const lockIndex = chat.lockedBy.findIndex(l => l.user.toString() === userId.toString());
    if (lockIndex > -1) {
        chat.lockedBy[lockIndex].password = hashedPassword;
        chat.markModified('lockedBy');
    } else {
        chat.lockedBy.push({ user: userId, password: hashedPassword });
    }

    await chat.save();
    return chat;
};

const verifyChatLock = async (chatId, userId, password) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");
    
    const lock = chat.lockedBy.find(l => l.user.toString() === userId.toString());
    if (!lock) return true; // not locked by this user

    if (!password) return false; // password required but not provided
    return await bcrypt.compare(password, lock.password);
};

const setDisappearingTimer = async (chatId, seconds, userId) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");
    
    chat.disappearingTimer = seconds;
    chat.disappearingTimerSetBy = seconds > 0 ? userId : null;
    await chat.save();
    return chat;
};

function formatChatsForUser(chats, currentUserId, userPinnedChats = []) {
    return chats.map(chat => {
        let chatObj = chat.toObject ? chat.toObject() : chat;
        
        chatObj.isLocked = (chatObj.lockedBy || []).some(l => l.user.toString() === currentUserId.toString());
        delete chatObj.lockedBy; // Security: Never send password hash to frontend

        // Override isPinned with order from userPinnedChats if provided
        const pinIndex = userPinnedChats.findIndex(id => id.toString() === chatObj._id.toString());
        chatObj.isPinned = pinIndex > -1;
        chatObj.pinOrder = pinIndex > -1 ? pinIndex : 999999;

        if (chatObj.users) {
            chatObj.users = chatObj.users.map(u => {
                const uid = currentUserId.toString();
                u.isBlocked = (u.blockedBy || []).some(id => id.toString() === uid);
                u.isBlockedBy = (u.blockedUsers || []).some(id => id.toString() === uid);
                return u;
            });
        }
        
        // Merge global and local pinned messages for this user
        const globalPins = chatObj.pinnedMessages || [];
        const localPins = (chatObj.localPinnedMessages || [])
            .filter(p => p.pinnedBy.toString() === currentUserId.toString())
            .map(p => p.messageId);
            
        // Use Set to remove duplicates just in case
        chatObj.pinnedMessages = [...new Set([...globalPins, ...localPins])];
        delete chatObj.localPinnedMessages;

        // Add mute status
        const muteEntry = (chatObj.mutedBy || []).find(m => m.user.toString() === currentUserId.toString());
        if (muteEntry && new Date(muteEntry.mutedUntil) > new Date()) {
            chatObj.isMuted = true;
            chatObj.mutedUntil = muteEntry.mutedUntil;
        } else {
            chatObj.isMuted = false;
        }
        delete chatObj.mutedBy;

        return chatObj;
    });
}

const fetchUserChats = async (userId, page = 1, limit = 20, searchQuery = '') => {
    const user = await User.findById(userId);
    const userPinnedChats = user.pinnedChats || [];

    let query = {
        users: { $elemMatch: { $eq: userId } },
        deletedBy: { $ne: userId }
    };

    if (searchQuery) {
        const matchingUsers = await User.find({
            $or: [
                { name: { $regex: searchQuery, $options: 'i' } },
                { username: { $regex: searchQuery, $options: 'i' } }
            ]
        }).select('_id');
        const matchingUserIds = matchingUsers.map(u => u._id);

        query.$or = [
            { chatName: { $regex: searchQuery, $options: 'i' } },
            { users: { $elemMatch: { $in: matchingUserIds, $ne: userId } } } // Exclude self from matching otherwise all chats match
        ];
    }

    const skip = (page - 1) * limit;

    const chats = await Chat.find(query)
        .populate('users', '-password')
        .populate('admin', '-password')
        .populate({
            path: 'latestMessage',
            populate: { path: 'sender', select: 'name username email' }
        })
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit);
    
    const total = await Chat.countDocuments(query);
    
    return {
        chats: formatChatsForUser(chats, userId, userPinnedChats),
        hasMore: skip + chats.length < total
    };
};

const muteChat = async (chatId, userId, durationInHours) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    const muteUntil = durationInHours 
        ? new Date(Date.now() + durationInHours * 60 * 60 * 1000) 
        : new Date(2100, 1, 1); // practically 'Always'

    // Remove existing mute entry if any
    chat.mutedBy = chat.mutedBy.filter(m => m.user.toString() !== userId.toString());
    
    // Add new mute entry
    chat.mutedBy.push({ user: userId, mutedUntil: muteUntil });
    await chat.save();
    return chat;
};

const unmuteChat = async (chatId, userId) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    chat.mutedBy = chat.mutedBy.filter(m => m.user.toString() !== userId.toString());
    await chat.save();
    return chat;
};

const toggleChatAction = async (chatId, userId, action) => {
    if (action === 'pin') {
        const user = await User.findById(userId);
        if (!user) throw new Error("User not found");
        const index = user.pinnedChats.findIndex(id => id.toString() === chatId.toString());
        if (index > -1) {
            user.pinnedChats.splice(index, 1);
        } else {
            user.pinnedChats.push(chatId);
        }
        await user.save();
        
        // Ensure chat model also has it for backward compatibility if needed, though we rely on user.pinnedChats now
        const chat = await Chat.findById(chatId);
        return formatChatsForUser([chat], userId, user.pinnedChats)[0];
    }

    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    let arrayToUpdate;
    if (action === 'favourite') arrayToUpdate = chat.favouritedBy;
    else if (action === 'archive') arrayToUpdate = chat.archivedBy;
    else throw new Error("Invalid action. Must be 'pin', 'favourite', or 'archive'");

    const index = arrayToUpdate.findIndex(id => id.toString() === userId.toString());
    if (index > -1) {
        // Toggle off
        arrayToUpdate.splice(index, 1);
    } else {
        // Toggle on
        arrayToUpdate.push(userId);
    }

    await chat.save();
    const user = await User.findById(userId);
    return formatChatsForUser([chat], userId, user.pinnedChats || [])[0];
};

const reorderPinnedChats = async (userId, chatIds) => {
    const user = await User.findById(userId);
    if (!user) throw new Error("User not found");
    user.pinnedChats = chatIds;
    await user.save();
    return true;
};

const deleteChatForUser = async (chatId, userId) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    if (!chat.deletedBy.includes(userId)) {
        chat.deletedBy.push(userId);
    }
    
    // Also clear history
    const historyIndex = chat.clearedHistory.findIndex(ch => ch.user.toString() === userId.toString());
    if (historyIndex > -1) {
        chat.clearedHistory[historyIndex].timestamp = new Date();
    } else {
        chat.clearedHistory.push({ user: userId, timestamp: new Date() });
    }

    await chat.save();
    return chat;
};

const clearChatHistoryForUser = async (chatId, userId) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    const historyIndex = chat.clearedHistory.findIndex(ch => ch.user.toString() === userId.toString());
    if (historyIndex > -1) {
        chat.clearedHistory[historyIndex].timestamp = new Date();
    } else {
        chat.clearedHistory.push({ user: userId, timestamp: new Date() });
    }

    await chat.save();
    return chat;
};

const togglePinMessage = async (chatId, messageId, userId, isGlobal = null) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    if (isGlobal === null) {
        // Generic Unpin (Remove from both Global and Local)
        const globalIndex = chat.pinnedMessages.findIndex(id => id.toString() === messageId.toString());
        if (globalIndex > -1) chat.pinnedMessages.splice(globalIndex, 1);
        
        const localIndex = chat.localPinnedMessages.findIndex(
            p => p.messageId.toString() === messageId.toString() && p.pinnedBy.toString() === userId.toString()
        );
        if (localIndex > -1) chat.localPinnedMessages.splice(localIndex, 1);
        
    } else if (isGlobal === true) {
        // Toggle Global Pin
        const index = chat.pinnedMessages.findIndex(id => id.toString() === messageId.toString());
        if (index > -1) {
            chat.pinnedMessages.splice(index, 1); // Unpin
        } else {
            chat.pinnedMessages.push(messageId); // Pin
        }
    } else {
        // Toggle Local Pin (Pin for me)
        const localIndex = chat.localPinnedMessages.findIndex(
            p => p.messageId.toString() === messageId.toString() && p.pinnedBy.toString() === userId.toString()
        );
        
        if (localIndex > -1) {
            chat.localPinnedMessages.splice(localIndex, 1); // Unpin locally
        } else {
            chat.localPinnedMessages.push({ messageId, pinnedBy: userId }); // Pin locally
        }
    }
    
    await chat.save();
    return chat;
};

module.exports = {
    getOrCreateDirectChat,
    createGroupChat,
    blockUser,
    unblockUser,
    isBlocked,
    setChatLock,
    verifyChatLock,
    setDisappearingTimer,
    fetchUserChats,
    muteChat,
    unmuteChat,
    toggleChatAction,
    reorderPinnedChats,
    deleteChatForUser,
    clearChatHistoryForUser,
    togglePinMessage
};

const processMatchDecision = async (chatId, userId, decision) => {
    const chat = await Chat.findById(chatId);
    if (!chat) throw new Error("Chat not found");

    if (decision === 'match') {
        chat.matchStatus = 'matched';
        
        // Send push notification to the other user
        try {
            const { sendPushNotification } = require('./notification.service');
            const otherUserId = chat.users.find(u => u.toString() !== userId.toString());
            if (otherUserId) {
                const currentUser = await User.findById(userId);
                if (currentUser) {
                    await sendPushNotification(
                        otherUserId.toString(),
                        "It's a Match! 🎉",
                        `${currentUser.name || 'Someone'} matched with you! Send a message now.`,
                        { type: 'match', chatId: chat._id.toString() }
                    );
                }
            }
        } catch (e) {
            console.error('Failed to send match push notification', e);
        }
    } else if (decision === 'unmatch') {
        chat.matchStatus = 'unmatched';
    } else if (decision === 'not_now') {
        chat.promptStage = (chat.promptStage || 0) + 1;
    } else {
        throw new Error("Invalid decision. Must be 'match', 'unmatch', or 'not_now'");
    }

    await chat.save();
    return chat;
};

module.exports.processMatchDecision = processMatchDecision;
