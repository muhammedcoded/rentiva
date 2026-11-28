import Header from "@/components/Header";
import Footer from "@/components/Footer";
import SearchPanel from "@/components/SearchPanel";
import PropertyCard, { Property } from "@/components/PropertyCard";
import { ArrowRight, Building2, ChevronRight, MapPin, MessageCircle, Store, Trees, Warehouse, House, Hotel, Building, Landmark } from "lucide-react";
import Link from "next/link";

const hero = "/images/hero.jpg";
const properties:Property[] = [
 {title:"5 Bedroom Detached Duplex",location:"Lekki Phase 1, Lagos",price:"₦350,000",period:"year",beds:5,baths:5,garages:1,image:"/images/property-1.jpg",featured:true},
 {title:"3 Bedroom Apartment",location:"Maitama, Abuja",price:"₦2,500,000",period:"year",beds:3,baths:4,garages:1,image:"/images/property-2.jpg",featured:true},
 {title:"4 Bedroom Terrace Duplex",location:"Ikoyi, Lagos",price:"₦550,000",period:"year",beds:4,baths:5,garages:2,image:"/images/property-3.jpg",featured:true},
 {title:"2 Bedroom Shortlet Apartment",location:"Victoria Island, Lagos",price:"₦60,000",period:"night",beds:2,baths:2,garages:1,image:"/images/property-4.jpg",featured:true}
];
const types = [{name:"Houses",icon:House},{name:"Apartments",icon:Building2},{name:"Duplexes",icon:House},{name:"Flats",icon:Building},{name:"Self Contain",icon:House},{name:"Land",icon:Trees},{name:"Shortlets",icon:Hotel},{name:"Offices",icon:Building2},{name:"Shops",icon:Store},{name:"Warehouses",icon:Warehouse},{name:"Commercial",icon:Landmark}];
const locations = [["Lagos","12,456"],["Abuja","8,732"],["Port Harcourt","4,289"],["Ibadan","3,678"],["Benin City","2,345"],["Kano","2,001"],["Kaduna","1,876"],["Enugu","1,502"]];
const states = ["Lagos","FCT Abuja","Rivers","Oyo","Kano","Delta","Edo","Kaduna","Anambra","Ogun","Akwa Ibom","Imo","Enugu","Abia","Ondo","Osun","Kwara","Cross River","Bauchi","Plateau","Nasarawa","Benue","Kogi","Sokoto","Adamawa","Taraba","Yobe","Zamfara","Kebbi","Borno"];

export default function HomePage() {
 return <>
  <Header/>
  <main>
   <section className="hero" style={{backgroundImage:`linear-gradient(90deg,rgba(5,25,34,.45),rgba(5,25,34,.25)),url("${hero}")`}}>
    <div className="ad-slot ad-left"><strong>AD SLOT</strong><small>300x600</small></div>
    <div className="hero-content"><h1>REAL ESTATE &amp; PROPERTY IN NIGERIA</h1><h2>Real Estate and Property for Rent &amp; Sale Across Nigeria</h2><p>Find your next home, land or commercial property.</p><SearchPanel/></div>
    <div className="ad-slot ad-right"><strong>AD SLOT</strong><small>300x600</small></div>
   </section>
   <div className="content-layout">
    <div className="main-column">
     <section className="section-block types-section"><div className="section-heading"><h2>Explore Property Types</h2><Link href="/#properties" className="mobile-view-all">View All <ChevronRight size={15}/></Link></div><div className="types-grid">{types.map(({name,icon:Icon})=><Link href="/#properties" className="type-card" key={name}><Icon size={23}/><span>{name}</span></Link>)}</div></section>
     <section className="section-block" id="properties"><div className="section-heading"><h2>Featured Properties</h2><Link href="/#properties" className="view-all">View All <ChevronRight size={17}/></Link></div><div className="properties-grid">{properties.map(p=><PropertyCard key={p.title} property={p}/>)}</div></section>
     <section className="states-banner"><div className="states-intro"><h3>Find a Property<br/>Anywhere in Nigeria</h3><p>Browse properties in all 36 states + FCT</p><Link href="/#properties" className="btn btn-green">Browse by State <ChevronRight size={15}/></Link></div><div className="states-list">{states.map(s=><Link href="/#properties" key={s}><MapPin size={12}/>{s}</Link>)}</div></section>
     <section className="lower-grid"><div><div className="section-heading"><h2>Latest Properties</h2><Link href="/#properties" className="view-all">View All <ChevronRight size={16}/></Link></div><div className="latest-grid">{properties.slice(0,3).map(p=><PropertyCard key={p.title} property={p}/>)}</div></div><div className="blog-preview"><div className="section-heading"><h2>Latest from the Blog</h2><Link href="/#blog" className="view-all">View All <ChevronRight size={16}/></Link></div><article className="blog-card"><img src="/images/blog.jpg" alt="Elegant home interior"/><div><h3>Top 10 Things to Consider Before Renting a Home in Nigeria</h3><small>May 20, 2026</small><span>Tips &amp; Guides</span></div></article></div></section>
    </div>
    <aside className="sidebar"><section className="popular-card"><div className="section-heading"><h2>Popular Locations</h2><Link href="/#locations" className="view-all">View All <ChevronRight size={15}/></Link></div>{locations.map(([name,count])=><Link href="/#properties" className="popular-row" key={name}><span><MapPin size={14}/>{name}</span><small>{count} Properties</small></Link>)}</section><div className="ad-slot ad-square"><strong>AD SLOT</strong><small>300x250</small></div></aside>
   </div>
  </main>
  <Footer/>
  <Link href="/login" className="chat-float" aria-label="Chat with Rentiva"><MessageCircle size={21}/></Link>
 </>;
}
