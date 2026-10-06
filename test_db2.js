const mongoose = require('mongoose');
const Chat = require('./src/models/chat.model');
mongoose.connect('mongodb://localhost:27017/webrtc-chat')
  .then(async () => {
    const chats = await Chat.find({});
    for (let chat of chats) {
      if (chat.lockedBy && chat.lockedBy.length > 0) {
        console.log(`Chat ID: ${chat._id}, isGroup: ${chat.isGroupChat}`);
        for (let lock of chat.lockedBy) {
          console.log(`- Locked by User: ${lock.user}`);
          console.log(`  Password hash: ${lock.password}`);
        }
      }
    }
    process.exit(0);
  });
