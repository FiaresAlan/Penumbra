"""Receptor local temporário: o Command Bar do Studio envia (POST) os IDs dos assets importados
e este script grava o corpo em tools/assets/imported_ids.json. Só escuta em 127.0.0.1."""
import http.server
import pathlib
import sys

OUT = pathlib.Path(__file__).parent / "assets" / "imported_ids.json"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        OUT.write_bytes(body)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")
        print(f"recebido {length} bytes", flush=True)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    http.server.HTTPServer(("127.0.0.1", port), Handler).serve_forever()
