"use client";

import { useState } from "react";
import { Building2, ChevronDown, Home, LandPlot, Search, SlidersHorizontal, Sparkles } from "lucide-react";

const modes = [
  {label:"Rent", icon:Home}, {label:"Buy", icon:Home}, {label:"Shortlet", icon:Building2},
  {label:"Land", icon:LandPlot}, {label:"Commercial", icon:Building2}
];

export default function SearchPanel() {
  const [mode, setMode] = useState("Rent");
  const [more, setMore] = useState(false);
  const fields = [
    {label:"State", placeholder:"Select State", options:["Lagos","FCT Abuja","Rivers","Oyo","Kano","Ogun"]},
    {label:"City", placeholder:"Select City", options:["Lekki","Ikeja","Victoria Island","Abuja","Port Harcourt"]},
    {label:"Area", placeholder:"Select Area", options:["Ikate","Lekki Phase 1","Ajah","Guzape","Maitama"]},
    {label:"Property Type", placeholder:"Select Type", options:["Houses","Apartments","Duplexes","Flats","Land"]},
    {label:"Price Range", placeholder:"Any Price", options:["Any Price","Under ₦1m","₦1m - ₦5m","₦5m - ₦10m","₦10m+"]}
  ];
  return (
    <div className="search-panel" id="search">
      <div className="search-tabs">{modes.map(({label,icon:Icon}) => <button key={label} onClick={() => setMode(label)} className={mode === label ? "active" : ""}><Icon size={14}/>{label}</button>)}</div>
      <div className="search-fields">
        {fields.map((f) => <label className="select-field" key={f.label}><span>{f.label}</span><div><select defaultValue=""><option value="" disabled>{f.placeholder}</option>{f.options.map(o=><option key={o}>{o}</option>)}</select><ChevronDown size={14}/></div></label>)}
        <button className="btn btn-green search-submit" onClick={() => document.getElementById("properties")?.scrollIntoView({behavior:"smooth"})}>Search Properties <Search size={16}/></button>
      </div>
      <button className="more-filters" onClick={() => setMore(!more)}><SlidersHorizontal size={14}/>{more ? "Hide Filters" : "More Filters"}</button>
      {more && <div className="extra-filters"><label>Bedrooms <select><option>Any</option><option>1+</option><option>2+</option><option>3+</option><option>4+</option></select></label><label>Bathrooms <select><option>Any</option><option>1+</option><option>2+</option><option>3+</option></select></label><label>Furnishing <select><option>Any</option><option>Furnished</option><option>Unfurnished</option></select></label></div>}
    </div>
  );
}
