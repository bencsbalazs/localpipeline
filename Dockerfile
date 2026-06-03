FROM python:3.11-slim

# Add a non-root user for security
RUN useradd -m -r appuser && \
    mkdir /app && \
    chown -R appuser /app

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY app.py .
COPY test.py .

# Ensure ownership of files
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 8080

CMD ["python", "app.py"]
