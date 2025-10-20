# 1. CAMBIO CLAVE: Usamos la imagen bullseye para más estabilidad en librerías.
FROM node:20-bullseye 

# 2. Crea un directorio de trabajo
WORKDIR /usr/src/app

# 3. Instalación de librerías. Esta lista es más segura con bullseye.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Librerías esenciales de Chromium
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
        libcups2 \
        # Limpieza
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Crea un usuario no-root para seguridad y compatibilidad de Puppeteer
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser
RUN chown -R pptruser:pptruser /usr/src/app

# 5. Copia los archivos y dependencias
COPY package*.json ./
RUN npm install

COPY . .

# 6. Cambia al usuario no-root para ejecutar la aplicación
USER pptruser 

# 7. CRÍTICO: Volumen para persistencia de la sesión de WhatsApp
VOLUME /usr/src/app/.wwebjs_auth 

# 8. Expone el puerto que usa Express (puerto 3000)
EXPOSE 3000

# 9. Define el comando para iniciar la aplicación
CMD [ "node", "index.js" ]
