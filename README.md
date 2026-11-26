# Rentiva.ng

Rentiva is a Nigerian property marketplace, agent listing SaaS and property-management service by Remscorp.

## Stack
- Next.js 15 App Router and TypeScript
- Supabase Auth, PostgreSQL, RLS and Storage
- Paystack for NGN payments
- Railway deployment

## Local development
1. Use Node.js 20 or newer.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local` and fill in your Supabase values.
4. Run both SQL files in order in Supabase SQL Editor:
   - `supabase/migrations/0001_initial_schema.sql`
   - `supabase/migrations/0002_rentiva_business.sql`
5. Run `npm run dev`.

## First Super Admin account
1. In Supabase, open Authentication > Users and create the first administrator user with email confirmation enabled.
2. Copy that user's UUID.
3. In Supabase SQL Editor, run:

```sql
select public.bootstrap_first_super_admin('PASTE_AUTH_USER_UUID'::uuid);
```

The bootstrap function refuses to grant a second first-time Super Admin after one already exists. Sign in at `/login`.

Alternative: deploy with a temporary strong `BOOTSTRAP_ADMIN_SECRET` and call `POST /api/bootstrap-admin` with header `x-bootstrap-secret` and JSON `{ "email": "admin@example.com", "password": "a-long-password-at-least-12", "fullName": "Rentiva Super Admin" }`. Remove the bootstrap secret from Railway after use.

## Paystack setup
- Add `PAYSTACK_SECRET_KEY` to Railway as a server-only variable. Use `sk_test_...` while testing and switch to `sk_live_...` only after Paystack live activation and end-to-end test approval.
- Set `NEXT_PUBLIC_APP_URL` to the deployed Railway domain (or final custom domain).
- In Paystack Dashboard > Settings > API Keys & Webhooks, set the webhook URL to `https://YOUR-APP-DOMAIN/api/paystack/webhook`.
- The webhook validates Paystack's `x-paystack-signature` using HMAC SHA-512. Do not put the secret key in any `NEXT_PUBLIC_` variable or frontend code.
- Agent checkout is initialized server-side, payment is verified against Paystack before activating a subscription, and the webhook provides an independent confirmation path.

The initial subscription implementation charges the full monthly or annual term as a one-time Paystack transaction. Monthly access is 30 days and annual access is 365 days. Renewal is currently user-initiated from the billing page. Automatic card rebilling is not enabled in this release.

## Listing plans
| Plan | Monthly | Annual (10% off) | Active listings |
|---|---:|---:|---:|
| Starter | ₦14,900 | ₦160,920 | 130 |
| Pro | ₦26,900 | ₦290,520 | 300 |
| Executive | ₦80,000 | ₦864,000 | 1,000 |

A database trigger blocks publishing beyond the active listing quota and requires an active subscription. Draft and pending listings do not count toward the active published quota.

## Property management by Rentiva
The `/services` page lets landlords and owners request full property management, tenant finding, property promotion, inspections and valuation support. Requests appear in Super Admin under Payments > Managed Services. Service fees are intentionally admin-configurable and are not hardcoded because no service prices were supplied.

## Railway variables
Required:
- `NEXT_PUBLIC_APP_URL`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (server-side only)
- `PAYSTACK_SECRET_KEY` (server-side only)

Temporary first-admin bootstrap only:
- `BOOTSTRAP_ADMIN_SECRET` (remove after use)

## Important release notes
- Included routes cover the public marketplace, property detail and enquiry/viewing flows, saved properties and seeker account, agent dashboard and listing workspace, subscription checkout, Rentiva service requests, and the Super Admin navigation areas shown in the supplied UI references. Core data-management screens read and write Supabase records under RLS.
- The sidebar builder supports adding widgets, editing content and changing order with move controls. It is not a drag-and-drop canvas. Role permissions can be assigned, but granular permission enforcement on every individual screen and API action still needs a dedicated authorization pass.
- CMS records are manageable, but dynamic rendering of every CMS page/menu/theme on the public site is not yet complete. Email templates and newsletter subscribers are stored, but outbound email campaigns are not connected. Ads can be managed but frontend ad placements are not yet wired. Analytics is currently a data view rather than the full chart suite in the design. Backup execution is not implemented. Automatic recurring Paystack card debits are not enabled; renewals are user-initiated.
- Supabase email confirmation, SMTP, storage policies, domain configuration, Paystack webhook registration and live credentials must be configured in their respective provider dashboards.
- Do not mark the application production-ready until the database migrations have run, the first admin is bootstrapped, the Paystack test payment and webhook are verified, and the production build has passed.


## Additional marketplace features (migration 0003)

1. Run `supabase/migrations/0003_marketplace_content_locations.sql` after migrations 0001 and 0002.
2. Bootstrap the first Super Admin using the SQL command described earlier in this README.
3. Run `supabase/seed_demo_properties.sql` to add eight clearly marked demo listings.
4. Sign in as Super Admin and open **Properties → Locations**. Click **Import / Update Locations** to import the 37 state/FCT entries, 774 LGAs and supplied local areas. This requires the server-side Supabase service role key in Railway.
5. Open **Content Management → Pages & Contact**, **Blog Posts**, and **Ad Placements** to edit public content and manage homepage/global advertising positions. Banner images can be uploaded in Ad Placements. AdSense code can be pasted into the embed-code field.
6. Public land verification intake is available at `/land-verification`; submissions appear in **Land Verification** in the Super Admin menu.
7. Public sitemap is generated at `/sitemap.xml`.

The location source covers administrative areas and a maintained selection of local areas, not every street, estate or informal neighbourhood in Nigeria. Agents can enter an unlisted neighbourhood manually. Demo prices are asking-price illustrations informed by current market snapshots, not independent valuations.


### Demo asking-price references (26 November 2026)

Demo rents use current listing and index snapshots as calibration only: PropertyPro showed a 2-bedroom Lekki listing at ₦9m/year and a 3-bedroom Lekki average around ₦13.9m/year; current 3-bedroom Lekki listings included ₦7m and ₦12m/year. Ikeja 4-bedroom listings commonly showed ₦12m–₦30m/year, while Nigeria Property Centre reported a Life Camp 3-bedroom house median of ₦8.2m/year in September 2026. See the cited public market pages before treating a number as a valuation. Demo listings are clearly marked and must not be represented as verified live inventory.

- https://propertypro.ng/property-for-rent/flat-apartment/in/lagos/2-bedroom?maxPrice=rent
- https://propertypro.ng/property-for-rent/okeigbo/in/lagos/lekki/3-bedroom
- https://propertypro.ng/property-for-rent/house/in/lagos/ikeja/4-bedroom
- https://nigeriapropertycentre.com/market-trends/average-prices/for-rent/houses/abuja/life-camp?bedrooms=3

Demo property price and photo references are documented in `supabase/DEMO_LISTING_SOURCES.md`. Review image permissions before commercial launch.
