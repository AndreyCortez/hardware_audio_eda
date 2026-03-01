FROM python:3.12-slim

# Install system dependencies required for Ngspice and PySpice compilation
RUN apt-get update && apt-get install -y \
    ngspice \
    libngspice0 \
    libngspice0-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Upgrade pip and install standard packages
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Patch PySpice internally during build to fix NumPy and NgSpice incompatibilities
RUN sed -i 's/np.fromstring(b"".join(binary_data), dtype=float)/np.frombuffer(b"".join(binary_data), dtype=float)/g' /usr/local/lib/python3.12/site-packages/PySpice/Spice/NgSpice/RawFile.py
RUN sed -i '/if line.startswith(b"Note:"):/,+1d' /usr/local/lib/python3.12/site-packages/PySpice/Spice/NgSpice/RawFile.py
RUN sed -i '/if line.startswith(b"Warning:"):/,+1d' /usr/local/lib/python3.12/site-packages/PySpice/Spice/NgSpice/RawFile.py

COPY . .

# Run the Uvicorn server matching the docker-compose mapping
EXPOSE 8000
CMD ["uvicorn", "main_api:app", "--host", "0.0.0.0", "--port", "8000"]
