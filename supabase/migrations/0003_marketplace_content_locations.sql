create extension if not exists pgcrypto;

alter table public.properties add column if not exists agency_fee_percent numeric(5,2) not null default 5 check(agency_fee_percent between 0 and 100);
alter table public.properties add column if not exists legal_fee_percent numeric(5,2) not null default 5 check(legal_fee_percent between 0 and 100);
alter table public.properties add column if not exists is_demo boolean not null default false;
alter table public.properties add column if not exists lga_name text;
alter table public.properties add column if not exists land_title_type text;
alter table public.properties add column if not exists land_size text;

-- Demo and platform-owned inventory may be published by an administrator without an agent subscription.
create or replace function public.enforce_agent_listing_limit()
returns trigger language plpgsql security definer set search_path=public as $$
declare lim integer; used integer;
begin
 if new.status='published' and not (session_user in ('postgres','service_role') or public.is_admin()) then
  lim := public.current_active_listing_limit(new.owner_id);
  if lim <= 0 then raise exception 'An active Rentiva subscription is required before publishing listings.'; end if;
  select count(*) into used from public.properties p where p.owner_id=new.owner_id and p.status='published' and p.id is distinct from new.id and (p.listing_expires_at is null or p.listing_expires_at>now());
  if used >= lim then raise exception 'Your plan allows % active listings. Upgrade your plan or deactivate an existing listing.', lim; end if;
 end if;
 return new;
end; $$;

create table if not exists public.site_pages (
 id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
 page_type text not null default 'standard' check(page_type in ('standard','about','contact','legal','verification')),
 content text not null default '', meta_title text, meta_description text,
 is_published boolean not null default false, updated_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.blog_posts (
 id uuid primary key default gen_random_uuid(), author_id uuid references public.profiles(id) on delete set null,
 title text not null, slug text not null unique, excerpt text, content text not null default '', cover_image_url text,
 category text, status text not null default 'draft' check(status in ('draft','published','scheduled','archived')),
 published_at timestamptz, meta_title text, meta_description text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.ad_placements (
 id uuid primary key default gen_random_uuid(), name text not null, placement_key text not null unique,
 placement_type text not null check(placement_type in ('image','adsense','html')),
 image_url text, target_url text, embed_code text, alt_text text,
 is_active boolean not null default false, starts_at timestamptz, ends_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.land_verification_requests (
 id uuid primary key default gen_random_uuid(), requester_id uuid references public.profiles(id) on delete set null,
 full_name text not null, email text not null, phone text not null, state_name text not null, lga_name text,
 city_name text, area_name text, land_address text not null, survey_plan_number text, title_document_type text,
 title_document_url text, survey_plan_url text, other_document_url text,
 status text not null default 'submitted' check(status in ('submitted','under_review','site_inspection','verification_in_progress','verified','rejected','needs_more_information')),
 admin_notes text, reference_code text not null unique default ('RVL-'||upper(substr(encode(gen_random_bytes(6),'hex'),1,10))), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.location_import_runs (
 id uuid primary key default gen_random_uuid(), source_url text not null, states_count integer not null default 0,
 lgas_count integer not null default 0, areas_count integer not null default 0, imported_at timestamptz not null default now(), imported_by uuid references public.profiles(id)
);

alter table public.site_pages enable row level security;
alter table public.blog_posts enable row level security;
alter table public.ad_placements enable row level security;
alter table public.land_verification_requests enable row level security;
alter table public.location_import_runs enable row level security;
create policy "public read published site pages" on public.site_pages for select using(is_published or public.is_admin());
create policy "admins manage site pages" on public.site_pages for all using(public.is_admin()) with check(public.is_admin());
create policy "public read published blog posts" on public.blog_posts for select using(status='published' or public.is_admin());
create policy "admins manage blog posts" on public.blog_posts for all using(public.is_admin()) with check(public.is_admin());
create policy "public read active ad placements" on public.ad_placements for select using(is_active and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()) or public.is_admin());
create policy "admins manage ad placements" on public.ad_placements for all using(public.is_admin()) with check(public.is_admin());
create policy "visitors submit land verification" on public.land_verification_requests for insert with check(requester_id is null or requester_id=auth.uid());
create policy "requesters read own land verification" on public.land_verification_requests for select using(requester_id=auth.uid() or public.is_admin());
create policy "admins manage land verification" on public.land_verification_requests for all using(public.is_admin()) with check(public.is_admin());
create policy "admins read location imports" on public.location_import_runs for select using(public.is_admin());

insert into public.site_pages(title,slug,page_type,content,is_published,meta_title,meta_description) values
('About Rentiva','about','about','Rentiva is a Nigerian property marketplace and property-management service by Remscorp. We help people discover property, list real estate, find tenants and manage property with confidence.',true,'About Rentiva','Learn about Rentiva, a Nigerian property marketplace and property management company.'),
('Contact Rentiva','contact','contact','Contact the Rentiva team for property enquiries, listing support, property management, promotion and verification requests. Add your current business phone, email and office address in the page editor.',true,'Contact Rentiva','Get in touch with Rentiva for property and management support.'),
('Land Verification','land-verification','verification','Submit your land details and supporting documents for a preliminary review. Final verification may require independent searches with the relevant state land registry, surveyor and legal professionals.',true,'Land Verification Request','Request a land title and property document review through Rentiva.')
on conflict(slug) do nothing;

insert into public.ad_placements(name,placement_key,placement_type,is_active) values
('Homepage Sidebar','home_sidebar','image',false),('Homepage Header','home_header','image',false),('Homepage Footer','home_footer','image',false),('Global Header','global_header','image',false),('Global Footer','global_footer','image',false)
on conflict(placement_key) do nothing;

insert into public.property_categories(name,slug,description) values
('Residential','residential','Homes and residential property'),('Land','land','Land and plots'),('Commercial','commercial','Commercial real estate') on conflict(slug) do nothing;
insert into public.property_types(name,slug,category_id,description) values
('Apartment','apartment',(select id from public.property_categories where slug='residential'),'Flats and apartments'),
('Detached Duplex','detached-duplex',(select id from public.property_categories where slug='residential'),'Detached family houses'),
('Terrace Duplex','terrace-duplex',(select id from public.property_categories where slug='residential'),'Terrace houses'),
('Residential Land','residential-land',(select id from public.property_categories where slug='land'),'Residential plots of land'),
('Semi-Detached Duplex','semi-detached-duplex',(select id from public.property_categories where slug='residential'),'Semi-detached homes')
on conflict(slug) do nothing;

-- Eight sample properties. Prices are asking-price examples informed by current local market data, not valuations.
do $$
declare admin_id uuid; apt uuid; det uuid; ter uuid; land uuid;
begin
 select p.id into admin_id from public.profiles p join public.user_roles ur on ur.user_id=p.id join public.roles r on r.id=ur.role_id where r.slug='super-admin' order by ur.assigned_at limit 1;
 if admin_id is null then raise notice 'Demo properties skipped: bootstrap the first Super Admin, then run 0004_demo_properties.sql'; return; end if;
 select id into apt from public.property_types where slug='apartment';
 select id into det from public.property_types where slug='detached-duplex';
 select id into ter from public.property_types where slug='terrace-duplex';
 select id into land from public.property_types where slug='residential-land';
 insert into public.properties(owner_id,title,slug,description,property_type_id,purpose,price,price_period,bedrooms,bathrooms,area_sqm,status,published_at,state_name,city_name,area_name,address,is_demo,agency_fee_percent,legal_fee_percent)
 values
 (admin_id,'Modern 2 Bedroom Apartment in Lekki','demo-modern-2-bedroom-lekki','Demo listing. Modern apartment with fitted kitchen, secure estate access and parking. Contact Rentiva to arrange a viewing. Demo photo is illustrative and may not depict this exact property.',apt,'rent',9000000,'per year',2,2,110,'published',now(),'Lagos','Eti-Osa','Lekki Phase 1','Lekki Phase 1, Lagos',true,5,5),
 (admin_id,'Luxury 3 Bedroom Apartment in Ikate','demo-luxury-3-bedroom-ikate','Demo listing. Spacious three-bedroom apartment in the Lekki corridor with modern finishes. Demo photo is illustrative and may not depict this exact property.',apt,'rent',14000000,'per year',3,3,160,'published',now(),'Lagos','Eti-Osa','Ikate Elegushi','Ikate, Lekki, Lagos',true,5,5),
 (admin_id,'4 Bedroom Detached Duplex in Ikeja GRA','demo-4-bedroom-ikeja-gra','Demo listing. Family home with generous living spaces, parking and private outdoor area. Demo photo is illustrative and may not depict this exact property.',det,'rent',25000000,'per year',4,4,320,'published',now(),'Lagos','Ikeja','Ikeja GRA','Ikeja GRA, Lagos',true,5,5),
 (admin_id,'3 Bedroom Terrace Duplex in Ajah','demo-3-bedroom-terrace-ajah','Demo listing. Contemporary terrace home in a gated residential development. Demo photo is illustrative and may not depict this exact property.',ter,'rent',7000000,'per year',3,3,185,'published',now(),'Lagos','Eti-Osa','Ajah','Ajah, Lagos',true,5,5),
 (admin_id,'2 Bedroom Apartment in Lokogoma','demo-2-bedroom-lokogoma','Demo listing. Newly built apartment with good access to the city and estate security. Demo photo is illustrative and may not depict this exact property.',apt,'rent',4500000,'per year',2,2,105,'published',now(),'Federal Capital Territory','AMAC','Lokogoma','Lokogoma, Abuja',true,5,5),
 (admin_id,'3 Bedroom Terrace Duplex in Life Camp','demo-3-bedroom-life-camp','Demo listing. Three-bedroom terrace home with fitted kitchen, parking and estate facilities. Demo photo is illustrative and may not depict this exact property.',ter,'rent',9000000,'per year',3,3,210,'published',now(),'Federal Capital Territory','AMAC','Life Camp','Life Camp, Abuja',true,5,5),
 (admin_id,'4 Bedroom Detached Duplex in Guzape','demo-4-bedroom-guzape','Demo listing. Premium family residence in the Guzape district with spacious rooms and parking. Demo photo is illustrative and may not depict this exact property.',det,'rent',30500000,'per year',4,4,360,'published',now(),'Federal Capital Territory','AMAC','Guzape','Guzape, Abuja',true,5,5),
 (admin_id,'Residential Land in Lugbe','demo-residential-land-lugbe','Demo listing. Residential land opportunity in the Lugbe area. Title and survey details must be independently verified. Demo photo is illustrative and may not depict this exact plot.',land,'sale',20000000,'asking price',0,0,600,'published',now(),'Federal Capital Territory','AMAC','Lugbe','Lugbe, Abuja',true,5,5)
 on conflict(slug) do nothing;
 insert into public.property_media(property_id,storage_path,public_url,alt_text,is_cover,display_order)
 select p.id,'demo/'||p.slug||'.jpg',v.url,p.title,true,1 from public.properties p join (values
 ('demo-modern-2-bedroom-lekki','https://propertyonline.com.ng/wp-content/uploads/2022/04/Reposta_277944130_669244317638168_7840865753038037013_njpg.png-1.jpg'),
 ('demo-luxury-3-bedroom-ikate','https://www.demarkprojects.com/img/gallery/1726505585_gallery.png'),
 ('demo-4-bedroom-ikeja-gra','https://images.nigeriapropertycentre.com/properties/images/thumbs/3326239/0698319420566d-newly-built-5-bedroom-detached-duplex-with-pool-and-bq-detached-duplexes-for-sale-ikota-lekki-lagos.jpg'),
 ('demo-3-bedroom-terrace-ajah','https://i0.wp.com/www.bilaadnigeria.com/wp-content/uploads/2025/08/DJI_0023-copy-scaled.jpg?fit=2560%2C1438&ssl=1'),
 ('demo-2-bedroom-lokogoma','https://www.crossatlanticproperties.com/upload/types/House%20design%2010.jpg'),
 ('demo-3-bedroom-life-camp','https://www.aqila.ng/wp-content/uploads/2025/05/The-Bellavue-Estate-Abuja-1024x895.jpg'),
 ('demo-4-bedroom-guzape','https://propertyonline.com.ng/wp-content/uploads/2022/04/Reposta_277944130_669244317638168_7840865753038037013_njpg.png-1.jpg'),
 ('demo-residential-land-lugbe','https://i0.wp.com/www.bilaadnigeria.com/wp-content/uploads/2025/08/DJI_0023-copy-scaled.jpg?fit=2560%2C1438&ssl=1')
 ) as v(slug,url) on v.slug=p.slug where p.is_demo and not exists(select 1 from public.property_media pm where pm.property_id=p.id);
end $$;

do $$ declare t text; begin foreach t in array array['site_pages','blog_posts','ad_placements','land_verification_requests'] loop if not exists(select 1 from pg_trigger where tgname=t||'_updated_at') then execute format('create trigger %I before update on public.%I for each row execute function public.handle_updated_at()',t||'_updated_at',t); end if; end loop; end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('land-documents','land-documents',false,10485760,array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
create policy "users upload own land verification docs" on storage.objects for insert to authenticated
with check(bucket_id='land-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "owners and admins read land verification docs" on storage.objects for select to authenticated
using(bucket_id='land-documents' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));
