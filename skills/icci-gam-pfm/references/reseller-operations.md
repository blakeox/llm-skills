# Reseller Operations — GAM Reference

ICCI is a Google Workspace reseller (Customer ID: C03zbaxd2, Reseller ID: C03zbaxd2).

## Customer Discovery

```bash
# List all reseller customers
~/bin/gam7/gam print channelcustomers fields name,domain

# List all subscriptions
~/bin/gam7/gam print resoldsubscriptions todrive

# Subscriptions for specific customer
~/bin/gam7/gam print resoldsubscriptions customerid CUSTOMERID todrive

# Info on customer
~/bin/gam7/gam info resoldcustomer CUSTOMERID
```

## Customer Management

```bash
# Create new resold customer
gam create resoldcustomer newcustomer.com \
    email admin@newcustomer.com contact "John Doe" phone "555-1234" \
    name "New Customer Inc" address1 "123 Main St" city "Ann Arbor" \
    state MI postalcode 48104 country US

# Update customer info
gam update resoldcustomer CUSTOMERID contact "Jane Doe" phone "555-5678"
```

## Subscription Management

```bash
# Create subscription
gam create resoldsubscription CUSTOMERID sku 1010020020 plan flexible seats 25

# Update seats
gam update resoldsubscription CUSTOMERID 1010020020 seats 50

# Activate
gam update resoldsubscription CUSTOMERID 1010020020 activate

# Suspend
gam update resoldsubscription CUSTOMERID 1010020020 suspend

# Cancel
gam delete resoldsubscription CUSTOMERID 1010020020 cancel
```

## Important Notes

- The reseller API is for **billing/subscription** operations only
- For **admin data** (users, groups, reports, etc.), use per-domain sections with the Directory/Reports APIs
- DwD must be authorized separately for each customer domain
- The shared `oauth2.txt` provides admin access to all reseller customers via the reseller relationship
