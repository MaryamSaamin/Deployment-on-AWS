# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY app.py .
COPY index.html .

# Expose the port Flask will run on
EXPOSE 5000

# Command to run the app
CMD ["python", "app.py"]
