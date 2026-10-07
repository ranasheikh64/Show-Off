const mongoose = require('mongoose');

const showOffChoiceSchema = new mongoose.Schema({
  chooser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  chosen: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
}, {
  timestamps: true
});

// A user can choose another user only once
showOffChoiceSchema.index({ chooser: 1, chosen: 1 }, { unique: true });

module.exports = mongoose.model('ShowOffChoice', showOffChoiceSchema);
