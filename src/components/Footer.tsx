import Link from "next/link";
import Brand from "./Brand";
import { Facebook, Instagram, Linkedin, Twitter } from "lucide-react";

const columns = [
  {title:"Quick Links",items:["Buy Properties","Rent Properties","Shortlets","Land for Sale","Commercial Properties"]},
  {title:"Locations",items:["Lagos","Abuja","Port Harcourt","Ibadan","All Locations"]},
  {title:"Company",items:["About Us","Blog","Contact Us","Careers","Privacy Policy"]},
  {title:"Support",items:["Help Center","Terms of Use","FAQs","Report Property","Sitemap"]}
];
export default function Footer() {
  return <footer className="site-footer">
    <div className="footer-main">
      <div className="footer-brand"><Brand light/><p>Real Estate and Property for Rent &amp; Sale Across Nigeria.</p><div className="socials"><Facebook/><Twitter/><Instagram/><Linkedin/></div></div>
      {columns.map(c=><div className="footer-column" key={c.title}><h4>{c.title}</h4>{c.items.map(x=><Link key={x} href="/#properties">{x}</Link>)}</div>)}
      <div className="newsletter"><h4>Subscribe to our Newsletter</h4><p>Get the latest property listings and real estate updates delivered to your inbox.</p><form action="#"><input type="email" placeholder="Enter your email" aria-label="Email address"/><button className="btn btn-green">Subscribe</button></form></div>
    </div>
    <div className="footer-bottom"><span>© 2026 Rentiva. All rights reserved.</span><span>We Accept: <b className="payment visa">VISA</b> <b className="payment">●●</b> <b className="payment verve">Verve</b> <b className="payment paystack">Paystack</b></span></div>
  </footer>;
}
