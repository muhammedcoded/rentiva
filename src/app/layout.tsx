import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Rentiva | Find. Rent. Own.",
  description: "Find homes, land and commercial property for rent and sale across Nigeria.",
};

export default function RootLayout({children}:{children:React.ReactNode}) {
  return <html lang="en"><body>{children}</body></html>;
}
