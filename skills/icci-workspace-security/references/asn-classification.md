# ASN Classification Database

## Overview

This database classifies Autonomous System Numbers (ASNs) as either **LEGITIMATE** (property/staff traffic) or **ATTACK** (hosting/VPN/cloud infrastructure). It is the foundation of accurate traffic separation.

**Self-improvement rule:** After every engagement, add any new ASNs encountered to this database with WHOIS-verified details.

---

## Attack ASNs (Hosting / VPN / Cloud Infrastructure)

Events from these ASNs are classified as attack traffic. These are commercial hosting providers, VPN services, and cloud platforms commonly used by cybercriminal groups for automated credential attacks.

| ASN | Provider | Country | Type | First Seen |
|---|---|---|---|---|
| 62240 | SIA Singularity Telecom / EGIHosting | Latvia/US | VPN/Hosting | DAHL-2026-01, WVH-2026-03 (confirmed unauthorized access) |
| 16276 | OVH SAS | France/Canada | Cloud hosting | DAHL-2026-01 |
| 132203 | Tencent Cloud Computing | China | Cloud hosting | DAHL-2026-01 |
| 212238 | M247 Europe SRL | UK/Romania | VPN/Hosting | DAHL-2026-01 |
| 24940 | Hetzner Online GmbH | Germany | Cloud hosting | DAHL-2026-01 |
| 136907 | Huawei Cloud Service | China | Cloud hosting | DAHL-2026-01 |
| 9009 | M247 Ltd (alt range) | Romania | VPN/Hosting | DAHL-2026-01 |
| 205100 | Clouvider Ltd | UK | Hosting | DAHL-2026-01 |
| 44477 | Stark Industries Solutions | Moldova | Hosting | DAHL-2026-01 |
| 396982 | Google Cloud Platform | US | Cloud (misused) | DAHL-2026-01 |
| 174 | Cogent/PSINet | US | Transit (misused) | DAHL-2026-01 |
| 14061 | DigitalOcean LLC | US | Cloud hosting | DAHL-2026-01 |
| 8100 | QuadraNet Enterprises | US | Hosting | DAHL-2026-01 |
| 46562 | Total Server Solutions | US | Hosting | DAHL-2026-01 |
| 20473 | Vultr Holdings LLC | Global | Cloud hosting | DAHL-2026-01 |
| 16509 | Amazon AWS (EC2) | US | Cloud (misused) | DAHL-2026-01 |
| 55286 | ServerMania / B2 Net Solutions | Canada | Hosting | IRANIWISE-2026-01 |
| 263740 | Laceibanetsociety (LACNIC) | Honduras | Hosting/ISP | IRANIWISE-2026-01 |
| 203020 | Hostroyale Technologies | US | Hosting | DAHL-2026-03 |
| 36352 | HostPapa Inc | US | Hosting | DAHL-2026-03 |
| 397423 | H4Y Technologies LLC | US | Hosting | DAHL-2026-03 |
| 18779 | EGIHosting (alt ASN) | US | Hosting | WVH-2026-03 |
| 396073 | Majestic Hosting Solutions | US | Hosting | DAHL-2026-03 |
| 215413 | PebbleHost Ltd | UK | Hosting | DAHL-2026-03 |
| 21859 | Zenlayer Inc | US | CDN/Hosting | DAHL-2026-03 |
| 51167 | Contabo GmbH | Germany | Cloud hosting | PCO-2026-03 |
| 213230 | Hetzner Cloud (alt ASN) | Germany/US | Cloud hosting | IRANIWISE-2026-02 |
| 6461 | Zayo Group (Ukrainian alloc) | US/UA | Transit (verify IP) | IRANIWISE-2026-02 |
| 13335 | Cloudflare Inc | US | CDN/Proxy | General |
| 8075 | Microsoft Azure | Global | Cloud (context-dependent) | General |
| 15169 | Google LLC | US | Cloud (context-dependent) | General |

### Notes on Context-Dependent ASNs
- **8075 (Microsoft Azure)**: Legitimate for MigrationWiz, Office 365, Azure AD. Attack when used for credential stuffing.
- **15169 (Google)**: Legitimate for Google Workspace internal delivery. Attack when used as proxy.
- **13335 (Cloudflare)**: **IMPORTANT — Dual-use ASN.** Cloudflare WARP is a legitimate staff VPN used by multiple ICCI clients (Dahlmann, Phoenix Co, ICCI). When a user consistently logs in via WARP with valid MFA (passkey, authenticator, device prompt), reclassify as LEGITIMATE. Flag for manual review when: (a) it's a new user on WARP, (b) MFA was not used, or (c) the login pattern is inconsistent with the user's history. Never auto-classify WARP logins as attacks.
- **22616 (Zscaler Inc)**: Corporate security gateway. Legitimate when used by IT vendors or managed service providers (e.g., EnTech IT at Dahlmann uses Zscaler). The login will show Google Authenticator or other MFA. IPs typically in 104.129.x.x, 136.226.x.x, 165.225.x.x ranges.
- **16509 (AWS)**: Legitimate for business SaaS apps and client-owned infrastructure (e.g., ICCI uses AWS us-east-2 for servers). Attack when used for credential stuffing bots. Always check if the specific IP belongs to the client before classifying.
- **14618 (AWS us-east-1)**: Alternate AWS ASN. Same rules as 16509 — verify if client-owned.
- **6461 (Zayo Group)**: Legitimate for US business fiber transit. However, specific IP allocations within Zayo's transit range (e.g., 193.34.72.0/22) are assigned to organizations in Ukraine and other countries. Always WHOIS the specific IP, not just the ASN.
- **3257 (GTT Communications / Telia)**: Transit provider. Some IP allocations (e.g., 45.86.18.x, 45.86.19.x) are suballocated to hosting providers like Hostroyale. Always WHOIS the specific IP.
- **54113 (Fastly Inc)**: CDN. Usually legitimate for websites using Fastly. Suspicious if appearing in login events without clear CDN/proxy explanation.

**Decision rule:** If the ASN is context-dependent, check the specific IP's reverse DNS and the event type. Inbound mail delivery from Google IPs is normal. Login attempts from Google Cloud Compute IPs are suspicious. For Cloudflare WARP, check the user's MFA method and login pattern before classifying.

---

## Legitimate ASNs (Residential ISP / Cellular / Business)

Events from these ASNs are classified as legitimate property/staff traffic. Failed logins from these ASNs are genuine user errors (mistyped password, expired session), NOT attacks.

### Common US Residential ISPs
| ASN | Provider | Notes |
|---|---|---|
| 7922 | Comcast Cable | Major residential ISP, nationwide |
| 209 | CenturyLink / Lumen | Residential + business, nationwide |
| 33668 | Spectrum / Charter | Major residential ISP, nationwide |
| 20115 | Charter Communications | Residential variant |
| 10796 | Spectrum (TWC legacy) | Time Warner Cable legacy |
| 11351 | RR / TWC (Road Runner) | Legacy cable ISP |
| 22773 | Cox Communications | Residential, southeast US |
| 701 | Verizon Business (MCI) | Business fiber |
| 6389 | BellSouth / AT&T | Residential DSL, southeast |
| 46690 | SNET America (Southern New England Telephone) | Residential, Connecticut | TAMUL-2026-03 |
| 20001 | TWC / Spectrum (alt) | Legacy cable |
| 11426 | TWC / Spectrum (alt) | Legacy cable |
| 5650 | Frontier Communications | Residential, rural areas |
| 7843 | TWC / Spectrum (alt) | Legacy cable |

### US Cellular Providers
| ASN | Provider | Notes |
|---|---|---|
| 6167 | Verizon Wireless | Major cellular, IPv6 prefix: 2600:1006: |
| 7018 | AT&T Wireless | Major cellular |
| 21928 | T-Mobile US | Major cellular |
| 22394 | Verizon Wireless (alt) | Alternate range |
| 7065 | AT&T (alt) | Alternate range |

### US Fixed Wireless / Home Internet / Satellite
| ASN | Provider | Notes |
|---|---|---|
| 17133 | T-Mobile USA (T-Fiber) | Fixed wireless home internet | ICCI-2026-03 |
| 12083 | WideOpenWest (WOW!) | Regional residential ISP (Midwest) | ICCI-2026-03 |
| 6167 | WOW/Wideopenwest (alt) | Midwest regional cable ISP | PCO-2026-03 |
| 14593 | SpaceX Starlink | Satellite internet — residential, legitimate | DAHL-2026-03 |
| 40306 | ViaSat / Exede | Satellite internet — residential, legitimate | DAHL-2026-03 |
| 46293 | Midwest Energy & Communications | Michigan rural ISP / fiber | PCO-2026-03 |
| 63251 | Metro Wireless Inc | Michigan fixed wireless ISP | PCO-2026-03 |

### Additional US Residential ISP Variants
| ASN | Provider | Notes |
|---|---|---|
| 33661 | Comcast Cable (IPv4 variant) | Alternate Comcast ASN | DAHL-2026-03 |
| 33652 | Comcast Cable (IPv6 variant) | Alternate Comcast ASN | DAHL-2026-03 |
| 20214 | Comcast Cable (IPv6 variant) | Alternate Comcast ASN (Florida) | IRANIWISE-2026-02 |
| 11427 | Charter/Spectrum (IPv6) | Alternate Spectrum ASN | DAHL-2026-03 |
| 33363 | Charter/BHN (residential) | Bright House Networks legacy | PCO-2026-03 |
| 2379 | CenturyLink (Embarq legacy) | Legacy Embarq/Sprint ISP | DAHL-2026-03 |
| 11404 | Spectrum Networks (Aviation RE) | Spectrum business variant | IRANIWISE-2026-01 |

### US Cellular Providers (Additional)
| ASN | Provider | Notes |
|---|---|---|
| 20057 | AT&T Enterprises (IPv6) | AT&T variant ASN | DAHL-2026-03 |

### Business / Office ISPs
| ASN | Provider | Notes |
|---|---|---|
| 3356 | Level3 / Lumen | Business transit |
| 2914 | NTT Communications | Business transit |
| 6461 | Zayo Group | Business fiber (verify specific IPs — some suballocations are attack infra) |
| 12129 | 123.Net, Inc. | Michigan business fiber ISP | ICCI-2026-03 |
| 174 | Cogent Communications | Business transit (also appears in attacks -- verify context) |
| 36375 | Merit Network Inc | Michigan university/research network | DAHL-2026-03 |
| 2553 | Florida State University | University network | DAHL-2026-03 |

### International Residential ISPs (Staff Travel)
| ASN | Provider | Country | Notes |
|---|---|---|---|
| 2856 | BT Group plc | UK | British Telecom residential broadband | DAHL-2026-03 |
| 15146 | Cable Bahamas Ltd | Bahamas | Caribbean residential ISP | DAHL-2026-03 |
| 3462 | Chunghwa Telecom (HiNet) | Taiwan | Largest Taiwan ISP — verify with user if unexpected | IRANIWISE-2026-02 |
| 3826 | Hilton Worldwide | US/Global | Hotel chain network — staff travel | DAHL-2026-03 |

### Managed Services / IT Vendor ASNs
| ASN | Provider | Notes |
|---|---|---|
| 62728 | Velocity MSP | Managed services company | DAHL-2026-03 |
| 22616 | Zscaler Inc | Corporate security gateway — verify IT vendor context | DAHL-2026-03 |

---

## WHOIS Lookup Procedure

When encountering an unknown IP/ASN:

### Quick Lookup
```bash
whois {IP} 2>/dev/null | grep -iE 'OrgName|NetName|CIDR|Country|descr|netname' | head -10
```

### Classification Decision Tree
1. **OrgName contains residential ISP name** (Comcast, Charter, CenturyLink, Cox, etc.) → LEGITIMATE
2. **OrgName contains cellular provider** (Verizon Wireless, AT&T Wireless, T-Mobile) → LEGITIMATE
3. **OrgName contains "hosting", "cloud", "server", "VPN", "data center"** → ATTACK
4. **Country is not US/CA** and **OrgName is a hosting provider** → ATTACK (high confidence)
5. **Country is not US/CA** and **OrgName is a residential ISP** → LEGITIMATE (staff traveling or VPN)
6. **Unknown** → Check reverse DNS. If rDNS shows a hostname with "host", "vps", "cloud", "server" → ATTACK

### Adding New ASNs
After classification, add to the appropriate section above with:
- ASN number
- Provider name (from WHOIS OrgName)
- Country
- Type (residential, cellular, business, hosting, VPN, cloud)
- First Seen (engagement reference, e.g., `DAHL-2026-01`)

---

## Client-Specific Legitimate ASNs

Each engagement may have property-specific ISPs. Document them here during the engagement and archive them after.

### Template
```
## {CLIENT NAME} — Legitimate Property ASNs
| ASN | Provider | Property/Location |
|---|---|---|
| XXXXX | {ISP} | {Property name / address} |
```

### Dahlmann Group (DAHL-2026-01 → DAHL-2026-03)
| ASN | Provider | Property/Location |
|---|---|---|
| 7922/33661/33652 | Comcast | Sanibel Inn, Bell Tower Hotel, staff homes |
| 209/2379 | CenturyLink/Lumen/Embarq | Sanibel Inn, DDP offices |
| 33668/11427/33363 | Spectrum/Charter | Bell Tower Hotel, Ann Arbor Regent, staff homes |
| 12129 | 123.Net | Dahlmann office fiber (207.91.x.x) |
| 6167 | Verizon Wireless | Staff cellular (IPv6: 2600:1006:*) |
| 7018/20057 | AT&T | Staff cellular |
| 22773 | Cox Communications | Staff home (Atlanta area) |
| 20115 | Charter residential | Staff home |
| 14593 | SpaceX Starlink | Staff satellite internet |
| 40306 | ViaSat | Staff satellite internet |
| 15146 | Cable Bahamas | Sanibel staff/guests |
| 13335 | Cloudflare WARP | Staff VPN (ben@, smilne@, vbruno@, sales@, trios@, eburrell@) |
| 22616 | Zscaler | EnTech IT vendor |
| 3826 | Hilton Worldwide | Staff travel |
| 62728 | Velocity MSP | Managed services |
| 2856 | BT Broadband | UK staff travel |
| 2553 | Florida State University | University network |
| 36375 | Merit Network | Michigan university |

### WVH Cares (WVH-2026-03)
| ASN | Provider | Property/Location |
|---|---|---|
| 33668 | Comcast Cable | Office/clinic (68.61.136.211 + IPv6 2603:3015:*) |
| 7018 | AT&T Services | wvhadmin (ICCI admin), ceberly_isretired |
| 16509 | Amazon AWS | ICCI infrastructure (18.223.233.22 wvhadmin) |

### Phoenix Co (PCO-2026-03)
| ASN | Provider | Property/Location |
|---|---|---|
| 63251 | Metro Wireless | Primary office ISP (Michigan) |
| 33668 | Spectrum/Charter | Staff home internet |
| 6167 | WOW/Wideopenwest | Staff home internet |
| 13335 | Cloudflare WARP | Staff VPN (jhiser@, ndhiser@) |
| 20115/33363 | Charter/BHN | Staff home/mobile |
| 46293 | Midwest Energy & Comms | Staff home (Michigan rural) |
| 7018 | AT&T | Staff cellular + ICCI admin |
| 14593 | SpaceX Starlink | Staff satellite internet |
| 12129 | 123.Net | Staff (single event) |

### ICCI LLC (ICCI-2026-03)
| ASN | Provider | Property/Location |
|---|---|---|
| 7018 | AT&T | ICCI office (107.210.140.42), staff cellular |
| 33668 | Spectrum/Charter | Staff home ISPs (Michigan) |
| 12129 | 123.Net | ICCI office fiber (207.91.193.x) |
| 12083 | WideOpenWest (WOW!) | bgeng home (50.4.x.x) |
| 17133 | T-Mobile T-Fiber | boxford home (64.13.x.x) |
| 22773 | Cox Communications | boxford travel (Arizona) |
| 6167 | Verizon Wireless | Staff cellular |
| 20115 | Charter residential | Staff home |
| 20001 | Spectrum/TWC legacy | Staff home/travel |
| 16509 | AWS us-east-2 | ICCI infrastructure (18.223.233.22) |
| 14618 | AWS us-east-1 | ICCI service (52.70.167.83) |
| 13335 | Cloudflare WARP | Staff VPN |

### Tamulevich (TAMUL-2026-03)
| ASN | Provider | Property/Location |
|---|---|---|
| 33668 | Charter/Spectrum | David home (Michigan), IPv6: 2601:401:100:5cd0:* |
| 7018 | AT&T | David travel (Colorado), Janet home/travel (MI, AZ), IPv6: 2600:381:*, 2600:387:* |
| 46690 | SNET America | David travel (Connecticut), IPv4: 32.218.31.73 |
| 6389 | BellSouth/AT&T | David travel (Alabama), IPv4: 209.149.209.125 |

### Irani & Wise, PLC (IRANIWISE-2026-01 → IRANIWISE-2026-02)
| ASN | Provider | Property/Location |
|---|---|---|
| 33668 | Charter/Spectrum | Office ISP (Ann Arbor, MI) |
| 7018 | AT&T | Staff cellular/home (MI) |
| 6167 | Verizon Wireless | Staff cellular (MI) |
| 701 | Verizon Business (UUNET) | Annette Dentel (DC area) |
| 11426 | Charter/Spectrum (Carolinas) | Staff travel (KS) |
| 11404 | Aviation RE LLC (Spectrum Networks) | Christine Falinski (CA) |
| 20214 | Comcast Cable (IPv6) | Annette Dentel travel (FL, Nov 2025) |
| 3462 | Chunghwa Telecom (HiNet) | **ANOMALOUS** — Annette Dentel Taiwan login (Feb 19). Verify with user. |
