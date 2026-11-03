-- EQUAL FUTURE: Supabase schema and Row Level Security
-- Run once in Supabase Dashboard > SQL Editor. Never put a service-role key in the website.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  college text,
  skill_interest text,
  goal text,
  role text not null default 'student' check (role in ('student','admin')),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.courses (
 id uuid primary key default gen_random_uuid(), title text not null, description text,
 level text, url text, published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.mentors (
 id uuid primary key default gen_random_uuid(), name text not null, expertise text,
 bio text, contact_url text, published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.projects (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references auth.users(id) on delete cascade,
 title text not null, description text, project_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.certificates (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references auth.users(id) on delete cascade,
 title text not null, certificate_url text, issued_at date default current_date,
 created_at timestamptz not null default now()
);
create table if not exists public.opportunities (
 id uuid primary key default gen_random_uuid(), title text not null, type text,
 organization text, description text, apply_url text, location text,
 published boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.applications (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references auth.users(id) on delete cascade,
 opportunity_id uuid not null references public.opportunities(id) on delete cascade,
 message text, status text not null default 'submitted',
 created_at timestamptz not null default now(), unique(student_id, opportunity_id)
);

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.mentors enable row level security;
alter table public.projects enable row level security;
alter table public.certificates enable row level security;
alter table public.opportunities enable row level security;
alter table public.applications enable row level security;

-- Profiles: users can read/update only themselves; role cannot be changed by client policies.
drop policy if exists "profile read own" on public.profiles;
create policy "profile read own" on public.profiles for select to authenticated using (id = auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "profile insert own" on public.profiles;
create policy "profile insert own" on public.profiles for insert to authenticated with check (id=auth.uid() and role='student');
drop policy if exists "profile update own fields" on public.profiles;
create policy "profile update own fields" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid() and role='student');

-- Published learning content is readable by signed-in students; admins manage it.
drop policy if exists "published courses read" on public.courses;
create policy "published courses read" on public.courses for select to authenticated using (published or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "admin manage courses" on public.courses;
create policy "admin manage courses" on public.courses for all to authenticated using (exists(select 1 from public.profiles where id=auth.uid() and role='admin')) with check (exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "published mentors read" on public.mentors;
create policy "published mentors read" on public.mentors for select to authenticated using (published or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "admin manage mentors" on public.mentors;
create policy "admin manage mentors" on public.mentors for all to authenticated using (exists(select 1 from public.profiles where id=auth.uid() and role='admin')) with check (exists(select 1 from public.profiles where id=auth.uid() and role='admin'));

-- Student-owned records remain private; admins may review them.
drop policy if exists "students read own projects" on public.projects;
create policy "students read own projects" on public.projects for select to authenticated using (student_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "students create own projects" on public.projects;
create policy "students create own projects" on public.projects for insert to authenticated with check (student_id=auth.uid());
drop policy if exists "students update own projects" on public.projects;
create policy "students update own projects" on public.projects for update to authenticated using (student_id=auth.uid()) with check (student_id=auth.uid());
drop policy if exists "students read own certificates" on public.certificates;
create policy "students read own certificates" on public.certificates for select to authenticated using (student_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "admin manage certificates" on public.certificates;
create policy "admin manage certificates" on public.certificates for all to authenticated using (exists(select 1 from public.profiles where id=auth.uid() and role='admin')) with check (exists(select 1 from public.profiles where id=auth.uid() and role='admin'));

drop policy if exists "published opportunities read" on public.opportunities;
create policy "published opportunities read" on public.opportunities for select to authenticated using (published or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "admin manage opportunities" on public.opportunities;
create policy "admin manage opportunities" on public.opportunities for all to authenticated using (exists(select 1 from public.profiles where id=auth.uid() and role='admin')) with check (exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "students read applications" on public.applications;
create policy "students read applications" on public.applications for select to authenticated using (student_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
drop policy if exists "students submit applications" on public.applications;
create policy "students submit applications" on public.applications for insert to authenticated with check (student_id=auth.uid() and exists(select 1 from public.opportunities where id=opportunity_id and published));

grant usage on schema public to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select on public.courses, public.mentors, public.opportunities to authenticated;
grant insert, select, update on public.projects to authenticated;
grant select on public.certificates to authenticated;
grant select, insert on public.applications to authenticated;
