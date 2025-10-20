# Usa una imagen base de Node.js que ya incluye algunas dependencias de compilación
FROM node:20-slim

# Instala TODAS las dependencias necesarias de Chromium para Puppeteer.
# Este comando es más amplio y resuelve la mayoría de los errores de 'shared libraries'.
# Los paquetes 'libatk-bridge-2.0-0' y 'libgbm-dev' suelen ser los que faltan.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Librerías esenciales de X11 y Gráficos (resolverán el error libatk-bridge)
        libnss3 \
        libxss1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libgbm-dev \
        # Paquetes adicionales que Chromium a menudo requiere
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
        # Limpieza para reducir el tamaño final de la imagen
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crea un directorio de trabajo
WORKDIR /usr/src/app

# ... (El resto del Dockerfile sigue igual)
# COPY package*.json ./
# RUN npm install
# COPY . .
# VOLUME /usr/src/app/.wwebjs_auth
# EXPOSE 3000
# CMD [ "node", "index.js" ]
