const axios = require('axios');

class MusicService {
  /**
   * Search music tracks across Deezer with iTunes fallback.
   * Both provide reliable 30-second audio previews without 403 API restrictions.
   * @param {string} query
   * @returns {Promise<Array>}
   */
  async searchMusic(query) {
    if (!query || !query.trim()) {
      return await this._getChartTracks();
    }

    const trimmedQuery = query.trim();

    try {
      return await this._searchDeezer(trimmedQuery);
    } catch (deezerError) {
      console.warn('[MusicService] Deezer failed, falling back to iTunes:', deezerError.message);
      try {
        return await this._searchITunes(trimmedQuery);
      } catch (itunesError) {
        console.error('[MusicService] Both Deezer and iTunes search failed:', itunesError.message);
        throw new Error('Failed to search music from audio providers');
      }
    }
  }

  async _getChartTracks() {
    try {
      const response = await axios.get('https://api.deezer.com/chart/0/tracks', {
        params: { limit: 25 },
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
      return await this._searchITunes('top hits');
    }
  }


  async _searchDeezer(query) {
    const response = await axios.get('https://api.deezer.com/search', {
      params: { q: query, limit: 25 },
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

  async _searchITunes(query) {
    const response = await axios.get('https://itunes.apple.com/search', {
      params: { term: query, media: 'music', limit: 25 },
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

