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
  reportedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  musicUrl: {
    type: String,
    default: null
  },
  musicTitle: {
    type: String,
    default: null
  },
  musicArtist: {
    type: String,
    default: null
  },
}, {
  timestamps: true
});

const ShowOff = mongoose.model('ShowOff', showOffSchema);

module.exports = ShowOff;
