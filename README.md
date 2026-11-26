# BazerbdShop

Static storefront connected to the Supabase project **OWL Proxy Shop**.

## Features
- Email/password registration and sign-in
- Product catalog, search, category filter and cart
- Secure order creation through the `place_order` database function
- Customer order history
- Admin product add/hide/delete and order status management

## Setup
1. In Supabase SQL Editor, run `supabase/migrations/202611260001_bazerbdshop.sql`.
2. Register a normal user through the site.
3. Promote your own account to admin in Supabase SQL Editor (replace the email):
   ```sql
   update public.profiles p
   set role = 'admin'
   from auth.users u
   where p.id = u.id and u.email = 'YOUR_EMAIL@example.com';
   ```
4. Enable GitHub Pages: Repository Settings → Pages → Deploy from a branch → `main` → `/ (root)`.

The frontend uses only the Supabase publishable key. Never put a service_role/secret key in browser code.

## Payment note
Checkout creates a pending order. No payment gateway has been configured; confirm payment manually until a supported gateway is added.
