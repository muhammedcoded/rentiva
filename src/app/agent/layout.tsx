import {redirect} from 'next/navigation';
import AgentShell from '@/components/agent-shell';
import {createClient} from '@/lib/supabase/server';
export default async function Layout({children}:{children:React.ReactNode}){
 const db=await createClient();if(!db)redirect('/login');const {data:{user}}=await db.auth.getUser();if(!user)redirect('/login?next=/agent');
 const {data:profile}=await db.from('profiles').select('full_name,account_type').eq('id',user.id).single();
 if(!profile||!['agent','landlord','agency','staff'].includes(profile.account_type))redirect('/');
 return <AgentShell name={profile.full_name||'Agent'}>{children}</AgentShell>;
}
