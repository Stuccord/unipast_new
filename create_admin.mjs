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
                    resolve({ status: res.statusCode, body: JSON.parse(data) });
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
    console.log('Step 1: Creating admin user...');

    // Create user via Supabase Admin Auth API
    const createRes = await request({
        hostname: SUPABASE_URL,
        path: '/auth/v1/admin/users',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json'
        }
    }, {
        email: EMAIL,
        password: PASSWORD,
        email_confirm: true,
        user_metadata: { full_name: 'Admin' }
    });

    console.log('Create user response status:', createRes.status);
    console.log('Response body:', JSON.stringify(createRes.body, null, 2));

    let userId;

    if (createRes.status === 200 || createRes.status === 201) {
        userId = createRes.body.id;
        console.log(`\nUser created! ID: ${userId}`);
    } else if (createRes.status === 422 && JSON.stringify(createRes.body).includes('already')) {
        console.log('\nUser already exists. Fetching existing user...');

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
        if (existing) {
            userId = existing.id;
            console.log(`Found existing user with ID: ${userId}`);
        } else {
            console.log('Could not find existing user.');
            return;
        }
    } else {
        console.log('Unexpected error creating user.');
        return;
    }

    // Step 2: Upsert profile with is_admin = true
    console.log('\nStep 2: Setting is_admin = true in profiles table...');
    const profileBody = { id: userId, is_admin: true, full_name: 'Admin' };

    const profileRes = await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/profiles',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates,return=representation'
        }
    }, profileBody);

    console.log('Profile upsert status:', profileRes.status);
    console.log('Response:', JSON.stringify(profileRes.body, null, 2));

    if (profileRes.status >= 200 && profileRes.status < 300) {
        console.log('\n===== SUCCESS =====');
        console.log(`Email:    ${EMAIL}`);
        console.log(`Password: ${PASSWORD}`);
        console.log('is_admin: true');
        console.log('You can now log in at: http://localhost:3000/login');
    } else {
        console.log('\nProfile update may have failed. Check the response above.');
        console.log('Try manually setting is_admin=true in Supabase Table Editor for user ID:', userId);
    }
}

main().catch(console.error);
