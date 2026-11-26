import {redirect} from 'next/navigation';
import AdminShell from '@/components/admin-shell';
import {createClient} from '@/lib/supabase/server';
export default async function Layout({children}:{children:React.ReactNode}){
 const db=await createClient();if(!db)redirect('/login');
 const {data:{user}}=await db.auth.getUser();if(!user)redirect('/login?next=/admin');
 const {data:assignments}=await db.from('user_roles').select('role_id').eq('user_id',user.id);
 const ids=(assignments||[]).map(x=>x.role_id);const {data:roles}=ids.length?await db.from('roles').select('slug').in('id',ids):{data:[] as any[]};
 const allowed=(roles||[]).some((r:any)=>['super-admin','editor','support-agent','marketing-manager'].includes(r.slug));if(!allowed)redirect('/agent');
 return <AdminShell>{children}</AdminShell>;
}
