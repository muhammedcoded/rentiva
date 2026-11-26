export type Row = Record<string, any>;
export const menu: {label:string;icon:string;items:[string,string][]}[] = [
 {label:"Dashboard",icon:"LayoutDashboard",items:[["Overview","/admin"]]},
 {label:"Users & Roles",icon:"Users",items:[["All Users","/admin/users"],["User Roles","/admin/roles"],["Permissions","/admin/permissions"]]},
 {label:"Properties",icon:"House",items:[["All Properties","/admin/properties"],["Property Approvals","/admin/property-approvals"],["Categories","/admin/categories"],["Locations","/admin/locations"],["Features","/admin/features"],["Property Types","/admin/property-types"]]},
 {label:"Enquiries & Bookings",icon:"MessagesSquare",items:[["All Enquiries","/admin/enquiries"],["Viewings","/admin/viewings"],["Bookings","/admin/bookings"],["Calendar","/admin/calendar"]]},
 {label:"Reviews",icon:"Star",items:[["Reviews","/admin/reviews"]]},
 {label:"Content Management",icon:"PanelsTopLeft",items:[ ["Land Verification","/admin/land-verification"], ["Blog Posts","/admin/blog"], ["Ad Placements","/admin/ad-placements"],["Articles","/admin/articles"],["Categories","/admin/content-categories"],["Tags","/admin/tags"],["Media","/admin/media"],["Pages & Contact","/admin/pages"],["Menus","/admin/menus"],["Sidebars","/admin/sidebars"],["Comments","/admin/comments"]]},
 {label:"Appearance",icon:"Palette",items:[["Themes","/admin/themes"],["Customize","/admin/customize"]]},
 {label:"Marketing",icon:"Megaphone",items:[["Ads & Banners","/admin/marketing"],["Email Templates","/admin/email-templates"],["Newsletters","/admin/newsletters"]]},
 {label:"Payments",icon:"CreditCard",items:[["Agent Subscriptions","/admin/subscriptions"],["Subscription Plans","/admin/subscription-plans"],["Managed Services","/admin/managed-services"],["Property Promotions","/admin/service-promotions"],["Transactions","/admin/payments"],["Payouts","/admin/payouts"],["Payment Settings","/admin/payment-settings"]]},
 {label:"Reports & Analytics",icon:"ChartNoAxesCombined",items:[["Analytics","/admin/analytics"],["Activity Logs","/admin/activity-logs"]]},
 {label:"Settings",icon:"Settings",items:[["General Settings","/admin/settings"],["SEO Settings","/admin/seo-settings"],["Social Links","/admin/social-links"]]},
 {label:"System",icon:"ShieldCheck",items:[["System Info","/admin/system"],["Backup & Restore","/admin/backups"]]}
];
