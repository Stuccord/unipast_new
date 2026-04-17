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
    console.log('--- SEEDING ACADEMIC DATA ---');

    // 1. Create University
    console.log('Creating University...');
    const uniRes = await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/universities',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
    }, { name: 'KNUST' });
    const universityId = uniRes.body?.[0]?.id;
    console.log('University ID:', universityId);

    // 2. Create Faculty
    console.log('Creating Faculty...');
    const facRes = await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/faculties',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
    }, { name: 'Faculty of Engineering', university_id: universityId });
    const facultyId = facRes.body?.[0]?.id;
    console.log('Faculty ID:', facultyId);

    // 3. Create Programme
    console.log('Creating Programme...');
    const progRes = await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/programmes',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
    }, { name: 'BSc. Computer Engineering', faculty_id: facultyId });
    const programmeId = progRes.body?.[0]?.id;
    console.log('Programme ID:', programmeId);

    // 4. Create Course
    console.log('Creating Course...');
    const courseRes = await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/courses',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
    }, { 
        title: 'Introduction to Programming', 
        code: 'COE 151', 
        level: 100, 
        semester: 1, 
        programme_id: programmeId 
    });
    const courseId = courseRes.body?.[0]?.id;
    console.log('Course ID:', courseId);

    // 5. Create Past Question
    console.log('Creating Past Question...');
    await request({
        hostname: SUPABASE_URL,
        path: '/rest/v1/past_questions',
        method: 'POST',
        headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json'
        }
    }, { 
        course_id: courseId, 
        year: 2023, 
        semester: 1, 
        pdf_url: 'sample.pdf' 
    });
    console.log('Past Question created.');

    // 6. Update Admin User Profile
    console.log('Updating Admin Profile with Academic Info...');
    // We already know admin email
    const EMAIL = 'admin@unipast.app';
    
    // Fetch admin user ID
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
    const adminUser = users.find(u => u.email === EMAIL);
    if (adminUser) {
        const userId = adminUser.id;
        await request({
            hostname: SUPABASE_URL,
            path: `/rest/v1/profiles?id=eq.${userId}`,
            method: 'PATCH',
            headers: {
                'apikey': SERVICE_ROLE_KEY,
                'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
                'Content-Type': 'application/json'
            }
        }, {
            university_id: universityId,
            faculty_id: facultyId,
            programme_id: programmeId,
            current_level: 100,
            current_semester: 1
        });
        console.log('Admin Profile Updated!');
    } else {
        console.log('Admin User not found.');
    }

    console.log('--- SEEDING COMPLETE ---');
}

main().catch(console.error);
