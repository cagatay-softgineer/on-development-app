from waitress import serve
from server import server  # Adjust based on your project structure

if __name__ == "__main__":
    serve(server, host="0.0.0.0", port=8080, ssl_context=("cert.pem", "key.pem"))
