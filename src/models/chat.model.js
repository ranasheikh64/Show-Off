const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
    isGroupChat: { type: Boolean, default: false },
    chatName: { type: String, trim: true },
    users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    admin: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    lockedBy: [
        {
            user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
            password: { type: String } // Hashed password for this specific user
        }
    ],
    disappearingTimer: { type: Number, default: 0 }, // In seconds, 0 means disabled
    disappearingTimerSetBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    latestMessage: { type: mongoose.Schema.Types.ObjectId, ref: 'Message' },
    pinnedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    favouritedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    archivedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    deletedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // Users who deleted the chat
    clearedHistory: [
        {
            user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
            timestamp: { type: Date }
        }
    ],
    pinnedMessages: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Message' }], // Global pins
    localPinnedMessages: [ // Local pins (Pin for me)
        {
            messageId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message' },
            pinnedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
        }
    ],
    mutedBy: [
        {
            user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
            mutedUntil: { type: Date } // Date until the chat is muted. If very far in future, it means 'Always'
        }
    ],
    // Match fields
    matchStatus: { type: String, enum: ['pending', 'matched', 'unmatched'], default: 'pending' },
    messageCount: { type: Number, default: 0 },
    promptStage: { type: Number, default: 0 } // 0 = waiting for 5, 1 = waiting for 35, etc.
}, { timestamps: true });

module.exports = mongoose.model('Chat', chatSchema);
