import DataManager from '@/components/data-manager';
import BillingPlans from '@/components/billing-plans';
import PaymentReturn from '@/components/payment-return';
import ServiceRequest from '@/components/service-request';
import ProfileForm from '@/components/profile-form';
export default async function AgentSection({params}:{params:Promise<{section:string}>}){const {section}=await params;const allowed:Record<string,string>={listings:'properties',enquiries:'enquiries',bookings:'bookings'};if(section==='billing')return <div className="agent-page"><h1>Subscription & Billing</h1><p>Choose a listing plan and pay securely with Paystack.</p><PaymentReturn/><BillingPlans/></div>;if(section==='services')return <div className="agent-page"><h1>Rentiva Property Services</h1><p>Request professional support from the Rentiva team.</p><ServiceRequest/></div>;if(section==='profile')return <div className="agent-page"><h1>My Profile</h1><ProfileForm/></div>;return <div className="agent-page"><DataManager section={allowed[section]||'properties'} mode="agent"/></div>}
