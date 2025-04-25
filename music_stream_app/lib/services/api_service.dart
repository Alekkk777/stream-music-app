// lib/services/api_service.dart (modifiche complete)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/models/playlist.dart';

class ApiService {
  // URL di base dell'API


  // Intestazioni HTTP comuni
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Getter per ottenere la directory di download appropriata
  Future<String> get localMusicDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(path.join(appDir.path, 'Music'));
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir.path;
  }

  // Ricerca su YouTube
  Future<List<Song>> searchYoutube(String query) async {
    final url = Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return jsonData.map((item) => Song.fromSearchResult(item)).toList();
      } else {
        throw Exception('Errore nella ricerca: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore di rete durante la ricerca: $e');
      rethrow;
    }
  }

  // Download di una canzone su cloud
  Future<Song> downloadSong(String videoId, String title) async {
    final url = Uri.parse('$_baseUrl/download');
    
    try {
      final response = await http.post(
        url, 
        headers: _headers,
        body: jsonEncode({
          'video_id': videoId,
          'title': title,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Song.fromJson({
          'id': jsonData['song_id'],
          'video_id': videoId,
          'title': title,
          'cloud_url': jsonData['cloud_url'],
        });
      } else {
        throw Exception('Errore nel download: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore di rete durante il download: $e');
      rethrow;
    }
  }

  // Nuovo metodo: Download di una canzone solo in locale
  Future<Song> downloadSongLocally(String videoId, String title) async {
    final url = Uri.parse('$_baseUrl/download_local');
    
    try {
      final response = await http.post(
        url, 
        headers: _headers,
        body: jsonEncode({
          'video_id': videoId,
          'title': title,
          'save_to_db': true, // Aggiungi questo parametro per salvare nel database
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Song.fromJson({
          'id': jsonData['song_id'],
          'video_id': videoId,
          'title': title,
          'local_path': jsonData['local_path'],
          'is_local_only': true,
        });
      } else {
        throw Exception('Errore nel download locale: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore di rete durante il download locale: $e');
      rethrow;
    }
  }


  Future<Song> addStreamingSongToDatabase(Song song) async {
    final url = Uri.parse('$_baseUrl/add_streaming_song');
    
    try {
      final response = await http.post(
        url, 
        headers: _headers,
        body: jsonEncode({
          'video_id': song.videoId,
          'title': song.title,
          'thumbnail': song.thumbnailUrl,
          'channel': song.channelTitle,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Song.fromJson({
          'id': jsonData['song_id'],
          'video_id': song.videoId,
          'title': song.title,
          'thumbnail': song.thumbnailUrl,
          'channel': song.channelTitle,
          'is_streaming_only': true,
        });
      } else {
        throw Exception('Errore nell\'aggiunta del brano in streaming: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore di rete durante l\'aggiunta del brano in streaming: $e');
      rethrow;
    }
  }

  // Nuovo metodo: Ottiene l'URL per lo streaming diretto
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    final url = Uri.parse('$_baseUrl/stream_url/$videoId');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Errore nell\'ottenere lo stream URL: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore di rete durante l\'ottenimento dello stream URL: $e');
      rethrow;
    }
  }

  // Nuovo metodo: Elimina una canzone
  Future<void> deleteSong(int songId) async {
    final url = Uri.parse('$_baseUrl/delete_song/$songId');
    
    try {
      final response = await http.delete(url, headers: _headers);
      
      if (response.statusCode != 200) {
        throw Exception('Errore nella cancellazione della canzone: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore di rete durante la cancellazione della canzone: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    final url = Uri.parse('$_baseUrl/playlists/$playlistId');
    
    try {
      // Assicurati di usare il metodo DELETE
      final response = await http.delete(
        url, 
        headers: _headers,
      );
      
      if (response.statusCode != 200) {
        debugPrint('Errore nella risposta del server: ${response.body}');
        throw Exception('Errore nell\'eliminazione della playlist: ${response.statusCode}');
      }
      
      // Log per debug
      debugPrint('Playlist eliminata con successo: $playlistId');
    } catch (e) {
      debugPrint('Errore di rete durante l\'eliminazione della playlist: $e');
      rethrow;
    }
  }

  // Ottieni tutte le canzoni
  Future<List<Song>> getSongs() async {
    final url = Uri.parse('$_baseUrl/songs');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return jsonData.map((item) => Song.fromJson(item)).toList();
      } else {
        throw Exception('Errore nel caricamento delle canzoni');
      }
    } catch (e) {
      debugPrint('Errore di rete nel caricamento delle canzoni: $e');
      rethrow;
    }
  }

  // Ottieni tutte le playlist
  Future<List<Playlist>> getPlaylists() async {
    final url = Uri.parse('$_baseUrl/playlists');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return jsonData.map((item) => Playlist.fromJson(item)).toList();
      } else {
        throw Exception('Errore nel caricamento delle playlist');
      }
    } catch (e) {
      debugPrint('Errore di rete nel caricamento delle playlist: $e');
      rethrow;
    }
  }

  // Crea una nuova playlist
  Future<Playlist> createPlaylist(String name) async {
    final url = Uri.parse('$_baseUrl/playlists');
    
    try {
      final response = await http.post(
        url, 
        headers: _headers,
        body: jsonEncode({
          'name': name,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Playlist(
          id: jsonData['id'],
          name: jsonData['name'],
          songs: [],
        );
      } else {
        throw Exception('Errore nella creazione della playlist');
      }
    } catch (e) {
      debugPrint('Errore di rete nella creazione della playlist: $e');
      rethrow;
    }
  }

  // Aggiungi una canzone a una playlist
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final url = Uri.parse('$_baseUrl/playlists/$playlistId/songs');
    
    try {
      final response = await http.post(
        url, 
        headers: _headers,
        body: jsonEncode({
          'song_id': songId,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Errore nell\'aggiunta della canzone alla playlist');
      }
    } catch (e) {
      debugPrint('Errore di rete nell\'aggiunta della canzone alla playlist: $e');
      rethrow;
    }
  }

  // Nuovo metodo: Rimuovi una canzone da una playlist
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final url = Uri.parse('$_baseUrl/playlists/$playlistId/songs/$songId');
    
    try {
      final response = await http.delete(url, headers: _headers);
      
      if (response.statusCode != 200) {
        throw Exception('Errore nella rimozione della canzone dalla playlist');
      }
    } catch (e) {
      debugPrint('Errore di rete nella rimozione della canzone dalla playlist: $e');
      rethrow;
    }
  }

  // Nuovo metodo: Aggiungi una canzone in modalità streaming (senza download)
  Future<Song> addStreamingSong(String videoId) async {
    try {
      final urlInfo = await getStreamUrl(videoId);
      
      if (urlInfo.containsKey('stream_url') && urlInfo.containsKey('title')) {
        // Crea un oggetto Song per la modalità streaming
        return Song(
          videoId: videoId,
          title: urlInfo['title'],
          thumbnailUrl: urlInfo['thumbnail'],
          channelTitle: urlInfo['channel'],
          isStreamingOnly: true,
        );
      } else {
        throw Exception('Informazioni sul video mancanti');
      }
    } catch (e) {
      debugPrint('Errore durante l\'aggiunta di una canzone in streaming: $e');
      rethrow;
    }
  }

  Future<String> getTestAudioUrl() async {
    try {
      final url = Uri.parse('$_baseUrl/api/test_audio');
      
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stream_url'];
      } else {
        // Fallback a un URL statico se l'API fallisce
        return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
      }
    } catch (e) {
      // Fallback a un URL statico se c'è un errore di rete
      debugPrint("Errore nel recupero dell'URL di test: $e");
      return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
    }
  }

  // Nuovo metodo: Ottieni il percorso per la riproduzione locale
  Future<String> getLocalPlaybackUrl(Song song) async {
    if (song.localPath != null && song.isLocalOnly) {
      // Verifica che il file esista
      final file = File(song.localPath!);
      if (await file.exists()) {
        return 'file://${song.localPath}';
      } else {
        throw Exception('File locale non trovato');
      }
    } else if (song.isStreamingOnly) {
      // Per le canzoni in modalità streaming, ottieni l'URL di streaming
      final streamInfo = await getStreamUrl(song.videoId);
      return streamInfo['stream_url'];
    } else if (song.cloudUrl != null) {
      // Per le canzoni su cloud, usa l'URL del cloud
      return song.cloudUrl!;
    } else {
      throw Exception('Nessuna fonte di riproduzione disponibile per questa canzone');
    }
  }


  Future<String> getProxyStreamUrl(String videoId) async {
    // Controlla prima in cache
    final cachedUrl = StreamUrlCache.get(videoId);
    if (cachedUrl != null) {
      debugPrint("Stream URL trovato in cache: $cachedUrl");
      return cachedUrl;
    }
    
    final streamUrl = '$_baseUrl/api/stream/$videoId';
    
    try {
      // Verifica che il server sia raggiungibile
      final testResponse = await http.head(Uri.parse(streamUrl));
      
      if (testResponse.statusCode >= 200 && testResponse.statusCode < 300) {
        debugPrint("Stream URL verificato: $streamUrl");
        StreamUrlCache.set(videoId, streamUrl);
        return streamUrl;
      } else {
        debugPrint("Stream URL non disponibile (${testResponse.statusCode}), tentativo diretto...");
        // Se il proxy non è disponibile, ottieni l'URL diretto
        try {
          return await getDirectStreamUrl(videoId);
        } catch (e) {
          debugPrint("Anche il fallback diretto è fallito: $e");
          // Ultima risorsa: URL di test audio
          return await getTestAudioUrl();
        }
      }
    } catch (e) {
      debugPrint("Errore nella verifica dello stream URL: $e");
      
      try {
        // Fallback su URL diretto in caso di errore
        return await getDirectStreamUrl(videoId);
      } catch (e2) {
        debugPrint("Anche il fallback diretto è fallito: $e2");
        
        // Ultima risorsa: URL di test audio
        return await getTestAudioUrl();
      }
    }
  }

// Nuovo metodo per ottenere uno stream URL diretto da YouTube
Future<String> getDirectStreamUrl(String videoId) async {
  final url = Uri.parse('$_baseUrl/stream_url/$videoId');
  
  try {
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('stream_url')) {
        debugPrint("Stream URL diretto ottenuto: ${data['stream_url']}");
        return data['stream_url'];
      } else {
        throw Exception('Stream URL non trovato nella risposta');
      }
    } else {
      throw Exception('Errore nell\'ottenere lo stream URL: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("Errore nell'ottenimento dello stream URL diretto: $e");
    // Come ultima risorsa, usa un URL predefinito
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}
}
class StreamUrlCache {
  static final Map<String, String> _cache = {};
  static final Map<String, DateTime> _expiry = {};
  
  static const Duration _cacheTime = Duration(minutes: 30);
  
  static String? get(String videoId) {
    final url = _cache[videoId];
    if (url != null) {
      final expires = _expiry[videoId];
      if (expires != null && DateTime.now().isBefore(expires)) {
        return url;
      } else {
        // Rimuovi URL scaduti
        _cache.remove(videoId);
        _expiry.remove(videoId);
      }
    }
    return null;
  }
  
  static void set(String videoId, String url) {
    _cache[videoId] = url;
    _expiry[videoId] = DateTime.now().add(_cacheTime);
  }
}
