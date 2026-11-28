"use client";

import Link from "next/link";
import { useState } from "react";
import { ChevronDown, Heart, Menu, X } from "lucide-react";
import Brand from "./Brand";

const links = ["Buy", "Rent", "Shortlets", "Land", "Commercial", "Locations", "Blog", "About Us", "Contact"];

export default function Header() {
  const [open, setOpen] = useState(false);
  return (
    <header className="site-header">
      <div className="header-inner">
        <button className="mobile-menu" aria-label="Open navigation" onClick={() => setOpen(!open)}>{open ? <X /> : <Menu />}</button>
        <Brand />
        <nav className={`main-nav ${open ? "nav-open" : ""}`}>
          {links.map((item) => <Link key={item} href={item === "Rent" ? "/#search" : "/#properties"} onClick={() => setOpen(false)}>{item}{item === "Locations" && <ChevronDown size={13} />}</Link>)}
        </nav>
        <div className="header-actions">
          <Link href="/login" className="saved-link"><Heart size={17} /> Saved</Link>
          <Link href="/login" className="btn btn-outline header-login">Login</Link>
          <Link href="/signup" className="btn btn-green header-signup">Sign Up</Link>
        </div>
      </div>
    </header>
  );
}
