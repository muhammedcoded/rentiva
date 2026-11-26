-- Run after migration 0003 and after bootstrap_first_super_admin().
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
