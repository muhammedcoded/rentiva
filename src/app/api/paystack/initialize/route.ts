import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
export const runtime='nodejs';
export async function POST(req:Request){
 try{
  const supabase=await createClient(); if(!supabase) return NextResponse.json({error:'Supabase is not configured.'},{status:503});
  const {data:{user}}=await supabase.auth.getUser(); if(!user) return NextResponse.json({error:'Please sign in.'},{status:401});
  const body=await req.json(); const code=String(body.plan||''); const cycle=body.cycle==='yearly'?'yearly':'monthly';
  if(!process.env.PAYSTACK_SECRET_KEY)return NextResponse.json({error:'Paystack secret key is not configured on the server.'},{status:503});
  const admin=createAdminClient();
  const {data:profile}=await admin.from('profiles').select('account_type').eq('id',user.id).single();
  if(!profile||!['agent','landlord','agency'].includes(profile.account_type)) return NextResponse.json({error:'Only property agents, landlords and agencies can purchase listing plans.'},{status:403});
  const {data:plan}=await admin.from('subscription_plans').select('*').eq('code',code).eq('is_active',true).single();
  if(!plan) return NextResponse.json({error:'Selected plan is unavailable.'},{status:404});
  const amount=cycle==='yearly'?Math.round(Number(plan.monthly_price_kobo)*12*(1-Number(plan.yearly_discount||10)/100)):Number(plan.monthly_price_kobo);
  const {data:sub,error:subError}=await admin.from('agent_subscriptions').insert({user_id:user.id,plan_id:plan.id,billing_cycle:cycle,amount_kobo:amount,status:'pending'}).select().single();
  if(subError||!sub) throw subError||new Error('Could not create subscription.');
  const reference=`RVA-${sub.id.replaceAll('-','').slice(0,20)}-${Date.now()}`;
  const {error:paymentError}=await admin.from('payments').insert({user_id:user.id,provider:'paystack',provider_reference:reference,amount:amount/100,currency:'NGN',status:'pending',metadata:{subscription_id:sub.id,plan_code:code,billing_cycle:cycle}});
  if(paymentError) throw paymentError;
  const appUrl=process.env.NEXT_PUBLIC_APP_URL||new URL(req.url).origin;
  let response:Response;let result:any;
  try{response=await fetch('https://api.paystack.co/transaction/initialize',{method:'POST',headers:{Authorization:`Bearer ${process.env.PAYSTACK_SECRET_KEY}`, 'Content-Type':'application/json'},body:JSON.stringify({email:user.email,amount,currency:'NGN',reference,callback_url:`${appUrl}/agent/billing?payment=return`,metadata:{subscription_id:sub.id,user_id:user.id,plan_code:code,billing_cycle:cycle,custom_fields:[{display_name:'Rentiva plan',variable_name:'rentiva_plan',value:plan.name}]}})});result=await response.json()}catch{await admin.from('payments').update({status:'failed'}).eq('provider_reference',reference);await admin.from('agent_subscriptions').update({status:'cancelled'}).eq('id',sub.id);throw new Error('Could not connect to Paystack. Please try again.')}
  if(!response.ok||!result.status){await admin.from('payments').update({status:'failed'}).eq('provider_reference',reference);await admin.from('agent_subscriptions').update({status:'cancelled'}).eq('id',sub.id);throw new Error(result.message||'Paystack could not initialize payment.');}
  await admin.from('agent_subscriptions').update({last_payment_reference:reference}).eq('id',sub.id);
  return NextResponse.json({authorization_url:result.data.authorization_url,reference});
 }catch(e){return NextResponse.json({error:e instanceof Error?e.message:'Payment initialization failed.'},{status:400});}
}
