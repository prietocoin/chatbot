RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # ASEGÚRATE de que esta librería esté aquí (resuelve tu error)
        libatk-bridge2.0-0 \
        # Dependencias comunes de Chromium
        libnss3 \
        libxss1 \
        libasound2 \
        libgbm-dev \
        libgconf-2-4 \
        libexpat1 \
        libdrm2 \
        libdbus-1-3 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxkbcommon0 \
        fonts-liberation \
        udev \
        # Limpieza
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
