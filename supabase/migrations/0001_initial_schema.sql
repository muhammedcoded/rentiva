create extension if not exists pgcrypto;

create type public.account_status as enum ('active','pending','inactive','suspended','banned');
create type public.property_status as enum ('draft','pending','published','rejected','archived');
create type public.listing_purpose as enum ('rent','sale','short_let');
create type public.review_status as enum ('pending','published','hidden','reported');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 phone text unique,
 avatar_url text,
 status public.account_status not null default 'active',
 email_verified boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.roles (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 description text,
 is_system boolean not null default false,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
create table public.permissions (
 id uuid primary key default gen_random_uuid(),
 module text not null,
 action text not null,
 description text,
 unique(module,action)
);
create table public.role_permissions (
 role_id uuid not null references public.roles(id) on delete cascade,
 permission_id uuid not null references public.permissions(id) on delete cascade,
 primary key(role_id,permission_id)
);
create table public.user_roles (
 user_id uuid not null references public.profiles(id) on delete cascade,
 role_id uuid not null references public.roles(id) on delete cascade,
 assigned_by uuid references public.profiles(id) on delete set null,
 assigned_at timestamptz not null default now(),
 primary key(user_id,role_id)
);
create table public.property_categories (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 description text,
 is_active boolean not null default true,
 display_order int not null default 0,
 created_at timestamptz not null default now()
);
create table public.locations (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 slug text not null,
 parent_id uuid references public.locations(id) on delete set null,
 location_type text not null check(location_type in ('country','state','city','area')),
 country_code text default 'NG',
 is_active boolean not null default true,
 display_order int not null default 0,
 unique(parent_id,slug)
);
create table public.property_types (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 category_id uuid references public.property_categories(id) on delete set null,
 description text,
 icon text,
 color text default '#16A34A',
 display_order int not null default 0,
 is_active boolean not null default true,
 allow_rent boolean not null default true,
 allow_sale boolean not null default true,
 show_in_filter boolean not null default true,
 created_by uuid references public.profiles(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.features (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 icon text,
 category text,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
create table public.properties (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete cascade,
 title text not null,
 slug text not null unique,
 description text,
 category_id uuid references public.property_categories(id) on delete set null,
 property_type_id uuid references public.property_types(id) on delete set null,
 location_id uuid references public.locations(id) on delete set null,
 address text,
 purpose public.listing_purpose not null default 'rent',
 price numeric(14,2) not null check(price >= 0),
 currency text not null default 'NGN',
 price_period text,
 bedrooms int check(bedrooms >= 0),
 bathrooms int check(bathrooms >= 0),
 toilets int check(toilets >= 0),
 parking_spaces int check(parking_spaces >= 0),
 area_sqm numeric(12,2),
 status public.property_status not null default 'pending',
 rejection_reason text,
 views_count bigint not null default 0,
 published_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.property_feature_links (
 property_id uuid references public.properties(id) on delete cascade,
 feature_id uuid references public.features(id) on delete cascade,
 primary key(property_id,feature_id)
);
create table public.property_media (
 id uuid primary key default gen_random_uuid(),
 property_id uuid not null references public.properties(id) on delete cascade,
 storage_path text not null,
 public_url text,
 alt_text text,
 is_cover boolean not null default false,
 display_order int not null default 0,
 created_at timestamptz not null default now()
);
create table public.enquiries (
 id uuid primary key default gen_random_uuid(),
 property_id uuid references public.properties(id) on delete set null,
 user_id uuid references public.profiles(id) on delete set null,
 name text not null,
 email text not null,
 phone text,
 message text not null,
 status text not null default 'new' check(status in ('new','in_progress','pending','closed','spam')),
 assigned_to uuid references public.profiles(id) on delete set null,
 created_at timestamptz not null default now()
);
create table public.bookings (
 id uuid primary key default gen_random_uuid(),
 property_id uuid not null references public.properties(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 booking_type text not null default 'viewing',
 start_at timestamptz,
 end_at timestamptz,
 status text not null default 'pending' check(status in ('pending','confirmed','cancelled','completed')),
 notes text,
 created_at timestamptz not null default now()
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(),
 property_id uuid not null references public.properties(id) on delete cascade,
 reviewer_id uuid not null references public.profiles(id) on delete cascade,
 rating int not null check(rating between 1 and 5),
 review text not null,
 status public.review_status not null default 'pending',
 admin_notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(property_id,reviewer_id)
);
create table public.tags (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 description text,
 category text,
 meta_title text,
 meta_description text,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
create table public.property_tags (
 property_id uuid references public.properties(id) on delete cascade,
 tag_id uuid references public.tags(id) on delete cascade,
 primary key(property_id,tag_id)
);
create table public.content_categories (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 description text,
 created_at timestamptz not null default now()
);
create table public.articles (
 id uuid primary key default gen_random_uuid(),
 author_id uuid references public.profiles(id) on delete set null,
 category_id uuid references public.content_categories(id) on delete set null,
 title text not null,
 slug text not null unique,
 excerpt text,
 body jsonb not null default '{}'::jsonb,
 status text not null default 'draft' check(status in ('draft','published','archived')),
 published_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.pages (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 slug text not null unique,
 body jsonb not null default '{}'::jsonb,
 status text not null default 'draft',
 meta_title text,
 meta_description text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.menus (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 location text not null,
 items jsonb not null default '[]'::jsonb,
 is_active boolean not null default true,
 updated_at timestamptz not null default now()
);
create table public.sidebars (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 slug text not null unique,
 location text not null,
 description text,
 widgets jsonb not null default '[]'::jsonb,
 settings jsonb not null default '{}'::jsonb,
 is_active boolean not null default true,
 updated_at timestamptz not null default now()
);
create table public.media_assets (
 id uuid primary key default gen_random_uuid(),
 uploaded_by uuid references public.profiles(id) on delete set null,
 storage_path text not null,
 file_name text not null,
 mime_type text,
 size_bytes bigint,
 alt_text text,
 created_at timestamptz not null default now()
);
create table public.comments (
 id uuid primary key default gen_random_uuid(),
 article_id uuid references public.articles(id) on delete cascade,
 user_id uuid references public.profiles(id) on delete set null,
 body text not null,
 status text not null default 'pending',
 created_at timestamptz not null default now()
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete cascade,
 title text not null,
 body text,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create table public.payments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete set null,
 property_id uuid references public.properties(id) on delete set null,
 provider text not null default 'paystack',
 provider_reference text unique,
 amount numeric(14,2) not null,
 currency text not null default 'NGN',
 status text not null default 'pending',
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table public.audit_logs (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references public.profiles(id) on delete set null,
 action text not null,
 resource_type text not null,
 resource_id uuid,
 details jsonb not null default '{}'::jsonb,
 ip_address inet,
 created_at timestamptz not null default now()
);

create index properties_status_created_idx on public.properties(status,created_at desc);
create index properties_location_idx on public.properties(location_id);
create index properties_type_idx on public.properties(property_type_id);
create index properties_owner_idx on public.properties(owner_id);
create index enquiries_status_created_idx on public.enquiries(status,created_at desc);
create index bookings_user_start_idx on public.bookings(user_id,start_at);
create index reviews_status_created_idx on public.reviews(status,created_at desc);
create index articles_status_published_idx on public.articles(status,published_at desc);
create index audit_logs_created_idx on public.audit_logs(created_at desc);

create or replace function public.handle_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end; $$;
do $$ declare t text; begin
 foreach t in array array['profiles','property_types','properties','reviews','articles','pages'] loop
 execute format('create trigger %I_updated_at before update on public.%I for each row execute function public.handle_updated_at()',t,t);
 end loop;
end $$;

create or replace function public.has_role(role_slug text) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=auth.uid() and r.slug=role_slug and r.is_active);
$$;
create or replace function public.has_permission(module_name text, action_name text) returns boolean language sql stable security definer set search_path=public as $$
 select public.has_role('super-admin') or exists(
 select 1 from public.user_roles ur join public.role_permissions rp on rp.role_id=ur.role_id join public.permissions p on p.id=rp.permission_id
 where ur.user_id=auth.uid() and p.module=module_name and p.action=action_name);
$$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select public.has_role('super-admin') or public.has_role('editor') or public.has_role('support-agent') or public.has_role('marketing-manager');
$$;

alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_roles enable row level security;
alter table public.property_categories enable row level security;
alter table public.locations enable row level security;
alter table public.property_types enable row level security;
alter table public.features enable row level security;
alter table public.properties enable row level security;
alter table public.property_feature_links enable row level security;
alter table public.property_media enable row level security;
alter table public.enquiries enable row level security;
alter table public.bookings enable row level security;
alter table public.reviews enable row level security;
alter table public.tags enable row level security;
alter table public.property_tags enable row level security;
alter table public.content_categories enable row level security;
alter table public.articles enable row level security;
alter table public.pages enable row level security;
alter table public.menus enable row level security;
alter table public.sidebars enable row level security;
alter table public.media_assets enable row level security;
alter table public.comments enable row level security;
alter table public.notifications enable row level security;
alter table public.payments enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles self or admin read" on public.profiles for select using(id=auth.uid() or public.is_admin());
create policy "profiles self update" on public.profiles for update using(id=auth.uid()) with check(id=auth.uid());
create policy "roles admin read" on public.roles for select using(public.is_admin());
create policy "roles super admin manage" on public.roles for all using(public.has_role('super-admin')) with check(public.has_role('super-admin'));
create policy "permissions admin read" on public.permissions for select using(public.is_admin());
create policy "permissions super admin manage" on public.permissions for all using(public.has_role('super-admin')) with check(public.has_role('super-admin'));
create policy "user roles self or admin read" on public.user_roles for select using(user_id=auth.uid() or public.is_admin());
create policy "user roles super admin manage" on public.user_roles for all using(public.has_role('super-admin')) with check(public.has_role('super-admin'));


create policy "public read active categories" on public.property_categories for select using (is_active or public.is_admin());
create policy "public read active locations" on public.locations for select using (is_active or public.is_admin());
create policy "public read active property types" on public.property_types for select using (is_active or public.is_admin());
create policy "public read active features" on public.features for select using (is_active or public.is_admin());
create policy "public read published properties" on public.properties for select using (status='published' or owner_id=auth.uid() or public.is_admin());
create policy "owners create properties" on public.properties for insert with check(owner_id=auth.uid());
create policy "owners update own properties" on public.properties for update using(owner_id=auth.uid() or public.is_admin()) with check(owner_id=auth.uid() or public.is_admin());
create policy "public read media for published listings" on public.property_media for select using (
 exists(select 1 from public.properties p where p.id=property_id and p.status='published') or public.is_admin()
);
create policy "owners manage own property media" on public.property_media for all using (
 exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()
) with check (
 exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()
);
create policy "public read published reviews" on public.reviews for select using(status='published' or reviewer_id=auth.uid() or public.is_admin());
create policy "users create own reviews" on public.reviews for insert with check(reviewer_id=auth.uid());
create policy "reviewers update own pending reviews" on public.reviews for update using(reviewer_id=auth.uid() and status='pending' or public.is_admin()) with check(reviewer_id=auth.uid() and status='pending' or public.is_admin());
create policy "public read published articles" on public.articles for select using(status='published' or public.is_admin());
create policy "public read published pages" on public.pages for select using(status='published' or public.is_admin());
create policy "public read active menus" on public.menus for select using(is_active or public.is_admin());
create policy "public read active sidebars" on public.sidebars for select using(is_active or public.is_admin());
create policy "public read tags" on public.tags for select using(is_active or public.is_admin());
create policy "public read content categories" on public.content_categories for select using(true);
create policy "users read own enquiries" on public.enquiries for select using(user_id=auth.uid() or public.is_admin());
create policy "visitors submit enquiries" on public.enquiries for insert with check(user_id is null or user_id=auth.uid());
create policy "users read own bookings" on public.bookings for select using(user_id=auth.uid() or public.is_admin());
create policy "users create own bookings" on public.bookings for insert with check(user_id=auth.uid());
create policy "users read own notifications" on public.notifications for select using(user_id=auth.uid() or public.is_admin());
create policy "users update own notifications" on public.notifications for update using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy "users read own payments" on public.payments for select using(user_id=auth.uid() or public.is_admin());
create policy "users read own comments" on public.comments for select using(user_id=auth.uid() or public.is_admin());
create policy "users submit comments" on public.comments for insert with check(user_id=auth.uid());
create policy "admins manage property categories" on public.property_categories for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage locations" on public.locations for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage property types" on public.property_types for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage features" on public.features for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage properties" on public.properties for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage enquiries" on public.enquiries for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage bookings" on public.bookings for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage reviews" on public.reviews for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage tags" on public.tags for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage property tags" on public.property_tags for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage property features" on public.property_feature_links for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage content categories" on public.content_categories for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage articles" on public.articles for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage pages" on public.pages for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage menus" on public.menus for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage sidebars" on public.sidebars for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage media assets" on public.media_assets for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage comments" on public.comments for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage notifications" on public.notifications for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage payments" on public.payments for all using(public.is_admin()) with check(public.is_admin());
create policy "admins read audit logs" on public.audit_logs for select using(public.is_admin());
create policy "admins insert audit logs" on public.audit_logs for insert with check(public.is_admin());
create policy "users manage own property tags" on public.property_tags for all using (
 exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()
) with check (
 exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()
);
create policy "users manage own property features" on public.property_feature_links for all using (
 exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()
) with check (
 exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()
);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name,email_verified)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),coalesce(new.email_confirmed_at is not null,false))
 on conflict(id) do nothing;
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

insert into public.roles(name,slug,description,is_system) values
 ('Super Admin','super-admin','Full access to all platform modules.',true),
 ('Property User','property-user','Users who can list and manage properties.',true),
 ('Normal User','normal-user','Users who browse and make enquiries.',true),
 ('Editor','editor','Can manage content, articles and pages.',false),
 ('Support Agent','support-agent','Can respond to enquiries and support tickets.',false),
 ('Marketing Manager','marketing-manager','Can manage marketing campaigns and promotions.',false)
on conflict(slug) do nothing;

insert into public.property_categories(name,slug,description) values
 ('Residential','residential','Residential properties'),('Commercial','commercial','Commercial properties'),('Land','land','Land and plots')
on conflict(slug) do nothing;

insert into public.locations(name,slug,location_type,country_code) values ('Nigeria','nigeria','country','NG') on conflict(parent_id,slug) do nothing;
