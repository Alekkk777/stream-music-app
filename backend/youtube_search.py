# backend/youtube_search.py
import os
from googleapiclient.discovery import build
from dotenv import load_dotenv

load_dotenv()  # Carica le variabili di ambiente dal file .env

# Ottieni la chiave API da variabili di ambiente
YOUTUBE_API_KEY = os.getenv('YOUTUBE_API_KEY')

def search_youtube(query, max_results=10):
    """
    Cerca video su YouTube usando la YouTube Data API.
    
    Args:
        query (str): Query di ricerca
        max_results (int): Numero massimo di risultati (default: 10)
        
    Returns:
        list: Lista di risultati con video_id, titolo, thumbnail
    """
    youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
    
    # Richiesta di ricerca
    search_response = youtube.search().list(
        q=query,
        part='id,snippet',
        maxResults=max_results,
        type='video'  # Solo video, non playlist o canali
    ).execute()
    
    # Estrai le informazioni rilevanti
    results = []
    for item in search_response.get('items', []):
        if item['id']['kind'] == 'youtube#video':
            video_data = {
                'video_id': item['id']['videoId'],
                'title': item['snippet']['title'],
                'thumbnail': item['snippet']['thumbnails']['high']['url'],
                'channel': item['snippet']['channelTitle']
            }
            results.append(video_data)
            
    return results


def get_video_details(video_id):
    """
    Ottiene i dettagli di un video specifico da YouTube.
    
    Args:
        video_id (str): ID del video YouTube
        
    Returns:
        dict: Dettagli del video
    """
    youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
    
    # Richiesta per i dettagli del video
    video_response = youtube.videos().list(
        part='snippet,contentDetails',
        id=video_id
    ).execute()
    
    # Verifica se il video esiste
    if not video_response.get('items'):
        return None
    
    video_data = video_response['items'][0]
    snippet = video_data['snippet']
    
    # Estrai le informazioni rilevanti
    return {
        'video_id': video_id,
        'title': snippet['title'],
        'thumbnail': snippet['thumbnails']['high']['url'],
        'channel': snippet['channelTitle'],
        'description': snippet['description'],
        'published_at': snippet['publishedAt'],
        'duration': video_data['contentDetails']['duration']  # Formato ISO 8601
    }