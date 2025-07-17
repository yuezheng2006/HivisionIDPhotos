FROM python:3.10-slim

LABEL "language"="python"
LABEL "framework"="gradio"
LABEL "maintainer"="HivisionIDPhotos"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    wget \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt requirements-app.txt ./
RUN pip install --no-cache-dir -r requirements.txt -r requirements-app.txt

COPY . .

RUN chmod +x /app/start_with_model.sh

RUN mkdir -p hivision/creator/weights hivision/creator/retinaface/weights

RUN bash /app/start_with_model.sh true || echo "Build-time model download failed, will retry at runtime"

EXPOSE 8080

# Zeabur 平台会自动注入 PORT=8080 环境变量
CMD ["bash", "-c", "/app/start_with_model.sh false && python3 -u app.py --host 0.0.0.0 --port ${PORT:-8080}"]

