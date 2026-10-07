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
