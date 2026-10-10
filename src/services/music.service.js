const axios = require('axios');

class MusicService {
  constructor() {
    this.clientId = process.env.SPOTIFY_CLIENT_ID;
    this.clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
    this.accessToken = null;
    this.tokenExpiration = null;
  }

  async getAccessToken() {
    if (this.accessToken && this.tokenExpiration && Date.now() < this.tokenExpiration) {
      return this.accessToken;
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
      
      return this.accessToken;
    } catch (error) {
      console.error('Error fetching Spotify token:', error.response?.data || error.message);
      throw new Error('Failed to authenticate with Spotify');
    }
  }

  async searchMusic(query) {
    if (!query) return [];
    
    const token = await this.getAccessToken();
    
    try {
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

      return response.data.tracks.items
        .filter(track => track.preview_url)
        .map(track => ({
          id: track.id,
          title: track.name,
          artist: track.artists.map(a => a.name).join(', '),
          previewUrl: track.preview_url,
          coverImage: track.album.images[0]?.url || null,
          duration: track.duration_ms
        }));
        
    } catch (error) {
      console.error('Error searching Spotify:', error.response?.data || error.message);
      throw new Error('Failed to search music');
    }
  }
}

module.exports = new MusicService();
