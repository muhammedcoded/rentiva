import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
const SOURCE='https://raw.githubusercontent.com/ayoolaowoilu/Nigeria-Locations-Dataset-2026-API/main/nigeria_locations.json';
export async function POST(){
 try{
  const auth=await createClient(); if(!auth)return NextResponse.json({error:'Supabase is not configured.'},{status:503});
  const {data:{user}}=await auth.auth.getUser(); if(!user)return NextResponse.json({error:'Sign in required.'},{status:401});
  const {data:roles}=await auth.from('user_roles').select('role_id').eq('user_id',user.id);
  const ids=(roles||[]).map(r=>r.role_id); const {data:roleRows}=ids.length?await auth.from('roles').select('slug').in('id',ids):{data:[] as any[]};
  if(!(roleRows||[]).some((r:any)=>r.slug==='super-admin'))return NextResponse.json({error:'Super Admin access required.'},{status:403});
  const response=await fetch(SOURCE,{cache:'no-store'}); if(!response.ok)throw new Error('Could not retrieve the Nigeria location dataset.');
  const dataset=await response.json(); if(dataset.totalStates!==37||dataset.totalLgas!==774||!Array.isArray(dataset.states))throw new Error('The location source returned an unexpected dataset.');
  const admin=createAdminClient(); let {data:country,error:countryError}=await admin.from('locations').select('id').eq('name','Nigeria').eq('location_type','country').maybeSingle();
  if(countryError)throw countryError; if(!country){const inserted=await admin.from('locations').insert({name:'Nigeria',slug:'nigeria',location_type:'country',country_code:'NG',is_active:true}).select('id').single();if(inserted.error)throw inserted.error;country=inserted.data;}
  let lgasCount=0,areasCount=0;
  for(const state of dataset.states){
   const {data:s,error:se}=await admin.from('locations').upsert({name:state.name,slug:slug(state.name),parent_id:country.id,location_type:'state',country_code:'NG',is_active:true},{onConflict:'parent_id,slug'}).select('id').single(); if(se)throw se;
   for(const lga of state.lgas||[]){
    const {data:l,error:le}=await admin.from('locations').upsert({name:lga.name,slug:slug(lga.name),parent_id:s.id,location_type:'city',country_code:'NG',is_active:true},{onConflict:'parent_id,slug'}).select('id').single(); if(le)throw le; lgasCount++;
    const rows=(lga.areas||[]).map((name:string)=>({name,slug:slug(name),parent_id:l.id,location_type:'area',country_code:'NG',is_active:true}));
    if(rows.length){const {error:ae}=await admin.from('locations').upsert(rows,{onConflict:'parent_id,slug'});if(ae)throw ae;areasCount+=rows.length;}
   }
  }
  await admin.from('location_import_runs').insert({source_url:SOURCE,states_count:dataset.states.length,lgas_count:lgasCount,areas_count:areasCount,imported_by:user.id});
  return NextResponse.json({ok:true,states:dataset.states.length,lgas:lgasCount,areas:areasCount,source:SOURCE});
 }catch(e:any){return NextResponse.json({error:e.message||'Location import failed.'},{status:500});}
}
function slug(value:string){return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');}
