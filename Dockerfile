# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies and application dependencies into a virtual environment
COPY requirements.txt .
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code (including test files for the build stage if needed for analysis)
COPY app.py .
COPY test.py .

# Stage 2: Production
FROM python:3.11-slim

# Add a non-root user for security
RUN useradd -m -r appuser && \
    mkdir /app && \
    chown -R appuser /app

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy source code
COPY --from=builder /app/app.py .

# Ensure ownership of files
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 8080

CMD ["python", "app.py"]
