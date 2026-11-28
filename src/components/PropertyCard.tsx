"use client";

import { useState } from "react";
import { Bath, BedDouble, CarFront, Heart, MapPin } from "lucide-react";

export type Property = { title:string; location:string; price:string; period:string; beds:number; baths:number; garages:number; image:string; featured?:boolean };
export default function PropertyCard({property:p}: {property:Property}) {
  const [saved,setSaved] = useState(false);
  return <article className="property-card">
    <div className="property-image" style={{backgroundImage:`url("${p.image}")`}}>
      {p.featured && <span className="featured-tag">FEATURED</span>}
      <button className={`save-property ${saved ? "is-saved" : ""}`} aria-label="Save property" onClick={()=>setSaved(!saved)}><Heart size={21} fill={saved ? "currentColor" : "none"}/></button>
    </div>
    <div className="property-info">
      <h3>{p.title}</h3>
      <p className="property-location"><MapPin size={13}/>{p.location}</p>
      <p className="property-price">{p.price} <span>/ {p.period}</span></p>
      <div className="property-meta"><span><BedDouble size={13}/>{p.beds} Beds</span><span><Bath size={13}/>{p.baths} Baths</span><span><CarFront size={13}/>{p.garages} Garage</span></div>
    </div>
  </article>;
}
