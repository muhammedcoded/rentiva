"use client";
import {useState} from "react";
import {useRouter} from "next/navigation";
import {createClient} from "@/lib/supabase/client";
import Link from "next/link";
import {usePathname} from "next/navigation";
import * as Icons from "lucide-react";
import {menu} from "@/lib/admin-data";
export default function AdminShell({children}:{children:React.ReactNode}){
 const path=usePathname();const router=useRouter();const [open,setOpen]=useState(false);const [search,setSearch]=useState("");const [expanded,setExpanded]=useState<string[]>(["Properties","Users & Roles","Content Management"]);
 const toggle=(label:string)=>setExpanded(v=>v.includes(label)?v.filter(x=>x!==label):[...v,label]);
 const title=menu.flatMap(g=>g.items).find(x=>x[1]===path)?.[0]||"Dashboard";
 const icon=(name:string)=>{const C=(Icons as any)[name]||Icons.Circle;return <C size={16}/>};
 return <div className="admin-shell">
  <aside className={`sidebar ${open?"open":""}`}>
   <Link href="/admin" className="brand"><Icons.House size={34} className="brand-mark"/><div><div className="brand-name">RENTIVA</div><div className="brand-sub">SUPER ADMIN</div></div></Link>
   <nav className="side-nav">{menu.map(group=>{const active=group.items.some(i=>i[1]===path);const expandedNow=expanded.includes(group.label)||active;return <div key={group.label}>
    {group.items.length===1?<Link onClick={()=>setOpen(false)} className={`nav-link ${active?"active":""}`} href={group.items[0][1]}>{icon(group.icon)}<span>{group.label}</span></Link>:<button className={`nav-heading ${active?"active":""}`} onClick={()=>toggle(group.label)}>{icon(group.icon)}<span style={{flex:1}}>{group.label}</span>{expandedNow?<Icons.ChevronUp size={13}/>:<Icons.ChevronDown size={13}/>}</button>}
    {group.items.length>1&&expandedNow&&<div className="nav-sub">{group.items.map(item=><Link onClick={()=>setOpen(false)} key={item[1]} href={item[1]} className={path===item[1]?"active":""}>{item[0]}</Link>)}</div>}
   </div>})}</nav>
   <div className="side-bottom"><div style={{fontWeight:750}}>Super Admin</div><div style={{color:"#9fb0c2",marginTop:4}}>superadmin@rentiva.ng</div><div style={{color:"#18b66b",marginTop:8,fontSize:9}}>A REMSCORP PRODUCT</div></div>
  </aside>
  <div className={`mobile-overlay ${open?"show":""}`} onClick={()=>setOpen(false)}/>
  <main className="admin-main">
   <header className="topbar"><div className="top-left"><button className="menu-toggle" onClick={()=>setOpen(true)} aria-label="Open menu"><Icons.Menu size={21}/></button><span className="top-title">{title}</span></div><div className="top-right"><label className="global-search"><Icons.Search size={14}/><input value={search} onChange={e=>setSearch(e.target.value)} onKeyDown={e=>{if(e.key==="Enter"&&search.trim())router.push(`/admin/search?q=${encodeURIComponent(search.trim())}`)}} placeholder="Search anything..."/></label><button className="icon-btn" aria-label="Notifications" onClick={()=>router.push("/admin/activity-logs")}><Icons.Bell size={16}/></button><button className="avatar" title="Sign out" onClick={async()=>{const db=createClient();await db?.auth.signOut();router.replace("/login");router.refresh()}}><Icons.UserRound size={17}/></button><div className="user-meta"><div style={{fontSize:11,fontWeight:800}}>Admin Account</div><div style={{fontSize:9,color:"#64748b"}}>Super Administrator</div></div><Icons.ChevronDown size={13}/></div></header>
   {children}
  </main>
 </div>
}
