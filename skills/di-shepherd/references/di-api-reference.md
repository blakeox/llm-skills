# Deep Instinct REST API Reference

## Authentication

All requests require the `Authorization` header with the API key value directly (no "Bearer" prefix):

```
Authorization: eyJhbGciOiJIUzI1NiIs...
```

**Permission levels** (ascending privilege):
1. `READ_ONLY` — list/search/get operations
2. `READ_AND_REMEDIATION` — read + isolate, close events, delete files, terminate processes
3. `FULL_ACCESS` — all above + create/modify/delete policies, groups, tenants
4. `ACCOUNT_ADMIN` — user management

ICCI's current key is **READ_AND_REMEDIATION** — sufficient for reporting and remediation but cannot modify policies or manage allow/deny lists.

## Base URL

```
https://msp360.customers.deepinstinctweb.com/api/v1/
```

Swagger UI: `https://msp360.customers.deepinstinctweb.com/api/v1/` (browser)
OpenAPI spec: `https://msp360.customers.deepinstinctweb.com/api/v1/swagger.json`

## Pagination

**Devices and Events**: Return **50 items per request** (hard limit, not configurable).

- **Devices**: Cursor-based via `after_device_id` query parameter. Set to the last device ID from the previous page. Loop until fewer than 50 results returned.
- **Events**: Cursor-based via `after_event_id` or `first_event_id`. Same pattern.
- **Users**: Offset-based with `offset` (default 0) and `size` (default 100).
- **Audit Logs**: Offset-based with `offset`, `size`, plus `from_timestamp`/`to_timestamp` (ISO 8601).

**Pagination helper pattern:**
```python
def paginate_devices(base_url, headers):
    devices = []
    after_id = None
    while True:
        params = {}
        if after_id:
            params['after_device_id'] = after_id
        resp = requests.get(f"{base_url}/devices/", headers=headers, params=params)
        resp.raise_for_status()
        batch = resp.json()
        if not batch:
            break
        devices.extend(batch)
        after_id = batch[-1]['id']
        if len(batch) < 50:
            break
    return devices
```

## Rate Limiting

No explicit rate limits documented. No `429` responses or `X-RateLimit-*` headers observed. Exercise reasonable pacing — add a small delay (0.2-0.5s) between paginated calls to be a good API citizen.

## Error Handling

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized (bad/expired API key, or feature not enabled) |
| 403 | Forbidden (insufficient permission level) |
| 404 | Resource not found |
| 422 | Unprocessable (e.g., trying to delete default policy/group) |
| 500 | Server error |

## Endpoints

### Health Check

```
GET /health_check
```
No auth required. Returns system health status.

---

### Devices (16 endpoints)

#### List Devices
```
GET /devices/
Query params: after_device_id (int, optional)
Returns: Array of device objects (max 50)
Permission: READ_ONLY
```

#### Search Devices
```
POST /devices/search
Body: JSON search/filter criteria
Returns: Array of matching device objects
Permission: READ_ONLY
```

#### Get Device
```
GET /devices/{device_id}
Returns: Single device object
Permission: READ_ONLY
```

**Device object fields:** `id`, `hostname`, `os_type`, `os_version`, `ip_address`, `mac_address`, `domain`, `connectivity_status` (ALIVE/EXPIRED), `deployment_status` (REGISTERED/ACTIVATED/etc), `group_id`, `group_name`, `policy_id`, `policy_name`, `tenant_id`, `tenant_name`, `agent_version`, `brain_version`, `last_contact`, `comment`, `tag`

#### Isolate Device from Network
```
POST /devices/actions/isolate-from-network
Body: {"ids": [device_id1, device_id2, ...]}
Permission: READ_AND_REMEDIATION
```
Bulk operation. Isolates devices at next check-in.

#### Release from Isolation
```
POST /devices/actions/release-from-isolation
Body: {"ids": [device_id1, device_id2, ...]}
Permission: READ_AND_REMEDIATION
```

#### Archive Devices
```
POST /devices/actions/archive
Body: {"ids": [device_id1, device_id2, ...]}
Permission: READ_AND_REMEDIATION
```

#### Unarchive Devices
```
POST /devices/actions/unarchive
Body: {"ids": [device_id1, device_id2, ...]}
Permission: READ_AND_REMEDIATION
```

#### Delete Remote Files
```
POST /devices/actions/delete-remote-files
Body: {"event_id": event_id}
Permission: READ_AND_REMEDIATION
```
Queues file deletion on the endpoint. Executes at next agent check-in.

#### Terminate Remote Process
```
POST /devices/actions/terminate-remote-process
Body: {"event_id": event_id}
Permission: READ_AND_REMEDIATION
```
Queues process termination. Executes at next agent check-in.

#### Request Remote File Upload
```
POST /devices/actions/request-remote-file-upload/{event_id}
Permission: READ_AND_REMEDIATION
```
Requests the agent to upload the file associated with the event for analysis.

#### Disable Device
```
POST /devices/{device_id}/actions/disable
Permission: READ_AND_REMEDIATION
```
Disables the DI agent on the device at next check-in.

#### Enable Device
```
POST /devices/{device_id}/actions/enable
Permission: READ_AND_REMEDIATION
```

#### Remove Device (Uninstall Agent)
```
POST /devices/{device_id}/actions/remove
Permission: READ_AND_REMEDIATION
```
Uninstalls the DI agent at next check-in. **Destructive — requires strong justification.**

#### Upload Device Logs
```
POST /devices/{device_id}/actions/upload-logs
Permission: READ_AND_REMEDIATION
```
Requests the agent to upload diagnostic logs.

#### Update Device Comment
```
PUT /devices/{device_id}/comment
Body: {"comment": "text"}
Permission: READ_AND_REMEDIATION
```

#### Update Device Tag
```
PATCH /devices/{device_id}/tag
Body: {"tag": "text"}
Permission: READ_AND_REMEDIATION
```

---

### Events (10 endpoints)

#### List Events
```
GET /events/
Query params: after_event_id (int, optional)
Returns: Array of event objects (max 50)
Permission: READ_ONLY
```

#### Search Events
```
POST /events/search
Body: JSON search criteria (flexible filters)
Returns: Array of matching events
Permission: READ_ONLY
```
**This is the most powerful query endpoint.** Supports filtering by status, type, severity, action, device, tenant, time range, and more.

#### Get Event
```
GET /events/{event_id}
Returns: Single event object
Permission: READ_ONLY
```

#### Get File Details by Hash
```
GET /events/file/{file_hash}
Returns: File analysis details
Permission: READ_ONLY
```

#### Download Uploaded File
```
GET /events/actions/download-uploaded-file/{file_hash}
Returns: Binary file content
Permission: READ_AND_REMEDIATION
```

#### Close Events (Bulk)
```
POST /events/actions/close
Body: {"ids": [event_id1, event_id2, ...]}
Permission: READ_AND_REMEDIATION
```

#### Close All Events for Hash
```
POST /events/actions/close/{file_hash}
Permission: READ_AND_REMEDIATION
```
Closes all events associated with a specific file hash.

#### Open Events (Bulk)
```
POST /events/actions/open
Body: {"ids": [event_id1, event_id2, ...]}
Permission: READ_AND_REMEDIATION
```

#### Archive Events (Bulk)
```
POST /events/actions/archive
Body: {"ids": [event_id1, event_id2, ...]}
Permission: READ_AND_REMEDIATION
```

#### Unarchive Events (Bulk)
```
POST /events/actions/unarchive
Body: {"ids": [event_id1, event_id2, ...]}
Permission: READ_AND_REMEDIATION
```

**Event object fields:** `id`, `file_hash`, `file_size`, `file_type`, `threat_severity` (VERY_HIGH/HIGH/MEDIUM_HIGH/MEDIUM_LOW/LOW/VERY_LOW), `action` (PREVENTED/DETECTED), `status` (OPEN/CLOSED), `type` (STATIC_ANALYSIS/BEHAVIORAL_ANALYSIS/etc), `sandbox_status`, `mitre_classifications`, `device_id`, `device_hostname`, `device_os`, `tenant_id`, `tenant_name`, `timestamp`, `reoccurrence_count`, `file_path`, `process_name`

---

### Suspicious Events (7 endpoints)

**Note:** Returns 401 if the suspicious events feature is not enabled on your tenant/license. Handle gracefully.

#### List Suspicious Events
```
GET /suspicious-events/
Permission: READ_ONLY
```

#### List Archived Suspicious Events
```
GET /suspicious-events/archive
Permission: READ_ONLY
```

#### Search Suspicious Events
```
POST /suspicious-events/search
Body: JSON search criteria
Permission: READ_ONLY
```

#### Get Suspicious Event
```
GET /suspicious-events/{event_id}
Permission: READ_ONLY
```

#### Archive Suspicious Events
```
POST /suspicious-events/actions/archive
Body: {"ids": [...]}
Permission: READ_AND_REMEDIATION
```

#### Close Suspicious Events
```
POST /suspicious-events/actions/close
Body: {"ids": [...]}
Permission: READ_AND_REMEDIATION
```

#### Unarchive Suspicious Events
```
POST /suspicious-events/actions/unarchive
Body: {"ids": [...]}
Permission: READ_AND_REMEDIATION
```

---

### Policies (READ_ONLY access only with our key)

#### List Policies
```
GET /policies/
Returns: Array of policy objects
Permission: READ_ONLY
```

#### Get Policy
```
GET /policies/{policy_id}
Returns: Single policy object
Permission: READ_ONLY
```

#### Get Policy Data
```
GET /policies/{policy_id}/data
Returns: Platform-specific policy configuration
Permission: READ_ONLY
```
Policy data is polymorphic by platform: WindowsPolicyData, MacOSPolicyData, LinuxPolicyData, AndroidPolicyData, IOSPolicyData, ChromeOSPolicyData, etc.

#### Allow/Deny List Reading (READ_ONLY)
```
GET /policies/{policy_id}/allow-list/hashes
GET /policies/{policy_id}/allow-list/certificates
GET /policies/{policy_id}/allow-list/paths
GET /policies/{policy_id}/allow-list/process_paths
GET /policies/{policy_id}/allow-list/scripts
GET /policies/{policy_id}/deny-list/hashes
GET /policies/{policy_id}/exclusion-list/folder_path
GET /policies/{policy_id}/exclusion-list/process_path
```

**Modifying allow/deny lists requires FULL_ACCESS** — not available with our current key.

---

### Groups (READ_ONLY access only with our key)

#### List Groups
```
GET /groups/
Returns: Array of group objects
Permission: READ_ONLY
```

#### Get Group
```
GET /groups/{group_id}
Returns: Single group object
Permission: READ_ONLY
```

**Creating/modifying groups and moving devices between groups requires FULL_ACCESS.**

---

### Multitenancy / MSP

#### List MSPs
```
GET /multitenancy/msp/
Permission: READ_ONLY
```

#### List Tenants
```
GET /multitenancy/tenant/
Permission: READ_ONLY
```

#### Get Tenant
```
GET /multitenancy/tenant/{tenant_id}
Permission: READ_ONLY
```

---

### Deployment

#### List Agent Versions
```
GET /deployment/agent-versions
Permission: READ_ONLY
```

#### List Deployment Tokens
```
GET /deployment/token
Permission: READ_ONLY
```

#### Get Tokens for Tenant
```
GET /deployment/token/{tenant_id}
Permission: READ_ONLY
```

---

### Audit Logs

```
GET /audit_logs/
Query params: offset (default 0), size (default 100), from_timestamp, to_timestamp (ISO 8601)
Permission: READ_ONLY
```

---

## Key Gotchas

1. **No quarantine restore endpoint** — quarantine restore is GUI-only. The API can delete files and close events, but cannot restore quarantined files.
2. **50-item hard page size** — cannot be increased. Must paginate with cursors.
3. **Actions execute at next check-in** — device disable/enable/remove/file-delete/process-terminate are queued, not immediate.
4. **MSP vs Tenant connector scoping** — MSP connector sees all tenants. Tenant connector is scoped to selected tenants only.
5. **Cannot delete default policies or groups** — API returns 422.
6. **Cannot change policy platform** — once created for Windows, stays Windows. Returns 422 on attempt.
7. **Suspicious events feature flag** — `/suspicious-events/` returns 401 if not enabled on license.
8. **All responses are JSON** — except file downloads which are binary.
9. **Python wrapper is deprecated** — the `pvz01/deepinstinct-rest-api-wrapper` on GitHub is abandoned. Use direct API calls.
10. **Allow/deny list modification requires FULL_ACCESS** — our READ_AND_REMEDIATION key cannot modify these. If the user needs to add hashes to allow/deny lists, they must do it through the DI web console or request a FULL_ACCESS key.
