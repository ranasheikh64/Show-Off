const fs = require('fs');
const logFile = __dirname + '/debug.log'; // Logging inside the src folder

try {
    fs.writeFileSync(logFile, '[' + new Date().toISOString() + '] Server init started. Node Version: ' + process.version + '\n');
} catch (e) { }

process.on('uncaughtException', (err) => {
    try { fs.appendFileSync(logFile, 'Uncaught Exception: ' + (err && err.stack ? err.stack : err) + '\n'); } catch (e) { }
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    try { fs.appendFileSync(logFile, 'Unhandled Rejection: ' + reason + '\n'); } catch (e) { }
});

const origLog = console.log;
const origErr = console.error;
console.log = function (...args) {
    try { fs.appendFileSync(logFile, 'LOG: ' + args.join(' ') + '\n'); } catch (e) { }
    origLog.apply(console, args);
};
console.error = function (...args) {
    try { fs.appendFileSync(logFile, 'ERROR: ' + args.join(' ') + '\n'); } catch (e) { }
    origErr.apply(console, args);
};

require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const uploadRoutes = require('./routes/upload.routes');
const userRoutes = require('./routes/user.routes');
const chatRoutes = require('./routes/chat.routes');
const showOffRoutes = require('./routes/showoff.routes');

const http = require('http');

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const apiRouter = express.Router();
apiRouter.use('/auth', authRoutes);
apiRouter.use('/upload', uploadRoutes);
apiRouter.use('/users', userRoutes);
apiRouter.use('/chats', chatRoutes);
apiRouter.use('/showoff', showOffRoutes);
apiRouter.get('/debug-log', (req, res) => {
    try { res.sendFile(__dirname + '/debug.log'); } catch(e) { res.send(e.toString()); }
});

app.use('/api', apiRouter);
app.use('/showoff/api', apiRouter);
app.get(["/", "/showoff", "/showoff/"], (req, res) => {
    res.send("Show Off Backend server is running");
});

// Database connection
mongoose.connect(process.env.MONGO_URI, { family: 4 })
    .then(() => console.log('Connected to MongoDB successfully.'))
    .catch((err) => console.error('MongoDB connection error:', err));

// Initialize WebSockets
server.on('request', (req, res) => {
    console.log(`[RAW HTTP] Method: ${req.method} URL: ${req.url} OriginalURL: ${req.originalUrl || 'none'}`);
});

const initSockets = require('./sockets/index');
initSockets(server);

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on 0.0.0.0:${PORT}`);
});
// Trigger deployment
