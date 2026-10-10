const axios = require('axios');

class MusicService {
  constructor() {
    this.clientId = process.env.SPOTIFY_CLIENT_ID;
    this.clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
    this.accessToken = null;
    this.tokenExpiration = null;
    console.log('[MusicService] Initialized with Client ID:', this.clientId ? 'Set' : 'Missing', 'Client Secret:', this.clientSecret ? 'Set' : 'Missing');
  }

  async getAccessToken() {
    console.log('[MusicService] Requesting access token...');
    if (this.accessToken && this.tokenExpiration && Date.now() < this.tokenExpiration) {
      console.log('[MusicService] Returning cached token.');
      return this.accessToken;
    }

    if (!this.clientId || !this.clientSecret) {
      console.error('[MusicService] Error: Missing Spotify credentials in .env');
      throw new Error('Missing Spotify credentials');
    }

    const credentials = Buffer.from(`${this.clientId}:${this.clientSecret}`).toString('base64');
    
    try {
      const response = await axios.post('https://accounts.spotify.com/api/token', 'grant_type=client_credentials', {
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });

      this.accessToken = response.data.access_token;
      this.tokenExpiration = Date.now() + (response.data.expires_in * 1000) - 300000;
      
      console.log('[MusicService] Token successfully acquired!');
      return this.accessToken;
    } catch (error) {
      console.error('[MusicService] Error fetching Spotify token:', error.response?.data || error.message);
      throw new Error(error.response?.data?.error || error.message || 'Failed to authenticate with Spotify');
    }
  }

  async searchMusic(query) {
    console.log(`[MusicService] Searching music for query: "${query}"`);
    if (!query) return [];
    
    try {
      const token = await this.getAccessToken();
      console.log(`[MusicService] Calling Spotify Search API...`);
      const response = await axios.get(`https://api.spotify.com/v1/search`, {
        params: {
          q: query,
          type: 'track',
          limit: 20
        },
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      console.log(`[MusicService] Spotify API returned ${response.data.tracks.items.length} tracks.`);
      const mappedTracks = response.data.tracks.items
        .filter(track => track.preview_url)
        .map(track => ({
          id: track.id,
          title: track.name,
          artist: track.artists.map(a => a.name).join(', '),
          previewUrl: track.preview_url,
          coverImage: track.album.images[0]?.url || null,
          duration: track.duration_ms
        }));
      console.log(`[MusicService] Filtered down to ${mappedTracks.length} tracks with preview URLs.`);
      return mappedTracks;
        
    } catch (error) {
      console.error('[MusicService] Error searching Spotify:', error.response?.data || error.message);
      throw new Error(error.response?.data?.error?.message || error.message || 'Failed to search music');
    }
  }
}

module.exports = new MusicService();
