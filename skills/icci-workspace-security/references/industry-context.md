# Industry Breach Context for Executive Reports

## Purpose
Use these examples when making the case for MFA and security hardening. Match examples to the client's industry. Update this file after each engagement with new breaches.

---

## Hospitality / Hotels

### MGM Resorts International -- September 2023
- **How it started:** Attacker found an MGM employee on LinkedIn, called IT help desk impersonating them. Help desk reset the employee's MFA credentials. **Total time to gain access: one 10-minute phone call.**
- **What happened:** Slot machines went offline across all Las Vegas properties. Hotel room keys stopped working. Online reservations, mobile app, payment systems all failed. Properties reverted to **manual check-in with pen and paper** for 9 days.
- **Financial impact:** $100+ million in lost revenue. $10 million in incident response costs. MGM refused to pay ransom.
- **Data exposed:** Customer PII including names, contact info, DOB, driver's license numbers, SSNs, passport numbers.
- **Key point:** Started with credential theft/social engineering. MFA bypass via help desk. Phishing-resistant MFA (FIDO2) would have prevented it.

### Caesars Entertainment -- August 2023
- **How it started:** Same Scattered Spider group social-engineered an **outsourced IT support vendor**. Gained credentials providing access to Caesars' internal network. Breach undetected for 3 weeks.
- **What happened:** Loyalty program database with up to **65 million customer records** exfiltrated. SSNs and driver's license numbers stolen.
- **Financial impact:** Caesars paid $15 million ransom (negotiated from $30M). Class-action lawsuits followed.
- **Key point:** Credential compromise of a third-party vendor cascaded to enterprise systems.

### Choice Hotels -- January 2026
- **How it started:** Social engineering attack gave unauthorized access to an application containing sensitive **franchisee records including SSNs** -- even though the application required MFA.
- **What happened:** Names, contact info, SSNs, DOBs exposed. 2 years credit monitoring + $1M identity theft insurance for affected individuals.
- **Key point:** Even with MFA, sophisticated attacks can succeed. Phishing-resistant MFA (Passkeys/FIDO2) is the new standard.

### Otelier Platform Breach -- 2024
- **How it started:** Credentials stolen via **info-stealer malware** from an Otelier employee. Used to access Atlassian server, then scraped AWS S3 credentials.
- **What happened:** 7.8 terabytes of hotel customer data exfiltrated. Affected Marriott, Hilton, Hyatt.
- **Data exposed:** 437,000+ customer email addresses, names, addresses, phone numbers, booking details, partial credit card data.
- **Key point:** Single set of stolen credentials at a third-party platform exposed data across multiple major hotel brands.

### Industry Statistics (Hospitality)
- **82% of North American hotels** experienced a successful cyberattack during summer 2024 (VikingCloud)
- **58% of hotels** targeted by 5+ attacks
- **44% of hotels** experienced 12+ hours of downtime from an attack
- **Front desk systems** identified as top-3 risk target (34% of security leaders)
- Average hospitality breach cost: **$3.86 million** in 2024
- CISA Advisory AA23-320A specifically warns about Scattered Spider targeting hotels

---

## Healthcare / Veterinary

### Change Healthcare -- February 2024
- **How it started:** Stolen credentials used to access a remote access portal that **lacked MFA**.
- **What happened:** Largest healthcare data breach in US history. Payment processing for pharmacies and hospitals disrupted nationwide for weeks.
- **Financial impact:** UnitedHealth paid $22 million ransom. Estimated total cost: $1.6 billion.
- **Data exposed:** ~100 million patient records (names, SSNs, medical records, insurance info).
- **Key point:** CEO testified to Congress that MFA was not enabled on the compromised system.

### Ascension Health -- May 2024
- **How it started:** Employee clicked a malicious link (phishing). Ransomware deployed.
- **What happened:** 140 hospitals affected. EHR systems down. Ambulances diverted. Medication errors reported.
- **Financial impact:** Estimated $1.8 billion in losses. Weeks of manual operations.

### National Veterinary Associates (NVA) -- October 2019
- **How it started:** Ryuk ransomware deployed via compromised credentials. NVA operates 700+ veterinary hospitals.
- **What happened:** Practice management systems encrypted across multiple facilities. Clinics forced to revert to paper records for days. Patient scheduling, billing, and medical records inaccessible.
- **Financial impact:** Undisclosed, but operational disruption across hundreds of clinics.
- **Key point:** Directly relevant to veterinary clients. Shows that vet practices are not too small to target — attackers target the corporate network and hit all clinics at once. Credential compromise was the entry vector. Used in WVH-2026-03 report.

### Industry Statistics (Healthcare)
- Healthcare is the most expensive sector for data breaches: **$10.93 million** average (IBM 2024)
- **HIPAA penalties** for breaches caused by insufficient access controls: $100K - $2M per violation category
- HHS requires MFA for HIPAA compliance (2025 NPRM)

---

## Education / Schools

### Minneapolis Public Schools -- February 2023
- **How it started:** Ransomware via compromised credentials.
- **What happened:** 300,000+ files stolen and published. Student psychological records, sexual assault reports, disciplinary files exposed publicly.
- **Financial impact:** $1M ransom demand (not paid). Massive reputational damage.

### Los Angeles Unified School District -- September 2022
- **How it started:** Credential compromise leading to ransomware (Vice Society).
- **What happened:** 500GB of student and employee data stolen. SSNs, passport scans, psychological assessments.
- **Data exposed:** 2,000+ student psychological evaluations, contractor SSNs, employee records.

### Industry Statistics (Education)
- K-12 schools experienced 325 publicly disclosed cyber incidents in 2024
- Average recovery cost: **$750,000** per incident
- 80% of school districts have no dedicated cybersecurity staff

---

## Professional Services / Small Business

### General Statistics
- **43% of cyberattacks target small businesses** (Verizon DBIR 2024)
- **60% of small businesses** close within 6 months of a major cyberattack
- Average small business breach cost: **$164,000**
- Credential abuse is the #1 initial access vector: **22% of all breaches** (Verizon DBIR 2025)
- Phishing is the #2 vector: **15% of breaches**

### Key Talking Point for Small Business Clients
> "The difference between MGM and your company is not that the attackers are less skilled -- it's that your data and systems have not yet been fully exploited. The credential attacks hitting your accounts right now are the exact same attack pattern that cost MGM $100 million. MFA is the control that stops them."

---

## CISA Recommendations (All Sectors)

From CISA Advisory AA23-320A (Scattered Spider) and general guidance:
1. Implement **FIDO/WebAuthn or PKI-based MFA** (phishing-resistant)
2. Do NOT rely on SMS-based or push-notification MFA alone
3. Train help desk staff to verify identity through out-of-band methods
4. Monitor for info-stealer malware and credential dumps
5. Implement conditional access policies based on device trust and location

---

## Update Log

| Date | Update | Engagement |
|---|---|---|
| 2026-03-03 | Initial creation with hospitality focus | DAHL-2026-01 |
