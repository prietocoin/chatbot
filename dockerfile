# 1. Imagen base estable
FROM node:20-bullseye 

# 2. Crea un directorio de trabajo
WORKDIR /usr/src/app

# 3. Instalación de librerías de Chromium (Resuelve todos los errores anteriores)
# Nota: La línea 'chromium' instala el binario que necesitamos.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libatk-bridge2.0-0 libnss3 libxss1 libasound2 libgbm-dev libgconf-2-4 libexpat1 libdrm2 libdbus-1-3 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxkbcommon0 fonts-liberation udev libcups2 chromium \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Copia los archivos de definición de dependencias
COPY package*.json ./

# 5. Instala las dependencias de Node.js
RUN npm install

# 6. Copia el código fuente de la aplicación
COPY . .

# 7. CRÍTICO: Volumen para persistencia de la sesión de WhatsApp
VOLUME /usr/src/app/.wwebjs_auth 

# 8. Exposición del puerto
EXPOSE 3000

# 9. Comando de inicio (Ejecutado como ROOT, el usuario por defecto)
CMD [ "node", "index.js" ]
