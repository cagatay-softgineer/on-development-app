import jwt
import time
from config.config import settings  # Make sure your settings are imported correctly


def generate_apple_developer_token(expires_in: int = 15777000):
    """
    Generates a new Apple Music developer token using the ES256 algorithm.
    Reads credentials and private key path from your config settings.
    Returns the JWT as a string.
    Args:
        expires_in (int): Expiration time of the token, in **seconds** (default: 15777000, 6 months).
    """
    team_id = settings.apple_team_id
    key_id = settings.apple_key_id
    private_key_path = settings.apple_private_key_path

    # Read the private key from file
    with open(private_key_path, 'r') as key_file:
        private_key = key_file.read()

    headers = {
        'alg': 'ES256',
        'kid': key_id
    }
    now = int(time.time())
    payload = {
        'iss': team_id,
        'iat': now,
        'exp': now + expires_in  # 6 months
    }
    developer_token = jwt.encode(
        payload,
        private_key,
        algorithm='ES256',
        headers=headers
    )
    if isinstance(developer_token, bytes):
        developer_token = developer_token.decode('utf-8')
    return developer_token, (now + expires_in)
