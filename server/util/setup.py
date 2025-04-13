# Load environment variables from the .env file.
import json
import os
from dotenv import load_dotenv


current_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
load_dotenv()
# Retrieve the JSON string from the environment variable.
raw_json_str = os.getenv("FIREBASE_CC_JSON")
if not raw_json_str:
    raise EnvironmentError("FIREBASE_CC_JSON environment variable not found.")
# Decode escape sequences so that '\\n' becomes actual newline characters.
# This is necessary so that the private_key gets formatted correctly.
decoded_json_str = raw_json_str.encode("utf-8").decode("unicode_escape")
# Parse the JSON string to make sure it is valid.
try:
    json_data = json.loads(decoded_json_str)
except json.JSONDecodeError as e:
    raise ValueError("The FIREBASE_CC_JSON environment variable contains invalid JSON.") from e
# Ensure that the target directory exists.
target_directory = os.path.join(current_dir, "database")
os.makedirs(target_directory, exist_ok=True)
# Define the full file path.
file_path = os.path.join(target_directory, "fb-cc-test.json")
# Write the parsed JSON data into the file with pretty printing.
with open(file_path, 'w', encoding='utf-8') as file:
    json.dump(json_data, file, indent=2)
print(f"JSON file has been successfully written to: {file_path}")
raw_json_str = os.getenv("GOOGLE_CLIENT_SECRET_FILE")
if not raw_json_str:
    raise EnvironmentError("GOOGLE_CLIENT_SECRET_FILE environment variable not found.")
# Decode escape sequences so that '\\n' becomes actual newline characters.
# This is necessary so that the private_key gets formatted correctly.
decoded_json_str = raw_json_str.encode("utf-8").decode("unicode_escape")
# Parse the JSON string to make sure it is valid.
try:
    json_data = json.loads(decoded_json_str)
except json.JSONDecodeError as e:
    raise ValueError("The GOOGLE_CLIENT_SECRET_FILE environment variable contains invalid JSON.") from e
# Ensure that the target directory exists.
target_directory = os.path.join(current_dir, "keys")
os.makedirs(target_directory, exist_ok=True)
# Define the full file path.
file_path = os.path.join(target_directory, "client_secret_test.json")
# Write the parsed JSON data into the file with pretty printing.
with open(file_path, 'w', encoding='utf-8') as file:
    json.dump(json_data, file, indent=2)
print(f"JSON file has been successfully written to: {file_path}")