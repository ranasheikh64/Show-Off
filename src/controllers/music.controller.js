const musicService = require('../services/music.service');

class MusicController {
  async searchMusic(req, res) {
    try {
      const { query, page, limit } = req.query;
      const tracks = await musicService.searchMusic(query || '', page, limit);
      res.status(200).json({ success: true, data: tracks });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
}



module.exports = new MusicController();
