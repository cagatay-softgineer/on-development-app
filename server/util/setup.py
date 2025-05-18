# Load environment variables from the .env file.
import json
import os
from dotenv import load_dotenv

current_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
load_dotenv()

# --- Firebase ---
raw_json_str = os.getenv("FIREBASE_CC_JSON")
if not raw_json_str:
    raise EnvironmentError("FIREBASE_CC_JSON environment variable not found.")
decoded_json_str = raw_json_str.encode("utf-8").decode("unicode_escape")
try:
    json_data = json.loads(decoded_json_str)
except json.JSONDecodeError as e:
    raise ValueError("The FIREBASE_CC_JSON environment variable contains invalid JSON.") from e
target_directory = os.path.join(current_dir, "database")
os.makedirs(target_directory, exist_ok=True)
file_path = os.path.join(target_directory, "fb-cc-test.json")
with open(file_path, 'w', encoding='utf-8') as file:
    json.dump(json_data, file, indent=2)
print(f"JSON file has been successfully written to: {file_path}")

# --- Google Client Secret ---
raw_json_str = os.getenv("GOOGLE_CLIENT_SECRET_FILE")
if not raw_json_str:
    raise EnvironmentError("GOOGLE_CLIENT_SECRET_FILE environment variable not found.")
decoded_json_str = raw_json_str.encode("utf-8").decode("unicode_escape")
try:
    json_data = json.loads(decoded_json_str)
except json.JSONDecodeError as e:
    raise ValueError("The GOOGLE_CLIENT_SECRET_FILE environment variable contains invalid JSON.") from e
target_directory = os.path.join(current_dir, "keys")
os.makedirs(target_directory, exist_ok=True)
file_path = os.path.join(target_directory, "client_secret_test.json")
with open(file_path, 'w', encoding='utf-8') as file:
    json.dump(json_data, file, indent=2)
print(f"JSON file has been successfully written to: {file_path}")

# --- Apple Private Key ---
apple_private_key = os.getenv("APPLE_PRIVATE_KEY")
apple_private_key_path = os.getenv("APPLE_PRIVATE_KEY_PATH", "keys/AuthKey_MISSING.p8")
if not apple_private_key:
    raise EnvironmentError("APPLE_PRIVATE_KEY environment variable not found.")

# Remove extra surrounding quotes if any
if apple_private_key.startswith('"') and apple_private_key.endswith('"'):
    apple_private_key = apple_private_key[1:-1]
# Decode escape sequences (so \n is newlines)
apple_private_key = apple_private_key.encode("utf-8").decode("unicode_escape")

# Ensure target directory for key exists
apple_key_dir = os.path.dirname(os.path.join(current_dir, apple_private_key_path))
os.makedirs(apple_key_dir, exist_ok=True)

# Write the private key file (PEM format)
apple_key_full_path = os.path.join(current_dir, apple_private_key_path)
with open(apple_key_full_path, "w", encoding="utf-8") as f:
    f.write(apple_private_key)
print(f"Apple private key has been successfully written to: {apple_key_full_path}")
