# UniPast Admin Dashboard

A standalone Next.js 14 web application for managing the UniPast platform.

## 🚀 Features
- **Dashboard Overview**: Key platform stats (users, revenue, content).
- **Academic Management**: CRUD for Universities, Faculties, Programmes, and Courses.
- **Content Upload**: Professional PDF upload form with metadata handling.
- **Rep Management**: Assign and manage campus representatives.
- **Financial History**: Track payments and subscriptions via Supabase/Paystack.

## 🛠 Setup & Local Development

1. **Clone & Navigate**:
   ```bash
   cd unipast-admin
   ```

2. **Install Dependencies**:
   ```bash
   npm install
   ```

3. **Environment Variables**:
   - Copy `.env.example` to `.env.local`.
   - Fill in your `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`.

4. **Run Development Server**:
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000) in your browser.

## ☁️ Deployment (Vercel)

1. **Connect Repository**: Link this folder to a new [Vercel](https://vercel.com) project.
2. **Configure Environment Variables**: Add the keys from `.env.local` to the Vercel project settings.
3. **Build Command**: Set to `next build`.
4. **Deploy**: Push to main or trigger a manual deploy.

## 🔒 Security
- **Middleware**: All `/admin` routes are protected by Next.js middleware.
- **Role Check**: Access is strictly limited to users with `is_admin: true` in the Supabase `profiles` table.
