const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true
        },
        username: {
            type: String,
            unique: true,
            sparse: true,
            lowercase: true,
            trim: true
        },
        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true
        },
        password: {
            type: String,
            required: true
        },
        otp: {
            type: String,
            default: null
        },
        otpExpiry: {
            type: Date,
            default: null
        },
        isVerified: {
            type: Boolean,
            default: false
        },
        gender: {
            type: String,
            enum: ['Male', 'Female', 'Other', 'Prefer not to say'],
            default: 'Prefer not to say'
        },
        age: {
            type: Number,
            default: null
        },
        passion: {
            type: [String],
            default: []
        },
        profileImage: {
            type: String,
            default: null
        },
        location: {
            type: { type: String, enum: ['Point'], default: 'Point' },
            coordinates: { type: [Number], default: [0, 0] } // [longitude, latitude]
        },
        blockedUsers: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }],
        blockedBy: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }],
        isOnline: {
            type: Boolean,
            default: false
        },
        lastActive: {
            type: Date,
            default: Date.now
        },
        pinnedChats: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Chat'
        }]
    },
    { timestamps: true }
);

userSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('User', userSchema);
