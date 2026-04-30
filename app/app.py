from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "<h1>Site do Instituto IBK</h1><p>O container Docker está funcionando!</p>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
