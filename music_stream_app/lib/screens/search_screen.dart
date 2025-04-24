// lib/screens/search_screen.dart (modifiche)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/widgets/search_result_item.dart';
import 'package:music_stream_app/theme.dart';
import 'package:music_stream_app/screens/download_options_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      _searchFocusNode.unfocus();
      Provider.of<AppState>(context, listen: false)
        ..setSearchQuery(_searchController.text)
        ..searchSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Cerca',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Cerca brani, artisti, album...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _showClearButton
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<AppState>(context, listen: false).setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  if (appState.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (appState.searchQuery.isEmpty) {
                    return _buildSearchSuggestions();
                  }

                  if (appState.searchResults.isEmpty) {
                    return const Center(
                      child: Text('Nessun risultato trovato'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: appState.searchResults.length,
                    itemBuilder: (context, index) {
                      final song = appState.searchResults[index];
                      return SearchResultItem(
                        song: song,
                        onTap: () => _showDownloadOptions(song), // Modificato per usare la nuova schermata
                        onPlay: () => _streamSong(appState, song), // Nuovo metodo per lo streaming diretto
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    // Suggerimenti di ricerca o generi musicali
    final List<Map<String, dynamic>> suggestions = [
      {'icon': Icons.trending_up, 'text': 'Tendenze', 'color': Colors.red},
      {'icon': Icons.music_note, 'text': 'Pop', 'color': Colors.blue},
      {'icon': Icons.electric_bolt, 'text': 'Rock', 'color': Colors.purple},
      {'icon': Icons.headphones, 'text': 'Hip Hop', 'color': Colors.orange},
      {'icon': Icons.piano, 'text': 'Classica', 'color': Colors.teal},
      {'icon': Icons.music_note, 'text': 'Jazz', 'color': Colors.amber},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggerimenti',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: suggestions.map((suggestion) {
              return InkWell(
                onTap: () {
                  _searchController.text = suggestion['text'];
                  _performSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: suggestion['color'], width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(suggestion['icon'], color: suggestion['color'], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        suggestion['text'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  // Nuovo metodo per mostrare la schermata di opzioni di download
  void _showDownloadOptions(song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadOptionsScreen(song: song),
      ),
    );
  }

  // Nuovo metodo per riprodurre direttamente una canzone in streaming
  Future<void> _streamSong(AppState appState, song) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Preparazione streaming...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Aggiunge la canzone come streaming e la riproduce
      final streamingSong = await appState.addStreamingSong(song);
      await appState.playSong(streamingSong);
      
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Errore durante lo streaming: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}