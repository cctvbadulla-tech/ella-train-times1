# Ella Train Timetable & Train Times (ellatraintimes.com)

A modern, responsive, trilingual railway timetable and tourism guide for **Ella Railway Station**, Ella, Badulla District, Uva Province, Sri Lanka.

* **Primary Domain:** `ellatraintimes.com`
* **Station Code:** `ELA`
* **Station Elevation:** 1,041 m (3,415 ft)
* **Milepost:** 166m 73c from Colombo Fort
* **Supported Languages:** English, Sinhala (සිංහල), Tamil (தமிழ்)
* **Status:** Independent timetable and passenger guidance service (Audited from official Sri Lanka Railways Main Line schedules)

---

## 1. System Architecture & Features

### Public Portal
1. **Live Sri Lanka Time & Date:** Real-time clock in `Asia/Colombo` (UTC +5:30).
2. **Timetable Search & Filter Engine:**
   - Filter by direction (All, Departing Ella, Arriving Ella).
   - Filter by destination (Badulla, Colombo Fort, Kandy, Nanu Oya, Haputale, Bandarawela).
   - Filter by operating day (Daily, Thursdays/Weekends for Ella Odyssey).
   - Filter by time period (Morning, Afternoon, Evening).
   - Instant search by Train Number or Name (`1005 Podi Menike`, `1041 Ella Odyssey`, `1007 Night Mail`, etc.).
   - Train details modal showing full intermediate stopping sequences.
3. **Verified Fares Calculator & Matrix:** Official distance-based passenger tariffs across 1st Class, 2nd Class, 3rd Class, and Observation Saloons.
4. **Service Delays & Cancellation Alerts:** Prominent trilingual banner displaying real-time operational notices with source verification.
5. **Ella Station Guide:** Facilities breakdown (luggage cloakroom, 24/7 ticket counters, restrooms, waiting lounges, platform kiosks).
6. **Tourist Attractions Near Station:** Verified distances from Ella Station (km, walking minutes, tuk-tuk minutes) with permitted Unsplash photography and Google Maps links (Nine Arch Bridge, Little Adam's Peak, Ella Rock, Ravana Falls, Demodara Loop).
7. **Emergency Hotlines:** Direct dial links for Station Master Desk, Tourist Police, 1990 Suwa Seriya Free National Ambulance, Ella Divisional Hospital, Badulla Train Control.
8. **Passenger Feedback & Correction Form:** Validated input fields with anti-spam honeypot and human verification challenge.
9. **Legal Disclaimers & Official Link:** Clear notice that this is an independent service with direct link to the official Sri Lanka Railways e-Services system.

### Station Master Admin Console (`/admin.html` or in-app modal)
- **Initial Setup Credentials:** Username: `Admin` | Initial Password: `Admin1234`
- **Mandatory Password Change:** Forces administrator to update credentials on first sign-in.
- **Brute-Force Rate Limiting:** Locks login attempts after 3 consecutive failures.
- **Trains Management:** Add, edit, and delete train schedules with confirmation modals.
- **CSV Bulk Timetable Import/Export:** Validates required columns before saving into the database.
- **Service Alerts Management:** Issue delay, cancellation, and advisory announcements.
- **Fares & Tourist Management:** Modify ticket prices and attraction details.
- **Feedback Inbox:** Read private passenger submissions, track status (`Pending`, `In Progress`, `Resolved`), and add private internal notes.
- **Security Audit Logs:** Chronological logging of all administrative actions.

---

## 2. GitHub Pages Deployment (Quick Start)

To deploy to `https://cctvbadulla-tech.github.io/ella-train-times/`:

1. **Extract all files from `ella-train-times-github-pages.zip`** into your repository root directory.
   - Ensure the `.github/` folder and `src/` folder are placed at the root level of your repository.
2. **Commit and push** to your GitHub repository:
   ```bash
   git add .
   git commit -m "Deploy complete Ella Train Timetable to GitHub Pages"
   git push origin main
   ```
3. **Configure GitHub Pages Source**:
   - Go to your repository on GitHub: `Settings` -> `Pages`.
   - Under **Build and deployment** -> **Source**, select **GitHub Actions**.
4. The automated workflow `.github/workflows/deploy.yml` will install dependencies, build the Vite application into `dist/`, and publish it to GitHub Pages.

---

## 3. Local Installation & Development Guide
```bash
# Clone or open repository
git clone https://github.com/your-username/ella-train-times.git
cd ella-train-times

# Install dependencies
npm install

# Start development server on port 3000
npm run dev
```

### Step 2: Supabase Database Setup
1. Create a free account at [Supabase](https://supabase.com/).
2. Create a new project (e.g. `ella-railway-prod`) and choose region `Singapore (ap-southeast-1)` or `Mumbai (ap-south-1)` for lowest latency to Sri Lanka.
3. Navigate to **SQL Editor** in the Supabase Dashboard.
4. Copy the entire contents of `supabase-schema.sql` into the SQL editor and run it.
5. This automatically creates:
   - All 13 relational tables with foreign keys and indexes.
   - Row Level Security (RLS) policies ensuring public visitors can only read published schedules and insert feedback.
   - Initial verified seed data for Ella Railway Station.

### Step 3: Configure Authentication
1. In Supabase Dashboard, go to **Authentication** -> **Users**.
2. Click **Add User** -> **Create User**.
   - Email: `admin@ellatraintimes.com`
   - Password: `Admin1234` (initial setup password)
   - Auto-confirm User: `Checked`
3. In SQL Editor, link the created user to `admin_profiles`:
```sql
INSERT INTO admin_profiles (id, username, full_name, role, must_change_password)
VALUES ('<PASTE-USER-UUID-FROM-AUTH>', 'Admin', 'Ella Station Master', 'station_master', true);
```
4. On first sign-in, the system prompts for a new strong password and automatically clears `must_change_password`.

### Step 4: Configure Email Provider (Resend)
1. Sign up for a free account at [Resend](https://resend.com/) (allows up to 3,000 emails/month free).
2. Generate an API Key under **API Keys**.
3. Set your server environment variables in `.env`:
```env
RESEND_API_KEY="re_your_api_key_here"
STATION_MASTER_EMAIL="ellastation.inquiries@gmail.com"
NOTIFICATION_SENDER_EMAIL="alerts@ellatraintimes.com"
```
4. Verify your sending domain (`ellatraintimes.com`) inside the Resend dashboard with standard SPF and DKIM DNS TXT records.

### Step 5: Connecting Domain & DNS (`ellatraintimes.com`)
1. Purchase or configure `ellatraintimes.com` at your registrar (Namecheap, Cloudflare Registrar, Porkbun, or Google Domains).
2. For hosting with Cloud Run, Vercel, or Netlify:
   - **Type A Record:** `@` points to host IP
   - **CNAME Record:** `www` points to `ellatraintimes.com`
3. Enable automatic SSL/TLS certificate generation (Let's Encrypt HTTPS).

---

## 3. CSV Timetable Import Format

When using the Admin Console to import schedules, format the CSV as follows (or use `sample-timetable-ella.csv`):

```csv
trainNumber,name,direction,originStation,destinationStation,arrivalTimeElla,departureTimeElla,operatingDays,platform,currentStatus,source
"1005","Podi Menike (Express)","to_badulla","Colombo Fort (FOT)","Badulla (BDA)","15:14","15:17","Daily","Platform 1","On Time","Sri Lanka Railways Main Line Working Timetable"
```

Required Columns:
- `trainNumber`: Integer or string code (e.g. `1005`)
- `name`: Train name (e.g. `Podi Menike`)
- `direction`: `to_badulla`, `to_colombo`, or `to_kandy`
- `originStation`: Starting terminal
- `destinationStation`: Final terminus
- `arrivalTimeElla`: 24h format `HH:MM`
- `departureTimeElla`: 24h format `HH:MM`
- `operatingDays`: Semicolon-delimited days (e.g. `Daily` or `Thursday;Saturday;Sunday`)

---

## 4. Cost & Maintenance Overview

* **Database & Hosting (Supabase + Cloud Run/Vercel):** $0/month on free tiers (supports up to 50,000 monthly active visitors).
* **Email Dispatch (Resend):** $0/month (up to 3,000 emails free).
* **Domain Name (`ellatraintimes.com`):** ~$10 - $14 / year.
* **Routine Maintenance:** Run weekly audits against the [Sri Lanka Railways e-Services Schedule Portal](https://eservices.railway.gov.lk/schedule/homeAction.action?lag=en).

---

## 5. Security & Privacy Notes

- Public visitors are never exposed to private passenger messages or internal station notes.
- Passwords are never stored in plaintext.
- Rate-limiting safeguards the admin portal against brute-force attacks.
- Anti-spam verification blocks automated bots from flooding the Station Master's inbox.
