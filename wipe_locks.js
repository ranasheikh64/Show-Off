require('dotenv').config();
const mongoose = require('mongoose');
const Chat = require('./src/models/chat.model');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const chats = await Chat.find({});
    for (let chat of chats) {
      if (chat.lockedBy && chat.lockedBy.length > 0) {
        chat.lockedBy = [];
        await chat.save();
        console.log(`Cleared lock for chat: ${chat._id}`);
      }
    }
    console.log("All locks cleared.");
    process.exit(0);
  }).catch(err => {
    console.error(err);
    process.exit(1);
  });
