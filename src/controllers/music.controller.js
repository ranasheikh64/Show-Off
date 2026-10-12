const musicService = require('../services/music.service');

class MusicController {
  async searchMusic(req, res) {
    try {
      const { query } = req.query;
      const tracks = await musicService.searchMusic(query || '');
      res.status(200).json({ success: true, data: tracks });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
}


module.exports = new MusicController();
