import https from 'https';

const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6YnFzdmZ4cGtheWdvY2pvZGprIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4NDYxNCwiZXhwIjoyMDg4MzYwNjE0fQ.Yd2Y-L4QLeCtx--6-pCBWF2QI2dyw6RgWOF0yUzicjg';
const SUPABASE_URL = 'hzbqsvfxpkaygocjodjk.supabase.co';
const EMAIL = 'admin@unipast.com';
const PASSWORD = 'Ebube123...';

function request(options, body) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null });
                } catch {
                    resolve({ status: res.statusCode, body: data });
                }
            });
        });
        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

async function main() {
    console.log('Fetching user...');
    
    // List users to find existing one
    const listRes = await request({
        hostname: SUPABASE_URL,
        path: '/auth/v1/admin/users?page=1&per_page=50',
        method: 'GET',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`
        }
    });

    const users = listRes.body.users || [];
    const existing = users.find(u => u.email === EMAIL);
    if (!existing) {
        console.log('Could not find existing user.');
        return;
    }

    const userId = existing.id;
    console.log(`Found existing user with ID: ${userId}`);
    console.log(`Updating password...`);

    const updateRes = await request({
        hostname: SUPABASE_URL,
        path: `/auth/v1/admin/users/${userId}`,
        method: 'PUT',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json'
        }
    }, {
        password: PASSWORD
    });

    console.log('Update response status:', updateRes.status);
    console.log('Response body:', JSON.stringify(updateRes.body, null, 2));

    if (updateRes.status >= 200 && updateRes.status < 300) {
        console.log('Password successfully changed!');
    } else {
        console.log('Error changing password.');
    }
}

main().catch(console.error);
