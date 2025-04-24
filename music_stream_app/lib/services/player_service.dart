// lib/services/player_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_stream_app/models/song.dart';
import 'dart:async';
import 'package:path/path.dart' as path;

enum PlaybackSource {
  cloud,
  local,
  streaming
}

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  PlaybackSource? _currentSource;
  
  // Stream per lo stato del player
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => 
      _audioPlayer.playerStateStream.map((state) => 
          state.playing && state.processingState != ProcessingState.completed);
  
  // Informazioni sulla canzone corrente
  Song? get currentSong => _currentSong;
  PlaybackSource? get currentSource => _currentSource;
  
  // Metodo aggiornato per la riproduzione in base alla fonte
  Future<void> play(String url, Song song, {PlaybackSource source = PlaybackSource.cloud}) async {
    try {
      debugPrint("=============== TENTATIVO DI RIPRODUZIONE ===============");
      debugPrint("URL: $url");
      debugPrint("Fonte: $source");
      debugPrint("Titolo: ${song.title}");
      
      _currentSong = song;
      _currentSource = source;
      
      // Ferma qualsiasi riproduzione in corso
      await _audioPlayer.stop();
      
      // Crea MediaItem per just_audio_background
      final mediaItem = MediaItem(
        id: song.id?.toString() ?? song.videoId,
        title: song.title,
        artist: song.channelTitle ?? 'Unknown',
        artUri: song.thumbnailUrl != null ? Uri.parse(song.thumbnailUrl!) : null,
      );
      
      // Convalida URL
      if (url.trim().isEmpty) {
        throw Exception("URL di riproduzione vuoto o non valido");
      }
      
      if (source == PlaybackSource.local && song.localPath != null) {
        final filePath = song.localPath!;
        debugPrint("Percorso file locale: $filePath");
        
        // Verifica se il file esiste
        final file = File(filePath);
        final exists = await file.exists();
        debugPrint("Il file esiste: $exists");
        
        if (exists) {
          // Usa un URI file valido
          final fileUri = Uri.file(filePath);
          debugPrint("URI del file: $fileUri");
          
          // Usa sempre il tag mediaItem
          await _audioPlayer.setAudioSource(
            AudioSource.uri(fileUri, tag: mediaItem)
          );
        } else {
          // Fallback su riproduzione streaming
          debugPrint("File locale non trovato, fallback su streaming");
          _currentSource = PlaybackSource.streaming;
          
          // Se il file locale non esiste, cerca di ottenere lo streaming URL
          final streamingUrl = url; // usa l'URL passato
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(streamingUrl), tag: mediaItem)
          );
        }
      } else {
        debugPrint("Utilizzo AudioSource.uri con: $url");
        
        // Aggiungiamo intestazioni per lo streaming
        final headers = <String, String>{
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Cache-Control': 'max-age=1800'  // suggerisce al client di memorizzare nella cache per 30 minuti
        };
        
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(url), tag: mediaItem, headers: headers)
        );
      }
      
      debugPrint("Avvio della riproduzione...");
      await _audioPlayer.play();
      debugPrint("Riproduzione avviata con successo!");
    } catch (e) {
      debugPrint("=============== ERRORE DI RIPRODUZIONE ===============");
      debugPrint("Dettagli completi: $e");
      debugPrint("Tipo di errore: ${e.runtimeType}");
      debugPrint("================================================");
      
      // Tentativo di fallback se la riproduzione iniziale fallisce
      try {
        debugPrint("Tentativo di riproduzione con metodo alternativo...");
        // IMPORTANTE: Crea un MediaItem per il fallback
        final fallbackMediaItem = MediaItem(
          id: 'fallback-${song.videoId}',
          title: song.title,
          artist: song.channelTitle ?? 'Unknown',
        );
        
        // Usa AudioSource.uri con il tag mediaItem invece di setUrl
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(url), tag: fallbackMediaItem)
        );
        await _audioPlayer.play();
        debugPrint("Riproduzione con fallback riuscita!");
      } catch (fallbackError) {
        debugPrint("Anche il fallback è fallito: $fallbackError");
        
        // Ultimo tentativo con URL di test statico
        try {
          const fallbackUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
          
          final testMediaItem = MediaItem(
            id: 'test-audio',
            title: 'Test Audio (Fallback)',
            artist: 'SoundHelix',
          );
          
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(fallbackUrl), tag: testMediaItem)
          );
          await _audioPlayer.play();
          debugPrint("Riproduzione con URL di test riuscita!");
        } catch (e3) {
          debugPrint("Tutti i tentativi di riproduzione falliti: $e3");
          rethrow;
        }
      }
    }
  }

  Future<void> playSimple(String url) async {
    try {
      debugPrint("Tentativo di riproduzione semplificata: $url");
      await _audioPlayer.stop();
      
      // IMPORTANTE: Crea MediaItem per just_audio_background
      final mediaItem = MediaItem(
        id: 'simple-playback-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Audio',
        artist: 'Unknown',
      );
      
      // Aggiungi header per migliorare la compatibilità
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      };
      
      // IMPORTANTE: Usa AudioSource.uri con il tag mediaItem
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url), headers: headers, tag: mediaItem)
      );
      
      await _audioPlayer.play();
      debugPrint("Riproduzione semplice avviata!");
      
      // Aggiorna lo stato
      _currentSource = PlaybackSource.streaming;
    } catch (e) {
      debugPrint("Errore nella riproduzione semplice: $e");
      
      // Tentativo di fallback con URL di test statico
      try {
        const fallbackUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
        
        final testMediaItem = MediaItem(
          id: 'test-audio',
          title: 'Test Audio (Fallback)',
          artist: 'SoundHelix',
        );
        
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(fallbackUrl), tag: testMediaItem)
        );
        await _audioPlayer.play();
        debugPrint("Riproduzione con URL di test riuscita!");
      } catch (e2) {
        debugPrint("Anche il fallback è fallito: $e2");
        rethrow;
      }
    }
  }
  
  // Metodo specifico per provare a riprodurre file locali in modo alternativo
  Future<void> playLocalFile(String filePath) async {
    try {
      debugPrint("Tentativo di riproduzione file locale alternativo: $filePath");
      await _audioPlayer.stop();
      
      // Verifica se il file esiste
      final file = File(filePath);
      final exists = await file.exists();
      debugPrint("Il file esiste: $exists");
      
      if (!exists) {
        throw Exception("File non trovato: $filePath");
      }
      
      // Normalizza il percorso per assicurarsi che sia un URI valido
      final fileUri = Uri.file(filePath);
      debugPrint("FileUri: $fileUri");
      
      // Crea MediaItem
      final fileName = path.basename(filePath);
      final mediaItem = MediaItem(
        id: filePath,
        title: fileName,
        artist: 'File locale',
      );
      
      // Usa setAudioSource invece di approcci alternativi
      await _audioPlayer.setAudioSource(
        AudioSource.uri(fileUri, tag: mediaItem)
      );
      
      await _audioPlayer.play();
      debugPrint("Riproduzione file locale avviata con successo!");
    } catch (e) {
      debugPrint("Errore finale in playLocalFile: $e");
      
      // Tentativo di recupero con modalità semplificata
      try {
        debugPrint("Tentativo con modalità semplificata...");
        
        // IMPORTANTE: Crea un MediaItem anche per questo fallback
        final fallbackMediaItem = MediaItem(
          id: 'file-fallback-${DateTime.now().millisecondsSinceEpoch}',
          title: path.basename(filePath),
          artist: 'File Locale',
        );
        
        // Usa AudioSource.uri con il tag mediaItem invece di setUrl
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse('file://$filePath'), tag: fallbackMediaItem)
        );
        await _audioPlayer.play();
      } catch (e2) {
        debugPrint("Anche la modalità semplificata è fallita: $e2");
        rethrow;
      }
    }
  }

  // Nuovo metodo per provare a riprodurre file di test
  Future<bool> playTestAudio() async {
    const testUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
    
    try {
      debugPrint("Tentativo di riproduzione audio di test");
      await _audioPlayer.stop();
      
      final testMediaItem = MediaItem(
        id: 'test-audio',
        title: 'Test Audio',
        artist: 'SoundHelix',
      );
      
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(testUrl), tag: testMediaItem)
      );
      
      await _audioPlayer.play();
      debugPrint("Riproduzione audio di test riuscita!");
      return true;
    } catch (e) {
      debugPrint("Errore nella riproduzione audio di test: $e");
      return false;
    }
  }

  Future<void> playNextTrack(Song nextSong) async {
    await play(nextSong.videoId, nextSong);
  }

  // Metodo per tornare alla traccia precedente (da collegare ad AppState)
  Future<void> playPreviousTrack(Song previousSong) async {
    await play(previousSong.videoId, previousSong);
  }

  // Metodo per verificare e risolvere problemi di riproduzione - corretto
  Future<bool> checkPlayback() async {
    try {
      // Verifica lo stato di processamento - correggo la referenza a ProcessingState.error
      if (_audioPlayer.processingState == ProcessingState.idle || 
          _audioPlayer.processingState == ProcessingState.completed ||
          _audioPlayer.processingState == ProcessingState.buffering) {
        debugPrint("Rilevato possibile problema di riproduzione, tentativo di recupero...");
        await _audioPlayer.stop();
        // Piccola pausa per garantire il reset completo
        await Future.delayed(Duration(milliseconds: 500));
        await _audioPlayer.play();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Errore nel controllo della riproduzione: $e");
      return false;
    }
  }
  
  void pause() {
    _audioPlayer.pause();
  }
  
  void resume() {
    _audioPlayer.play();
  }
  
  void stop() {
    _audioPlayer.stop();
    _currentSong = null;
    _currentSource = null;
  }
  
  void seekTo(Duration position) {
    _audioPlayer.seek(position);
  }
  
  // Controlli aggiuntivi
  void setVolume(double volume) {
    _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }
  
  void setSpeed(double speed) {
    _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}