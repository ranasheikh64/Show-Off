const mongoose = require('mongoose');

const showOffSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  images: [{
    type: String,
    required: true
  }],
}, {
  timestamps: true
});

const ShowOff = mongoose.model('ShowOff', showOffSchema);

module.exports = ShowOff;
