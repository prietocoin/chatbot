# 1. ESENCIAL: Define la imagen base. ESTA DEBE SER LA PRIMERA LÍNEA.
FROM node:20-slim 

# 2. Crea un directorio de trabajo
WORKDIR /usr/src/app

# 3. Instalación de las librerías de Chromium para Puppeteer.
# Incluye las correcciones para libatk-bridge y libcups2.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Dependencias de Chromium para Headless/Slim Images
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
        # Dependencia CRÍTICA faltante: libcups.so.2
        libcups2 \
        # Limpieza para reducir el tamaño final de la imagen
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Copia los archivos de definición de dependencias
COPY package*.json ./

# 5. Instala las dependencias de Node.js
RUN npm install

# 6. Copia el código fuente de la aplicación
COPY . .

# 7. CRÍTICO: Volumen para persistencia de la sesión de WhatsApp
# Asegúrate de mapear esta ruta a un volumen persistente en EasyPanel.
VOLUME /usr/src/app/.wwebjs_auth 

# 8. Expone el puerto que usa Express (puerto 3000)
EXPOSE 3000

# 9. Define el comando para iniciar la aplicación
CMD [ "node", "index.js" ]
