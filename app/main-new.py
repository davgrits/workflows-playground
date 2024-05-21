import socket
import urllib.request
from flask import Flask

app = Flask(__name__)

internal_ip = socket.gethostbyname(socket.gethostname())
external_ip = urllib.request.urlopen('https://v4.ident.me').read().decode('utf8')

@app.route('/')
def welcome():
   return f"Welcome adventurers! Your external IP is {external_ip} and your Internal IP is {internal_ip}. Good luck!"

@app.route('/api')
def welcome2api():
   return "Welcome to adventurers API"

if __name__ == '__main__':
   app.run()
