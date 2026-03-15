# Contact Management Reference

## Searching Contacts

- `happyfox_contacts_search(q="search term", page=1, size=10)`
- Search is fuzzy/fulltext — does NOT match on email prefix reliably (see BUG-004)
- Returns: id, name, email, is_login_enabled, created_at, updated_at

## Creating Contacts

- `happyfox_contacts_create(email="user@domain.com", name="Full Name")`
- If contact already exists, it updates the existing record (acts like upsert)
- Optional: `phones` (array of {number, type, is_primary}), `is_login_enabled` (bool), `custom_fields` (object)
- Phone types: "mo" (mobile), "w" (work), "m" (main), "h" (home), "o" (other)

## Known Contacts (ICCI clients with tickets)

Created/confirmed during 2026-03-10 session:

- ID 43: St. Joseph Parish IT Admin (stjosadmin@stjos.com)

## Contact Groups

Tools exist but are untested:

- `happyfox_contact_groups_list`
- `happyfox_contact_group_create`, `_update`, `_delete`
- `happyfox_contact_group_add_contacts`, `_remove_contacts`
- `happyfox_contact_group_manage`

## Best Practice

Since search is unreliable, prefer `happyfox_contact_upsert` when you need to ensure a contact exists before creating a ticket. This avoids the search-then-create race condition.
