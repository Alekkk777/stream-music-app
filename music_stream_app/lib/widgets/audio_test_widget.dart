// lib/widgets/audio_test_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_stream_app/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';

class AudioTestWidget extends StatefulWidget {
  const AudioTestWidget({super.key});

  @override
  State<AudioTestWidget> createState() => _AudioTestWidgetState();
}

class _AudioTestWidgetState extends State<AudioTestWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _selectedFilePath;
  String? _streamUrl;
  String _statusMessage = 'Nessun file selezionato';
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _audioPlayer.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndPlayFile() async {
    try {
      setState(() {
        _statusMessage = 'Selezione file...';
      });

      // Usa FilePicker per selezionare un file audio
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        setState(() {
          _selectedFilePath = filePath;
          _statusMessage = 'File selezionato: $filePath';
        });

        await _playLocalFile(filePath);
      } else {
        setState(() {
          _statusMessage = 'Selezione file annullata';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Errore nella selezione del file: $e';
      });
    }
  }

  Future<void> _playLocalFile(String filePath) async {
    try {
      setState(() {
        _statusMessage = 'Tentativo di riproduzione: $filePath';
      });

      await _audioPlayer.stop();

      // Verifica se il file esiste
      final file = File(filePath);
      final exists = await file.exists();
      
      if (!exists) {
        setState(() {
          _statusMessage = 'File non trovato: $filePath';
        });
        return;
      }

      // Approccio 1: setFilePath
      try {
        setState(() {
          _statusMessage = 'Tentativo con setFilePath...';
        });
        await _audioPlayer.setFilePath(filePath);
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _statusMessage = 'Riproduzione riuscita con setFilePath';
        });
        return;
      } catch (e1) {
        setState(() {
          _statusMessage = 'Errore con setFilePath: $e1';
        });
        
        // Approccio 2: setUrl con file://
        try {
          setState(() {
            _statusMessage = 'Tentativo con setUrl e file://...';
          });
          final fileUrl = 'file://$filePath';
          await _audioPlayer.setUrl(fileUrl);
          await _audioPlayer.play();
          setState(() {
            _isPlaying = true;
            _statusMessage = 'Riproduzione riuscita con setUrl(file://)';
          });
          return;
        } catch (e2) {
          setState(() {
            _statusMessage = 'Errore anche con setUrl: $e2';
          });
          
          // Approccio 3: AudioSource.uri
          try {
            setState(() {
              _statusMessage = 'Tentativo con AudioSource.uri...';
            });
            await _audioPlayer.setAudioSource(
              AudioSource.uri(Uri.file(filePath))
            );
            await _audioPlayer.play();
            setState(() {
              _isPlaying = true;
              _statusMessage = 'Riproduzione riuscita con AudioSource.uri';
            });
            return;
          } catch (e3) {
            setState(() {
              _isPlaying = false;
              _statusMessage = 'Tutti i tentativi falliti. Errore finale: $e3';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _statusMessage = 'Errore generale: $e';
      });
    }
  }

  Future<void> _playStreamUrl() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Inserisci un URL valido';
      });
      return;
    }

    final url = _urlController.text;
    setState(() {
      _streamUrl = url;  
      _statusMessage = 'Tentativo di riproduzione URL: $_streamUrl';  
    });

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _statusMessage = 'Riproduzione URL riuscita';
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _statusMessage = 'Errore nella riproduzione URL: $e';
      });
    }
  }

  void _stopPlayback() {
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _statusMessage = 'Riproduzione fermata';
    });
  }

  // Nuovo metodo per testare l'audio con URL pubblico
  Future<void> _playTestAudio() async {
    setState(() {
      _statusMessage = 'Avvio test audio pubblico...';
    });

    try {
      // Usa il metodo in AppState per riprodurre l'audio di test
      final success = await Provider.of<AppState>(context, listen: false).debugPlayTestAudio();
      
      setState(() {
        _isPlaying = success;
        _statusMessage = success 
            ? 'Test audio pubblico: riproduzione riuscita'
            : 'Test audio pubblico: errore nella riproduzione';
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _statusMessage = 'Errore nel test audio pubblico: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Riproduzione Audio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            
            // Test file locale
            const Text('Test File Locale:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickAndPlayFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Seleziona e Riproduci File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isPlaying)
                  IconButton(
                    onPressed: _stopPlayback,
                    icon: const Icon(Icons.stop),
                    color: Colors.redAccent,
                  ),
              ],
            ),
            if (_selectedFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'File: $_selectedFilePath',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Test streaming URL
            const Text('Test URL Streaming:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Inserisci URL di streaming',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _playStreamUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                  child: const Text('Riproduci'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // NUOVO: Pulsante per test audio pubblico
            const Text('Test con audio pubblico:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _playTestAudio,
              icon: const Icon(Icons.public),
              label: const Text('Test Audio Pubblico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test URL pronto per Flask
            const Text('URL pronti per test:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            _buildQuickUrlButton('Test Stream YouTube', 'http://127.0.0.1:8000/api/stream/XKBjIaKUGhg'),
            const SizedBox(height: 4),
            _buildQuickUrlButton('Test MP3 statico', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
            
            const SizedBox(height: 16),
            
            // Stato attuale
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stato:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(_statusMessage),
                  const SizedBox(height: 4),
                  Text('Riproduzione: ${_isPlaying ? 'Attiva' : 'Inattiva'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickUrlButton(String label, String url) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _urlController.text = url;
          _playStreamUrl();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accentColor,
          side: BorderSide(color: AppTheme.accentColor),
          alignment: Alignment.centerLeft,
        ),
        child: Text(label),
      ),
    );
  }
}