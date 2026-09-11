# ===== STAGE 1: Install Python dependencies =====
FROM python:3.11-slim AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Встановлюємо системні залежності для компіляції (за потреби)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ===== STAGE 2: Final runtime image =====
FROM python:3.11-slim AS runtime

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH="/install/lib/python3.11/site-packages:$PYTHONPATH"

# Create not-root user for security in Kubernetes
RUN addgroup --gid 10001 appgroup && \
    adduser --uid 10001 --gid 10001 --disabled-password appuser

# Copy only installed libraries from the builder stage
COPY --from=builder /install /usr/local

# Copy application code
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER 10001

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]