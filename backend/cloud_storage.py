# backend/cloud_storage.py
import os
import oci
from dotenv import load_dotenv

load_dotenv()  # Carica le variabili di ambiente dal file .env

# Configurazione Oracle Cloud
config = {
    "user": os.getenv("OCI_USER"),
    "key_file": os.getenv("OCI_KEY_FILE"),
    "fingerprint": os.getenv("OCI_FINGERPRINT"),
    "tenancy": os.getenv("OCI_TENANCY"),
    "region": os.getenv("OCI_REGION")
}

# Namespace e bucket name
namespace = os.getenv("OCI_NAMESPACE")
bucket_name = os.getenv("OCI_BUCKET_NAME")

def upload_to_cloud(file_path):
    """
    Carica un file su Oracle Cloud Storage.
    
    Args:
        file_path (str): Percorso del file locale da caricare
        
    Returns:
        str: URL del file caricato su cloud
    """
    try:
        # Crea un client per Object Storage
        object_storage = oci.object_storage.ObjectStorageClient(config)
        
        # Nome dell'oggetto (file) nel bucket
        object_name = os.path.basename(file_path)
        
        # Leggi il file in modalità binaria
        with open(file_path, 'rb') as file_data:
            # Carica il file su Oracle Cloud Storage
            object_storage.put_object(
                namespace_name=namespace,
                bucket_name=bucket_name,
                object_name=object_name,
                put_object_body=file_data.read()
            )
        
        # Costruisci l'URL del file
        # Nota: questo è un esempio, l'URL effettivo potrebbe essere diverso
        cloud_url = f"https://objectstorage.{config['region']}.oraclecloud.com/n/{namespace}/b/{bucket_name}/o/{object_name}"
        
        return cloud_url
    except Exception as e:
        raise Exception(f"Errore durante l'upload su cloud: {str(e)}")

def download_from_cloud(object_name, destination_path):
    """
    Scarica un file da Oracle Cloud Storage.
    
    Args:
        object_name (str): Nome del file nel bucket
        destination_path (str): Percorso dove salvare il file scaricato
        
    Returns:
        str: Percorso del file scaricato
    """
    try:
        # Crea un client per Object Storage
        object_storage = oci.object_storage.ObjectStorageClient(config)
        
        # Scarica l'oggetto
        response = object_storage.get_object(
            namespace_name=namespace,
            bucket_name=bucket_name,
            object_name=object_name
        )
        
        # Salva il contenuto nel file di destinazione
        with open(destination_path, 'wb') as file:
            for chunk in response.data.raw.stream(1024 * 1024, decode_content=False):
                file.write(chunk)
        
        return destination_path
    except Exception as e:
        raise Exception(f"Errore durante il download da cloud: {str(e)}")

def list_files():
    """
    Elenca tutti i file nel bucket.
    
    Returns:
        list: Lista di oggetti nel bucket
    """
    try:
        # Crea un client per Object Storage
        object_storage = oci.object_storage.ObjectStorageClient(config)
        
        # Ottieni l'elenco degli oggetti
        response = object_storage.list_objects(
            namespace_name=namespace,
            bucket_name=bucket_name
        )
        
        # Estrai le informazioni degli oggetti
        objects = []
        for obj in response.data.objects:
            objects.append({
                'name': obj.name,
                'size': obj.size,
                'time_created': obj.time_created.isoformat(),
                'url': f"https://objectstorage.{config['region']}.oraclecloud.com/n/{namespace}/b/{bucket_name}/o/{obj.name}"
            })
        
        return objects
    except Exception as e:
        raise Exception(f"Errore durante l'elenco dei file: {str(e)}")
    
def delete_from_cloud(object_name):
    """
    Elimina un file da Oracle Cloud Storage.
    
    Args:
        object_name (str): Nome del file nel bucket o path completo
        
    Returns:
        bool: True se l'eliminazione ha avuto successo
    """
    try:
        # Se object_name è un URL completo, estraiamo solo il nome del file
        if object_name.startswith('http'):
            object_name = object_name.split('/')[-1]
        
        # Crea un client per Object Storage
        object_storage = oci.object_storage.ObjectStorageClient(config)
        
        # Elimina l'oggetto
        object_storage.delete_object(
            namespace_name=namespace,
            bucket_name=bucket_name,
            object_name=object_name
        )
        
        return True
    except Exception as e:
        raise Exception(f"Errore durante l'eliminazione da cloud: {str(e)}")