import Link from "next/link";
import { House } from "lucide-react";

export default function Brand({ light = false }: { light?: boolean }) {
  return (
    <Link href="/" className={`brand ${light ? "brand-light" : ""}`} aria-label="Rentiva home">
      <span className="brand-mark"><House size={30} strokeWidth={2.5} /></span>
      <span className="brand-copy"><strong>RENTIVA</strong><small>FIND. RENT. OWN.</small></span>
    </Link>
  );
}
