import Link from 'next/link';
import type { LucideIcon } from 'lucide-react';
import {
  Activity,
  ArrowUpRight,
  Building2,
  CalendarDays,
  CreditCard,
  Eye,
  FileText,
  Headset,
  House,
  Image as ImageIcon,
  MessageSquare,
  Users,
} from 'lucide-react';

import { createClient } from '@/lib/supabase/server';

type DashboardMetric = {
  label: string;
  key: string;
  icon: LucideIcon;
};

type QuickAction = {
  label: string;
  href: string;
  icon: LucideIcon;
};

const dashboardMetrics: DashboardMetric[] = [
  { label: 'Total Users', key: 'users', icon: Users },
  { label: 'Property Agents', key: 'agents', icon: Building2 },
  { label: 'Total Properties', key: 'properties', icon: House },
  { label: 'Published Properties', key: 'published', icon: Eye },
  { label: 'Enquiries', key: 'enquiries', icon: MessageSquare },
  { label: 'Bookings', key: 'bookings', icon: CalendarDays },
  { label: 'Active Subscriptions', key: 'subscriptions', icon: CreditCard },
  { label: 'Service Requests', key: 'service_requests', icon: Headset },
];

const quickActions: QuickAction[] = [
  { label: 'Add Property', href: '/admin/properties', icon: House },
  { label: 'Manage Users', href: '/admin/users', icon: Users },
  { label: 'Property Approvals', href: '/admin/property-approvals', icon: Building2 },
  { label: 'Manage Articles', href: '/admin/articles', icon: FileText },
  { label: 'Media Library', href: '/admin/media', icon: ImageIcon },
  { label: 'Subscriptions', href: '/admin/subscriptions', icon: CreditCard },
  { label: 'Managed Services', href: '/admin/managed-services', icon: Headset },
  { label: 'Analytics', href: '/admin/analytics', icon: Activity },
];

function formatCount(value: unknown): string {
  const numericValue = typeof value === 'number' ? value : Number(value ?? 0);
  return Number.isFinite(numericValue)
    ? numericValue.toLocaleString('en-NG')
    : '0';
}

function formatNaira(value: unknown): string {
  const numericValue = typeof value === 'number' ? value : Number(value ?? 0);
  return Number.isFinite(numericValue)
    ? numericValue.toLocaleString('en-NG', { maximumFractionDigits: 2 })
    : '0';
}

export default async function AdminDashboardPage() {
  const supabase = await createClient();

  let metrics: Record<string, unknown> = {};
  let metricsError: string | null = null;

  if (supabase) {
    const result = await supabase.rpc('admin_dashboard_metrics');

    if (result.error) {
      metricsError = result.error.message;
    } else if (result.data && typeof result.data === 'object' && !Array.isArray(result.data)) {
      metrics = result.data as Record<string, unknown>;
    }
  } else {
    metricsError = 'Supabase is not configured. Add the Supabase environment variables in Railway.';
  }

  return (
    <div className="page-wrap">
      <div className="page-head">
        <div>
          <h1>Dashboard</h1>
          <div className="crumb">Live Rentiva platform overview</div>
        </div>
        <span className="live-label">LIVE DATABASE</span>
      </div>

      {metricsError ? (
        <div className="notice">Dashboard metrics could not load: {metricsError}</div>
      ) : null}

      <div className="stats-grid">
        {dashboardMetrics.map((metric) => {
          const MetricIcon = metric.icon;

          return (
            <div className="stat-card" key={metric.key}>
              <div className="stat-icon">
                <MetricIcon size={18} aria-hidden="true" />
              </div>
              <div className="stat-label">{metric.label}</div>
              <div className="stat-value">{formatCount(metrics[metric.key])}</div>
            </div>
          );
        })}
      </div>

      <div className="content-grid">
        <section className="panel" aria-labelledby="quick-management-title">
          <h2 className="panel-title" id="quick-management-title">
            Quick management
          </h2>

          <div className="admin-quick-grid">
            {quickActions.map((action) => {
              const ActionIcon = action.icon;

              return (
                <Link
                  href={action.href}
                  className="admin-quick"
                  key={action.href}
                >
                  <span>
                    <ActionIcon size={19} aria-hidden="true" />
                  </span>
                  <b>{action.label}</b>
                  <ArrowUpRight size={14} aria-hidden="true" />
                </Link>
              );
            })}
          </div>
        </section>

        <section className="panel" aria-labelledby="platform-revenue-title">
          <h2 className="panel-title" id="platform-revenue-title">
            Platform revenue
          </h2>
          <div className="revenue-total">₦{formatNaira(metrics.payments)}</div>
          <p className="muted">
            Total successful payments recorded in Rentiva.
          </p>
          <Link href="/admin/payments">View transactions →</Link>

          <hr />

          <h2 className="panel-title">Property services</h2>
          <p className="muted">
            Manage requests for property management, tenant finding, inspection
            and promotion.
          </p>
          <Link href="/admin/managed-services">Open service requests →</Link>
        </section>
      </div>

      <div className="product-note">Rentiva is a product of Remscorp.</div>
    </div>
  );
}
