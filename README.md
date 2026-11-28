# Rentiva | Batch 1

Fresh Next.js 15 application built from the supplied Rentify/Rentiva UI references.

## Included in this batch
- Responsive public homepage
- Responsive login page
- Responsive signup page
- Supabase browser authentication integration
- Nigerian property marketplace sample content

## Local development
1. Install Node.js 20 or newer.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local`.
4. Add your Supabase project URL and publishable/anon key.
5. Run `npm run dev`.

The public homepage can render without Supabase credentials. Login and signup require valid Supabase credentials.

## Railway
Set:
- `NEXT_PUBLIC_APP_URL` to the Railway public URL
- `NEXT_PUBLIC_SUPABASE_URL` to the Supabase Project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` to the Supabase publishable/anon key

The application start script listens on Railway's `PORT` when supplied, otherwise port 3000.

## Scope
This batch intentionally includes only the homepage, login and signup. Property search results, property details, dashboards and admin tools are not included yet.
