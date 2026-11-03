# EQUAL FUTURE

**Learn. Build. Earn. Grow.**

Live website: https://equal-future.vercel.app/

## Platform

EQUAL FUTURE is a student initiative platform built as a mobile-friendly installable web app.

### Current features
- Student email/password sign-up and login through Supabase Auth
- Student profile stored in Supabase
- Course catalogue and course enrollment
- Approved mentor directory
- Student project portfolio
- Certificates issued to student accounts
- Job and internship listings
- Opportunity applications and a student application history
- Admin dashboard for publishing courses/opportunities, approving mentors, issuing certificates, and reviewing applications
- Installable PWA shell with service worker

## Architecture
- Frontend: static HTML, CSS, and JavaScript in `index.html`
- Backend: Supabase Auth and PostgreSQL
- Hosting: Vercel, connected to the GitHub `main` branch
- Public frontend uses only the Supabase publishable key. **Never add a Supabase service-role/secret key to browser code or Vercel public environment variables.**

## Vercel settings
- Framework preset: Other
- Root directory: `./`
- Build command: blank
- Install command: blank
- Output directory: `.`

A push to `main` should trigger a new Vercel deployment when the Git integration is connected.

## Database and security
The production Supabase project already has the required tables: `profiles`, `courses`, `enrollments`, `mentors`, `projects`, `certificates`, `opportunities`, and `applications`. Row Level Security is enabled on all of them.

A database trigger now creates a student profile when a new Auth user is created. Students can only create their own projects/applications/enrollments; application and enrollment inserts are restricted to active opportunities and published courses. Admin privileges are checked server-side through the private `private.is_admin()` function and must never be granted from client-side form fields.

### Admin activation
1. Create and verify the intended administrator account through the website's **Student Account** form.
2. Only after confirming the exact administrator email, assign `profiles.role = 'admin'` to that account from the Supabase SQL Editor.
3. Log out and log back in so the admin dashboard loads with the updated role.

Do not promote an existing student account unless it is explicitly the intended owner/admin account.

## Current readiness notes
- The database currently has no published courses, mentors, certificates, or opportunities; admins must add verified content before students can see it.
- The admin account still needs to be registered and explicitly assigned the admin role.
- Learning progress is currently stored on the user's device, not synced to the cloud.
- Email notifications, payment flows, and automated certificate PDF generation are not implemented.
- Test sign-up, login, profile save, course enrollment, project save, opportunity application, and admin actions before inviting students.

## PWA
The service worker cache version is bumped with frontend releases so installed copies can refresh the app shell.
