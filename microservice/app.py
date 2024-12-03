from flask import Flask, request, jsonify
import requests
import os
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/weather', methods=['GET'])
def get_weather():
    try:
        # Get location from query parameters
        location = request.args.get('location')
        if not location:
            return jsonify({'error': 'Location parameter is required'}), 400

        # Call Open-Meteo API for weather data
        api_url = f"https://api.open-meteo.com/v1/forecast"
        params = {
            'latitude': 0,  # Will be updated based on location
            'longitude': 0,  # Will be updated based on location
            'current_weather': True,
            'hourly': 'temperature_2m,precipitation_probability'
        }

        # First, get coordinates for the location using Nominatim
        geocoding_url = f"https://nominatim.openstreetmap.org/search?q={location}&format=json"
        headers = {'User-Agent': 'WeatherService/1.0'}
        
        geo_response = requests.get(geocoding_url, headers=headers)
        geo_data = geo_response.json()

        if not geo_data:
            return jsonify({'error': 'Location not found'}), 404

        # Update coordinates in params
        params['latitude'] = float(geo_data[0]['lat'])
        params['longitude'] = float(geo_data[0]['lon'])

        # Get weather data
        weather_response = requests.get(api_url, params=params)
        weather_data = weather_response.json()

        # Format response
        formatted_response = {
            'location': location,
            'coordinates': {
                'latitude': params['latitude'],
                'longitude': params['longitude']
            },
            'current_weather': weather_data.get('current_weather', {}),
            'hourly_forecast': {
                'temperature': weather_data.get('hourly', {}).get('temperature_2m', [])[:24],
                'precipitation_probability': weather_data.get('hourly', {}).get('precipitation_probability', [])[:24]
            },
            'timestamp': datetime.now().isoformat()
        }

        logger.info(f"Successfully retrieved weather data for {location}")
        return jsonify(formatted_response)

    except requests.RequestException as e:
        logger.error(f"Error fetching weather data: {str(e)}")
        return jsonify({'error': 'Failed to fetch weather data', 'details': str(e)}), 503
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
