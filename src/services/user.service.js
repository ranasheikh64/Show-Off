const User = require('../models/user.model');

const searchUsers = async (query, currentUserId) => {
    // Search by username or email, excluding the current user
    const users = await User.find({
        _id: { $ne: currentUserId },
        $or: [
            { username: { $regex: query, $options: 'i' } },
            { email: { $regex: query, $options: 'i' } },
            { name: { $regex: query, $options: 'i' } }
        ]
    }).select('-password -otp -otpExpiry'); // Exclude sensitive info

    return users;
};

const discoverUsers = async (currentUserId, query) => {
    const { lat, lng, maxDistance = 50, minAge, maxAge, gender, passion } = query;
    
    let filter = { _id: { $ne: currentUserId } };

    if (lat && lng) {
        filter.location = {
            $near: {
                $geometry: {
                    type: "Point",
                    coordinates: [parseFloat(lng), parseFloat(lat)]
                },
                $maxDistance: parseInt(maxDistance) * 1000 // Convert km to meters
            }
        };
    }

    if (minAge || maxAge) {
        filter.age = {};
        if (minAge) filter.age.$gte = parseInt(minAge);
        if (maxAge) filter.age.$lte = parseInt(maxAge);
    }

    if (gender) {
        filter.gender = gender;
    }

    if (passion) {
        const passionsArray = Array.isArray(passion) ? passion : passion.split(',').map(p => p.trim());
        filter.passion = { $in: passionsArray };
    }

    const users = await User.find(filter).select('-password -otp -otpExpiry');
    return users;
};

const updateProfile = async (userId, updateData) => {
    const allowedFields = ['name', 'gender', 'age', 'passion', 'location', 'profileImage', 'education', 'petLover', 'preferences'];
    const filteredData = {};
    
    Object.keys(updateData).forEach(key => {
        if (allowedFields.includes(key) && updateData[key] !== undefined) {
            filteredData[key] = updateData[key];
        }
    });

    if (filteredData.location && filteredData.location.lat && filteredData.location.lng) {
        filteredData.location = {
            type: 'Point',
            coordinates: [parseFloat(filteredData.location.lng), parseFloat(filteredData.location.lat)]
        };
    }

    const updatedUser = await User.findByIdAndUpdate(
        userId,
        { $set: filteredData },
        { new: true, runValidators: true }
    ).select('-password -otp -otpExpiry');

    return updatedUser;
};

module.exports = { searchUsers, discoverUsers, updateProfile };

const Showoff = require('../models/showoff.model');
const ShowOffChoice = require('../models/showoffChoice.model');
const Chat = require('../models/chat.model');

const getProfileWithStats = async (userId) => {
    const user = await User.findById(userId).select('-password -otp -otpExpiry').lean();
    if (!user) throw new Error('User not found');

    const postsCount = await Showoff.countDocuments({ user: userId });
    const lovedByCount = await ShowOffChoice.countDocuments({ chooser: userId });
    
    // We will assume matchedCount is stored directly in user model and incremented on match,
    // or we can count Chats that have matchStatus = 'matched' where users includes userId
    const matchedChatsCount = await Chat.countDocuments({ users: userId, matchStatus: 'matched' });

    user.postsCount = postsCount;
    user.lovedByCount = lovedByCount;
    user.matchedCount = matchedChatsCount; // Override what's in DB for now

    // update DB in background optionally
    User.findByIdAndUpdate(userId, { postsCount, lovedByCount, matchedCount: matchedChatsCount }).exec();

    return user;
};

module.exports.getProfileWithStats = getProfileWithStats;
