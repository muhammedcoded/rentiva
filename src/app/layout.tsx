import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Rentiva | Nigerian Property Marketplace", description: "Rentiva property marketplace and management platform by Remscorp." };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="en"><body>{children}</body></html>; }
