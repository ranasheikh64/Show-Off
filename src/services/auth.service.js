const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { sendOTP } = require('./email.service');
const userService = require('./user.service');

const registerUser = async (name, username, email, password, gender, age, passion, location) => {
    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
        throw new Error('User with this email already exists.');
    }

    const existingUsername = await User.findOne({ username });
    if (existingUsername) {
        throw new Error('This username is already taken. Please choose another one.');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const newUser = new User({
        name,
        username,
        email,
        password: hashedPassword,
        gender,
        age,
        passion,
        location: location && location.lat && location.lng ? { type: 'Point', coordinates: [parseFloat(location.lng), parseFloat(location.lat)] } : undefined
    });

    await newUser.save();
    return newUser;
};

const loginUser = async (email, password) => {
    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('Invalid email or password.');
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
        throw new Error('Invalid email or password.');
    }

    // Generate Token
    const payload = {
        user: {
            id: user.id
        }
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });
    
    // Fetch full profile with stats
    const userWithStats = await userService.getProfileWithStats(user.id);
    
    return { token, user: userWithStats };
};

const processForgotPassword = async (email) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('No user found with this email address.');
    }

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Set expiry to 10 minutes from now
    const otpExpiry = new Date();
    otpExpiry.setMinutes(otpExpiry.getMinutes() + 10);

    user.otp = otp;
    user.otpExpiry = otpExpiry;
    await user.save();

    // Send email
    const emailSent = await sendOTP(email, otp);
    if (!emailSent) {
        throw new Error('Failed to send OTP email. Please try again later.');
    }

    return true;
};

const processVerifyOtp = async (email, otp) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('No user found with this email address.');
    }

    if (user.otp !== otp) {
        throw new Error('Invalid OTP.');
    }

    if (new Date() > user.otpExpiry) {
        throw new Error('OTP has expired. Please request a new one.');
    }

    return true;
};

const processResetPassword = async (email, otp, newPassword) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('No user found with this email address.');
    }

    if (user.otp !== otp) {
        throw new Error('Invalid OTP. Please verify your OTP again.');
    }

    if (new Date() > user.otpExpiry) {
        throw new Error('OTP has expired. Please request a new one.');
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    user.password = hashedPassword;
    user.otp = null;
    user.otpExpiry = null;
    await user.save();

    return true;
};

module.exports = {
    registerUser,
    loginUser,
    processForgotPassword,
    processVerifyOtp,
    processResetPassword
};
