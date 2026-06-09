import http from 'k6/http';
import { check } from 'k6';

export default function () {

  const res = http.patch(url, payload, {
    headers: {
      'Content-Type': 'application/json',
    },
  });

  check(res, {
    'status 200': (r) => r.status === 200,
  });

  if (res.status !== 200) {
    console.log(`Error: ${res.status}`);
    console.log(res.body);
  }
}