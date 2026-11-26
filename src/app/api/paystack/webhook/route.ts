import { NextResponse } from 'next/server';
import crypto from 'node:crypto';
import { createAdminClient } from '@/lib/supabase/admin';
export const runtime='nodejs';
export async function POST(req:Request){
 const raw=await req.text();const signature=req.headers.get('x-paystack-signature');const secret=process.env.PAYSTACK_SECRET_KEY;
 if(!secret||!signature)return NextResponse.json({error:'Webhook is not configured.'},{status:400});
 const expected=crypto.createHmac('sha512',secret).update(raw).digest('hex');
 const a=Buffer.from(signature);const b=Buffer.from(expected);if(a.length!==b.length||!crypto.timingSafeEqual(a,b))return NextResponse.json({error:'Invalid signature.'},{status:401});
 try{
  const event=JSON.parse(raw);const admin=createAdminClient();const reference=event.data?.reference||null;
  const eventId=String(event.data?.id||`${event.event}:${reference}`);
  const {data:prior}=await admin.from('paystack_events').select('id,processed_at').eq('event_id',eventId).maybeSingle();
  if(prior?.processed_at)return NextResponse.json({received:true,duplicate:true});
  if(!prior){const {error:logError}=await admin.from('paystack_events').insert({event_id:eventId,event_type:event.event,reference,payload:event});if(logError&&logError.code!=='23505')throw logError;}
  if(event.event==='charge.success'&&reference){
   const {data:payment}=await admin.from('payments').select('id,user_id,metadata,amount,status').eq('provider_reference',reference).single();
   if(payment&&payment.status!=='success'&&Number(event.data.amount)===Math.round(Number(payment.amount)*100)&&event.data.status==='success'){
    const {data:sub}=await admin.from('agent_subscriptions').select('id,billing_cycle').eq('id',payment.metadata.subscription_id).single();
    if(sub){const start=new Date();const end=new Date(start);end.setDate(end.getDate()+(sub.billing_cycle==='yearly'?365:30));await admin.from('agent_subscriptions').update({status:'active',starts_at:start.toISOString(),ends_at:end.toISOString(),last_payment_reference:reference,paystack_customer_code:event.data.customer?.customer_code||null}).eq('id',sub.id);
     await admin.from('properties').update({listing_expires_at:end.toISOString()}).eq('owner_id',payment.user_id).eq('status','published').eq('is_managed_by_rentiva',false);await admin.from('notifications').insert({user_id:payment.user_id,title:'Rentiva subscription activated',body:'Your listing plan is now active. You can publish properties within your plan limit.'});}
    await admin.from('payments').update({status:'success',metadata:{...payment.metadata,paystack_transaction_id:event.data.id}}).eq('id',payment.id);
   }
  }
  if(event.event==='charge.failed'&&reference)await admin.from('payments').update({status:'failed'}).eq('provider_reference',reference).neq('status','success');
  await admin.from('paystack_events').update({processed_at:new Date().toISOString()}).eq('event_id',eventId);
  return NextResponse.json({received:true});
 }catch{return NextResponse.json({error:'Webhook processing failed.'},{status:500});}
}
