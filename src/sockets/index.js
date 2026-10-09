const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');

const registerChatHandlers = require('./handlers/chat.handler');
const registerMessageHandlers = require('./handlers/message.handler');

const initSockets = (server) => {
    const io = socketIo(server, {
        path: '/showoff/api/stream',
        cors: { origin: "*", methods: ["GET", "POST"] }
    });

    // Authentication Middleware
    io.use((socket, next) => {
        let token = socket.handshake.auth.token || socket.handshake.headers.authorization || socket.handshake.headers.token;
        console.log("RECEIVED TOKEN:", token); console.log("=== TOKEN RECEIVED ===", token);

        if (!token) {
            return next(new Error("Authentication error: Token not provided"));
        }

        if (!token.startsWith("Bearer ")) {
            return next(new Error("Authentication error: Token must start with Bearer"));
        }

        token = token.split(" ")[1];

        jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
            if (err) return next(new Error("Authentication error: Invalid token"));
            socket.user = decoded.user;
            next();
        });
    });

const User = require('../models/user.model');

    io.on("connection", async (socket) => {
        console.log(`User connected: ${socket.user.id}`);

        // Update user online status
        await User.findByIdAndUpdate(socket.user.id, { isOnline: true });
        io.emit("user_status_changed", { userId: socket.user.id, isOnline: true });

        // Join personal room to receive personal events (like new group added)
        socket.join(socket.user.id);

        // Client should explicitly emit 'join_chat' to join a specific chat room
        socket.on("join_chat", (data) => {
            const room = typeof data === 'string' ? data : data.chatId;
            if (room) {
                socket.join(room);
                console.log(`User ${socket.user.id} joined chat ${room}`);
            }
        });

        // Register handlers
        registerChatHandlers(io, socket);
        registerMessageHandlers(io, socket);

        socket.on("disconnect", async () => {
            console.log(`User disconnected: ${socket.user.id}`);
            await User.findByIdAndUpdate(socket.user.id, { isOnline: false, lastActive: new Date() });
            io.emit("user_status_changed", { userId: socket.user.id, isOnline: false, lastActive: new Date().toISOString() });
        });
    });
};

module.exports = initSockets;
