from flask import Flask, jsonify, request
import json
from kafka import KafkaProducer
import os

app_instance = Flask(__name__)

# Kafka Producer setup
KAFKA_BROKER = os.getenv('KAFKA_BROKER', 'kafka-service:9092')
producer = KafkaProducer(
    bootstrap_servers=[KAFKA_BROKER],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

def log_to_kafka(topic, message):
    try:
        producer.send(topic, message)
        producer.flush()
        print(f"Sent message to Kafka topic {topic}: {message}")
    except Exception as e:
        print(f"Could not send message to Kafka: {e}")


def get_fizzbuzz_result(number):
    result = ""
    if number % 15 == 0:
        result = "FizzBuzz"
    elif number % 3 == 0:
        result = "Fizz"
    elif number % 5 == 0:
        result = "Buzz"
    else:
        result = str(number)
    
    log_to_kafka('app-logs', {'type': 'fizzbuzz_request', 'number': number, 'result': result})
    return result

@app_instance.route('/health')
def healthcheck():
    log_to_kafka('app-logs', {'type': 'healthcheck_request', 'status': 'OK'})
    return "OK"

@app_instance.route('/fizzbuzz/<int:number>')
def fizzbuzz_endpoint(number):
    result = get_fizzbuzz_result(number)
    return jsonify({"number": number, "result": result})

if __name__ == "__main__":
    app_instance.run(host='0.0.0.0', port=8080)
