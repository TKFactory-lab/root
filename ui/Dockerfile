# Dockerfile for roadmap_ui (simple, minimal)
FROM python:3.11-slim

WORKDIR /app

# Copy only what's needed
COPY requirements.txt /app/requirements.txt
COPY scripts/roadmap_ui.py /app/roadmap_ui.py

RUN pip install --no-cache-dir -r /app/requirements.txt && \
	pip install --no-cache-dir gunicorn

EXPOSE 8001
# Run Gunicorn with 1 worker (sufficient for simple UI), bind to 0.0.0.0:8001
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:8001", "scripts.roadmap_ui:app"]
