import {NextResponse} from 'next/server';
import {createAdminClient} from '@/lib/supabase/admin';
export const runtime='nodejs';
export async function POST(req:Request){
 try{
  if(!process.env.BOOTSTRAP_ADMIN_SECRET||req.headers.get('x-bootstrap-secret')!==process.env.BOOTSTRAP_ADMIN_SECRET)return NextResponse.json({error:'Not authorized.'},{status:401});
  const {email,password,fullName}=await req.json();if(!email||!password||String(password).length<12||!fullName)return NextResponse.json({error:'Provide full name, email and a password of at least 12 characters.'},{status:400});
  const admin=createAdminClient();const {data:existing}=await admin.from('user_roles').select('user_id,roles!inner(slug)').eq('roles.slug','super-admin').limit(1);
  if(existing?.length)return NextResponse.json({error:'A super administrator already exists.'},{status:409});
  const {data,error}=await admin.auth.admin.createUser({email,email_confirm:true,password, user_metadata:{full_name:fullName}});if(error)throw error;
  await admin.from('user_roles').delete().eq('user_id',data.user.id);
  const {error:roleError}=await admin.from('user_roles').insert({user_id:data.user.id,role_id:(await admin.from('roles').select('id').eq('slug','super-admin').single()).data?.id});
  if(roleError)throw roleError;
  await admin.from('profiles').upsert({id:data.user.id,full_name:fullName,email_verified:true,account_type:'staff'});
  return NextResponse.json({success:true,message:'First Super Admin account created. Sign in at /login.'});
 }catch(e){return NextResponse.json({error:e instanceof Error?e.message:'Could not create administrator.'},{status:400});}
}
