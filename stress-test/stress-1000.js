import http from 'k6/http';

export let options = {
  stages: [
    { duration: '1m', target: 200 },   // sube a 200
    { duration: '1m', target: 400 },   // sube a 400
    { duration: '1m', target: 700 },   // sube a 700
    { duration: '1m', target: 1000 },  // 🔥 pico máximo
    { duration: '1m', target: 0 },     // baja
  ],
};

export default function () {
  const docId = `evento1_user_${__VU}`;

  const url = `https://firestore.googleapis.com/v1/projects/eventos-b074e/databases/(default)/documents/asistencias/${docId}`;

  const payload = JSON.stringify({
    fields: {
      estudiante_id: { stringValue: `user_${__VU}` },
      evento_id: { stringValue: "evento_prueba" },
      timestamp: { timestampValue: new Date().toISOString() }
    }
  });

  http.patch(url, payload, {
    headers: { 'Content-Type': 'application/json' },
  });
}