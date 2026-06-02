import http from 'k6/http';

export let options = {
  stages: [
    { duration: '20s', target: 50 },   // sube a 50 usuarios
    { duration: '20s', target: 100 },  // sube a 100
    { duration: '20s', target: 200 },  // sube a 200 (🔥 estrés real)
    { duration: '20s', target: 0 },    // baja
  ],
};

export default function () {
  const url = 'https://firestore.googleapis.com/v1/projects/eventos-b074e/databases/(default)/documents/asistencias';

  const payload = JSON.stringify({
    fields: {
      estudiante_id: { stringValue: `user_${__VU}` },
      evento_id: { stringValue: "evento_prueba" },
      timestamp: { timestampValue: new Date().toISOString() }
    }
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  http.post(url, payload, params);
}