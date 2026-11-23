from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics


# Create the Flask application
app = Flask(__name__)

# Enable Prometheus monitoring
metrics = PrometheusMetrics(app)

@app.route("/")
def home():
    return "DevOps Lifecycle App is running!"


@app.route("/test-error")
def test_error():
    return "Simulated server error", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
