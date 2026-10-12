const axios = require('axios');

class MusicService {
  /**
   * Search music tracks across Deezer with iTunes fallback.
   * Supports pagination using page and limit.
   * @param {string} query
   * @param {number|string} page
   * @param {number|string} limit
   * @returns {Promise<Array>}
   */
  async searchMusic(query, page = 1, limit = 20) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    const offset = (pageNum - 1) * limitNum;
    const term = query && query.trim() ? query.trim() : 'top hits';

    try {
      return await this._searchITunes(term, offset, limitNum);
    } catch (itunesError) {
      console.warn('[MusicService] iTunes failed, falling back to Deezer:', itunesError.message);
      try {
        return await this._searchDeezer(term, offset, limitNum);
      } catch (deezerError) {
        console.error('[MusicService] Both iTunes and Deezer failed:', deezerError.message);
        throw new Error('Failed to search music from audio providers');
      }
    }
  }


  async _getChartTracks(index = 0, limit = 20) {
    try {
      const response = await axios.get('https://api.deezer.com/chart/0/tracks', {
        params: { index, limit },
        timeout: 8000
      });
      const items = response.data?.data || [];
      return items
        .filter((track) => track.preview)
        .map((track) => ({
          id: String(track.id),
          title: track.title,
          artist: track.artist?.name || 'Unknown Artist',
          previewUrl: track.preview,
          coverImage: track.album?.cover_medium || track.album?.cover || null,
          duration: track.duration ? track.duration * 1000 : null
        }));
    } catch (error) {
      console.warn('[MusicService] Chart tracks failed, falling back to top hits:', error.message);
      return await this._searchITunes('top hits', index, limit);
    }
  }

  async _searchDeezer(query, index = 0, limit = 20) {
    const response = await axios.get('https://api.deezer.com/search', {
      params: { q: query, index, limit },
      timeout: 8000
    });

    const items = response.data?.data || [];
    return items
      .filter((track) => track.preview)
      .map((track) => ({
        id: String(track.id),
        title: track.title,
        artist: track.artist?.name || 'Unknown Artist',
        previewUrl: track.preview,
        coverImage: track.album?.cover_medium || track.album?.cover || null,
        duration: track.duration ? track.duration * 1000 : null
      }));
  }

  async _searchITunes(query, index = 0, limit = 20) {
    const response = await axios.get('https://itunes.apple.com/search', {
      params: { term: query, media: 'music', offset: index, limit },
      timeout: 8000
    });

    const items = response.data?.results || [];
    return items
      .filter((track) => track.previewUrl)
      .map((track) => ({
        id: String(track.trackId),
        title: track.trackName,
        artist: track.artistName || 'Unknown Artist',
        previewUrl: track.previewUrl,
        coverImage: track.artworkUrl100
          ? track.artworkUrl100.replace('100x100bb', '400x400bb')
          : null,
        duration: track.trackTimeMillis || null
      }));
  }
}

module.exports = new MusicService();


