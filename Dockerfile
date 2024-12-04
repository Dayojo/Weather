# Dockerfile for Weather Service
# This file defines how to build the container image for our weather service application
# Base image: Python 3.9-slim for a smaller footprint
# Exposes port 5000 for the Flask application

FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

EXPOSE 5000

CMD ["python", "app.py"]
