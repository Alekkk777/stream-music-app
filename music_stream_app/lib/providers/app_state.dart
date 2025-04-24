// lib/providers/app_state.dart (corretto)
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/models/playlist.dart';
import 'package:music_stream_app/services/api_service.dart';
import 'package:music_stream_app/services/player_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final PlayerService _playerService = PlayerService();
  
  // Stato di riproduzione attuale
  List<Song> _currentPlaybackQueue = [];
  int _currentIndex = -1;
  
  // Stato di ricerca
  List<Song> _searchResults = [];
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Libreria musicale
  List<Song> _songs = [];
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  
  // Riproduzione
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  
  // Nuovi stati per la gestione delle diverse fonti di riproduzione
  PlaybackSource? _currentPlaybackSource;
  bool _isDownloading = false;
  String? _downloadProgress;
  
  // Getters
  List<Song> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  List<Song> get songs => _songs;
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds 
      : 0.0;
  List<Song> get currentPlaybackQueue => _currentPlaybackQueue;
  int get currentIndex => _currentIndex;
  PlaybackSource? get currentPlaybackSource => _currentPlaybackSource;
  bool get isDownloading => _isDownloading;
  String? get downloadProgress => _downloadProgress;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  
  bool get hasPrevious => _currentIndex > 0 && _currentPlaybackQueue.isNotEmpty;
  bool get hasNext => _currentIndex < _currentPlaybackQueue.length - 1 && _currentPlaybackQueue.isNotEmpty;

  bool _loopMode = false; // Loop dell'intera coda
  bool _loopOneSong = false;
  
  bool get loopMode => _loopMode;
  bool get loopOneSong => _loopOneSong;

  // Metodi per la ricerca
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  Future<void> searchSongs() async {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      final results = await _apiService.searchYoutube(_searchQuery);
      _searchResults = results;
    } catch (e) {
      debugPrint('Errore durante la ricerca: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  // Metodi per la libreria
  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _songs = await _apiService.getSongs();
      _playlists = await _apiService.getPlaylists();
    } catch (e) {
      debugPrint('Errore durante il caricamento della libreria: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Metodo per scaricare su cloud (esistente modificato)
  bool songExists(String videoId) {
    return _songs.any((s) => s.videoId == videoId);
  }

  // Metodo rinominato per verificare duplicati
  bool checkSongExists(String videoId) {
    return _songs.any((s) => s.videoId == videoId);
  }

  void toggleLoopMode() {
    if (!_loopMode && !_loopOneSong) {
      // Prima attiva il loop della coda
      _loopMode = true;
      _loopOneSong = false;
    } else if (_loopMode && !_loopOneSong) {
      // Poi attiva il loop della singola canzone
      _loopMode = false;
      _loopOneSong = true;
    } else {
      // Infine disattiva entrambi
      _loopMode = false;
      _loopOneSong = false;
    }
    notifyListeners();
  }

  // Metodo per determinare la fonte di riproduzione (ora utilizzato)
  PlaybackSource determinePlaybackSource(Song song) {
    if (song.isLocalOnly && song.localPath != null) {
      return PlaybackSource.local;
    } else if (song.cloudUrl != null) {
      return PlaybackSource.cloud;
    } else {
      return PlaybackSource.streaming;
    }
  }
  
  // Metodo per ottenere l'URL di riproduzione (ora utilizzato)
  Future<String> getPlaybackUrl(Song song) async {
    if (song.isLocalOnly && song.localPath != null && await File(song.localPath!).exists()) {
      return song.localPath!;
    } else if (song.cloudUrl != null) {
      return song.cloudUrl!;
    } else {
      // Default a streaming tramite proxy
      return await _apiService.getProxyStreamUrl(song.videoId);
    }
  }

  Future<bool> debugPlayTestAudio() async {
    debugPrint("==== TEST AUDIO CON FILE PUBBLICO ====");
    try {
      // Prima prova a ottenere l'URL dal server
      String testUrl;
      try {
        testUrl = await _apiService.getTestAudioUrl();
        debugPrint("URL di test ottenuto dall'API: $testUrl");
      } catch (e) {
        // Se il server non risponde, usa un URL statico
        debugPrint("Errore nel recupero dell'URL di test, utilizzo URL statico: $e");
        testUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
      }
      
      // Crea una canzone fittizia per il test
      final testSong = Song(
        id: -1,
        videoId: "test-audio",
        title: "Test Audio",
        isStreamingOnly: true,
      );
      
      await _playerService.play(testUrl, testSong, source: PlaybackSource.streaming);
      
      _currentSong = testSong;
      _isPlaying = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint("Errore test audio: $e");
      
      // Prova direttamente con il metodo playTestAudio del PlayerService
      try {
        debugPrint("Tentativo con metodo playTestAudio diretto...");
        final success = await _playerService.playTestAudio();
        
        if (success) {
          _isPlaying = true;
          notifyListeners();
        }
        
        return success;
      } catch (e2) {
        debugPrint("Anche il tentativo diretto è fallito: $e2");
        return false;
      }
    }
  }

  // Modifica il metodo downloadSong per verificare duplicati
  Future<Song?> downloadSong(Song song) async {
    // Verifica se la canzone esiste già
    if (checkSongExists(song.videoId)) {
      // Trova la canzone nella libreria
      final existingSong = _songs.firstWhere((s) => s.videoId == song.videoId);
      
      // Se è già scaricata, mostra un messaggio
      if (existingSong.cloudUrl != null) {
        debugPrint('La canzone è già stata scaricata nel cloud.');
        return existingSong;
      }
    }
    
    _isDownloading = true;
    _downloadProgress = "Downloading ${song.title}...";
    notifyListeners();
    
    try {
      final downloadedSong = await _apiService.downloadSong(song.videoId, song.title);
      
      // Aggiorna la libreria
      if (!_songs.any((s) => s.id == downloadedSong.id)) {
        _songs.add(downloadedSong);
      } else {
        // Aggiorna la canzone esistente
        final index = _songs.indexWhere((s) => s.id == downloadedSong.id);
        if (index >= 0) {
          _songs[index] = downloadedSong;
        }
      }
      
      return downloadedSong;
    } catch (e) {
      debugPrint('Errore durante il download: $e');
      rethrow;
    } finally {
      _isDownloading = false;
      _downloadProgress = null;
      notifyListeners();
    }
  }
  
  // Nuovo metodo: download locale
  Future<Song?> downloadSongLocally(Song song) async {
    _isDownloading = true;
    _downloadProgress = "Downloading locally ${song.title}...";
    notifyListeners();
    
    try {
      final downloadedSong = await _apiService.downloadSongLocally(song.videoId, song.title);
      
      // Aggiorna la libreria
      if (!_songs.any((s) => s.id == downloadedSong.id)) {
        _songs.add(downloadedSong);
      } else {
        // Aggiorna la canzone esistente
        final index = _songs.indexWhere((s) => s.id == downloadedSong.id);
        if (index >= 0) {
          _songs[index] = downloadedSong;
        }
      }
      
      return downloadedSong;
    } catch (e) {
      debugPrint('Errore durante il download locale: $e');
      rethrow;
    } finally {
      _isDownloading = false;
      _downloadProgress = null;
      notifyListeners();
    }
  }
  
  // Nuovo metodo: Aggiunge una canzone in modalità streaming (senza download)
  Future<Song> addStreamingSong(Song song) async {
    try {
      // Controlla se la canzone è già nel database
      final existingSong = _songs.firstWhere(
        (s) => s.videoId == song.videoId,
        orElse: () => song,
      );
      
      // Se la canzone ha già un ID, restituisci quella esistente
      if (existingSong.id != null) {
        return existingSong;
      }
      
      // Ottieni informazioni di streaming e URL
      final streamUrl = await _apiService.getProxyStreamUrl(song.videoId);
      debugPrint('Stream URL: $streamUrl');
      
      try {
        final streamInfo = await _apiService.getStreamUrl(song.videoId);
        final title = streamInfo['title'] ?? song.title;
        final thumbnail = streamInfo['thumbnail'] ?? song.thumbnailUrl;
        final channel = streamInfo['channel'] ?? song.channelTitle;
        
        // Crea una nuova song con le informazioni dello streaming
        final newSong = Song(
          id: _songs.isEmpty ? 1 : (_songs.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1),
          videoId: song.videoId,
          title: title,
          thumbnailUrl: thumbnail,
          channelTitle: channel,
          isStreamingOnly: true,
        );
        
        _songs.add(newSong);
        notifyListeners();
        
        return newSong;
      } catch (e) {
        // Se non riusciamo a ottenere info da YouTube, usiamo quelle che abbiamo
        final newSong = Song(
          id: _songs.isEmpty ? 1 : (_songs.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1),
          videoId: song.videoId,
          title: song.title,
          thumbnailUrl: song.thumbnailUrl,
          channelTitle: song.channelTitle,
          isStreamingOnly: true,
        );
        
        _songs.add(newSong);
        notifyListeners();
        
        return newSong;
      }
    } catch (e) {
      debugPrint('Errore nell\'aggiunta di una canzone in streaming: $e');
      rethrow;
    }
  }


  Future<void> deleteLocalFile(Song song) async {
    await deleteSong(song, localOnly: true);
  }

  
  // Nuovo metodo: Elimina una canzone
  Future<void> deleteSong(Song song, {bool localOnly = false}) async {
    if (song.id == null) {
      throw Exception('Non è possibile eliminare una canzone senza ID');
    }
    
    try {
      debugPrint('Tentativo di eliminazione del brano: ${song.id} - ${song.title}');
      debugPrint('Modalità: ${localOnly ? "solo locale" : "completa"}');
      
      // Controlla se la canzone è in riproduzione
      if (_currentSong?.id == song.id) {
        stop();
      }
      
      if (localOnly) {
        // Elimina solo il file locale senza rimuovere dal database
        if (song.localPath != null) {
          final file = File(song.localPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('File locale eliminato con successo: ${song.localPath}');
          } else {
            debugPrint('File locale non trovato: ${song.localPath}');
          }
          
          // Aggiorna lo stato del brano (rendi il brano solo streaming)
          final updatedSong = song.copyWith(
            localPath: null,
            isLocalOnly: false,
            isStreamingOnly: true,
          );
          
          // Aggiorna la versione locale
          final index = _songs.indexWhere((s) => s.id == song.id);
          if (index >= 0) {
            _songs[index] = updatedSong;
            debugPrint('Stato locale del brano aggiornato');
          }
          
          // Dovresti anche sincronizzare con il backend (chiamata API)
          // Per ora possiamo lasciare questa parte commentata
          
          // Se il brano è in qualche playlist, aggiorniamolo anche lì
          for (var i = 0; i < _playlists.length; i++) {
            final playlist = _playlists[i];
            final songIndex = playlist.songs.indexWhere((s) => s.id == song.id);
            
            if (songIndex >= 0) {
              // Crea una nuova lista di canzoni con la canzone aggiornata
              final updatedSongs = List<Song>.from(playlist.songs);
              updatedSongs[songIndex] = updatedSong;
              
              // Aggiorna la playlist
              _playlists[i] = Playlist(
                id: playlist.id,
                name: playlist.name,
                songs: updatedSongs,
                createdAt: playlist.createdAt,
              );
            }
          }
        } else {
          debugPrint('Nessun file locale da eliminare per questo brano');
        }
      } else {
        // Eliminazione completa del brano
        debugPrint('Avvio eliminazione completa del brano con ID: ${song.id}');
        
        // Elimina la canzone dal server
        await _apiService.deleteSong(song.id!);
        
        // Rimuovi la canzone dalla lista locale
        _songs.removeWhere((s) => s.id == song.id);
        
        // Rimuovi la canzone da tutte le playlist
        for (var i = 0; i < _playlists.length; i++) {
          final playlist = _playlists[i];
          if (playlist.songs.any((s) => s.id == song.id)) {
            final updatedSongs = playlist.songs.where((s) => s.id != song.id).toList();
            _playlists[i] = Playlist(
              id: playlist.id,
              name: playlist.name,
              songs: updatedSongs,
              createdAt: playlist.createdAt,
            );
          }
        }
      }
      
      debugPrint('Operazione completata con successo');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante l\'eliminazione del brano: $e');
      rethrow;
    }
  }

  Future<void> addToQueue(Song song) async {
    try {
      // Se non c'è una coda attiva, crea una coda con tutti i brani della libreria
      // partendo dalla posizione corrente
      if (_currentPlaybackQueue.isEmpty && _currentSong == null) {
        await playSong(song);
        return;
      }
      
      // Se c'è già una coda attiva
      if (_currentPlaybackQueue.isNotEmpty) {
        // Verifica se il brano è già nella coda
        final index = _currentPlaybackQueue.indexWhere((s) => s.videoId == song.videoId);
        
        if (index >= 0 && index > _currentIndex) {
          // Se il brano è già nella coda dopo la posizione corrente, non fare nulla
          debugPrint('Il brano è già in coda alla posizione ${index + 1}');
          return;
        } else if (index >= 0 && index <= _currentIndex) {
          // Se il brano è già nella coda prima o alla posizione corrente, 
          // rimuovilo per aggiungerlo alla fine
          _currentPlaybackQueue.removeAt(index);
          
          // Correggi l'indice corrente se necessario
          if (index < _currentIndex) {
            _currentIndex--;
          }
        }
        
        // Aggiungi il brano alla fine della coda
        _currentPlaybackQueue.add(song);
        debugPrint('Brano aggiunto alla coda, nuova lunghezza: ${_currentPlaybackQueue.length}');
        
        notifyListeners();
      } else {
        // Se non c'è una coda, ma c'è un brano in riproduzione,
        // crea una coda con il brano corrente e quello nuovo
        if (_currentSong != null) {
          _currentPlaybackQueue = [_currentSong!];
          _currentIndex = 0;
          _currentPlaybackQueue.add(song);
          debugPrint('Creata nuova coda di riproduzione con 2 brani');
          
          notifyListeners();
        } else {
          // Se non c'è né una coda né un brano in riproduzione,
          // riproduci direttamente il brano
          await playSong(song);
        }
      }
    } catch (e) {
      debugPrint('Errore durante l\'aggiunta alla coda: $e');
      rethrow;
    }
  }

  // Metodo per ottenere la coda di riproduzione attuale
  List<Song> getQueue() {
    return _currentPlaybackQueue;
  }

  // Metodo per rimuovere un brano dalla coda
  void removeFromQueue(int queueIndex) {
    if (queueIndex < 0 || queueIndex >= _currentPlaybackQueue.length) {
      return; // Indice fuori dai limiti
    }
    
    // Se l'indice è prima dell'indice corrente, aggiorna l'indice corrente
    if (queueIndex < _currentIndex) {
      _currentIndex--;
    }
    
    // Se l'indice è l'indice corrente, passa al brano successivo
    if (queueIndex == _currentIndex && _isPlaying) {
      playNextSong();
    }
    
    // Rimuovi il brano dalla coda
    _currentPlaybackQueue.removeAt(queueIndex);
    
    // Se la coda è ora vuota, interrompi la riproduzione
    if (_currentPlaybackQueue.isEmpty) {
      stop();
    }
    
    notifyListeners();
  }

  // Metodo per pulire completamente la coda (tranne il brano in riproduzione)
  void clearQueue() {
    if (_currentPlaybackQueue.isEmpty) return;
    
    // Se c'è un brano in riproduzione, mantienilo
    if (_currentIndex >= 0 && _currentIndex < _currentPlaybackQueue.length) {
      final currentSong = _currentPlaybackQueue[_currentIndex];
      _currentPlaybackQueue = [currentSong];
      _currentIndex = 0;
    } else {
      _currentPlaybackQueue = [];
      _currentIndex = -1;
    }
    
    notifyListeners();
  }

  
  
  // Metodi per le playlist
  Future<void> createPlaylist(String name) async {
    try {
      final newPlaylist = await _apiService.createPlaylist(name);
      _playlists.add(newPlaylist);
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante la creazione della playlist: $e');
      rethrow;
    }
  }
  
  // Metodo modificato per consentire l'aggiunta di canzoni non scaricate
  Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    try {
      debugPrint('Aggiunta del brano alla playlist: ${song.videoId} - ${song.title}');
      
      // Variabile per tenere traccia del brano aggiornato
      Song updatedSong = song;
      
      // Se la canzone non ha un ID o è solo in streaming (non ha URL cloud)
      if (song.id == null || (song.isStreamingOnly && song.cloudUrl == null)) {
        debugPrint("La canzone non ha un ID o è solo in streaming. Scaricandola su cloud...");
        
        // Se è una canzone che è solo in streaming, dobbiamo prima scaricarla
        if (song.isStreamingOnly) {
          // Mostra notifica che stiamo scaricando
          // Nota: questo va gestito dall'interfaccia grafica, non qui
          
          // Scarica la canzone su cloud
          updatedSong = (await downloadSong(song))!;
          
          debugPrint("Canzone scaricata su cloud: ${updatedSong.cloudUrl}");
        } else {
          // Se è una nuova canzone non ancora nel database
          // Aggiungila come streaming e poi scaricala
          final streamingSong = await addStreamingSong(song);
          updatedSong = (await downloadSong(streamingSong))!;
        }
        
        // A questo punto, updatedSong dovrebbe avere un ID e un cloud_url
        if (updatedSong.id == null) {
          throw Exception('Impossibile ottenere un ID per questa canzone dopo il download');
        }
      }
      
      // Ora aggiungi la canzone con ID alla playlist
      await _apiService.addSongToPlaylist(playlist.id, updatedSong.id!);
      
      // Aggiorna la playlist locale
      _updatePlaylistWithNewSong(playlist, updatedSong);
      
      // Ricarica le playlist per assicurarsi che l'UI sia aggiornata
      await loadPlaylists();
    } catch (e) {
      debugPrint('Errore durante l\'aggiunta alla playlist: $e');
      rethrow;
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _currentPlaybackQueue.length || 
        newIndex < 0 || newIndex >= _currentPlaybackQueue.length) {
      return; // Indici fuori dai limiti
    }
    
    // Gestione delle restrizioni di riordinamento
    
    // Non permettere di spostare il brano in riproduzione
    if (oldIndex == _currentIndex) {
      debugPrint('Tentativo di spostare il brano in riproduzione: operazione non consentita');
      return;
    }
    
    // Non permettere di spostare un brano prima di quello in riproduzione
    if (newIndex <= _currentIndex && oldIndex > _currentIndex) {
      debugPrint('Tentativo di inserire un brano prima di quello in riproduzione: operazione non consentita');
      return;
    }
    
    // Gestisci lo spostamento di un brano dopo quello in riproduzione
    if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      // Stiamo spostando un brano da prima a dopo il brano corrente
      _currentIndex--; // Aggiustiamo l'indice corrente perché un brano prima è stato rimosso
    }
    
    // Ottieni il brano da spostare
    final song = _currentPlaybackQueue.removeAt(oldIndex);
    
    // Aggiorna l'indice corrente se necessario
    if (oldIndex < _currentIndex) {
      // Se rimuoviamo un brano prima dell'indice corrente, l'indice corrente si sposta indietro
      _currentIndex--;
    }
    
    // Gestisci l'inserimento del brano
    if (newIndex <= _currentIndex) {
      // Se inseriamo un brano prima o all'indice corrente, l'indice corrente si sposta avanti
      _currentIndex++;
    }
    
    // Inserisci il brano alla nuova posizione
    _currentPlaybackQueue.insert(newIndex, song);
    
    debugPrint('Riordinamento coda completato: vecchio indice=$oldIndex, nuovo indice=$newIndex, indice corrente=$_currentIndex');
    notifyListeners();
  }

  Future<void> loadPlaylists() async {
    try {
      _playlists = await _apiService.getPlaylists();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante il caricamento delle playlist: $e');
    }
  }
  
  // Metodo di utilità per aggiornare la playlist locale
  void _updatePlaylistWithNewSong(Playlist playlist, Song song) {
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      // Aggiungiamo la canzone alla lista di canzoni
      final updatedSongs = List<Song>.from(_playlists[index].songs)..add(song);
      
      // Creiamo una nuova playlist con le canzoni aggiornate
      final updatedPlaylist = Playlist(
        id: _playlists[index].id,
        name: _playlists[index].name,
        songs: updatedSongs,
        createdAt: _playlists[index].createdAt,
      );
      
      // Sostituiamo la playlist nella lista
      _playlists[index] = updatedPlaylist;
      notifyListeners();
    }
  }
  
  // Nuovo metodo: Rimuovi canzone da playlist
  Future<void> removeSongFromPlaylist(Playlist playlist, Song song) async {
    try {
      if (song.id == null) {
        throw Exception('Song ID è null e non può essere rimosso dalla playlist');
      }
      
      await _apiService.removeSongFromPlaylist(playlist.id, song.id!);
      
      // Aggiorna la playlist locale
      final index = _playlists.indexWhere((p) => p.id == playlist.id);
      if (index >= 0) {
        // Rimuovi la canzone dalla lista
        final updatedSongs = List<Song>.from(_playlists[index].songs)
          ..removeWhere((s) => s.id == song.id);
        
        // Crea una nuova playlist con le canzoni aggiornate
        final updatedPlaylist = Playlist(
          id: _playlists[index].id,
          name: _playlists[index].name,
          songs: updatedSongs,
          createdAt: _playlists[index].createdAt,
        );
        
        // Sostituisci la playlist nella lista
        _playlists[index] = updatedPlaylist;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Errore durante la rimozione dalla playlist: $e');
      rethrow;
    }
  }
  
  // Metodi per il player - aggiornati per gestire le diverse fonti
  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    // Se viene specificata una coda di riproduzione, la utilizziamo
    if (queue != null && queue.isNotEmpty) {
      _currentPlaybackQueue = List.from(queue);
      _currentIndex = index ?? queue.indexOf(song);
      if (_currentIndex < 0) {
        _currentIndex = 0;
      }
    } else if (_currentPlaybackQueue.isEmpty) {
      // Se non c'è una coda attiva, crea una coda con tutti i brani della libreria
      // In questo modo l'utente può navigare tra tutti i brani
      _currentPlaybackQueue = List.from(_songs);
      _currentIndex = _songs.indexOf(song);
      if (_currentIndex < 0) {
        // Se il brano non è nella libreria, crea una coda con solo questo brano
        _currentPlaybackQueue = [song];
        _currentIndex = 0;
      }
    } else {
      // Se c'è già una coda attiva ma non è stata specificata, manteniamo quella attuale
      // e aggiorniamo solo l'indice per puntare al nuovo brano
      final indexInCurrentQueue = _currentPlaybackQueue.indexWhere((s) => s.videoId == song.videoId);
      if (indexInCurrentQueue >= 0) {
        _currentIndex = indexInCurrentQueue;
      } else {
        // Se il brano non è nella coda attuale, aggiungiamolo e riproduciamolo
        _currentPlaybackQueue.add(song);
        _currentIndex = _currentPlaybackQueue.length - 1;
      }
    }
    
    _currentSong = song;
    
    try {
      // Utilizziamo i metodi helper che abbiamo definito
      final playbackUrl = await getPlaybackUrl(song);
      final source = determinePlaybackSource(song);
      
      await _playerService.play(playbackUrl, song, source: source);
      _currentPlaybackSource = source;
      _isPlaying = true;
      _listenToPlayerState();
    } catch (e) {
      debugPrint('Errore durante la riproduzione: $e');
      _isPlaying = false;
    }
    
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    try {
      debugPrint('Tentativo di eliminazione della playlist: ${playlist.id} - ${playlist.name}');
      
      // Chiamata API per eliminare la playlist sul server
      await _apiService.deletePlaylist(playlist.id);
      
      // Rimuovi la playlist dalla lista locale
      _playlists.removeWhere((p) => p.id == playlist.id);
      
      debugPrint('Playlist eliminata con successo');
      
      // Notifica i listener che la lista delle playlist è cambiata
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante l\'eliminazione della playlist: $e');
      rethrow;
    }
  }

  bool isSongDownloadedLocally(Song song) {
    return song.isLocalOnly && song.localPath != null;
  }

  // Metodo per verificare se una canzone è scaricata nel cloud
  bool isSongDownloadedInCloud(Song song) {
    return song.cloudUrl != null;
  }

  Future<bool> debugPlaySong(Song song) async {
    debugPrint("==== DEBUG: INIZIO TEST RIPRODUZIONE ====");
    debugPrint("Canzone: ${song.title}");
    debugPrint("VideoID: ${song.videoId}");
    
    // Lista di fallimenti
    List<String> failures = [];
    
    // STRATEGIA 1: Streaming diretto dal backend
    try {
      debugPrint("STRATEGIA 1: Streaming tramite backend proxy");
      final streamUrl = await _apiService.getProxyStreamUrl(song.videoId);
      
      if (streamUrl.isNotEmpty) {
        await _playerService.play(streamUrl, song, source: PlaybackSource.streaming);
        debugPrint("✅ STRATEGIA 1 SUCCESSO!");
        return true;
      } else {
        failures.add("URL streaming vuoto");
      }
    } catch (e) {
      failures.add("Strategia 1 fallita: $e");
      debugPrint("❌ STRATEGIA 1 FALLITA: $e");
    }
    
    // STRATEGIA 2: URL di streaming diretto da YouTube
    try {
      debugPrint("STRATEGIA 2: URL streaming diretto da YouTube");
      final streamInfo = await _apiService.getStreamUrl(song.videoId);
      final directUrl = streamInfo['stream_url'];
      
      if (directUrl != null && directUrl.isNotEmpty) {
        await _playerService.play(directUrl, song, source: PlaybackSource.streaming);
        debugPrint("✅ STRATEGIA 2 SUCCESSO!");
        return true;
      } else {
        failures.add("URL streaming diretto non disponibile");
      }
    } catch (e) {
      failures.add("Strategia 2 fallita: $e");
      debugPrint("❌ STRATEGIA 2 FALLITA: $e");
    }
    
    // STRATEGIA 3: Audio Player semplificato
    try {
      debugPrint("STRATEGIA 3: Player semplificato con URL proxy");
      final streamUrl = await _apiService.getProxyStreamUrl(song.videoId);
      
      if (streamUrl.isNotEmpty) {
        await _playerService.playSimple(streamUrl);
        debugPrint("✅ STRATEGIA 3 SUCCESSO!");
        return true;
      } else {
        failures.add("URL per player semplificato non disponibile");
      }
    } catch (e) {
      failures.add("Strategia 3 fallita: $e");
      debugPrint("❌ STRATEGIA 3 FALLITA: $e");
    }
    
    // STRATEGIA 4: URL pubblico esterno
    try {
      debugPrint("STRATEGIA 4: URL audio pubblico esterno di test");
      final testUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
      
      await _playerService.playSimple(testUrl);
      debugPrint("✅ STRATEGIA 4 SUCCESSO (ma con audio di test)!");
      _currentSong = song; // Impostiamo comunque la canzone corrente
      _isPlaying = true;
      notifyListeners();
      return true;
    } catch (e) {
      failures.add("Strategia 4 fallita: $e");
      debugPrint("❌ STRATEGIA 4 FALLITA: $e");
    }
    
    // Se siamo qui, tutte le strategie sono fallite
    debugPrint("==== DEBUG: TUTTE LE STRATEGIE FALLITE ====");
    for (var failure in failures) {
      debugPrint("- $failure");
    }
    
    return false;
  }
  
  // Nuovo metodo per testare la riproduzione di file locali
  Future<void> testPlayLocalFile(String filePath) async {
    try {
      await _playerService.playLocalFile(filePath);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Errore nel test di riproduzione locale: $e');
      rethrow;
    }
  }
  
  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    if (playlist.songs.isEmpty) return;
    
    int index = startIndex.clamp(0, playlist.songs.length - 1);
    await playSong(playlist.songs[index], queue: playlist.songs, index: index);
  }
  
  // Metodo corretto per playPreviousSong che utilizza i metodi helper
  Future<void> playPreviousSong() async {
    if (!hasPrevious) return;
    
    _currentIndex--;
    final song = _currentPlaybackQueue[_currentIndex];
    
    try {
      final playbackUrl = await getPlaybackUrl(song);
      final source = determinePlaybackSource(song);
      
      await _playerService.play(playbackUrl, song, source: source);
      _currentPlaybackSource = source;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante la riproduzione del brano precedente: $e');
    }
  }

  
  // Metodo simile per playNextSong che utilizza i metodi helper
  Future<void> playNextSong() async {
    // Se siamo in modalità loop singola canzone, riproduci lo stesso brano
    if (_loopOneSong && _currentSong != null) {
      try {
        final playbackUrl = await getPlaybackUrl(_currentSong!);
        final source = determinePlaybackSource(_currentSong!);
        
        await _playerService.play(playbackUrl, _currentSong!, source: source);
        _currentPlaybackSource = source;
        
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Errore durante la riproduzione del brano in loop: $e');
      }
    }
    
    // Se siamo all'ultimo brano e in modalità loop coda, torna al primo
    if (!hasNext && _loopMode && _currentPlaybackQueue.isNotEmpty) {
      _currentIndex = 0;
      final song = _currentPlaybackQueue[_currentIndex];
      
      try {
        final playbackUrl = await getPlaybackUrl(song);
        final source = determinePlaybackSource(song);
        
        await _playerService.play(playbackUrl, song, source: source);
        _currentPlaybackSource = source;
        _currentSong = song;
        
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Errore durante la riproduzione in modalità loop: $e');
      }
    }
    
    // Comportamento normale se non c'è loop o se non siamo alla fine
    if (!hasNext) return;
    
    _currentIndex++;
    final song = _currentPlaybackQueue[_currentIndex];
    
    try {
      final playbackUrl = await getPlaybackUrl(song);
      final source = determinePlaybackSource(song);
      
      await _playerService.play(playbackUrl, song, source: source);
      _currentPlaybackSource = source;
      _currentSong = song;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante la riproduzione del brano successivo: $e');
    }
  }

  void shuffleQueue() {
    if (_currentPlaybackQueue.isEmpty) return;
    
    // Se c'è una canzone in riproduzione, mantienila in prima posizione
    Song? currentSong;
    if (_currentIndex >= 0 && _currentIndex < _currentPlaybackQueue.length) {
      currentSong = _currentPlaybackQueue[_currentIndex];
      _currentPlaybackQueue.removeAt(_currentIndex);
    }
    
    // Mescola il resto della coda
    _currentPlaybackQueue.shuffle();
    
    // Rimetti la canzone corrente all'inizio
    if (currentSong != null) {
      _currentPlaybackQueue.insert(0, currentSong);
      _currentIndex = 0;
    }
    
    notifyListeners();
  }
  
  void _listenToPlayerState() {
    _playerService.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
    
    _playerService.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });
    
    _playerService.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
      
      // Aggiungi questo blocco per gestire la fine del brano
      if (!playing && _position.inMilliseconds > 0 && 
          _position.inMilliseconds >= _duration.inMilliseconds - 500) {
        // Il brano è finito, verifichiamo se dobbiamo passare al successivo
        if (hasNext) {
          playNextSong();
        } else {
          // Se non c'è un brano successivo, resettiamo la posizione
          _position = Duration.zero;
          notifyListeners();
        }
      }
    });
  }
  
  void togglePlay() {
    if (_currentSong == null) return;
    
    if (_isPlaying) {
      _playerService.pause();
    } else {
      _playerService.resume();
    }
  }
  
  void seekTo(Duration position) {
    _playerService.seekTo(position);
  }
  
  void stop() {
    _playerService.stop();
    _currentSong = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentPlaybackQueue = [];
    _currentIndex = -1;
    _currentPlaybackSource = null;
    notifyListeners();
  }
  
  // Controlli aggiuntivi
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _playerService.setVolume(_volume);
    notifyListeners();
  }
  
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    _playerService.setSpeed(_playbackSpeed);
    notifyListeners();
  }
  
  // Metodo per mostrare tutte le playlist disponibili per aggiungere una canzone
  List<Playlist> getPlaylistsForSong(Song song) {
    // Restituisce tutte le playlist (non filtriamo più per song.id)
    return _playlists;
  }
  
  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }
}