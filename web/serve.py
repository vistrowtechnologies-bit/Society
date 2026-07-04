"""Minimal static file server for the built Flutter web app.

Railway sets $PORT at runtime; Python's http.server module doesn't read env
vars on its own, so this tiny wrapper does that and serves the `public/`
directory (the output of `flutter build web`).
"""
import http.server
import os
import socketserver

PORT = int(os.environ.get("PORT", 8080))
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with ReusableTCPServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"Serving {DIRECTORY} on port {PORT}")
        httpd.serve_forever()
