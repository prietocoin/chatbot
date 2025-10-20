# 1. ESENCIAL: Usamos la imagen bullseye para más estabilidad en librerías de Chromium.
FROM node:20-bullseye 

# 2. Crea un directorio de trabajo
WORKDIR /usr/src/app

# 3. Instalación de librerías de Chromium. Este comando resuelve los errores anteriores.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Dependencias esenciales de Chromium
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
        # Herramientas necesarias para la ejecución
        chromium \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Crea un usuario no-root para seguridad (requerido por Puppeteer)
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser

# 5. Copia los archivos de definición de dependencias
COPY package*.json ./

# 6. Instala las dependencias de Node.js
RUN npm install

# 7. Copia el código fuente de la aplicación
COPY . .

# 8. CORRECCIÓN DE PERMISOS: Da propiedad al nuevo usuario. 
# ESTA LÍNEA ES CLAVE para resolver el error EACCES: permission denied.
RUN chown -R pptruser:pptruser /usr/src/app

# 9. Cambia al usuario no-root para ejecutar la aplicación
USER pptruser 

# 10. CRÍTICO: Volumen para persistencia de la sesión de WhatsApp
# Asegúrate de que esta ruta esté mapeada a un volumen persistente en EasyPanel.
VOLUME /usr/src/app/.wwebjs_auth 

# 11. Expone el puerto que usa Express (puerto 3000)
EXPOSE 3000

# 12. Define el comando para iniciar la aplicación
CMD [ "node", "index.js" ]
