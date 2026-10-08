const showOffService = require('../services/showoff.service');

class ShowOffController {
  async createPost(req, res) {
    try {
      const { images } = req.body;
      const userId = req.user.id; // assuming auth middleware sets req.user

      if (!images || !images.length) {
        return res.status(400).json({ success: false, message: 'Images are required' });
      }

      const post = await showOffService.createPost(userId, images);
      res.status(201).json({ success: true, data: post });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  async getFeed(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const myPosts = req.query.myPosts === 'true';
      const userId = myPosts ? req.user.id : null;

      const filters = {
        minAge: req.query.minAge ? parseInt(req.query.minAge) : null,
        maxAge: req.query.maxAge ? parseInt(req.query.maxAge) : null,
        gender: req.query.gender,
        petLover: req.query.petLover,
        passion: req.query.passion,
        lookingFor: req.query.lookingFor,
      };

      const result = await showOffService.getFeed(page, limit, userId, req.user.id, filters);
      res.status(200).json({ success: true, ...result });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  async chooseUser(req, res) {
    try {
      const { userId } = req.body;
      if (!userId) {
        return res.status(400).json({ success: false, message: 'userId is required' });
      }

      const result = await showOffService.chooseUser(req.user.id, userId);
      res.status(200).json({ success: true, ...result });
    } catch (error) {
      const status = error.message.includes('yourself') ? 400 : 500;
      res.status(status).json({ success: false, message: error.message });
    }
  }

  async updatePost(req, res) {
    try {
      const { id } = req.params;
      const { images } = req.body;
      const userId = req.user.id;

      if (!images || !images.length) {
        return res.status(400).json({ success: false, message: 'Images are required' });
      }

      const post = await showOffService.updatePost(id, userId, images);
      res.status(200).json({ success: true, data: post });
    } catch (error) {
      if (error.message.includes('not found')) {
        return res.status(404).json({ success: false, message: error.message });
      }
      res.status(500).json({ success: false, message: error.message });
    }
  }

  async deletePost(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      await showOffService.deletePost(id, userId);
      res.status(200).json({ success: true, message: 'Post deleted successfully' });
    } catch (error) {
      if (error.message.includes('not found')) {
        return res.status(404).json({ success: false, message: error.message });
      }
      res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = new ShowOffController();
