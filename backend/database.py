# backend/database.py
import sqlite3
import os
import json

# Percorso del database
DB_PATH = 'music_app.db'

def init_db():
    """
    Inizializza il database SQLite con le tabelle necessarie.
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Modificare la tabella songs per aggiungere supporto per file locali
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        video_id TEXT UNIQUE NOT NULL,
        cloud_url TEXT,
        local_path TEXT,
        is_local_only BOOLEAN DEFAULT 0,
        is_streaming_only BOOLEAN DEFAULT 0,
        metadata TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''')
    
    # Verifica se è necessario aggiornare la tabella esistente
    try:
        cursor.execute("SELECT local_path FROM songs LIMIT 1")
    except sqlite3.OperationalError:
        # Aggiungi colonne mancanti a una tabella esistente
        cursor.execute("ALTER TABLE songs ADD COLUMN local_path TEXT")
        cursor.execute("ALTER TABLE songs ADD COLUMN is_local_only BOOLEAN DEFAULT 0")
        cursor.execute("ALTER TABLE songs ADD COLUMN is_streaming_only BOOLEAN DEFAULT 0")
        
        # Rendi cloud_url opzionale per le canzoni di solo streaming
        cursor.execute("CREATE TABLE songs_temp AS SELECT * FROM songs")
        cursor.execute("DROP TABLE songs")
        cursor.execute('''
        CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            video_id TEXT UNIQUE NOT NULL,
            cloud_url TEXT,
            local_path TEXT,
            is_local_only BOOLEAN DEFAULT 0,
            is_streaming_only BOOLEAN DEFAULT 0,
            metadata TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        cursor.execute("INSERT INTO songs SELECT id, title, video_id, cloud_url, NULL, 0, 0, metadata, created_at FROM songs_temp")
        cursor.execute("DROP TABLE songs_temp")
    
    # Il resto delle tabelle rimane invariato
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS playlist_songs (
        playlist_id INTEGER,
        song_id INTEGER,
        position INTEGER,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
    )
    ''')
    
    conn.commit()
    conn.close()

def add_song(title, video_id, cloud_url=None, local_path=None, is_local_only=False, is_streaming_only=False, metadata=None):
    """
    Aggiunge una canzone al database.
    
    Args:
        title (str): Titolo della canzone
        video_id (str): ID del video YouTube
        cloud_url (str, optional): URL del file su Oracle Cloud
        local_path (str, optional): Percorso del file locale
        is_local_only (bool): Flag per indicare se la canzone è solo locale
        is_streaming_only (bool): Flag per indicare se la canzone è solo streaming
        metadata (dict, optional): Metadati aggiuntivi
        
    Returns:
        int: ID della canzone inserita
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    metadata_json = json.dumps(metadata) if metadata else None
    
    try:
        # Verifica se la canzone esiste già
        cursor.execute("SELECT id FROM songs WHERE video_id = ?", (video_id,))
        existing_song = cursor.fetchone()
        
        if existing_song:
            song_id = existing_song[0]
            
            # Aggiorna la canzone esistente (es. aggiungi cloud_url o local_path)
            update_fields = []
            params = []
            
            if cloud_url:
                update_fields.append("cloud_url = ?")
                params.append(cloud_url)
                update_fields.append("is_local_only = 0")
            
            if local_path:
                update_fields.append("local_path = ?")
                params.append(local_path)
                
            if is_local_only:
                update_fields.append("is_local_only = 1")
                
            if is_streaming_only:
                update_fields.append("is_streaming_only = 1")
                
            if metadata:
                update_fields.append("metadata = ?")
                params.append(metadata_json)
                
            if update_fields:
                query = f"UPDATE songs SET {', '.join(update_fields)} WHERE id = ?"
                params.append(song_id)
                cursor.execute(query, params)
                conn.commit()
                
            return song_id
        else:
            # Inserisci una nuova canzone
            cursor.execute(
                "INSERT INTO songs (title, video_id, cloud_url, local_path, is_local_only, is_streaming_only, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (title, video_id, cloud_url, local_path, is_local_only, is_streaming_only, metadata_json)
            )
            song_id = cursor.lastrowid
            conn.commit()
            return song_id
    finally:
        conn.close()

def get_song_by_id(song_id):
    """
    Ottiene una canzone dal suo ID.
    
    Args:
        song_id (int): ID della canzone
        
    Returns:
        dict: Informazioni sulla canzone o None se non trovata
    """
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM songs WHERE id = ?", (song_id,))
    row = cursor.fetchone()
    
    if row:
        song = dict(row)
        if song['metadata']:
            song['metadata'] = json.loads(song['metadata'])
        conn.close()
        return song
    
    conn.close()
    return None

def remove_song(song_id):
    """
    Rimuove una canzone dal database.
    
    Args:
        song_id (int): ID della canzone da rimuovere
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Rimuovi prima eventuali riferimenti nelle playlist
    cursor.execute("DELETE FROM playlist_songs WHERE song_id = ?", (song_id,))
    
    # Rimuovi la canzone
    cursor.execute("DELETE FROM songs WHERE id = ?", (song_id,))
    
    conn.commit()
    conn.close()

def remove_song_from_playlist(playlist_id, song_id):
    """
    Rimuove una canzone da una playlist.
    
    Args:
        playlist_id (int): ID della playlist
        song_id (int): ID della canzone
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Ottieni la posizione attuale per riordinare le altre canzoni
    cursor.execute(
        "SELECT position FROM playlist_songs WHERE playlist_id = ? AND song_id = ?",
        (playlist_id, song_id)
    )
    result = cursor.fetchone()
    
    if result:
        position = result[0]
        
        # Rimuovi la canzone dalla playlist
        cursor.execute(
            "DELETE FROM playlist_songs WHERE playlist_id = ? AND song_id = ?",
            (playlist_id, song_id)
        )
        
        # Aggiorna le posizioni delle canzoni successive
        cursor.execute(
            "UPDATE playlist_songs SET position = position - 1 WHERE playlist_id = ? AND position > ?",
            (playlist_id, position)
        )
        
        conn.commit()
    
    conn.close()

def add_streaming_song(title, video_id, thumbnail=None, channel=None):
    """
    Aggiunge una canzone di solo streaming (senza download).
    
    Args:
        title (str): Titolo della canzone
        video_id (str): ID del video YouTube
        thumbnail (str, optional): URL della thumbnail
        channel (str, optional): Nome del canale
        
    Returns:
        int: ID della canzone inserita
    """
    metadata = {
        'thumbnail': thumbnail,
        'channel': channel
    }
    
    return add_song(
        title=title, 
        video_id=video_id, 
        cloud_url=None,
        local_path=None,
        is_streaming_only=True,
        metadata=metadata
    )
def get_songs():
    """
    Ottiene tutte le canzoni dal database.
    
    Returns:
        list: Lista di canzoni
    """
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Per ottenere risultati come dizionari
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM songs ORDER BY created_at DESC")
    
    songs = []
    for row in cursor.fetchall():
        song = dict(row)
        if song['metadata']:
            song['metadata'] = json.loads(song['metadata'])
        songs.append(song)
    
    conn.close()
    return songs

def get_playlists():
    """
    Ottiene tutte le playlist con le relative canzoni.
    
    Returns:
        list: Lista di playlist con canzoni
    """
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM playlists ORDER BY created_at DESC")
    playlists = []
    
    for playlist_row in cursor.fetchall():
        playlist = dict(playlist_row)
        
        # Ottieni le canzoni per questa playlist
        cursor.execute("""
            SELECT s.* FROM songs s
            JOIN playlist_songs ps ON s.id = ps.song_id
            WHERE ps.playlist_id = ?
            ORDER BY ps.position
        """, (playlist['id'],))
        
        playlist_songs = []
        for song_row in cursor.fetchall():
            song = dict(song_row)
            if song['metadata']:
                song['metadata'] = json.loads(song['metadata'])
            playlist_songs.append(song)
        
        playlist['songs'] = playlist_songs
        playlists.append(playlist)
    
    conn.close()
    return playlists

def add_playlist(name):
    """
    Crea una nuova playlist.
    
    Args:
        name (str): Nome della playlist
        
    Returns:
        int: ID della playlist creata
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("INSERT INTO playlists (name) VALUES (?)", (name,))
    playlist_id = cursor.lastrowid
    
    conn.commit()
    conn.close()
    
    return playlist_id

def add_song_to_playlist(playlist_id, song_id):
    """
    Aggiunge una canzone a una playlist.
    
    Args:
        playlist_id (int): ID della playlist
        song_id (int): ID della canzone
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Trova la posizione più alta attuale
    cursor.execute(
        "SELECT MAX(position) FROM playlist_songs WHERE playlist_id = ?",
        (playlist_id,)
    )
    result = cursor.fetchone()
    max_position = result[0] if result[0] is not None else -1
    next_position = max_position + 1
    
    try:
        cursor.execute(
            "INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES (?, ?, ?)",
            (playlist_id, song_id, next_position)
        )
        conn.commit()
    except sqlite3.IntegrityError:
        # La canzone è già nella playlist
        pass
    finally:
        conn.close()

def delete_playlist_from_db(playlist_id):
    """
    Elimina una playlist dal database.
    
    Args:
        playlist_id (int): ID della playlist da eliminare
    """
    print(f"Tentativo di eliminazione della playlist {playlist_id} dal database")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # Rimuovi prima i riferimenti nella tabella playlist_songs
        cursor.execute("DELETE FROM playlist_songs WHERE playlist_id = ?", (playlist_id,))
        print(f"Riferimenti rimossi per la playlist {playlist_id}")
        
        # Rimuovi la playlist
        cursor.execute("DELETE FROM playlists WHERE id = ?", (playlist_id,))
        print(f"Playlist {playlist_id} eliminata")
        
        conn.commit()
        print(f"Transazione completata con successo")
    except Exception as e:
        conn.rollback()
        print(f"Errore nell'eliminazione della playlist: {e}")
        raise e
    finally:
        conn.close()

def add_streaming_song_to_db(title, video_id, metadata=None):
    """
    Aggiunge un brano in modalità streaming al database.
    
    Args:
        title (str): Titolo del brano
        video_id (str): ID del video YouTube
        metadata (dict, optional): Metadati aggiuntivi
        
    Returns:
        int: ID del brano inserito
    """
    metadata_json = json.dumps(metadata) if metadata else None
    
    return add_song(
        title=title,
        video_id=video_id,
        cloud_url=None,
        local_path=None,
        is_streaming_only=True,
        metadata=metadata
    )

def delete_playlist_from_db(playlist_id):
    """
    Elimina una playlist dal database.
    
    Args:
        playlist_id (int): ID della playlist da eliminare
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Rimuovi prima i riferimenti nella tabella playlist_songs
    cursor.execute("DELETE FROM playlist_songs WHERE playlist_id = ?", (playlist_id,))
    
    # Rimuovi la playlist
    cursor.execute("DELETE FROM playlists WHERE id = ?", (playlist_id,))
    
    conn.commit()
    conn.close()

def add_streaming_song_to_db(title, video_id, metadata=None):
    """
    Aggiunge un brano in modalità streaming al database.
    
    Args:
        title (str): Titolo del brano
        video_id (str): ID del video YouTube
        metadata (dict, optional): Metadati aggiuntivi
        
    Returns:
        int: ID del brano inserito
    """
    metadata_json = json.dumps(metadata) if metadata else None
    
    return add_song(
        title=title,
        video_id=video_id,
        cloud_url=None,
        local_path=None,
        is_streaming_only=True,
        metadata=metadata
    )
