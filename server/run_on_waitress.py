from waitress import serve
from server import app  # Adjust based on your project structure

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=8080)