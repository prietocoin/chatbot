// Archivo index.js
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const express = require('express');
const qrcode = require('qrcode-terminal');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// 1. CARGA DE CONFIGURACIÓN
const env = process.env.NODE_ENV || 'development'; // Por defecto a 'development' si no está seteado
const configPath = path.resolve(__dirname, 'config.json');
let config = {};

try {
    const rawConfig = fs.readFileSync(configPath);
    const fullConfig = JSON.parse(rawConfig);
    config = fullConfig[env] || fullConfig['development']; // Usa el entorno actual
    
    if (!config.N8N_WEBHOOK_URL) {
        throw new Error(`URL de Webhook no encontrada para el entorno: ${env}`);
    }
    console.log(`🤖 Entorno de ejecución: ${env}`);
    console.log(`🔗 Webhook de N8N configurado: ${config.N8N_WEBHOOK_URL}`);
} catch (error) {
    console.error('❌ Error fatal al cargar la configuración (config.json o NODE_ENV):', error.message);
    process.exit(1);
}

const N8N_WEBHOOK_URL = config.N8N_WEBHOOK_URL; 

// Configuración de Axios para llamadas internas (para evitar problemas de certificados)
const axiosInstance = axios.create({
    // Si la URL es HTTP (red interna), usamos un agente especial
    httpAgent: N8N_WEBHOOK_URL.startsWith('http://') ? new require('http').Agent({ rejectUnauthorized: false }) : null,
    // Si la URL es HTTPS (red externa), el agente es nulo y usa el comportamiento por defecto (que incluye SSL)
    httpsAgent: N8N_WEBHOOK_URL.startsWith('https://') ? new require('https').Agent({ rejectUnauthorized: false }) : null,
});

const app = express();
const port = 3000; 

app.use(express.json({ limit: '50mb' }));

// 2. Configuración e Inicialización del Cliente
const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: {
        args: [
            '--no-sandbox', 
            '--disable-setuid-sandbox',
            '--disable-gpu',
            '--disable-dev-shm-usage', 
            '--no-zygote',
            '--single-process',
        ],
        executablePath: '/usr/bin/chromium', 
    }
});

// 3. Eventos de Conexión
client.on('qr', (qr) => {
    console.log('🤖 Escanea el código QR con WhatsApp Web:');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('✅ Noctus Chatbot está listo y conectado a WhatsApp.');
});

client.on('auth_failure', (msg) => {
    console.error('❌ Fallo en la autenticación. Revisa el QR o el volumen persistente.', msg);
});

// 4. Manejo de Mensajes (El Webhook que escucha los grupos)
client.on('message', async (message) => {
    // ⚠️ Escucha solo mensajes de Grupos.
    if (!message.fromMe && message.id.remote.endsWith('@g.us')) { 
        
        // Verifica la URL antes de enviar
        if (!N8N_WEBHOOK_URL) {
            console.error('❌ Error de lógica: La URL de Webhook no se cargó.');
            return;
        }

        console.log(`Mensaje de Grupo recibido: ${message.body ? message.body.substring(0, 30) + '...' : 'Media'} `);
        
        let payload = {
            messageType: message.hasMedia ? 'media' : 'text',
            groupId: message.from,
            authorId: message.author || message.from.split('@')[0],
            body: message.body || null,
            timestamp: message.timestamp,
        };

        if (message.hasMedia) {
            try {
                const media = await message.downloadMedia();
                payload.media = {
                    data: media.data, 
                    mimetype: media.mimetype,
                    filename: `file_${message.id.id}.${media.mimetype.split('/')[1]}`
                };
            } catch (error) {
                console.error('Error al descargar media:', error);
                payload.media = { error: 'Error al procesar media' };
            }
        }
        
        // Envía el payload al Webhook de N8N usando la instancia con configuración de red
        try {
            await axiosInstance.post(N8N_WEBHOOK_URL, payload);
            console.log('Datos enviados a N8N correctamente.');
        } catch (error) {
            console.error('❌ Error al enviar datos al Webhook de N8N:', error.message);
        }
    }
});

client.initialize();

// ------------------------------------------------------------------
// 5. Endpoints de la API (para que N8N Envíe)
// ------------------------------------------------------------------

// Endpoint: Enviar Mensaje Simple 
app.post('/sendMessage', async (req, res) => {
    const { targetGroup, message } = req.body; 
    
    if (!client.isReady) return res.status(503).send({ status: 'error', message: 'Chatbot no está listo o conectado.' });
    if (!targetGroup || !message) return res.status(400).send({ status: 'error', message: 'Faltan targetGroup y/o message.' });

    try {
        await client.sendMessage(targetGroup, message);
        res.send({ status: 'success', message: 'Mensaje enviado correctamente.' });
    } catch (error) {
        console.error('Error enviando mensaje:', error);
        res.status(500).send({ status: 'error', message: error.message });
    }
});

// Endpoint: Enviar Imagen 
app.post('/sendImage', async (req, res) => {
    const { targetGroup, base64Image, caption, mimetype = 'image/png' } = req.body; 
    
    if (!client.isReady) return res.status(503).send({ status: 'error', message: 'Chatbot no está listo o conectado.' });
    if (!targetGroup || !base64Image) return res.status(400).send({ status: 'error', message: 'Faltan targetGroup y/o base64Image.' });

    try {
        const media = new MessageMedia(mimetype, base64Image, 'imagen_noctus');

        await client.sendMessage(targetGroup, media, { caption: caption || 'Reporte de Noctus' });
        res.send({ status: 'success', message: 'Imagen enviada correctamente.' });
    } catch (error) {
        console.error('Error enviando imagen:', error);
        res.status(500).send({ status: 'error', message: error.message });
    }
});

// 6. Iniciar el Servidor Express
app.listen(port, () => {
    console.log(`✅ WhatsApp Bot API escuchando en el puerto ${port}`);
});
