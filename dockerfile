# 1. ESENCIAL: Define la imagen base.
FROM node:20-slim 

# 2. El bloque RUN apt-get... (el que ya tienes, que está correcto)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libatk-bridge2.0-0 \
        libnss3 \
        libxss1 \
        # ... todas las demás librerías ...
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. El resto del Dockerfile (WORKDIR, COPY, EXPOSE, CMD)
WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

# CRÍTICO: Volumen para persistencia de la sesión de WhatsApp
VOLUME /usr/src/app/.wwebjs_auth 

EXPOSE 3000

CMD [ "node", "index.js" ]
