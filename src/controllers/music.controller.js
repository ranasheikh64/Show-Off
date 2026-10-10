const musicService = require('../services/music.service');

class MusicController {
  async searchMusic(req, res) {
    try {
      const { query } = req.query;
      if (!query) {
        return res.status(400).json({ success: false, message: 'Search query is required' });
      }

      const tracks = await musicService.searchMusic(query);
      res.status(200).json({ success: true, data: tracks });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = new MusicController();
