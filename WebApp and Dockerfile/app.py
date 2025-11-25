from flask import Flask, request, jsonify, send_file
import math

app = Flask(__name__)

# Serve the HTML front-end
@app.route('/')
def index():
    return send_file('index.html')

# Endpoint to receive numbers and calculate formula
@app.route('/calculate', methods=['POST'])
def calculate():
    data = request.json
    x = float(data.get('x', 0))
    y = float(data.get('y', 0))

    # Example complex formula: sqrt(x^2 + y^2) + sin(x*y)
    result = math.sqrt(x**2 + y**2) + math.sin(x*y)

    return jsonify({'result': result})

if __name__ == '__main__':
    app.run(debug=True)
