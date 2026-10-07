const ShowOff = require('../models/showoff.model');
const ShowOffChoice = require('../models/showoffChoice.model');

class ShowOffService {
  async createPost(userId, images) {
    const post = new ShowOff({
      user: userId,
      images: images
    });
    
    await post.save();
    return await ShowOff.findById(post._id).populate('user', 'name phone profileImage isOnline');
  }

  async getFeed(page = 1, limit = 20, filterUserId = null, viewerId = null) {
    const skip = (page - 1) * limit;
    
    const query = {};
    if (filterUserId) {
      query.user = filterUserId;
    }

    const found = await ShowOff.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('user', 'name phone profileImage isOnline');

    const posts = await this._markChosen(found, viewerId);
    const total = await ShowOff.countDocuments(query);

    return {
      posts,
      total,
      page,
      pages: Math.ceil(total / limit)
    };
  }

  // Adds `isChosen` to each post: true if the viewer already chose the post owner
  async _markChosen(posts, viewerId) {
    const plain = posts.map(p => p.toObject());
    if (!viewerId) return plain.map(p => ({ ...p, isChosen: false }));

    const ownerIds = plain.map(p => p.user && p.user._id).filter(Boolean);
    const choices = await ShowOffChoice.find({ chooser: viewerId, chosen: { $in: ownerIds } }).select('chosen');
    const chosenSet = new Set(choices.map(c => c.chosen.toString()));

    return plain.map(p => ({ ...p, isChosen: !!p.user && chosenSet.has(p.user._id.toString()) }));
  }

  // Returns { alreadyChosen }. Safe to call repeatedly.
  async chooseUser(chooserId, chosenId) {
    if (chooserId === chosenId) {
      throw new Error('You cannot choose yourself');
    }
    const existing = await ShowOffChoice.findOne({ chooser: chooserId, chosen: chosenId });
    if (existing) return { alreadyChosen: true };

    await ShowOffChoice.create({ chooser: chooserId, chosen: chosenId });
    return { alreadyChosen: false };
  }

  async updatePost(postId, userId, images) {
    const post = await ShowOff.findOne({ _id: postId, user: userId });
    if (!post) {
      throw new Error('Post not found or unauthorized');
    }
    
    post.images = images;
    await post.save();
    
    return await ShowOff.findById(post._id).populate('user', 'name phone profileImage isOnline');
  }

  async deletePost(postId, userId) {
    const post = await ShowOff.findOne({ _id: postId, user: userId });
    if (!post) {
      throw new Error('Post not found or unauthorized');
    }
    
    await ShowOff.deleteOne({ _id: postId });
    return true;
  }
}

module.exports = new ShowOffService();
