import type { Config } from "tailwindcss";
const config: Config = { content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"], theme: { extend: { colors: { brand: { 50:"#eaf8f0",100:"#d3f1df",500:"#159653",600:"#087b43",700:"#056337",900:"#052b21" } }, boxShadow: { soft:"0 2px 12px rgba(15, 35, 65, .05)" } } }, plugins: [] };
export default config;
