# Python Flask application for weather service
# This microservice provides weather information using the Open-Meteo API
# Endpoint: /weather?location=<location>
# Returns: JSON weather data for the specified location

from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/weather', methods=['GET'])
def get_weather():
    location = request.args.get('location')
    response = requests.get(f"https://api.open-meteo.com/v1/forecast?latitude={location}&current_weather=true")
    return jsonify(response.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
