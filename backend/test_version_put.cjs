const jwt = require('jsonwebtoken');
require('dotenv').config({ path: 'D:/fieldtrack/backend/.env' });

async function run() {
  const token = jwt.sign({ userId: 'dev-admin', role: 'ADMIN' }, process.env.JWT_SECRET, { expiresIn: '1h' });
  console.log('Generated token');
  
  const res = await fetch('http://localhost:3000/api/v1/system/version', {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      latestVersion: '2.0.0',
      requiredVersion: '1.5.0',
      updateUrl: 'https://test.com'
    })
  });
  
  const data = await res.json();
  console.log('Status:', res.status);
  console.log('Response:', data);
}
run();
