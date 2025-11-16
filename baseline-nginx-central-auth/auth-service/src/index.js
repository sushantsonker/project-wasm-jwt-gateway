const express = require('express');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;

// In a real deployment, use JWKs or env vars
const SECRET = process.env.JWT_SECRET || "my-secret";

app.get('/verify', (req, res) => {
  const auth = req.headers['authorization'];

  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).send('Missing or invalid Authorization header');
  }

  const token = auth.slice('Bearer '.length);

  jwt.verify(token, SECRET, { algorithms: ['HS256'] }, (err, payload) => {
    if (err) {
      console.error('JWT verify error:', err.message);
      return res.status(401).send('Invalid token');
    }

    // Optional claim checks
    if (payload.iss !== 'auth.example.com') {
      return res.status(403).send('Invalid issuer');
    }

    // Attach info back to NGINX via response headers
    res.set('X-Auth-User', payload.sub || 'unknown');
    res.set('X-Auth-Roles', (payload.roles || []).join(','));

    return res.status(200).send('OK');
  });
});

app.listen(PORT, () => {
  console.log(`Auth service listening on port ${PORT}`);
});
