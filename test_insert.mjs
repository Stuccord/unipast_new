import https from 'https';

const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6YnFzdmZ4cGtheWdvY2pvZGprIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4NDYxNCwiZXhwIjoyMDg4MzYwNjE0fQ.Yd2Y-L4QLeCtx--6-pCBWF2QI2dyw6RgWOF0yUzicjg';
const SUPABASE_URL = 'hzbqsvfxpkaygocjodjk.supabase.co';

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
    console.log('--- TESTING INSERT INTO past_questions ---');

    // Use existing course ID from check_schema output
    const courseId = "7e58d000-e4eb-45d8-ade3-ba748b62afd6";

    const res = await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/past_questions',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
    }, { 
        course_id: courseId, 
        year: 2024, 
        semester: 1, 
        pdf_url: 'test_insertion.pdf' 
    });

    console.log('Status:', res.status);
    console.log('Body:', res.body);
}

main().catch(console.error);
