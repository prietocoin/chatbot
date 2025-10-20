# 2. El bloque RUN apt-get...
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Librerías esenciales de Chromium (las que ya agregamos)
        libatk-bridge2.0-0 \
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
        # <<<< ESTA ES LA NUEVA LÍNEA CLAVE PARA RESOLVER libcups.so.2 >>>>
        libcups2 \
        # Limpieza
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# ... (El resto del Dockerfile)
