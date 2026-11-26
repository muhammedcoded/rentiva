import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
export const runtime='nodejs';
export async function POST(req:Request){
 try{
  const supabase=await createClient(); if(!supabase)return NextResponse.json({error:'Supabase is not configured.'},{status:503});
  const {data:{user}}=await supabase.auth.getUser();if(!user)return NextResponse.json({error:'Please sign in.'},{status:401});
  if(!process.env.PAYSTACK_SECRET_KEY)return NextResponse.json({error:'Paystack secret key is not configured on the server.'},{status:503});
  const {reference}=await req.json();if(!reference)return NextResponse.json({error:'Payment reference is required.'},{status:400});
  const response=await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,{headers:{Authorization:`Bearer ${process.env.PAYSTACK_SECRET_KEY}`},cache:'no-store'});
  const result=await response.json();if(!response.ok||!result.status||result.data.status!=='success'||result.data.reference!==reference)return NextResponse.json({error:'Payment has not been confirmed.'},{status:402});
  if(result.data.currency!=='NGN')return NextResponse.json({error:'Unexpected payment currency.'},{status:400});
  const admin=createAdminClient();const {data:payment}=await admin.from('payments').select('*').eq('provider_reference',reference).eq('user_id',user.id).single();
  if(!payment)return NextResponse.json({error:'Payment reference not found.'},{status:404});
  if(Number(result.data.amount)!==Math.round(Number(payment.amount)*100))return NextResponse.json({error:'Payment amount does not match.'},{status:400});
  await activateSubscription(admin,reference,result.data);
  return NextResponse.json({success:true});
 }catch(e){return NextResponse.json({error:e instanceof Error?e.message:'Payment verification failed.'},{status:400});}
}
async function activateSubscription(admin:any,reference:string,tx:any){
 const {data:payment}=await admin.from('payments').select('id,metadata,user_id,status').eq('provider_reference',reference).single();if(!payment||payment.status==='success')return;
 const {data:sub}=await admin.from('agent_subscriptions').select('id,billing_cycle').eq('id',payment.metadata.subscription_id).single();if(!sub)return;
 const now=new Date();const end=new Date(now);end.setDate(end.getDate()+ (sub.billing_cycle==='yearly'?365:30));
 await admin.from('payments').update({status:'success',metadata:{...payment.metadata,paystack_transaction_id:tx.id}}).eq('id',payment.id);
 await admin.from('agent_subscriptions').update({status:'active',starts_at:now.toISOString(),ends_at:end.toISOString(),last_payment_reference:reference,paystack_customer_code:tx.customer?.customer_code||null}).eq('id',sub.id);
 await admin.from('properties').update({listing_expires_at:end.toISOString()}).eq('owner_id',payment.user_id).eq('status','published').eq('is_managed_by_rentiva',false);
 await admin.from('notifications').insert({user_id:payment.user_id,title:'Rentiva subscription activated',body:'Your listing plan is now active. You can publish properties within your plan limit.'});
}
