# Team Setup — GAM on ICCI Team Computers

How to set up GAM on other ICCI team members' computers so they can manage client domains.

## Prerequisites

- macOS with Homebrew (or Linux/Windows equivalent)
- GitHub access to `icci/icci-skills` repo (MUST have access — skill won't work without it)
- 1Password for SSH keys (ICCI standard)

## Install GAM7

```bash
# Install via the official installer
bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l ~/bin/gam7
```

Follow the prompts. This creates `~/bin/gam7/gam` and `~/.gam/`.

## Copy Shared Configuration

### 1. Copy gam.cfg
Copy the master `~/.gam/gam.cfg` from Aaron's machine (or from the skills repo). This has all domain sections.

### 2. Copy Service Account Key
Copy `~/.gam/oauth2service.json` — this is the GCP service account key shared across all ICCI team members. Same key works for all domains.

### 3. Copy client_secrets.json
Copy `~/.gam/client_secrets.json` — the OAuth client configuration.

## Credential Distribution

### Reseller Domains (icci.com and all 24 reseller customers)
Each team member needs their OWN `oauth2.txt` — they must authenticate with their own `@icci.com` admin account:

```bash
~/bin/gam7/gam oauth create
# Press 'c' to continue with default scopes
# Sign in with their @icci.com account in the browser
```

This creates `~/.gam/oauth2.txt` tied to their ICCI admin identity. The reseller relationship means this one token gives admin access to all 24 reseller customer domains.

### Non-Profit / School Domains (separate OAuth tokens)
These tokens are NOT tied to a specific person — they authenticate as the domain's admin account. They CAN be copied directly:

```bash
# Copy from the skills repo credentials/ directory:
cp ~/Documents/GitHub/icci-skills/skills/icci-gam-pfm/credentials/oauth2_stpatschool.txt ~/.gam/
cp ~/Documents/GitHub/icci-skills/skills/icci-gam-pfm/credentials/oauth2_stpaul.txt ~/.gam/
cp ~/Documents/GitHub/icci-skills/skills/icci-gam-pfm/credentials/oauth2_stmary.txt ~/.gam/
cp ~/Documents/GitHub/icci-skills/skills/icci-gam-pfm/credentials/oauth2_stjos.txt ~/.gam/
cp ~/Documents/GitHub/icci-skills/skills/icci-gam-pfm/credentials/oauth2_okf.txt ~/.gam/
```

These tokens authenticate as the respective domain admin accounts (stpatsadmin@, spaaadmin@, etc.) and work on any machine.

**Important:** If a non-profit token expires or needs refresh, re-run:
```bash
~/bin/gam7/gam select sectionname oauth create --no-browser
# Sign in as the domain's admin account in incognito
```
Then copy the new token back to the credentials/ directory and push to GitHub.

## Verify Setup

After setup, test each domain type:

```bash
# Test reseller domain (uses personal oauth2.txt)
~/bin/gam7/gam select icci info domain

# Test non-profit (uses copied token)
~/bin/gam7/gam select stpatschool info domain

# Test DwD service account
~/bin/gam7/gam select stpatschool user stpatsadmin@stpatschool.org check serviceaccount
```

## Summary: What's Shared vs Personal

| File | Shared? | Notes |
|------|---------|-------|
| `gam.cfg` | Yes | Same config for all team members |
| `oauth2service.json` | Yes | GCP service account key — same for everyone |
| `client_secrets.json` | Yes | OAuth client config — same for everyone |
| `oauth2.txt` | **NO** | Each person creates their own with their @icci.com account |
| `oauth2_stpatschool.txt` | Yes | Domain-specific token, copy from repo |
| `oauth2_stpaul.txt` | Yes | Domain-specific token, copy from repo |
| `oauth2_stmary.txt` | Yes | Domain-specific token, copy from repo |
| `oauth2_stjos.txt` | Yes | Domain-specific token, copy from repo |
| `oauth2_okf.txt` | Yes | Domain-specific token, copy from repo |

## Troubleshooting

### "Not Authorized" on reseller domain
→ Their `oauth2.txt` needs to be created with an @icci.com admin account that has reseller admin access.

### "Not Authorized" on non-profit domain
→ Check that the `oauth2_*.txt` file exists in `~/.gam/` and matches the filename in `gam.cfg`.

### "access_not_configured" during OAuth create
→ The domain's Admin Console needs to trust the GAM OAuth app. Add `246056598198-0bh476ht50qf4qm82jrl1b6c4ruhrn08.apps.googleusercontent.com` as a Trusted app in Security → API controls → App access control.

### DwD check fails
→ Authorize client ID `101167824996059402065` with the full scope string in the domain's Admin Console → Security → API controls → Domain-wide delegation.
