import firebase_admin
from firebase_admin import credentials, firestore
from models import FirebaseConfig

def init_firebase(config: FirebaseConfig):
    cred = credentials.Certificate("/server/fb-cc.json")
    firebase_admin.initialize_app(cred, {
        'apiKey': config.api_key,
        'authDomain': config.auth_domain,
        'projectId': config.project_id,
        'storageBucket': config.storage_bucket,
        'messagingSenderId': config.messaging_sender_id,
        'appId': config.app_id,
        'measurementId': config.measurement_id
    })
    return firestore.client()