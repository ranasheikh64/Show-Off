const express = require('express');
const router = express.Router();

const authController = require('../controllers/auth.controller');
const validators = require('../validators/auth.validator');

// Register
router.post('/register', validators.registerValidator, authController.register);

// Login
router.post('/login', validators.loginValidator, authController.login);

// Forgot Password (Send OTP)
router.post('/forgot-password', validators.forgotPasswordValidator, authController.forgotPassword);

// Verify OTP
router.post('/verify-otp', validators.verifyOtpValidator, authController.verifyOtp);

// Reset Password
router.post('/reset-password', validators.resetPasswordValidator, authController.resetPassword);

module.exports = router;
