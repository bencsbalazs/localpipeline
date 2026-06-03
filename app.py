from flask import Flask

app_instance = Flask(__name__)

def fizzbuzz():
    for i in range(1, 101):
        print("Fizz" * (not i % 3) + "Buzz" * (not i % 5) or i)

@app_instance.route('/health')
def healthcheck():
    return "OK"

if __name__ == "__main__":
    fizzbuzz()
    app_instance.run(host='0.0.0.0', port=8080)
