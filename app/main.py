from flask import Flask

app = Flask(__name__)

@app.route('/')
def welcome():
   return "Welcome adventurers! Do you know what are your IPs?"

@app.route('/api')
def welcome2api():
   return "Welcome to adventurers API"

if __name__ == '__main__':
   app.run()
