create extension if not exists pgcrypto;

create table if not exists public.subscription_plans (
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 name text not null,
 monthly_price_kobo bigint not null check(monthly_price_kobo > 0),
 listing_limit integer not null check(listing_limit > 0),
 yearly_discount numeric(5,2) not null default 10 check(yearly_discount between 0 and 100),
 is_active boolean not null default true,
 sort_order integer not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
insert into public.subscription_plans(code,name,monthly_price_kobo,listing_limit,yearly_discount,sort_order) values
 ('starter','Starter',1490000,130,10,1),
 ('pro','Pro',2690000,300,10,2),
 ('executive','Executive',8000000,1000,10,3)
on conflict(code) do update set name=excluded.name,monthly_price_kobo=excluded.monthly_price_kobo,listing_limit=excluded.listing_limit,yearly_discount=excluded.yearly_discount;

create table if not exists public.agent_subscriptions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 plan_id uuid not null references public.subscription_plans(id),
 billing_cycle text not null check(billing_cycle in ('monthly','yearly')),
 amount_kobo bigint not null,
 status text not null default 'pending' check(status in ('pending','active','expired','cancelled','past_due')),
 starts_at timestamptz,
 ends_at timestamptz,
 paystack_customer_code text,
 paystack_subscription_code text,
 last_payment_reference text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists agent_subscriptions_user_status_idx on public.agent_subscriptions(user_id,status,ends_at desc);

create table if not exists public.paystack_events (
 id uuid primary key default gen_random_uuid(),
 event_id text unique,
 event_type text not null,
 reference text,
 payload jsonb not null,
 processed_at timestamptz,
 created_at timestamptz not null default now()
);

create table if not exists public.property_promotions (
 id uuid primary key default gen_random_uuid(),
 property_id uuid not null references public.properties(id) on delete cascade,
 owner_id uuid not null references public.profiles(id) on delete cascade,
 promotion_type text not null default 'featured',
 starts_at timestamptz,
 ends_at timestamptz,
 status text not null default 'pending' check(status in ('pending','active','completed','cancelled')),
 payment_id uuid references public.payments(id) on delete set null,
 created_at timestamptz not null default now()
);

create table if not exists public.managed_property_requests (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid references public.profiles(id) on delete set null,
 full_name text not null,
 email text not null,
 phone text not null,
 service_type text not null check(service_type in ('full_management','tenant_finding','property_promotion','inspection','valuation','other')),
 property_address text not null,
 property_type text,
 details text,
 budget_kobo bigint,
 status text not null default 'new' check(status in ('new','contacted','inspection_scheduled','proposal_sent','in_progress','completed','declined')),
 assigned_to uuid references public.profiles(id) on delete set null,
 admin_notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists company_name text;
alter table public.profiles add column if not exists account_type text not null default 'seeker' check(account_type in ('seeker','agent','landlord','agency','staff'));
alter table public.profiles add column if not exists whatsapp_phone text;
alter table public.properties add column if not exists is_featured boolean not null default false;
alter table public.properties add column if not exists is_managed_by_rentiva boolean not null default false;
alter table public.properties add column if not exists is_promoted boolean not null default false;
alter table public.properties add column if not exists listing_expires_at timestamptz;
alter table public.properties add column if not exists currency text not null default 'NGN';
alter table public.properties add column if not exists state_name text;
alter table public.properties add column if not exists city_name text;
alter table public.properties add column if not exists area_name text;
alter table public.properties add column if not exists is_available boolean not null default true;
alter table public.properties add column if not exists verification_status text not null default 'unverified' check(verification_status in ('unverified','pending','verified','rejected'));

create or replace function public.current_active_listing_limit(p_user uuid)
returns integer language sql stable security definer set search_path=public as $$
 select coalesce((select sp.listing_limit from public.agent_subscriptions s join public.subscription_plans sp on sp.id=s.plan_id
 where s.user_id=p_user and s.status='active' and s.ends_at > now() order by s.created_at desc limit 1),0);
$$;

create or replace function public.enforce_agent_listing_limit()
returns trigger language plpgsql security definer set search_path=public as $$
declare lim integer; used integer;
begin
 if new.status='published' then
  lim := public.current_active_listing_limit(new.owner_id);
  if lim <= 0 then raise exception 'An active Rentiva subscription is required before publishing listings.'; end if;
  select count(*) into used from public.properties p where p.owner_id=new.owner_id and p.status='published' and (tg_op='INSERT' or p.id<>new.id) and (p.listing_expires_at is null or p.listing_expires_at>now());
  if used >= lim then raise exception 'Your plan allows % active listings. Upgrade your plan or deactivate an existing listing.', lim; end if;
 end if;
 return new;
end; $$;
drop trigger if exists enforce_agent_listing_limit on public.properties;
create trigger enforce_agent_listing_limit before insert or update of status,owner_id on public.properties for each row execute function public.enforce_agent_listing_limit();

create or replace function public.bootstrap_first_super_admin(p_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
 if exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where r.slug='super-admin') then
  raise exception 'A super administrator has already been configured.';
 end if;
 if not exists(select 1 from auth.users where id=p_user_id) then raise exception 'Auth user does not exist.'; end if;
 insert into public.profiles(id,full_name,email_verified,account_type)
 select id,coalesce(raw_user_meta_data->>'full_name','Rentiva Super Admin'),email_confirmed_at is not null,'staff' from auth.users where id=p_user_id
 on conflict(id) do update set account_type='staff';
 delete from public.user_roles where user_id=p_user_id;
 insert into public.user_roles(user_id,role_id)
 select p_user_id,id from public.roles where slug='super-admin' on conflict do nothing;
end; $$;
revoke all on function public.bootstrap_first_super_admin(uuid) from public, anon, authenticated;

create or replace function public.admin_dashboard_metrics()
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare out jsonb;
begin
 if not public.is_admin() then raise exception 'Not authorized'; end if;
 select jsonb_build_object(
  'users',(select count(*) from public.profiles),
  'agents',(select count(*) from public.profiles p where p.account_type in ('agent','landlord','agency')),
  'properties',(select count(*) from public.properties),
  'published',(select count(*) from public.properties where status='published'),
  'pending',(select count(*) from public.properties where status='pending'),
  'enquiries',(select count(*) from public.enquiries),
  'bookings',(select count(*) from public.bookings),
  'subscriptions',(select count(*) from public.agent_subscriptions where status='active' and ends_at>now()),
  'service_requests',(select count(*) from public.managed_property_requests where status not in ('completed','declined')),
  'payments',(select coalesce(sum(amount),0) from public.payments where status='success')
 ) into out;
 return out;
end; $$;

alter table public.subscription_plans enable row level security;
alter table public.agent_subscriptions enable row level security;
alter table public.paystack_events enable row level security;
alter table public.property_promotions enable row level security;
alter table public.managed_property_requests enable row level security;
create policy "plans public read active" on public.subscription_plans for select using(is_active or public.is_admin());
create policy "admins manage plans" on public.subscription_plans for all using(public.has_role('super-admin')) with check(public.has_role('super-admin'));
create policy "agents read own subscriptions" on public.agent_subscriptions for select using(user_id=auth.uid() or public.is_admin());
create policy "admins manage subscriptions" on public.agent_subscriptions for all using(public.is_admin()) with check(public.is_admin());
create policy "admins read paystack events" on public.paystack_events for select using(public.is_admin());
create policy "owners read own promotions" on public.property_promotions for select using(owner_id=auth.uid() or public.is_admin());
create policy "owners request own promotions" on public.property_promotions for insert with check(owner_id=auth.uid());
create policy "admins manage promotions" on public.property_promotions for all using(public.is_admin()) with check(public.is_admin());
create policy "requesters read own managed requests" on public.managed_property_requests for select using(requester_id=auth.uid() or public.is_admin());
create policy "visitors create managed requests" on public.managed_property_requests for insert with check(requester_id is null or requester_id=auth.uid());
create policy "admins manage managed requests" on public.managed_property_requests for all using(public.is_admin()) with check(public.is_admin());

insert into public.permissions(module,action,description)
select m,a,m||' '||a from (values
 ('users','view'),('users','create'),('users','update'),('users','delete'),
 ('properties','view'),('properties','create'),('properties','update'),('properties','delete'),('properties','approve'),
 ('billing','view'),('billing','manage'),('content','view'),('content','manage'),('services','manage'),('reports','view'),('settings','manage')
) x(m,a) on conflict(module,action) do nothing;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
 ('property-media','property-media',true,10485760,array['image/jpeg','image/png','image/webp']),
 ('avatars','avatars',true,5242880,array['image/jpeg','image/png','image/webp']),
 ('site-media','site-media',true,10485760,array['image/jpeg','image/png','image/webp','image/svg+xml'])
on conflict(id) do nothing;

create policy "public read property media bucket" on storage.objects for select using(bucket_id in ('property-media','avatars','site-media'));
create policy "authenticated upload own media" on storage.objects for insert to authenticated with check(bucket_id in ('property-media','avatars') and (storage.foldername(name))[1]=auth.uid()::text);
create policy "authenticated update own media" on storage.objects for update to authenticated using(bucket_id in ('property-media','avatars') and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id in ('property-media','avatars') and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admins manage site media" on storage.objects for all to authenticated using(bucket_id='site-media' and public.is_admin()) with check(bucket_id='site-media' and public.is_admin());

-- Use this once after creating the first user in Supabase Authentication:
-- select public.bootstrap_first_super_admin('AUTH_USER_UUID'::uuid);

create table if not exists public.site_settings (
 id uuid primary key default gen_random_uuid(), setting_key text not null unique, setting_value jsonb not null default '{}'::jsonb, updated_by uuid references public.profiles(id), updated_at timestamptz not null default now()
);
create table if not exists public.ad_campaigns (
 id uuid primary key default gen_random_uuid(), name text not null, placement text not null, image_url text, target_url text, starts_at timestamptz, ends_at timestamptz, status text not null default 'draft' check(status in ('draft','scheduled','active','paused','ended')), created_at timestamptz not null default now()
);
create table if not exists public.email_templates (
 id uuid primary key default gen_random_uuid(), name text not null, subject text not null, body text not null, template_key text unique, is_active boolean not null default true, updated_at timestamptz not null default now()
);
create table if not exists public.newsletters (
 id uuid primary key default gen_random_uuid(), email text not null unique, full_name text, status text not null default 'subscribed' check(status in ('subscribed','unsubscribed')), source text, created_at timestamptz not null default now()
);
create table if not exists public.payout_requests (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, amount numeric(14,2) not null, bank_name text, account_number text, account_name text, status text not null default 'pending' check(status in ('pending','processing','paid','rejected')), admin_note text, created_at timestamptz not null default now()
);
create table if not exists public.site_themes (
 id uuid primary key default gen_random_uuid(), name text not null, theme_key text not null unique, settings jsonb not null default '{}'::jsonb, is_active boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.viewing_requests (
 id uuid primary key default gen_random_uuid(), property_id uuid references public.properties(id) on delete set null, user_id uuid references public.profiles(id) on delete set null, full_name text not null, email text not null, phone text, preferred_at timestamptz, status text not null default 'pending' check(status in ('pending','confirmed','completed','cancelled')), notes text, created_at timestamptz not null default now()
);
create table if not exists public.contact_messages (
 id uuid primary key default gen_random_uuid(), name text not null, email text not null, phone text, subject text, message text not null, status text not null default 'new', created_at timestamptz not null default now()
);

alter table public.site_settings enable row level security;
alter table public.ad_campaigns enable row level security;
alter table public.email_templates enable row level security;
alter table public.newsletters enable row level security;
alter table public.payout_requests enable row level security;
alter table public.site_themes enable row level security;
alter table public.viewing_requests enable row level security;
alter table public.contact_messages enable row level security;
create policy "public read site settings safe" on public.site_settings for select using(setting_key in ('brand','homepage','contact','social_links','seo') or public.is_admin());
create policy "admins manage site settings" on public.site_settings for all using(public.is_admin()) with check(public.is_admin());
create policy "public read active ads" on public.ad_campaigns for select using(status='active' and (ends_at is null or ends_at>now()) or public.is_admin());
create policy "admins manage ads" on public.ad_campaigns for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage email templates" on public.email_templates for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage newsletters" on public.newsletters for all using(public.is_admin()) with check(public.is_admin());
create policy "public subscribe newsletter" on public.newsletters for insert with check(true);
create policy "users read own payout requests" on public.payout_requests for select using(user_id=auth.uid() or public.is_admin());
create policy "users request own payout" on public.payout_requests for insert with check(user_id=auth.uid());
create policy "admins manage payout requests" on public.payout_requests for all using(public.is_admin()) with check(public.is_admin());
create policy "public read active theme" on public.site_themes for select using(is_active or public.is_admin());
create policy "admins manage themes" on public.site_themes for all using(public.is_admin()) with check(public.is_admin());
create policy "users read own viewing requests" on public.viewing_requests for select using(user_id=auth.uid() or public.is_admin());
create policy "visitors request viewings" on public.viewing_requests for insert with check(user_id is null or user_id=auth.uid());
create policy "admins manage viewings" on public.viewing_requests for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage contact messages" on public.contact_messages for all using(public.is_admin()) with check(public.is_admin());
create policy "visitors send contact messages" on public.contact_messages for insert with check(true);

-- Basic seed data for Rentiva property classification.
insert into public.property_types(name,slug,description,allow_rent,allow_sale) values
 ('Apartment','apartment','Self-contained apartment',true,true),('Duplex','duplex','Duplex homes',true,true),('Detached House','detached-house','Detached residential homes',true,true),('Terrace','terrace','Terraced homes',true,true),('Bungalow','bungalow','Bungalow homes',true,true),('Studio','studio','Studio apartments',true,true),('Office Space','office-space','Commercial office space',true,true),('Shop','shop','Retail and shop spaces',true,true),('Warehouse','warehouse','Warehouse and industrial spaces',true,true),('Land','land','Residential or commercial land',false,true)
on conflict(slug) do nothing;
alter table public.profiles add column if not exists email text;
update public.profiles p set email=u.email from auth.users u where u.id=p.id and p.email is null;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name,email,email_verified,account_type)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email,new.email_confirmed_at is not null,coalesce(new.raw_user_meta_data->>'account_type','seeker'))
 on conflict(id) do update set email=excluded.email,full_name=case when public.profiles.full_name='' then excluded.full_name else public.profiles.full_name end;
 return new;
end; $$;

create policy "admins update profiles" on public.profiles for update using(public.is_admin()) with check(public.is_admin());
create policy "owners read property enquiries" on public.enquiries for select using(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());
create policy "owners read property bookings" on public.bookings for select using(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());
create policy "owners manage property bookings" on public.bookings for update using(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()) with check(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());
create policy "owners read property viewings" on public.viewing_requests for select using(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());
create policy "owners update property viewings" on public.viewing_requests for update using(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()) with check(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare target_role text;
begin
 insert into public.profiles(id,full_name,email,email_verified,account_type)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email,new.email_confirmed_at is not null,coalesce(new.raw_user_meta_data->>'account_type','seeker'))
 on conflict(id) do update set email=excluded.email,full_name=case when public.profiles.full_name='' then excluded.full_name else public.profiles.full_name end;
 target_role := case when coalesce(new.raw_user_meta_data->>'account_type','seeker') in ('agent','landlord','agency') then 'property-user' else 'normal-user' end;
 insert into public.user_roles(user_id,role_id) select new.id,id from public.roles where slug=target_role on conflict do nothing;
 return new;
end; $$;

create or replace function public.protect_profile_privileges() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if auth.uid()=old.id and not public.is_admin() then
  new.status:=old.status;
  new.account_type:=old.account_type;
  new.email_verified:=old.email_verified;
 end if;
 return new;
end; $$;
drop trigger if exists protect_profile_privileges on public.profiles;
create trigger protect_profile_privileges before update on public.profiles for each row execute function public.protect_profile_privileges();

with nigeria as (select id from public.locations where slug='nigeria' and location_type='country' limit 1), states(name,slug) as (values
 ('Abia','abia'),('Adamawa','adamawa'),('Akwa Ibom','akwa-ibom'),('Anambra','anambra'),('Bauchi','bauchi'),('Bayelsa','bayelsa'),('Benue','benue'),('Borno','borno'),('Cross River','cross-river'),('Delta','delta'),('Ebonyi','ebonyi'),('Edo','edo'),('Ekiti','ekiti'),('Enugu','enugu'),('Federal Capital Territory','fct'),('Gombe','gombe'),('Imo','imo'),('Jigawa','jigawa'),('Kaduna','kaduna'),('Kano','kano'),('Katsina','katsina'),('Kebbi','kebbi'),('Kogi','kogi'),('Kwara','kwara'),('Lagos','lagos'),('Nasarawa','nasarawa'),('Niger','niger'),('Ogun','ogun'),('Ondo','ondo'),('Osun','osun'),('Oyo','oyo'),('Plateau','plateau'),('Rivers','rivers'),('Sokoto','sokoto'),('Taraba','taraba'),('Yobe','yobe'),('Zamfara','zamfara')
) insert into public.locations(name,slug,parent_id,location_type,country_code) select s.name,s.slug,n.id,'state','NG' from states s cross join nigeria n on conflict(parent_id,slug) do nothing;
create policy "admins read role permissions" on public.role_permissions for select using(public.is_admin());
create policy "admins manage role permissions" on public.role_permissions for all using(public.has_role('super-admin')) with check(public.has_role('super-admin'));
create or replace function public.enforce_agent_listing_limit()
returns trigger language plpgsql security definer set search_path=public as $$
declare lim integer; used integer;
begin
 if new.status='published' and not coalesce(new.is_managed_by_rentiva,false) then
  lim := public.current_active_listing_limit(new.owner_id);
  if lim <= 0 then raise exception 'An active Rentiva subscription is required before publishing listings.'; end if;
  select count(*) into used from public.properties p where p.owner_id=new.owner_id and p.status='published' and p.id is distinct from new.id and (p.listing_expires_at is null or p.listing_expires_at>now());
  if used >= lim then raise exception 'Your plan allows % active listings. Upgrade your plan or deactivate an existing listing.', lim; end if;
 end if;
 return new;
end; $$;
create or replace function public.enforce_agent_listing_limit()
returns trigger language plpgsql security definer set search_path=public as $$
declare lim integer; used integer; sub_end timestamptz;
begin
 if not public.is_admin() then
  new.is_managed_by_rentiva := false;
  if tg_op='INSERT' then new.status := 'pending';
  elsif new.status='published' and old.status<>'published' then new.status := 'pending';
  end if;
 end if;
 if new.status='published' and not coalesce(new.is_managed_by_rentiva,false) then
  lim := public.current_active_listing_limit(new.owner_id);
  if lim <= 0 then raise exception 'An active Rentiva subscription is required before publishing listings.'; end if;
  select count(*) into used from public.properties p where p.owner_id=new.owner_id and p.status='published' and p.id is distinct from new.id and (p.listing_expires_at is null or p.listing_expires_at>now());
  if used >= lim then raise exception 'Your plan allows % active listings. Upgrade your plan or deactivate an existing listing.', lim; end if;
  select s.ends_at into sub_end from public.agent_subscriptions s join public.subscription_plans sp on sp.id=s.plan_id where s.user_id=new.owner_id and s.status='active' and s.ends_at>now() order by s.created_at desc limit 1;
  if sub_end is not null then new.listing_expires_at := sub_end; end if;
 end if;
 return new;
end; $$;
drop trigger if exists enforce_agent_listing_limit on public.properties;
create trigger enforce_agent_listing_limit before insert or update on public.properties for each row execute function public.enforce_agent_listing_limit();
drop policy if exists "public read published properties" on public.properties;
create policy "public read published properties" on public.properties for select using ((status='published' and is_available and (listing_expires_at is null or listing_expires_at>now())) or owner_id=auth.uid() or public.is_admin());
create table if not exists public.saved_properties (
 user_id uuid not null references public.profiles(id) on delete cascade,
 property_id uuid not null references public.properties(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,property_id)
);
alter table public.saved_properties enable row level security;
create policy "users manage own saved properties" on public.saved_properties for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "admins read saved properties" on public.saved_properties for select using(public.is_admin());
-- Only Rentiva staff can mark listings as company-managed, featured, promoted or verified.
create or replace function public.enforce_agent_listing_limit()
returns trigger language plpgsql security definer set search_path=public as $$
declare lim integer; used integer; sub_end timestamptz;
begin
 if not public.is_admin() then
  new.is_managed_by_rentiva := false;
  new.is_featured := false;
  new.is_promoted := false;
  new.verification_status := 'unverified';
  if tg_op='INSERT' then new.status := 'pending';
  elsif new.status='published' and old.status<>'published' then new.status := 'pending';
  end if;
 end if;
 if new.status='published' and not coalesce(new.is_managed_by_rentiva,false) then
  lim := public.current_active_listing_limit(new.owner_id);
  if lim <= 0 then raise exception 'An active Rentiva subscription is required before publishing listings.'; end if;
  select count(*) into used from public.properties p where p.owner_id=new.owner_id and p.status='published' and p.id is distinct from new.id and (p.listing_expires_at is null or p.listing_expires_at>now());
  if used >= lim then raise exception 'Your plan allows % active listings. Upgrade your plan or deactivate an existing listing.', lim; end if;
  select s.ends_at into sub_end from public.agent_subscriptions s join public.subscription_plans sp on sp.id=s.plan_id where s.user_id=new.owner_id and s.status='active' and s.ends_at>now() order by s.created_at desc limit 1;
  if sub_end is not null then new.listing_expires_at := sub_end; end if;
 end if;
 return new;
end; $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare target_role text;
begin
 insert into public.profiles(id,full_name,email,phone,email_verified,account_type)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email,nullif(new.raw_user_meta_data->>'phone',''),new.email_confirmed_at is not null,coalesce(new.raw_user_meta_data->>'account_type','seeker'))
 on conflict(id) do update set email=excluded.email,phone=coalesce(public.profiles.phone,excluded.phone),full_name=case when public.profiles.full_name='' then excluded.full_name else public.profiles.full_name end;
 target_role := case when coalesce(new.raw_user_meta_data->>'account_type','seeker') in ('agent','landlord','agency') then 'property-user' else 'normal-user' end;
 insert into public.user_roles(user_id,role_id) select new.id,id from public.roles where slug=target_role on conflict do nothing;
 return new;
end; $$;
create or replace function public.sync_user_email_verification() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.email_confirmed_at is distinct from old.email_confirmed_at then
  update public.profiles set email=new.email,email_verified=(new.email_confirmed_at is not null) where id=new.id;
 end if;
 return new;
end; $$;
drop trigger if exists on_auth_user_email_verified on auth.users;
create trigger on_auth_user_email_verified after update of email_confirmed_at on auth.users for each row execute function public.sync_user_email_verification();
create index if not exists properties_public_search_idx on public.properties(status,is_available,listing_expires_at,created_at desc);
create index if not exists managed_property_requests_status_idx on public.managed_property_requests(status,created_at desc);
create index if not exists paystack_events_reference_idx on public.paystack_events(reference);

create policy "owners update property enquiries" on public.enquiries for update using(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin()) with check(exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());
create or replace function public.increment_property_view(p_property_id uuid)
returns void language sql security definer set search_path=public as $$
 update public.properties set views_count=views_count+1 where id=p_property_id and status='published' and is_available;
$$;
grant execute on function public.increment_property_view(uuid) to anon, authenticated;
revoke all on function public.increment_property_view(uuid) from public;
grant execute on function public.increment_property_view(uuid) to anon, authenticated;
create or replace function public.admin_dashboard_metrics()
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare out jsonb;
begin
 if not public.is_admin() then raise exception 'Not authorized'; end if;
 select jsonb_build_object(
  'users',(select count(*) from public.profiles),
  'agents',(select count(*) from public.profiles p where p.account_type in ('agent','landlord','agency')),
  'properties',(select count(*) from public.properties),
  'published',(select count(*) from public.properties where status='published'),
  'pending',(select count(*) from public.properties where status='pending'),
  'enquiries',(select count(*) from public.enquiries),
  'bookings',(select count(*) from public.viewing_requests),
  'subscriptions',(select count(*) from public.agent_subscriptions where status='active' and ends_at>now()),
  'service_requests',(select count(*) from public.managed_property_requests where status not in ('completed','declined')),
  'views',(select coalesce(sum(views_count),0) from public.properties),
  'payments',(select coalesce(sum(amount),0) from public.payments where status='success')
 ) into out;
 return out;
end; $$;
create policy "owners delete own inactive properties" on public.properties for delete using(owner_id=auth.uid() and status in ('draft','pending','rejected','archived'));
