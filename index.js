const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const express = require('express');
const qrcode = require('qrcode-terminal');
const axios = require('axios');

// 🚨 Reemplaza esta URL con el Webhook de N8N que escuchará los mensajes de WhatsApp
const N8N_WEBHOOK_URL = 'https://tudominio.com/webhook/n8n/whatsapp-listener'; 

const app = express();
const port = 3000; 

app.use(express.json({ limit: '50mb' }));

// 1. Configuración e Inicialización del Cliente
const client = new Client({
    // Usa LocalAuth para persistir la sesión (CRÍTICO para la estrategia anti-bloqueo)
    authStrategy: new LocalAuth(),
    puppeteer: {
        // Configuraciones anti-bloqueo y para entornos Docker
        args: [
            '--no-sandbox', 
            '--disable-setuid-sandbox',
            '--disable-gpu',
            '--disable-dev-shm-usage', 
            '--no-zygote',
            '--single-process',
        ],
    }
});

// 2. Eventos de Conexión
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

// 3. Manejo de Mensajes (El Webhook que escucha los grupos)
client.on('message', async (message) => {
    // ⚠️ Escucha solo mensajes de Grupos, NO de mensajes personales.
    if (!message.fromMe && message.id.remote.endsWith('@g.us')) { 
        console.log(`Mensaje de Grupo recibido: ${message.body ? message.body.substring(0, 30) + '...' : 'Media'} `);
        
        let payload = {
            messageType: message.hasMedia ? 'media' : 'text',
            groupId: message.from,
            authorId: message.author || message.from.split('@')[0], // Identificador del autor
            body: message.body || null,
            timestamp: message.timestamp,
        };

        if (message.hasMedia) {
            try {
                // Descarga la media para obtener los datos binarios
                const media = await message.downloadMedia();
                
                // Pasa la data a N8N en Base64
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
        
        // Envía el payload al Webhook de N8N
        try {
            await axios.post(N8N_WEBHOOK_URL, payload);
            console.log('Datos enviados a N8N correctamente.');
        } catch (error) {
            console.error('❌ Error al enviar datos al Webhook de N8N:', error.message);
        }
    }
});

client.initialize();

// ------------------------------------------------------------------
// 4. Endpoints de la API (para que N8N Envíe)
// ------------------------------------------------------------------

// Endpoint: Enviar Mensaje Simple (Para reportes o respuestas planas)
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

// Endpoint: Enviar Imagen (Para la tasa diaria o reportes visuales)
app.post('/sendImage', async (req, res) => {
    const { targetGroup, base64Image, caption, mimetype = 'image/png' } = req.body; 
    
    if (!client.isReady) return res.status(503).send({ status: 'error', message: 'Chatbot no está listo o conectado.' });
    if (!targetGroup || !base64Image) return res.status(400).send({ status: 'error', message: 'Faltan targetGroup y/o base64Image.' });

    try {
        // El base64 debe ser una cadena pura, sin el prefijo 'data:image/png;base64,'
        const media = new MessageMedia(mimetype, base64Image, 'imagen_noctus');

        await client.sendMessage(targetGroup, media, { caption: caption || 'Reporte de Noctus' });
        res.send({ status: 'success', message: 'Imagen enviada correctamente.' });
    } catch (error) {
        console.error('Error enviando imagen:', error);
        res.status(500).send({ status: 'error', message: error.message });
    }
});

// 5. Iniciar el Servidor Express
app.listen(port, () => {
    console.log(`🤖 WhatsApp Bot API escuchando en el puerto ${port}`);
});
