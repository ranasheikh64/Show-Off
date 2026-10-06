const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    chat: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat', required: true },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    content: { type: String, required: true }, // Encrypted string
    replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    duration: { type: Number, default: null }, // for audio/video length in seconds
    reactions: [
        {
            user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
            emoji: { type: String }
        }
    ],
    readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    isDeletedForEveryone: { type: Boolean, default: false },
    deletedFor: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    expiresAt: { type: Date, default: null }, // MongoDB will use this for TTL
    isSystemMessage: { type: Boolean, default: false }
}, { timestamps: true });

// TTL Index: Deletes the document automatically when `expiresAt` is reached
// If expiresAt is null or not present, it won't be deleted.
messageSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('Message', messageSchema);
