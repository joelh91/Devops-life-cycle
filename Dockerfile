FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .

RUN python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip uninstall -y pip

COPY app.py .

RUN useradd -m -u 10001 appuser

USER appuser

CMD ["python", "app.py"]
