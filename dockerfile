# Usa la misma imagen base
FROM node:20-slim

# Instala las mismas dependencias necesarias para Chromium (Puppeteer interno)
# Es el mismo bloque de instalación de dependencias del sistema operativo que el anterior.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libnss3 \
        libxss1 \
        libasound2 \
        libatk1.0-0 \
        libgconf-2-4 \
        libgbm-dev \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crea el directorio de trabajo
WORKDIR /usr/src/app

# Copia los archivos de definición de dependencias
COPY package*.json ./

# Instala las dependencias de Node.js
RUN npm install

# Copia el código fuente de la aplicación
COPY . .

# El bot guarda la sesión en este directorio
# Es el directorio que DEBES mapear a un volumen persistente en EasyPanel
VOLUME /usr/src/app/.wwebjs_auth

# Expone el puerto que usa Express (puerto 3000)
EXPOSE 3000

# Define el comando para iniciar la aplicación
CMD [ "node", "index.js" ]
