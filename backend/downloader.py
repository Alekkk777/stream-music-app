# backend/downloader.py
import os
import yt_dlp
import uuid
import platform
import requests
import tempfile
import time
import random
from pathlib import Path

# Cartella per i download locali - basata sulla piattaforma
def get_download_folder():
    """
    Restituisce la cartella di download appropriata in base al sistema operativo.
    """
    system = platform.system()
    
    if system == 'Darwin':  # macOS
        downloads_dir = os.path.join(os.path.expanduser('~'), 'Music', 'MusicStreamApp')
    elif system == 'Windows':
        downloads_dir = os.path.join(os.path.expanduser('~'), 'Music', 'MusicStreamApp')
    else:  # Linux, Android, ecc.
        # Per Android, l'app Flutter dovrà fornire un percorso appropriato
        downloads_dir = os.path.join(os.path.expanduser('~'), 'Music', 'MusicStreamApp')
    
    # Verifica o crea la cartella con permessi corretti
    try:
        # Crea la cartella se non esiste
        os.makedirs(downloads_dir, exist_ok=True)
        
        # Verifica che sia scrivibile
        if not os.access(downloads_dir, os.W_OK):
            print(f"ATTENZIONE: La cartella {downloads_dir} non è scrivibile")
            # Fallback a una directory temporanea
            temp_dir = os.path.join(tempfile.gettempdir(), 'MusicStreamApp')
            os.makedirs(temp_dir, exist_ok=True)
            print(f"Utilizzo della directory temporanea: {temp_dir}")
            return temp_dir
            
        print(f"Directory di download impostata a: {downloads_dir}")
        return downloads_dir
        
    except Exception as e:
        print(f"Errore nell'impostazione della directory di download: {e}")
        # Fallback a una directory temporanea
        temp_dir = os.path.join(tempfile.gettempdir(), 'MusicStreamApp')
        os.makedirs(temp_dir, exist_ok=True)
        print(f"Utilizzo della directory temporanea: {temp_dir}")
        return temp_dir

# Cartella temporanea per i download
TEMP_FOLDER = os.path.abspath('temp_downloads')
os.makedirs(TEMP_FOLDER, exist_ok=True)

# Cartella per i download locali
LOCAL_FOLDER = get_download_folder()

# URL audio di fallback
FALLBACK_URLS = [
    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"
]

def verify_directory_permissions(directory):
    """Verifica che la directory esista e sia scrivibile."""
    try:
        if not os.path.exists(directory):
            print(f"La directory {directory} non esiste. Tentativo di creazione...")
            os.makedirs(directory, exist_ok=True)
        
        # Verifica che la directory sia scrivibile creando un file di test
        test_file_path = os.path.join(directory, 'test_write.tmp')
        with open(test_file_path, 'w') as f:
            f.write('test')
        os.remove(test_file_path)
        print(f"Directory {directory} verificata: scrivibile")
        return True
    except Exception as e:
        print(f"Errore nella verifica della directory {directory}: {e}")
        return False

def download_audio(video_id, title=None, destination_folder=None, upload_to_cloud=True):
    """
    Scarica l'audio da un video YouTube con errori dettagliati e verifiche.
    """
    video_url = f'https://www.youtube.com/watch?v={video_id}'
    
    # Genera un nome file unico con sanitizzazione rafforzata
    file_id = str(uuid.uuid4())
    if title:
        # Sanitizzazione più robusta del titolo
        import re
        safe_title = re.sub(r'[^\w\-_\. ]', '', title).strip()
        safe_title = safe_title.replace(' ', '_')  # Sostituisci spazi con underscore
        safe_title = safe_title[:40] if safe_title else file_id  # Limita a 40 caratteri
    else:
        safe_title = file_id
    
    # Determina e verifica la cartella di output
    if upload_to_cloud:
        output_folder = os.path.abspath(TEMP_FOLDER)
    else:
        output_folder = os.path.abspath(destination_folder or LOCAL_FOLDER)
    
    try:
        # Verifica che la directory sia valida
        if not verify_directory_permissions(output_folder):
            # Se la verifica fallisce, usa una directory temporanea come fallback
            output_folder = os.path.abspath(tempfile.gettempdir())
            print(f"Utilizzo della directory temporanea fallback: {output_folder}")
            
            # Verifica se anche questa fallisce
            if not verify_directory_permissions(output_folder):
                raise Exception("Impossibile trovare una directory scrivibile")
        
        print(f"Cartella di output verificata: {output_folder}")
                
        # Costruisci il percorso del file con estensione
        output_file = f"{safe_title}.mp3"
        output_path = os.path.join(output_folder, output_file)
        output_path_without_ext = output_path.replace('.mp3', '')
        
        # Assicurati che il file non esista già
        counter = 1
        while os.path.exists(output_path):
            output_path = os.path.join(output_folder, f"{safe_title}_{counter}.mp3")
            output_path_without_ext = output_path.replace('.mp3', '')
            counter += 1
        
        print(f"Percorso del file di output: {output_path}")
        
        # Verifica il percorso del file cookie
        cookie_path = '/opt/music-stream-app/backend/cookies.txt'
        if not os.path.exists(cookie_path):
            print(f"ATTENZIONE: Il file cookie non esiste: {cookie_path}")
            cookie_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cookies.txt')
            print(f"Tentativo con percorso relativo: {cookie_path}")
        
        # Configurazione yt-dlp con più diagnostica
        ydl_opts = {
            'format': 'bestaudio/best',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
            'outtmpl': output_path_without_ext,
            'quiet': False,  # Abilitiamo i log per il debug
            'no_warnings': False,
            'verbose': True,  # Output verboso per il debug
            'overwrites': True,
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'cookiefile': cookie_path,
            'retries': 5,              # Riprova fino a 5 volte
            'socket_timeout': 30,      # Timeout più lungo
            'extractor_retries': 3     # Riprova l'estrazione 3 volte
        }
        
        # Esegui il download con tentativi multipli
        max_attempts = 3
        attempts = 0
        
        while attempts < max_attempts:
            try:
                print(f"Tentativo di download {attempts+1}/{max_attempts}")
                
                # Esegui il download
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    info = ydl.extract_info(video_url, download=True)
                    # Correggi il percorso di output in base all'estensione effettiva
                    actual_output_path = ydl.prepare_filename(info)
                    # Verifica se il file esiste con estensione mp3
                    mp3_path = actual_output_path.replace(os.path.splitext(actual_output_path)[1], '.mp3')
                    
                    print(f"Download completato. Verifica del file in: {mp3_path}")
                    
                    # Verifica che il file sia stato effettivamente creato
                    if os.path.exists(mp3_path):
                        print(f"File trovato correttamente: {mp3_path}")
                        return mp3_path
                    
                    # Se il file mp3 non esiste, controlla se esiste con l'estensione originale
                    if os.path.exists(actual_output_path):
                        print(f"File trovato con estensione originale: {actual_output_path}")
                        return actual_output_path
                    
                    # Cerca qualsiasi file nella cartella che potrebbe corrispondere
                    file_prefix = os.path.splitext(os.path.basename(output_path_without_ext))[0]
                    all_files = os.listdir(output_folder)
                    matching_files = [f for f in all_files if f.startswith(file_prefix)]
                    
                    if matching_files:
                        found_path = os.path.join(output_folder, matching_files[0])
                        print(f"File trovato con nome simile: {found_path}")
                        return found_path
                
                # Se siamo arrivati qui, il download è fallito
                raise Exception(f"File non trovato dopo il download")
                
            except Exception as e:
                attempts += 1
                print(f"Tentativo {attempts}/{max_attempts} fallito: {str(e)}")
                
                if "Sign in to confirm" in str(e) or "Bot check" in str(e):
                    print("YouTube ha rilevato l'automazione. Verifica il file cookies.txt")
                
                if attempts < max_attempts:
                    wait_time = 2 ** attempts  # Backoff esponenziale: 2, 4, 8 secondi
                    print(f"Attesa di {wait_time} secondi prima del prossimo tentativo...")
                    time.sleep(wait_time)
                else:
                    print("Tutti i tentativi di download falliti.")
                    raise Exception(f"Errore durante il download dopo {max_attempts} tentativi: {str(e)}")
            
    except Exception as e:
        print(f"Errore dettagliato durante il download: {str(e)}")
        raise Exception(f"Errore durante il download: {str(e)}")

def get_youtube_stream_url(video_id):
    """
    Ottiene un URL diretto per lo streaming da YouTube con fallback.
    
    Args:
        video_id (str): ID del video YouTube
        
    Returns:
        str: URL per lo streaming audio o URL di fallback in caso di errore
    """
    video_url = f'https://www.youtube.com/watch?v={video_id}'
    
    # Percorso al file dei cookie
    cookie_path = '/opt/music-stream-app/backend/cookies.txt'
    if not os.path.exists(cookie_path):
        print(f"ATTENZIONE: Il file cookie non esiste: {cookie_path}")
        cookie_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cookies.txt')
        print(f"Tentativo con percorso relativo: {cookie_path}")
    
    # Opzioni yt-dlp migliorate
    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'noplaylist': True,
        'retries': 5,              # Riprova fino a 5 volte
        'socket_timeout': 30,      # Timeout più lungo
        'extractor_retries': 3,    # Riprova l'estrazione 3 volte
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
        'cookiefile': cookie_path
    }
    
    # Tentativi multipli con backoff esponenziale
    max_attempts = 3
    attempts = 0
    
    while attempts < max_attempts:
        try:
            print(f"Tentativo di recupero URL streaming {attempts+1}/{max_attempts}")
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(video_url, download=False)
                
                # Ottieni il formato audio migliore
                for f in info['formats']:
                    if f.get('acodec') != 'none' and f.get('vcodec') == 'none':
                        print(f"URL di streaming trovato per {video_id}")
                        return f['url']
                
                # Fallback al primo formato disponibile
                if info['formats']:
                    return info['formats'][0]['url']
            
            # Se siamo arrivati qui, non abbiamo trovato un formato adatto
            raise Exception("Nessun formato audio disponibile")
            
        except Exception as e:
            attempts += 1
            print(f"Tentativo {attempts}/{max_attempts} fallito: {str(e)}")
            
            if "Sign in to confirm" in str(e) or "Bot check" in str(e):
                print("YouTube ha rilevato l'automazione. Verifica il file cookies.txt")
            
            if attempts < max_attempts:
                wait_time = 2 ** attempts  # Backoff esponenziale: 2, 4, 8 secondi
                print(f"Attesa di {wait_time} secondi prima del prossimo tentativo...")
                time.sleep(wait_time)
            else:
                print(f"Tutti i tentativi falliti. Ritorno URL di fallback per {video_id}")
                # Scegliamo un URL di fallback casuale
                return random.choice(FALLBACK_URLS)

def get_video_info(video_id):
    """
    Ottiene le informazioni su un video di YouTube.
    
    Args:
        video_id (str): ID del video YouTube
        
    Returns:
        dict: Informazioni sul video
    """
    video_url = f'https://www.youtube.com/watch?v={video_id}'
    
    # Percorso al file dei cookie
    cookie_path = '/opt/music-stream-app/backend/cookies.txt'
    if not os.path.exists(cookie_path):
        print(f"ATTENZIONE: Il file cookie non esiste: {cookie_path}")
        cookie_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cookies.txt')
        print(f"Tentativo con percorso relativo: {cookie_path}")
    
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'noplaylist': True,
        'skip_download': True,
        'retries': 5,              # Riprova fino a 5 volte
        'socket_timeout': 30,      # Timeout più lungo
        'extractor_retries': 3,    # Riprova l'estrazione 3 volte
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
        'cookiefile': cookie_path
    }
    
    # Tentativi multipli con backoff esponenziale
    max_attempts = 3
    attempts = 0
    
    while attempts < max_attempts:
        try:
            print(f"Tentativo di recupero info video {attempts+1}/{max_attempts}")
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(video_url, download=False)
                return {
                    'title': info.get('title', 'Unknown'),
                    'thumbnail': info.get('thumbnail', None),
                    'channel': info.get('uploader', None),
                    'duration': info.get('duration', 0)
                }
                
        except Exception as e:
            attempts += 1
            print(f"Tentativo {attempts}/{max_attempts} fallito: {str(e)}")
            
            if "Sign in to confirm" in str(e) or "Bot check" in str(e):
                print("YouTube ha rilevato l'automazione. Verifica il file cookies.txt")
            
            if attempts < max_attempts:
                wait_time = 2 ** attempts  # Backoff esponenziale: 2, 4, 8 secondi
                print(f"Attesa di {wait_time} secondi prima del prossimo tentativo...")
                time.sleep(wait_time)
            else:
                print("Tutti i tentativi falliti. Ritorno info video generiche")
                # Ritorna info generiche in caso di errore
                return {
                    'title': f'Video {video_id}',
                    'thumbnail': None,
                    'channel': 'Unknown',
                    'duration': 0
                }