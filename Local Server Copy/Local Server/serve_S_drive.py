import http.server
import socketserver
import socket
import os
import sys

# Zowel IP-adressen als hostnamen toestaan
ALLOWED_CLIENTS = {
    "KPN-STA-001",	# server zelf
    "KPN-STA-101",	# test vm
}

NETWERK_PAD = "S:\\"

try:
    os.chdir(NETWERK_PAD)
except Exception as e:
    print(f"Kan map {NETWERK_PAD} niet openen:")
    print(str(e))
    sys.exit(1)

PORT = 8000

class SecureHandler(http.server.SimpleHTTPRequestHandler):
    def list_directory(self, path):
        self.send_error(403, "Directory browsing is disabled")

    def address_string(self):
        return self.client_address[0]

    def do_GET(self):
        client_ip = self.client_address[0]
        try:
            client_host = socket.gethostbyaddr(client_ip)[0].split('.')[0].upper()
        except Exception:
            client_host = None

        if client_ip not in ALLOWED_CLIENTS and (client_host not in ALLOWED_CLIENTS if client_host else True):
            self.send_error(403, f"Access denied for {client_ip} ({client_host})")
            return

        super().do_GET()

Handler = SecureHandler

hostname = socket.gethostname()
local_ip = socket.gethostbyname(hostname)

print(f"Server gestart op http://{local_ip}:{PORT}")
print(f"Gedeelde map: {NETWERK_PAD}")
print(f"Toegestane clients: {', '.join(ALLOWED_CLIENTS)}")
print("Stoppen met CTRL+C")

class ThreadingTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True

with ThreadingTCPServer(("0.0.0.0", PORT), Handler) as httpd:

    httpd.serve_forever()
