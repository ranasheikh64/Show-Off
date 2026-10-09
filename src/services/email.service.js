const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT || 465,
    secure: (process.env.SMTP_PORT || 465) == 465, // true for 465, false for other ports
    auth: {
        user: process.env.SMTP_EMAIL,
        pass: process.env.SMTP_PASSWORD
    }
});

const sendOTP = async (toEmail, otp) => {
    try {
        const mailOptions = {
            from: `"WebRTC App" <${process.env.SMTP_EMAIL}>`,
            to: toEmail,
            subject: 'Your Password Reset OTP',
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
                    <h2>Password Reset Request</h2>
                    <p>You requested to reset your password. Use the OTP below to proceed:</p>
                    <h1 style="color: #4CAF50; letter-spacing: 2px;">${otp}</h1>
                    <p>This OTP is valid for 10 minutes. If you didn't request this, please ignore this email.</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        return true;
    } catch (error) {
        console.error("Error sending email:", error);
        return false;
    }
};

module.exports = {
    sendOTP
};
