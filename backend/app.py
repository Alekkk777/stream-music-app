# backend/app.py

# Aggiunta di nuovi import
from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS
import os
import requests
import tempfile
from youtube_search import search_youtube
from downloader import download_audio, get_youtube_stream_url, get_video_info
from cloud_storage import upload_to_cloud, download_from_cloud, list_files, delete_from_cloud
from database import (init_db, add_song, get_songs, get_playlists, add_playlist, 
                    add_song_to_playlist, get_song_by_id, remove_song, 
                    remove_song_from_playlist, delete_playlist_from_db, add_streaming_song_to_db)

app = Flask(__name__)
CORS(app)  # Abilita CORS per consentire richieste da Flutter

# Inizializza il database
init_db()

# Endpoint originali
@app.route('/api/search', methods=['GET'])
def search():
    query = request.args.get('q', '')
    if not query:
        return jsonify({'error': 'Query parameter is required'}), 400
    
    results = search_youtube(query)
    return jsonify(results)

@app.route('/api/download', methods=['POST'])
def download():
    data = request.json
    video_id = data.get('video_id')
    title = data.get('title')
    
    if not video_id:
        return jsonify({'error': 'Video ID is required'}), 400
    
    try:
        # Download del file audio
        file_path = download_audio(video_id, title)
        
        # Upload su Oracle Cloud
        cloud_url = upload_to_cloud(file_path)
        
        # Aggiungi al database
        song_id = add_song(title, video_id, cloud_url)
        
        # Rimuovi il file locale dopo l'upload
        os.remove(file_path)
        
        return jsonify({
            'success': True,
            'song_id': song_id,
            'title': title,
            'cloud_url': cloud_url
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    

@app.route('/api/test_audio', methods=['GET'])
def test_audio():
    """
    Endpoint per testare la riproduzione audio con un file MP3 statico.
    Utile per diagnosticare problemi client senza dipendere da YouTube.
    """
    try:
        test_url = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        return jsonify({
            'success': True,
            'stream_url': test_url,
            'title': 'Test Audio',
            'thumbnail': 'https://via.placeholder.com/480x360.png?text=Test+Audio',
            'channel': 'Test Channel'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/songs', methods=['GET'])
def get_all_songs():
    songs = get_songs()
    return jsonify(songs)

@app.route('/api/playlists', methods=['GET'])
def get_all_playlists():
    playlists = get_playlists()
    return jsonify(playlists)

@app.route('/api/playlists', methods=['POST'])
def create_playlist():
    data = request.json
    name = data.get('name')
    
    if not name:
        return jsonify({'error': 'Playlist name is required'}), 400
    
    playlist_id = add_playlist(name)
    return jsonify({'id': playlist_id, 'name': name})

@app.route('/api/playlists/<int:playlist_id>/songs', methods=['POST'])
def add_to_playlist(playlist_id):
    data = request.json
    song_id = data.get('song_id')
    
    if not song_id:
        return jsonify({'error': 'Song ID is required'}), 400
    
    try:
        add_song_to_playlist(playlist_id, song_id)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Nuovi endpoint
@app.route('/api/stream_url/<string:video_id>', methods=['GET'])
def get_stream_url(video_id):
    """
    Restituisce un URL per lo streaming diretto di un video di YouTube
    senza scaricare il file completo.
    """
    try:
        stream_url = get_youtube_stream_url(video_id)
        
        # Ottieni anche le informazioni sul video
        video_info = get_video_info(video_id)
        
        return jsonify({
            'stream_url': stream_url,
            'title': video_info['title'],
            'thumbnail': video_info['thumbnail'],
            'channel': video_info['channel']
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/download_local', methods=['POST'])
def download_local():
    """
    Scarica un file audio in locale e restituisce il percorso locale.
    Non carica su Oracle Cloud.
    """
    data = request.json
    video_id = data.get('video_id')
    title = data.get('title')
    
    if not video_id:
        return jsonify({'error': 'Video ID is required'}), 400
    
    try:
        # Download del file audio solo in locale
        local_path = download_audio(video_id, title, upload_to_cloud=False)
        
        # Aggiungi al database con flag per indicare che è solo locale
        song_id = add_song(title, video_id, cloud_url=None, local_path=local_path, is_local_only=True)
        
        return jsonify({
            'success': True,
            'song_id': song_id,
            'title': title,
            'local_path': local_path
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/delete_song/<int:song_id>', methods=['DELETE'])
def delete_song(song_id):
    """
    Elimina una canzone dal database e, opzionalmente, da Oracle Cloud e locale.
    """
    try:
        # Ottieni informazioni sulla canzone
        song_info = get_song_by_id(song_id)
        if not song_info:
            return jsonify({'error': 'Song not found'}), 404
        
        # Elimina da Oracle Cloud se necessario
        if song_info['cloud_url']:
            delete_from_cloud(song_info['video_id'])
            
        # Elimina file locale se esiste
        if song_info.get('local_path') and os.path.exists(song_info['local_path']):
            os.remove(song_info['local_path'])
            
        # Elimina dal database
        remove_song(song_id)
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/play_local/<int:song_id>', methods=['GET'])
def play_local_song(song_id):
    """
    Restituisce il file locale per la riproduzione.
    """
    try:
        # Ottieni percorso del file locale
        song_info = get_song_by_id(song_id)
        if not song_info or not song_info.get('local_path'):
            return jsonify({'error': 'Local file not found'}), 404
            
        local_path = song_info['local_path']
        if not os.path.exists(local_path):
            return jsonify({'error': 'File not found on disk'}), 404
            
        return send_file(local_path, mimetype='audio/mpeg')
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/playlists/<int:playlist_id>/songs/<int:song_id>', methods=['DELETE'])
def remove_from_playlist(playlist_id, song_id):
    """
    Rimuove una canzone da una playlist.
    """
    try:
        remove_song_from_playlist(playlist_id, song_id)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Endpoint per il player streaming
# Modifica dell'endpoint di streaming in app.py

# Modifica dell'endpoint di streaming in app.py

@app.route('/api/stream/<string:video_id>', methods=['GET'])
def stream_audio(video_id):
    """
    Stream diretto dell'audio da YouTube.
    Questo è un proxy per evitare problemi CORS.
    """
    try:
        # Ottieni URL dello stream
        stream_url = get_youtube_stream_url(video_id)
        print(f"Stream URL: {stream_url}")
        
        # Verifica se è stata richiesta una parte specifica del file (range)
        range_header = request.headers.get('Range', None)
        
        if range_header:
            # Se c'è un range header, facciamo un proxy diretto senza scaricare tutto il file
            headers = {
                'Range': range_header,
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
            }
            
            # Facciamo una richiesta HEAD per ottenere i dettagli del file
            head_response = requests.head(stream_url, headers={
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
            })
            
            # Se la richiesta HEAD fallisce, procediamo comunque con la GET
            content_length = head_response.headers.get('Content-Length', None)
            content_type = head_response.headers.get('Content-Type', 'audio/mpeg')
            
            # Prepariamo la risposta streaming
            req = requests.get(stream_url, headers=headers, stream=True)
            req.raise_for_status()
            
            # Creiamo una risposta streaming
            def generate():
                for chunk in req.iter_content(chunk_size=4096):
                    if chunk:
                        yield chunk
            
            # Prepariamo gli header della risposta
            response_headers = {
                'Content-Type': content_type,
                'Accept-Ranges': 'bytes',
                'Cache-Control': 'max-age=1800',  # Aggiungi 30 minuti di cache
                'Pragma': 'public',               # Consenti il caching
                'Expires': '1800'                 # 30 minuti
            }
            
            # Se abbiamo la lunghezza, aggiungiamola agli header
            if content_length:
                response_headers['Content-Length'] = content_length
                
            # Se la richiesta originale era con range, manteniamo il Content-Range
            if req.headers.get('Content-Range'):
                response_headers['Content-Range'] = req.headers.get('Content-Range')
                
            # Restituisci la risposta streaming
            return Response(generate(), headers=response_headers, status=req.status_code)
        else:
            # Se non c'è un range header, possiamo usare l'approccio file temporaneo
            temp_file = tempfile.NamedTemporaryFile(delete=False)
            
            # Scarica lo stream in blocchi e passalo al client
            req = requests.get(stream_url, stream=True)
            req.raise_for_status()
            
            for chunk in req.iter_content(chunk_size=8192):
                if chunk:
                    temp_file.write(chunk)
            
            temp_file.close()
            
            # Invia il file come risposta con headers ottimizzati per macOS
            headers = {
                'Accept-Ranges': 'bytes',
                'Cache-Control': 'max-age=1800',  # 30 minuti di cache
                'Content-Type': 'audio/mpeg'
            }
            
            # Invia il file come risposta
            return send_file(
                temp_file.name,
                mimetype='audio/mpeg',
                as_attachment=True,
                download_name=f"{video_id}.mp3",
                conditional=True,
                etag=True,
                headers=headers  # Aggiungi gli headers personalizzati
            )
    except Exception as e:
        print(f"Errore nello streaming: {str(e)}")
        return jsonify({'error': str(e)}), 500
    

@app.route('/api/playlists/<int:playlist_id>', methods=['DELETE'])
def delete_playlist(playlist_id):
    """
    Elimina una playlist e tutte le sue relazioni con i brani.
    """
    try:
        # Log per debug
        print(f"Tentativo di eliminazione della playlist: {playlist_id}")
        
        # Implementa la funzione nel modulo database
        delete_playlist_from_db(playlist_id)
        
        # Log per debug
        print(f"Playlist {playlist_id} eliminata con successo")
        
        return jsonify({'success': True})
    except Exception as e:
        print(f"Errore durante l'eliminazione della playlist {playlist_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/add_streaming_song', methods=['POST'])
def add_streaming_song():
    """
    Aggiunge un brano in modalità streaming al database senza scaricare il file.
    """
    data = request.json
    video_id = data.get('video_id')
    title = data.get('title')
    thumbnail = data.get('thumbnail')
    channel = data.get('channel')
    
    if not video_id or not title:
        return jsonify({'error': 'Video ID and title are required'}), 400
    
    try:
        # Aggiungi al database con flag is_streaming_only
        metadata = {
            'thumbnail': thumbnail,
            'channel': channel
        }
        
        song_id = add_streaming_song_to_db(
            title=title,
            video_id=video_id,
            metadata=metadata
        )
        
        return jsonify({
            'success': True,
            'song_id': song_id,
            'title': title,
            'thumbnail': thumbnail,
            'channel': channel,
            'is_streaming_only': True
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)