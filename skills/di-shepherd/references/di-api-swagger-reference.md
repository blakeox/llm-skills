# Deep Instinct REST API Reference

Generated from Swagger spec at `https://msp360.customers.deepinstinctweb.com/api/v1/swagger.json`  
Spec version: 1.0 | Generated: 2026-03-08

**Base URL:** `https://msp360.customers.deepinstinctweb.com/api/v1`

---

## Authentication

All endpoints require an `Authorization` header with a JWT token. **No `Bearer` prefix** -- just the raw token:

```
Authorization: eyJ0eXAiOiJKV1Qi...
```

Content-Type for all request bodies: `application/json`

## Permission Levels

| Level | Description |
|-------|-------------|
| `READ_ONLY` | Read data only |
| `READ_AND_REMEDIATION` | Read data + take remediation actions (close events, isolate devices, etc.) |
| `FULL_ACCESS` | Full read/write including policy and config changes |
| `ACCOUNT_ADMIN` | User management operations |

## Practical Notes (from experience)

- **Auth header**: Just the JWT directly, NO `Bearer` prefix
- **Events endpoint** returns `{"last_id": int, "events": [...]}` -- not a plain list
- **Devices endpoint** returns `{"last_id": int, "devices": [...]}` with same wrapper
- **Pagination**: devices use `after_device_id`, events use `after_event_id`, both return 50 per page
- **Policy data** is at `GET/PUT /policies/{id}/data` (separate from `GET /policies/{id}`)
- **PUT /policies/{id}/data** needs `{"data": {...}}` envelope, must include `model` field, must EXCLUDE password hash fields
- **Allow-list items** use `{"item": "value", "comment": "text"}` format
- **Bulk endpoints** use `{"items": [...]}` wrapper
- **DELETE allow-list hashes** can use single `/hashes/{hash}` or bulk `/hashes` with `{"items": [...]}`
- **POST /events/actions/close** uses `{"ids": [...]}` (plural `ids`, not `id`)
- **POST /devices/actions/delete-remote-files** uses `{"ids": [...]}` with event IDs
- **POST /policies/** requires `base_policy_id` to clone from

## Table of Contents

**Endpoints:**
- [default](#default) (1 endpoints)
- [Multitenancy](#multitenancy) (9 endpoints)
- [Device groups](#device-groups) (8 endpoints)
- [Policies](#policies) (50 endpoints)
- [Devices](#devices) (16 endpoints)
- [Events](#events) (10 endpoints)
- [Suspicious Events](#suspicious-events) (7 endpoints)
- [Device Deployment](#device-deployment) (8 endpoints)
- [User](#user) (5 endpoints)
- [Audit Logs](#audit-logs) (1 endpoints)
- [API Connectors](#api-connectors) (2 endpoints)

**Schemas:**
- [Key Object Models](#key-object-models) (Device, Event, SuspiciousEvent)
- [Policy Data Models](#policy-data-models) (Windows, Mac, Linux, Android, iOS, Chrome, etc.)
- [Request/Response Models](#requestresponse-models)
- [Search Filter Models](#search-filter-models)
- [List/Envelope Models](#listenvelope-models)
- [Other Models](#other-models)

---

## default

### `GET /health_check`

**Responses:**

- `200`: Success

---

## Multitenancy

### `GET /multitenancy/msp/`

**Get MSPs according to API key permissions**

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of MSPs -- returns `MSPListModel`

---

### `POST /multitenancy/msp/`

**Create MSP**

Permission: Requires FULL_ACCESS permission

**Body schema:** `MSPCreationModel`

| Field | Type | Description |
|-------|------|-------------|
| `disable_password` | string |  |
| `license_limit` | integer | Maximum number of license for this MSP |
| `name` | string | Name of the MSP |
| `uninstall_password` | string |  |

**Responses:**

- `200`: MSP object -- returns `MSPModel`
- `400`: Number exceeds available licenses or is less than 1 / Password should be of length 8-35 / Password must contain at least one capital letter and one lower letter / Password must contain at least one digit / Password must contain at least one special character / msp name is of invalid length
- `401`: Unauthorized
- `409`: MSP name already exists

---

### `DELETE /multitenancy/msp/{msp_id}`

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `msp_id` (integer)

**Responses:**

- `204`: MSP deleted
- `403`: Only Hub-Admin can delete MSPs
- `404`: MSP not found
- `409`: Tried to delete a MSP but active devices still exist!

---

### `PUT /multitenancy/msp/{msp_id}`

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `msp_id` (integer)

**Body schema:** `MSPUpdateModel`

| Field | Type | Description |
|-------|------|-------------|
| `license_limit` | integer | Maximum number of license for this MSP |
| `name` | string | Name of the MSP |

**Responses:**

- `200`: MSP object -- returns `MSPModel`
- `204`: MSP updated
- `400`: License_limit must be greater than 1 and can not exceed available licenses or can only decrease msp license limit if there are enough not attached licenses or msp_name is of invalid length
- `403`: Only Hub-Admin can update MSPs
- `404`: MSP not found
- `409`: MSP name already exists

---

### `GET /multitenancy/msp/{msp_id}/tenants`

**Get 50 tenants, starting from id <after_tenant_id> (default is 0)**

Permission: Requires at least READ_ONLY permission

Notice: after_tenant_id param is not visible via Swagger

**Path parameters:**

- `msp_id` (integer)

**Responses:**

- `200`: List of Tenants -- returns `TenantListModel`
- `401`: msp_id not found
- `403`: Only hub admin is permitted to use this request

---

### `GET /multitenancy/tenant/`

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of Tenants -- returns `TenantListModel`

---

### `POST /multitenancy/tenant/`

**Create tenant**

Permission: Requires FULL_ACCESS permission

**Body schema:** `TenantCreationModel`

| Field | Type | Description |
|-------|------|-------------|
| `license_limit` | integer | Maximum number of license for this Tenant |
| `msp_id` | integer | ID of the MSP this Tenant belongs to |
| `name` | string | Name of the Tenant |

**Responses:**

- `200`: Tenant object -- returns `TenantCreationModel`
- `400`: License_limit must be greater than 1 and can not exceed available licenses or tenant_name is of invalid length
- `401`: Unauthorized
- `404`: Unauthorized
- `409`: msp ID not found or tenant name does not exist

---

### `GET /multitenancy/tenant/{tenant_id}`

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `tenant_id` (integer)

**Responses:**

- `200`: Tenant -- returns `TenantModel`
- `403`: No permissions to view tenant
- `404`: Tenant not found

---

### `PUT /multitenancy/tenant/{tenant_id}`

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `tenant_id` (integer)

**Body schema:** `TenantUpdateModel`

| Field | Type | Description |
|-------|------|-------------|
| `license_limit` | integer | Maximum number of license for this Tenant |
| `name` | string | Name of the Tenant |

**Responses:**

- `200`: Tenant object -- returns `TenantUpdateModel`
- `204`: Tenant updated!
- `400`: License_limit must be greater than 1 and can not exceed available licenses and must be at least the number of currently attached devices or tenant name is of invalid length
- `403`: No permissions to edit tenant
- `404`: Tenant not found
- `409`: Tenant name already exists

---

## Device groups

### `GET /groups/`

**Get all groups**

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of groups -- returns array of `DeviceGroupCreation`

---

### `POST /groups/`

**Create a group**

Permission: Requires FULL_ACCESS permission

**Body schema:** `DeviceGroupCreationModel`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for the group. |
| `msp_id` | integer | MSP ID to which this group belongs to. Ignored if not used by a multitenancy hub API connector. |
| `name` * | string | Name of the group |
| `policy_id` * | integer | Policy in use by this group. |
| `rules` | array\<object\> |  |

\* = required field

**Responses:**

- `200`: Group created -- returns `DeviceGroupCreation`
- `400`: rules are not well formatted / ruleTypeRef or ruleType is not presented / Empty Rule
- `404`: Policy ID is not found / one of the rules requiring entities such as Tenant, Domain or OU refer to non-existing entities
- `409`: Group name already exists
- `422`: The length must be between 3 and 35 characters

---

### `DELETE /groups/{group_id}`

**Delete group**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `group_id` (integer)

**Responses:**

- `204`: Group deleted
- `404`: Group not found
- `422`: Default group can not be removed

---

### `GET /groups/{group_id}`

**Get group by ID**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `group_id` (integer)

**Responses:**

- `200`: Device group -- returns `DeviceGroupCreation`
- `404`: Device group not found

---

### `PUT /groups/{group_id}`

**Update group by ID**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `group_id` (integer)

**Body schema:** `DeviceGroupEditModel`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for the group. |
| `name` | string | Name of the group |
| `policy_id` | integer | Policy in use by this group. |
| `priority` | integer | Group's priority used in rule calculation. |

**Responses:**

- `204`: Group updated
- `400`: rules are not well formatted / ruleTypeRef or ruleType is not presented / Empty Rule
- `404`: Device group not found / one of the rules requiring entities such as Tenant, Domain or OU refer to non-existing entities
- `409`: Group name already exists
- `422`: New policy_id must match the os of the group / Default groups cannot be changed / Invalid priority, value should be a positive number / Invalid priority, value maximum size can be total number of device groups

---

### `POST /groups/{group_id}/add-devices`

**Add devices to a group**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `group_id` (integer)

**Body schema:** `DeviceGroupDeviceList`

| Field | Type | Description |
|-------|------|-------------|
| `devices` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Group updated
- `404`: Device group not found

---

### `POST /groups/{group_id}/remove-devices`

**Remove devices from a group**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `group_id` (integer)

**Body schema:** `DeviceGroupDeviceList`

| Field | Type | Description |
|-------|------|-------------|
| `devices` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Group updated
- `404`: Device group not found

---

### `PUT /groups/{group_id}/rules`

**Update group rules by ID**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `group_id` (integer)

**Body schema:** `DeviceGroupRulesEdit`

| Field | Type | Description |
|-------|------|-------------|
| `rules` * | array\<object\> |  |

\* = required field

**Responses:**

- `204`: Group updated
- `400`: rules are not well formatted / ruleTypeRef or ruleType is not presented / Empty Rule
- `404`: Device group not found / one of the rules requiring entities such as Tenant, Domain or OU refer to non-existing entities
- `409`: One of the rules already exist
- `422`: Default groups cannot be changed

---

## Policies

### `GET /policies/`

**Get all policies**

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of policies -- returns array of `PolicyReadModel`

---

### `POST /policies/`

**Create a policy**

Permission: Requires FULL_ACCESS permission

**Body schema:** `PolicyCreateRequest`

Extends: `Policy`

| Field | Type | Description |
|-------|------|-------------|
| `base_policy_id` | integer | Policy ID on which to base this policy. |

**Responses:**

- `200`: Policy created -- returns `PolicyReadModel`
- `404`: Base policy or msp_id not found
- `409`: Policy name already exists
- `422`: The length must be between 3 and 35 characters

---

### `DELETE /policies/{policy_id}`

**Delete policy by ID**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `204`: Policy deleted
- `404`: Policy not found
- `422`: Default policies cannot be deleted

---

### `GET /policies/{policy_id}`

**Get policy by ID**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: Policy -- returns `PolicyReadModel`
- `404`: Device policy not found

---

### `PUT /policies/{policy_id}`

**Update policy base details by ID**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `Policy`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for this policy |
| `name` * | string | Policy name |

\* = required field

**Responses:**

- `200`: Success -- returns `PolicyReadModel`
- `204`: Policy updated
- `404`: Device policy not found
- `422`: Platform can not be changed for an existing policy

---

### `DELETE /policies/{policy_id}/allow-list/advanced_behavioral_analysis`

**Bulk remove advanced behavioral analysis processes from this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListIdItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`IdItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `GET /policies/{policy_id}/allow-list/advanced_behavioral_analysis`

**Fetch all advanced behavioral analysis processes in allow list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list items -- returns array of `ListItemAdvancedBehavioralAnalysisDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/advanced_behavioral_analysis`

**Bulk add advanced behavioral analysis process to given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemAdvancedBehavioralAnalysisDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemAdvancedBehavioralAnalysisDataModel`\> |  |

\* = required field

**Responses:**

- `200`: Ids of created items -- returns array of `ListIdItem`
- `400`: Bad request/Validation failed
- `404`: Device Policy not found

---

### `DELETE /policies/{policy_id}/allow-list/certificates`

**Bulk remove certificate thumbprints from this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `GET /policies/{policy_id}/allow-list/certificates`

**Fetch all certificates in allow list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list items -- returns array of `ListItemStringTestDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/certificates`

**Bulk add certificate thumbprints from this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemStringTestDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found
- `422`: Thumbprint is invalid

---

### `DELETE /policies/{policy_id}/allow-list/certificates/{thumbprint}`

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `thumbprint` (string)

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/certificates/{thumbprint}`

**Add a certificate thumbprint to this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `thumbprint` (string)

**Body schema:** `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found
- `422`: Thumbprint is invalid

---

### `DELETE /policies/{policy_id}/allow-list/hashes`

**Bulk remove file hashes from this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `GET /policies/{policy_id}/allow-list/hashes`

**Fetch the entire allow list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list items -- returns array of `ListItemStringTestDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/hashes`

**Bulk add file hashes to this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemStringTestDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found
- `422`: File hash is invalid

---

### `DELETE /policies/{policy_id}/allow-list/hashes/{file_hash}`

**Remove a file hash from this policy's allow list**

Permission: Requires FULL_ACCESS permission

Supports use cases:
    1. When there is more than one file hash allow list with the same file hash, different file type, different policy.
    2. When there is more than one file hash allow list with the same file hash, different file type, same policy.

**Path parameters:**

- `policy_id` (integer)
- `file_hash` (string)

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `POST /policies/{policy_id}/allow-list/hashes/{file_hash}`

**Add a file hash to this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `file_hash` (string)

**Body schema:** `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found
- `422`: File hash is invalid

---

### `DELETE /policies/{policy_id}/allow-list/paths`

**Bulk remove directory paths from this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `GET /policies/{policy_id}/allow-list/paths`

**Fetch the entire path allow list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list path items -- returns array of `ListItemStringTestDataModel`
- `204`: Policy updated
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/paths`

**Bulk add directory paths to this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemStringTestDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/allow-list/paths/{file_path}`

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `file_path` (string)

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/paths/{file_path}`

**Add a file_path to this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `file_path` (string)

**Body schema:** `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/allow-list/process_paths`

**Bulk remove behavioral analysis processes from this policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `GET /policies/{policy_id}/allow-list/process_paths`

**Fetch all behavioral analysis processes in allow list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list items -- returns array of `ListItemBehavioralAnalysisDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/process_paths`

**Bulk add behavioral analysis process to given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemBehavioralAnalysisDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemBehavioralAnalysisDataModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/allow-list/process_paths/{process_path}`

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `process_path` (string)

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `POST /policies/{policy_id}/allow-list/process_paths/{process_path}`

**Add a process of behavioral analysis  to the given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `process_path` (string)

**Body schema:** `ItemBehavioralAnalysisData`

| Field | Type | Description |
|-------|------|-------------|
| `behavior_ids` | array\<integer\> |  |
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/allow-list/scripts`

**Bulk remove script paths or script commands from the given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemDeleteScriptDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemScriptDataModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `GET /policies/{policy_id}/allow-list/scripts`

**Fetch all the scripts of the given policy’s allow list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list script items -- returns array of `ListItemScriptDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/allow-list/scripts`

**Bulk add script paths or script commands to the given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemScriptDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemScriptDataModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `400`: Script allow list is invalid for this OS type / Item data contains invalid fields
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/allow-list/scripts/{script_item}`

**Remove a script path or script command from the given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `script_item` (string)

**Body schema:** `DeleteScriptDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | item's type (path or command)[default - PATH]. Enum: `PATH`, `COMMAND` |

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `POST /policies/{policy_id}/allow-list/scripts/{script_item}`

**Add a script path or script command to the given policy's allow list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `script_item` (string)

**Body schema:** `ScriptDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User's comment |
| `type` | string | item's type (path or command)[default - PATH]. Enum: `PATH`, `COMMAND` |

**Responses:**

- `204`: Policy updated
- `400`: Script allow list is invalid for this OS type
- `404`: Policy not found

---

### `GET /policies/{policy_id}/data`

**Get policy data by ID**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: Policy data - use 'model' attribute to cast to correct model -- returns `PolicyDataEnvelope`
- `404`: Policy not found

---

### `PUT /policies/{policy_id}/data`

**Update policy data by ID**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `PolicyDataEnvelope`

| Field | Type | Description |
|-------|------|-------------|
| `data` | `PolicyData` |  |

**Responses:**

- `204`: Policy updated
- `400`: Invalid model
- `404`: Policy not found
- `422`: Invalid value / Two types of password supplied

---

### `DELETE /policies/{policy_id}/deny-list/hashes`

**Bulk remove file hashes from this policy's deny list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `GET /policies/{policy_id}/deny-list/hashes`

**Fetch the entire deny list**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of deny list items -- returns array of `ListItemStringTestDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/deny-list/hashes`

**Bulk add file hashes to this policy's deny list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemStringTestDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found
- `422`: File hash is invalid

---

### `DELETE /policies/{policy_id}/deny-list/hashes/{file_hash}`

**Remove a file hash from this policy's deny list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `file_hash` (string)

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `POST /policies/{policy_id}/deny-list/hashes/{file_hash}`

**Add hash to policy's deny list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `file_hash` (string)

**Body schema:** `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found
- `422`: File hash is invalid

---

### `DELETE /policies/{policy_id}/exclusion-list/folder_path`

**Bulk delete folder paths from exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `GET /policies/{policy_id}/exclusion-list/folder_path`

**Returns information for folder paths for a specific policy**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list items -- returns array of `ListItemStringTestDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/exclusion-list/folder_path`

**Bulk add folder paths to exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemStringTestDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/exclusion-list/folder_path/{folder_path}`

**Delete folder path from exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `folder_path` (string)

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `POST /policies/{policy_id}/exclusion-list/folder_path/{folder_path}`

**Add folder path to exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `folder_path` (string)

**Body schema:** `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/exclusion-list/process_path`

**Bulk delete process paths from exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListStringDeleteItem`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `GET /policies/{policy_id}/exclusion-list/process_path`

**Returns information for process paths for a specific policy**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `policy_id` (integer)

**Responses:**

- `200`: List of allow list items -- returns array of `ListItemStringTestDataModel`
- `404`: Policy not found

---

### `POST /policies/{policy_id}/exclusion-list/process_path`

**Bulk add process paths to exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)

**Body schema:** `ListItemStringTestDataModel`

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

### `DELETE /policies/{policy_id}/exclusion-list/process_path/{process_path}`

**Delete process path from exclusion listDelete process path from exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `process_path` (string)

**Responses:**

- `204`: Policy updated
- `404`: Item or policy not found

---

### `POST /policies/{policy_id}/exclusion-list/process_path/{process_path}`

**Add process path to exclusion list**

Permission: Requires FULL_ACCESS permission

**Path parameters:**

- `policy_id` (integer)
- `process_path` (string)

**Body schema:** `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

**Responses:**

- `204`: Policy updated
- `404`: Policy not found

---

## Devices

### `GET /devices/`

**Get 50 devices, starting from id <after_device_id> (default is 0)**

Permission: Requires at least READ_ONLY permission

Notice: after_device_id param is not visible via Swagger

**Responses:**

- `200`: List of devices -- returns `DeviceList`

---

### `POST /devices/actions/archive`

**Bulk archive devices**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `200`: Devices archived./None of the device ids was found/Some device ids were not found. Archived part of the devices
- `404`: Device id is not found.

---

### `POST /devices/actions/delete-remote-files`

**Command the device to delete the files associated with the given event IDs next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Commands queued

---

### `POST /devices/actions/isolate-from-network`

**Bulk isolate device**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `200`: Enqueued enable network isolation for all requested devices.
- `400`: Could not complete request. Some or all of the devices can not be isolated.

---

### `POST /devices/actions/release-from-isolation`

**Bulk Release devices from isolation**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `200`: Enqueued disable network isolation for all requested devices.
- `400`: Could not complete request. Some or all of the devices can not be isolated

---

### `POST /devices/actions/request-remote-file-upload/{event_id}`

**Command the device to upload the file associated with the given event ID the next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `event_id` (integer)

**Responses:**

- `204`: Commands queued
- `404`: Device id is not found

---

### `POST /devices/actions/terminate-remote-process`

**Command the device to kill the process associated with the given event IDs next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Commands queued

---

### `POST /devices/actions/unarchive`

**Bulk unarchive devices**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `200`: Devices unarchived/ None of the device ids was found/ Some device ids were not found. Unarchived part of the devices

---

### `POST /devices/search`

Permission: Requires at least READ_ONLY permission

**Body schema:** `DeviceSearch`

| Field | Type | Description |
|-------|------|-------------|
| `advertisement_id` | string | Advertisement ID of the device. |
| `agent_version` | string | Agent version |
| `brain_version` | string | Brain version |
| `comment` | string | Comment for this device |
| `connectivity_status` | array\<string\> |  |
| `deployment_status` | array\<string\> |  |
| `deployment_status_last_update` |  | Device deployment status last update. |
| `distinguished_name` | string | Distinguished device name |
| `domain` | string | Device's ActiveDirectory domain |
| `full_scan_in_progress` | boolean | Is full scan in progress |
| `group_id` | integer | Group ID that the device belongs to |
| `group_name` | string | Group that the device belongs to |
| `hostname` | string | Device's hostname |
| `id` | integer | Device ID |
| `ip_address` | string | Device's primary IP address |
| `last_contact` |  | Timestamp of last contact with device |
| `last_full_scan_end_timestamp` |  | Timestamp of last full scan |
| `last_registration` |  | Time this device last register. |
| `license_status` | array\<string\> |  |
| `log_status` | array\<string\> |  |
| `logged_in_users` | string | Comma-separated list of logged-in users |
| `mac_address` | string | Device's primary MAC address |
| `mobile_id` | string | Mobile ID of the device |
| `msp_id` | integer | MSP ID to which this device belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this device belongs to. Value only relevant in multitenancy configuration. |
| `os` | array\<string\> |  |
| `osv` | string | Operating system version |
| `policy_id` | integer | Policy ID that the device is using |
| `policy_name` | string | Policy that the device is using |
| `tag` | string | Deployment tag for this device |
| `tenant_id` | integer | Tenant ID to which this device belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this device belongs to. Value only relevant in multitenancy configuration. |

**Responses:**

- `200`: List of devices -- returns `DeviceList`

---

### `GET /devices/{device_id}`

**Get device by ID**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `device_id` (integer)

**Responses:**

- `200`: Device -- returns `Device`
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

### `POST /devices/{device_id}/actions/disable`

**Command the device with this ID to be disabled next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `device_id` (integer)

**Responses:**

- `204`: Device set to be disabled
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

### `POST /devices/{device_id}/actions/enable`

**Command the device with this ID to be enabled next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `device_id` (integer)

**Responses:**

- `204`: Device set to be enabled
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

### `POST /devices/{device_id}/actions/remove`

**Command the device with this ID to be removed next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `device_id` (integer)

**Responses:**

- `204`: Device set to be removed
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

### `POST /devices/{device_id}/actions/upload-logs`

**Command the device with this ID to upload device logs next time it checks in with the server**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `device_id` (integer)

**Responses:**

- `204`: Device set to upload logs
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

### `PUT /devices/{device_id}/comment`

**Update comment for device ID**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `device_id` (integer)

**Body schema:** `DeviceComment`

| Field | Type | Description |
|-------|------|-------------|
| `comment` * | string | Comment for this device |

\* = required field

**Responses:**

- `204`: Device comment updated
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

### `PATCH /devices/{device_id}/tag`

**Update device tag**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `device_id` (integer)

**Body schema:** `DeviceTag`

| Field | Type | Description |
|-------|------|-------------|
| `tag` * | string | tag for this device |

\* = required field

**Responses:**

- `204`: Device tag updated
- `403`: Device id does not belong to connector's msp
- `404`: Device not found

---

## Events

### `GET /events/`

**Get 50 events, starting from id <after_event_id> (default is 0)**

Permission: Requires at least READ_ONLY permission

Notice: after_event_id param is not visible via Swagger

**Responses:**

- `200`: List of events -- returns array of `EventList`

---

### `POST /events/actions/archive`

**Bulk archive events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Events archived/ None of the event ids was found/ Some event ids were not found. Archived part of the events

---

### `POST /events/actions/close`

**Bulk close events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Events closed/ Some event ids were not found/ Closed part of the events/ None of the event ids were found.

---

### `POST /events/actions/close/{file_hash}`

**Bulk close events by hash**

Permission: Requires at least READ_AND_REMEDIATION permission

**Path parameters:**

- `file_hash` (string)

**Responses:**

- `204`: Events closed/ No event found with file hash.

---

### `GET /events/actions/download-uploaded-file/{file_hash}`

**Download an uploaded file by its hash**

Permission: Requires at least READ_AND_REMEDIATION permission

If an archive, use the archive hash.

**Path parameters:**

- `file_hash` (string)

**Responses:**

- `404`: File not found

---

### `POST /events/actions/open`

**Bulk open events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Events opened/ Some event ids were not found/ Opened part of the events/ None of the event ids were found.

---

### `POST /events/actions/unarchive`

**Bulk unarchive events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Events unarchived/ Some event ids were not found. Unarchived part of the events/ None of the event ids was found

---

### `GET /events/file/{file_hash}`

**Get file details by hash; use archive hash if applicable**

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `file_hash` (string)

**Responses:**

- `200`: File details -- returns `FileDetails`
- `404`: No files with this hash were found

---

### `POST /events/search`

**Get 50 events, with IDs following <after_event_id> (default 0),**

Permission: Requires at least READ_ONLY permission

if specified & search using exact match for integers and enums, wildcard filters for strings
and range filters for dates.
Notice: after_event_id param is not visible via Swagger

**Body schema:** `EventSearch`

| Field | Type | Description |
|-------|------|-------------|
| `action` | array\<string\> |  |
| `close_timestamp` |  | Time the event was closed |
| `close_trigger` | array\<string\> |  |
| `comment` | string | Comment on this event |
| `container_hash` | string | Container Hash aka Archive Hash. |
| `device_id` | integer | ID of the device from which this event originated. |
| `file_hash` | string | Hash of the file which caused the event |
| `file_size` | integer | File size in bytes |
| `file_status` | array\<string\> |  |
| `file_type` | array\<string\> |  |
| `id` | integer | Event ID |
| `insertion_timestamp` |  | Time the event was received and saved by the server |
| `last_action` | array\<string\> |  |
| `last_occurrence` |  | Time this event last occurred. |
| `last_reoccurrence` |  | Time the last re-occurrence occurred. |
| `msp_id` | integer | MSP ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this event belongs to. Value only relevant in multitenancy configuration. |
| `path` | string | Full path of the file, if applicable |
| `reoccurrence_count` | integer | Amount of re-occurrences of events with this same hash, type and device ID. |
| `sandbox_status` | array\<string\> |  |
| `script_command` | string | Script command |
| `status` | array\<string\> |  |
| `target_file` | string | File to be encrypted |
| `target_process_path` | string | Path of the target process |
| `tenant_id` | integer | Tenant ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this event belongs to. Value only relevant in multitenancy configuration. |
| `threat_severity` | array\<string\> |  |
| `threat_type` | array\<string\> |  |
| `timestamp` |  | Time the event took place (on the device) |
| `trigger` | array\<string\> |  |
| `type` | array\<string\> |  |

**Responses:**

- `200`: List of events -- returns `EventList`

---

### `GET /events/{event_id}`

**Get event by ID**

Permission: Requires at least READ_ONLY permission

Notice: reoccurrence param is not visible via Swagger

**Path parameters:**

- `event_id` (integer)

**Responses:**

- `200`: Event -- returns `SingleEvent`
- `404`: Event not found

---

## Suspicious Events

### `GET /suspicious-events/`

**Get 50 events, starting from id <after_event_id> (default is 0)**

Permission: Requires at least READ_ONLY permission

Notice: after_event_id param is not visible via Swagger

**Responses:**

- `200`: List of suspicious event -- returns array of `SuspiciousEventList`
- `401`: Unauthorized, Suspicious Events Disabled.

---

### `POST /suspicious-events/actions/archive`

**Bulk archive events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Suspicious events archived/ None of the event ids was found/ Some event ids were not found. Archived part of the events
- `401`: Unauthorized, Suspicious Events Disabled.

---

### `POST /suspicious-events/actions/close`

**Bulk close events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Suspicious events closed/ Some event ids were not found/ Closed part of the events/ None of the event ids were found.
- `401`: Unauthorized, Suspicious Events Disabled.

---

### `POST /suspicious-events/actions/unarchive`

**Bulk unarchive events**

Permission: Requires at least READ_AND_REMEDIATION permission

**Body schema:** `IdsList`

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

**Responses:**

- `204`: Suspicious events unarchived/ Some event ids were not found. Unarchived part of the events/ None of the event ids was found
- `401`: Unauthorized, Suspicious Events Disabled.

---

### `GET /suspicious-events/archive`

**Returns information for suspicious archived events**

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of archived suspicious event -- returns array of `SuspiciousEventList`
- `401`: Unauthorized, Suspicious Events Disabled.

---

### `POST /suspicious-events/search`

**Get 50 events, with IDs following <after_event_id> (default 0),**

Permission: Requires at least READ_ONLY permission

if specified & search using exact match for integers and enums, wildcard filters for strings
and range filters for dates.
Notice: after_event_id param is not visible via Swagger

**Body schema:** `SuspiciousEventSearch`

| Field | Type | Description |
|-------|------|-------------|
| `action` | array\<string\> |  |
| `close_timestamp` |  | Time the event was closed |
| `close_trigger` | array\<string\> |  |
| `comment` | string | Comment on this event |
| `destination_ip` | string |  |
| `device_id` | integer | ID of the device from which this event originated. |
| `file_hash` | string | Hash of the file which caused the event |
| `file_path` | string |  |
| `file_status` | array\<string\> |  |
| `file_type` | array\<string\> |  |
| `id` | integer | Event ID |
| `insertion_timestamp` |  | Time the event was received and saved by the server |
| `is_administrator` | boolean |  |
| `last_action` | array\<string\> |  |
| `last_occurrence` |  | Time this event last occurred. |
| `logon_type` | array\<string\> |  |
| `msp_id` | integer | MSP ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this event belongs to. Value only relevant in multitenancy configuration. |
| `path` | string | Full path of the file, if applicable |
| `process_command_line` | string |  |
| `process_file_sha256` | string |  |
| `process_name` | string |  |
| `process_path` | string |  |
| `remediation` | array\<string\> |  |
| `remote_device_name` | string |  |
| `remote_ip` | string |  |
| `reoccurrence_count` | integer | Amount of re-occurrences of events with this same hash, type and device ID. |
| `rule_trigger` | array\<string\> |  |
| `service_account_name` | string |  |
| `service_file_name` | string |  |
| `service_name` | string |  |
| `status` | array\<string\> |  |
| `tenant_id` | integer | Tenant ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this event belongs to. Value only relevant in multitenancy configuration. |
| `threat_severity` | array\<string\> |  |
| `threat_type` | array\<string\> |  |
| `timestamp` |  | Time the event took place (on the device) |
| `trigger` | array\<string\> |  |
| `type` | array\<string\> |  |
| `username` | string |  |

**Responses:**

- `200`: List of events -- returns `SuspiciousEventList`
- `401`: Unauthorized, Suspicious Events Disabled.

---

### `GET /suspicious-events/{event_id}`

**Get event by ID**

Permission: Requires at least READ_ONLY permission

Notice: reoccurrence param is not visible via Swagger

**Path parameters:**

- `event_id` (integer)

**Responses:**

- `200`: SuspiciousEvent -- returns `SingleSuspiciousEvent`
- `401`: Unauthorized, Suspicious Events Disabled.
- `404`: Event not found

---

## Device Deployment

### `GET /deployment/agent-versions`

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of available agent versions -- returns array of `AgentVersionModel`

---

### `POST /deployment/armed-rpms/`

Permission: Requires at least READ_ONLY permission

**Body schema:** `CreateArmedRpmModel`

| Field | Type | Description |
|-------|------|-------------|
| `abort_if_no_server_connection` | boolean | Check connectivity pre installation |
| `agent_disabled_after_installation` | boolean | Agent disabled after installation  |
| `agent_version_id` * | integer | Agent version id |
| `extraction_path` | string | Installer extraction folder  |
| `manual_proxy` |  | Proxy configuration |
| `no_initial_full_scan` | boolean | No initial full scan after installation  |
| `randomize_initial_full_scan` | integer / null | Randomize initial Full-scan. It's relevant only if no_initial_full_scan is False, otherwise this value has to be None or not exists in the request body at all. |
| `tag` | string | Device Tag |
| `tenant_id` * | integer | Tenant |

\* = required field

**Responses:**

- `200`: Scheduled RPM data -- returns `ScheduledRpmData`

---

### `GET /deployment/armed-rpms/agent-versions`

Permission: Requires at least READ_ONLY permission

**Responses:**

- `200`: List of available agent versions for arming -- returns array of `ArmingRpmAgentVersionModel`

---

### `GET /deployment/armed-rpms/{armed_rpm_id}`

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `armed_rpm_id` (integer)

**Responses:**

- `200`: Status of the request Armed Rpm -- returns `ArmedRpmStatusModel`

---

### `GET /deployment/armed-rpms/{armed_rpm_id}/download`

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `armed_rpm_id` (integer)

**Responses:**

- `200`: Success

---

### `POST /deployment/download-installer`

Permission: Requires at least READ_ONLY permission

**Body schema:** `AgentVersionBaseModel`

| Field | Type | Description |
|-------|------|-------------|
| `os` * | string | Installation file for this OS Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `WINDOWS_SERVER`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `RED_HAT`, `CENTOS`, `UBUNTU`, `RED_HAT8`, `AMAZON_LINUX_2`, `ORACLE_LINUX`, `AMAZON_LINUX_3`, `SUSE_12`, `SUSE_15`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY`, `RED_HAT9` |
| `version` * | string | Agent version |

\* = required field

**Responses:**

- `400`: Bad request
- `404`: Agent version not found for this os

---

### `GET /deployment/token`

Permission: Requires at least READ_ONLY permission

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `size` | int | No | The amount of return results (size of page) |

**Responses:**

- `200`: List of Tenant Tokens -- returns `TenantTokenListModel`

---

### `GET /deployment/token/{tenant_id}`

Permission: Requires at least READ_ONLY permission

**Path parameters:**

- `tenant_id` (integer)

**Responses:**

- `200`: The Tenant Tokens -- returns `TenantTokenModel`
- `404`: Tenant not found or not authorized

---

## User

### `GET /users/`

**Get all users**

Permission: Requires ACCOUNT_ADMIN permission

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `offset` | int | No | How many entities to skip (can be used for paging) |
| `size` | int | No | The amount of return results (size of page) |

**Responses:**

- `200`: List of users -- returns array of `UserReadModel`

---

### `POST /users/`

**Create new user**

Permission: Requires ACCOUNT_ADMIN permission

**Body schema:** `UsersCreationModel`

Extends: `UserBaseModel`

| Field | Type | Description |
|-------|------|-------------|
| `auth_type` | string | Enum: `LOCAL`, `ACTIVEDIRECTORY`, `SSO_ONLY` |
| `enable_sso_for_local_auth_type` | boolean |  |
| `msp_id` | integer | MSP ID to which the new user belongs to. Relevant only for hub account admins |
| `password` | string |  |
| `role` | string | Enum: `MASTER_ADMINISTRATOR`, `ADMINISTRATOR`, `READ_ONLY`, `IT_ADMIN`, `SOC_ADMIN`, `HUB_ADMIN`, `TENANT_VIEWER`, `ACCOUNT_ADMINISTRATOR` |
| `tenant_id` | integer | Tenant ID to which the new user belongs to. Relevant only for MSP account admins creating a Tenant Viewer |
| `username` | string |  |

**Responses:**

- `200`: User -- returns array of `UserReadModel`
- `400`: MSP related user request shouldn't contain msp_id / MSP ID should be supplied for creating MSP related user (relevant for hub level account admins) / Selected Role is not TENANT_VIEWER so tenant_id is redundant / Request can contain either msp_id or tenant_id, not both / Selected Role is not MSP related so msp_id is redundant / Selected role can not be created in a non-multitenancy environment / Password should be according to these complexity standards: Length between 8-35 characters, contains upper and lower case letters, one or more numerical digits & at least 1 special character.
- `403`: MSP related user cannot create a HUB_ADMIN user / Given tenant_id doesn't match the controller's tenant_ids
- `409`: Username already exists

---

### `DELETE /users/{user_id}`

**Delete user by id**

Permission: Requires ACCOUNT_ADMIN permission

**Path parameters:**

- `user_id` (integer)

**Responses:**

- `204`: User deleted
- `404`: User not found

---

### `GET /users/{user_id}`

**Get user by ID**

Permission: Requires ACCOUNT_ADMIN permission

**Path parameters:**

- `user_id` (integer)

**Responses:**

- `200`: User -- returns array of `UserReadModel`

---

### `PUT /users/{user_id}`

**Update user by id**

Permission: Requires ACCOUNT_ADMIN permission

**Path parameters:**

- `user_id` (integer)

**Body schema:** `UserUpdateModel`

| Field | Type | Description |
|-------|------|-------------|
| `auth_type` | string | Enum: `LOCAL`, `ACTIVEDIRECTORY`, `SSO_ONLY` |
| `email` | string |  |
| `enable_sso_for_local_auth_type` | boolean |  |
| `first_name` | string | User's first name |
| `last_name` | string | User's last name |
| `password` | string |  |
| `role` | string | Enum: `MASTER_ADMINISTRATOR`, `ADMINISTRATOR`, `READ_ONLY`, `IT_ADMIN`, `SOC_ADMIN`, `HUB_ADMIN`, `TENANT_VIEWER`, `ACCOUNT_ADMINISTRATOR` |

**Responses:**

- `204`: User updated
- `400`: Password should be according to these complexity standards: Length between 8-35 characters, contains upper and lower case letters, one or more numerical digits & at least 1 special character.
- `404`: User not found

---

## Audit Logs

### `GET /audit_logs/`

**Get all audit logs**

Permission: Requires at least READ_ONLY permission

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_timestamp` | datetime | No | Event timestamp filter - From timestamp (ISO8601 Format) |
| `to_timestamp` | datetime | No | Event timestamp filter - To Timestamp (ISO8601 Format) |
| `offset` | int | No | How many entities to skip (can be used for paging) |
| `size` | int | No | The amount of return results (size of page) |

**Responses:**

- `200`: Audit Logs -- returns `AuditLogEntry`

---

## API Connectors

### `POST /api-connectors/msp-connector`

**Create MSP API Connector**

Permission: Requires FULL_ACCESS permission

**Body schema:** `RequestCreateMspApiConnector`

| Field | Type | Description |
|-------|------|-------------|
| `msp_id` * | integer / null | For specific msp provide the msp id, use "null" for all msps. |
| `name` * | string |  |
| `permission` * | string | Enum: `READ_ONLY`, `READ_AND_REMEDIATION`, `FULL_ACCESS`, `ACCOUNT_ADMIN` |

\* = required field

**Responses:**

- `200`: Success -- returns `ResponseCreateMspApiConnector`
- `403`: User is not authorized for this action
- `404`: Tenant Not Found / MSP Not Found
- `409`: Connector {name} already exists

---

### `POST /api-connectors/tenant-connector`

**Create tenant API Connector**

Permission: Requires FULL_ACCESS permission

**Body schema:** `RequestCreateTenantApiConnector`

| Field | Type | Description |
|-------|------|-------------|
| `msp_id` * | integer |  |
| `name` * | string |  |
| `permission` * | string | Enum: `READ_ONLY`, `READ_AND_REMEDIATION`, `FULL_ACCESS`, `ACCOUNT_ADMIN` |
| `tenants_ids` * | array\<integer\> | For specific tenants provide the tenants ids, use "[]" for all tenants. |

\* = required field

**Responses:**

- `200`: Success -- returns `ResponseCreateTenantApiConnector`
- `400`: Cannot create MSP level connector via the tenants connector / Full access is not permitted for a tenant level connector
- `403`: User is not authorized for this action
- `404`: Tenant Not Found / MSP Not Found
- `409`: Connector {name} already exists

---

## Model Schemas

### Key Object Models

### Device

| Field | Type | Description |
|-------|------|-------------|
| `advertisement_id` | string | Advertisement ID of the device. |
| `agent_version` | string | Agent version |
| `brain_version` | string | Brain version |
| `comment` | string | Comment for this device |
| `connectivity_status` | string | Connectivity status of the device Enum: `ONLINE`, `OFFLINE` |
| `deployment_status` | string | Deployment status of the device Enum: `NA`, `PENDING_INSTALLATION`, `REGISTERED`, `NOT_REGISTERED`, `DEACTIVATED`, `REMOVED`, `DEPLOYMENT_EMAIL_SENT`, `DEPLOYMNET_EMAIL_FAILURE`, `DEPLOYMENT_AGENT_INSTALLER_DOWNLOADED`, `LICENSE_ACTIVATION`, `LICENSE_DEACTIVATION`, `DISABLED`, `PENDING_ISOLATION`, `ISOLATED_FROM_NETWORK`, `AGENT_UPGRADE_STARTED`, `DEPLOYED_WITH_WARNINGS` |
| `deployment_status_last_update` | string (date-time) | Device deployment status last update. |
| `distinguished_name` | string | Distinguished device name |
| `domain` | string | Device's ActiveDirectory domain |
| `full_scan_in_progress` | boolean | Is full scan in progress |
| `group_id` | integer | Group ID that the device belongs to |
| `group_name` | string | Group that the device belongs to |
| `hostname` | string | Device's hostname |
| `id` | integer | Device ID |
| `ip_address` | string | Device's primary IP address |
| `last_contact` | string (date-time) | Timestamp of last contact with device |
| `last_full_scan_duration_in_milliseconds` | integer | Duration of last full scan in milliseconds |
| `last_full_scan_end_timestamp` | string (date-time) | Timestamp of last full scan |
| `last_full_scan_files_scanned` | integer | Files scanned during last full scan |
| `last_registration` | string (date-time) | Timestamp of last device registration |
| `license_status` | string | Device License status Enum: `ACTIVATED`, `DEACTIVATED_UNKNOWN`, `DEACTIVATED_UNINSTALLED` |
| `log_status` | string | Device log collection status Enum: `NA`, `PENDING`, `READY`, `ERROR`, `SENT_TO_CLIENT` |
| `logged_in_users` | string | Comma-separated list of logged-in users |
| `mac_address` | string | Device's primary MAC address |
| `mobile_id` | string | Mobile ID of the device |
| `msp_id` | integer | MSP ID to which this device belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this device belongs to. Value only relevant in multitenancy configuration. |
| `os` | string | Operating system Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `WINDOWS_SERVER`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `RED_HAT`, `CENTOS`, `UBUNTU`, `RED_HAT8`, `AMAZON_LINUX_2`, `ORACLE_LINUX`, `AMAZON_LINUX_3`, `SUSE_12`, `SUSE_15`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY`, `RED_HAT9` |
| `osv` | string | Operating system version |
| `policy_id` | integer | Policy ID that the device is using |
| `policy_name` | string | Policy that the device is using |
| `scanned_files` | integer | Amount of files by device so far |
| `tag` | string | Deployment tag for this device |
| `tenant_id` | integer | Tenant ID to which this device belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this device belongs to. Value only relevant in multitenancy configuration. |

### MaliciousEvent

| Field | Type | Description |
|-------|------|-------------|
| `action` * | string | Enum: `NON_COMPLIANT`, `PREVENTED`, `DETECTED`, `DEVICE_REPORT`, `CLEAR` |
| `advertisement_id` | string | Advertisement ID of the related device. |
| `affected_device` | integer | Amount of affected device that reported events on the same file hash. |
| `certificate_thumbprint` | string | Thumbprint of the certificate that signs this file, if the file is signed |
| `certificate_vendor_name` | string | Vendor that owns the certificate that signs this file, if the file is signed |
| `close_timestamp` | string (date-time) | Time the event was closed |
| `close_trigger` | string | Trigger for closing the event Enum: `MALICIOUS_FILE`, `FILE_DELETED`, `BENIGN_FILE`, `FILE_ADDED_TO_ALLOW_LIST`, `FILE_REMOVED_FROM_ALLOW_LIST`, `FILE_ADDED_TO_DENY_LIST`, `FILE_REMOVED_FROM_DENY_LIST`, `DETECTION_LEVEL_MODIFIED`, `PREVENTION_LEVEL_MODIFIED`, `OS_VERSION_UPGRADED`, `POLICY_MODIFIED`, `DEVICE_SETTINGS_CHANGED_BY_USER`, `HOST_FILE_RESTORED`, `SHIM`, `D_CLIENT_REMOVED`, `CERTIFICATE_ADDED_TO_ALLOW_LIST`, `PATH_ADDED_TO_ALLOW_LIST`, `CERTIFICATE_REMOVED_FROM_ALLOW_LIST`, `PATH_REMOVED_FROM_ALLOW_LIST`, `CLOSED_BY_ADMIN` |
| `comment` | string | Comment on this event |
| `container_hash` | string | Container Hash aka Archive Hash |
| `description` | string | Event description |
| `device_id` * | integer | ID of the device from which this event originated. |
| `disk_drive` | string | Disk Drive |
| `dot_net_version` | string | .NET version |
| `file_hash` | string | Hash of the file which caused the event |
| `file_size` | integer | File size in bytes |
| `file_status` | string | Whether the file was uploaded Enum: `UPLOADED`, `NOT_UPLOADED`, `NA` |
| `file_type` | string | Enum: `OTHER`, `PE`, `EXE`, `DLL`, `PDF`, `OFFICE`, `PPT`, `XLS`, `DOC`, `ZIP`, `RAR`, `VBA`, `RTF`, `TTF`, `TIFF`, `SCRIPT`, `EICAR`, `APK`, `IPA`, `NA`, `JAR`, `SWF`, `POWERSHELL`, `POWERSHELL_INTERACTIVE`, `ACTIVE_SCRIPT`, `HTML_APPLICATION`, `SEVEN_Z`, `MACHO`, `XAR`, `TAR`, `DMG`, `OTF`, `OOXML`, `PE64`, `PE32`, `ELF`, `SO`, `O`, `KO`, `LNK`, `JAVASCRIPT`, `MSG`, `EML`, `GZIP`, `BZIP2`, `ISO`, `HTML`, `MSI`, `UNSUPPORTED_ELF`, `AR`, `XZ`, `CSV` |
| `id` * | integer | Event ID |
| `insertion_timestamp` * | string (date-time) | Time the event was received and saved by the server |
| `last_action` | string | The last action performed on the device related to this event Enum: `QUARANTINE_FAILED`, `RESTORATION_FAILED`, `QUARANTINE_SUCCESS`, `RESTORATION_SUCCESS`, `DELETE_SUCCESS`, `FILE_UPLOADED_SUCCESSFULLY`, `FILE_UPLOADED_FAILED`, `DELETE_FAILED` |
| `last_reoccurrence` | string (date-time) | Time the last re-occurrence occurred. |
| `mitre_classifications` | array\<`MitreClassifications`\> | MITRE Classifications related to this event (List) |
| `mobile_id` | string | Mobile ID of the related device |
| `msp_id` | integer | MSP ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this event belongs to. Value only relevant in multitenancy configuration. |
| `occurrence_count` | integer | Amount of occurrences of events with this same file hash. |
| `path` | string | Full path of the file, if applicable |
| `powershell_version` | string | Powershell version |
| `process_chain` | array\<`ProcessTreeEntryModel`\> | Process tree/chain for event (List) |
| `ransom_note_path` | string | Ransom note path |
| `recorded_device_info` |  | Information about the device at the time of the event |
| `reoccurrence_count` | integer | Amount of re-occurrences of events with this same hash, type and device ID. |
| `sandbox_status` | string | Whether a sandbox report was created, is ready for creation, cannot be created, or failed creation. Enum: `IN_PROGRESS`, `FAILED`, `REPORT_CREATED`, `NOT_READY_TO_GENERATE`, `READY_TO_GENERATE` |
| `script_command` | string | Script command |
| `script_file_path` | string | Script file path |
| `shellcode_data` | string | Shellcode data |
| `shellcode_module_path` | string | Shellcode module path |
| `status` * | string | The event's status (open or closed) Enum: `OPEN`, `CLOSED`, `REOPEN` |
| `target_file` | string | Ransom target file |
| `target_process_path` | string | Ransom target file |
| `tenant_id` | integer | Tenant ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this event belongs to.Value only relevant in multitenancy configuration. |
| `threat_severity` | string | Enum: `LOW`, `MODERATE`, `HIGH`, `VERY_HIGH` |
| `threat_type` | string | The threat type with the highest probability. Enum: `DUAL_USE_DUAL_USE_TOOL`, `DUAL_USE_REMOTE_ADMIN_TOOL`, `DUAL_USE_MONITORING_TOOL`, `DUAL_USE_INVESTIGATION_TOOL`, `DUAL_USE_SSH_TOOL`, `DUAL_USE_DISK_ENCRYPTION_TOOL`, `DUAL_USE_FILE_SHARING_TOOL`, `DUAL_USE_NETWORK_TOOL`, `DUAL_USE_PASSWORD_TOOL`, `DUAL_USE_SYSTEM_MODIFICATION_TOOL`, `DUAL_USE_HARDWARE_MODIFICATION_TOOL`, `DUAL_USE_SCRIPTING_TOOL`, `PUA_GENERIC_PUA`, `PUA_MINER_PUA`, `PUA_RISKWARE_HACKTOOL`, `PUA_FAKEAPP`, `PUA_TOOLBAR`, `PUA_DOWNLOADER`, `PUA_ADWARE`, `PUA_GAMING`, `PUA_GENERIC`, `MALWARE_TROJAN`, `MALWARE_BACKDOOR`, `MALWARE_RANSOMWARE`, `MALWARE_DROPPER`, `MALWARE_SPYWARE`, `MALWARE_VIRUS`, `MALWARE_WORM`, `MALWARE_MINER_MALWARE` |
| `timestamp` * | string (date-time) | Time the event took place (on the device) |
| `trigger` * | string | Event trigger Enum: `MALICIOUS_FILE`, `FILE_REMOVED_FROM_ALLOW_LIST`, `FILE_ADDED_TO_DENY_LIST`, `FILE_REMOVED_FROM_DENY_LIST`, `DETECTION_LEVEL_MODIFIED`, `PREVENTION_LEVEL_MODIFIED`, `POLICY_MODIFIED`, `DEVICE_SETTINGS_CHANGED_BY_USER`, `FEATURE_NOT_COMPLIANT`, `OS_VERSION_DOWNGRADED`, `SHIM`, `FILE_INTEGRITY_FAILURE`, `INVALID_FILE_CERTIFICATE`, `POWERSHELL_EXECUTION`, `CERTIFICATE_REMOVED_FROM_ALLOW_LIST`, `PATH_REMOVED_FROM_ALLOW_LIST`, `POWERSHELL_INTERACTIVE_EXECUTION`, `ACTIVESCRIPT_EXECUTION`, `HTML_APPLICATION_JAVASCRIPT_EXECUTION`, `RANSOMWARE`, `REMOTE_CODE_INJECTION`, `KNOWN_PAYLOAD_EXECUTION`, `DDE_USAGE`, `ARBITRARY_SHELLCODE`, `REFLECTIVE_DLL_INJECTION`, `REFLECTIVE_DOTNET_INJECTION`, `AMSI_BYPASS`, `DIRECT_SYSTEM_CALL`, `CREDENTIAL_DUMP`, `DEEP_MEMORY_SCANNING`, `JS_EXECUTION`, `VSS_DELETION`, `VSS_RESIZING`, `PROCESS_TAMPERING` |
| `type` * | string | Event type Enum: `FILE_DELETION`, `D_CLIENT_INSTALLATION`, `FULL_SCAN`, `D_CLIENT_ACTIVATION`, `D_CLIENT_CRASH`, `D_CLIENT_DISABLE`, `MINIMUM_OS_VERSION`, `CAMERA`, `STORAGE_ENCRYPTION`, `PASSWORD_COMPLIANT`, `UNKNOWN_SOURCES`, `USB_DEBUGGING`, `DEVICE_ADMIN`, `ROOT`, `JAILBREAK`, `EXCESSIVE_LOGIN_ATTEMPTS`, `SSL_MITM`, `ARP_SPOOFING`, `HOST_FILE`, `USER_CERTIFICATE`, `LICENSE_ACTIVATION`, `LICENSE_DEACTIVATION`, `PENDING_INSTALLATION`, `SUCCESSFUL_REGISTRATION`, `D_CLIENT_FAILED_REGISTRATION`, `CONFIGURATION_UP_TO_DATE`, `ACTIVE_SCRIPT_EXECUTION_BLOCKED`, `EXTERNAL_STORAGE_REMOVAL`, `EXTERNAL_STORAGE_INSERTION`, `OS_VERSION_UPDATE`, `DEVICE_NAME`, `DEVICE_IP`, `DEVICE_MAC`, `D_CLIENT_VERSION`, `D_CLIENT_UNINSTALL`, `D_BRAIN_VERSION`, `QUARANTINE_FAILED`, `RESTORATION_FAILED`, `DELETE_FAILED`, `QUARANTINE_SUCCESS`, `RESTORATION_SUCCESS`, `DELETE_SUCCESS`, `BATTERY_OPTIMIZATIONS`, `STORAGE_ACCESS`, `REMOVABLE_STORAGE_ACCESS`, `APP_USAGE_ACCESS`, `DRAW_OVER_OTHER_APPS`, `HP_SERIAL`, `DISTINGUISHED_NAME`, `DOMAIN_NAME`, `UPLOAD_FILE_FAILED`, `FIREWALL_ON`, `FIREWALL_OFF`, `QUARANTINE_QUOTA_WARNING`, `QUARANTINE_QUOTA_FIXED`, `STATIC_ANALYSIS`, `RANSOMWARE_FILE_ENCRYPTION`, `REMOTE_CODE_INJECTION_EXECUTION`, `KNOWN_SHELLCODE_PAYLOADS`, `AGENT_CONFIG_RELOADED`, `ARBITRARY_SHELLCODE`, `REFLECTIVE_DLL`, `REFLECTIVE_DOTNET`, `AMSI_BYPASS`, `DIRECT_SYSTEMCALLS`, `CREDENTIAL_DUMP`, `SUSPICIOUS_SCRIPT_EXCECUTION`, `MALICIOUS_POWERSHELL_COMMAND_EXECUTION`, `DEEP_MEMORY_SCANNING`, `MALICIOUS_JS_EXECUTION`, `PROCESS_TAMPERING` |
| `volume_id` | string | Volume ID |

\* = required field

### SuspiciousEvent

| Field | Type | Description |
|-------|------|-------------|
| `action` * | string | Enum: `DETECTED`, `PREVENTED`, `REMEDIATED` |
| `affected_device` | integer | Amount of affected device that reported events on the same file hash. |
| `certificate_owner` | string |  |
| `certificate_thumbprint` | string |  |
| `close_timestamp` | string (date-time) | Time the event was closed |
| `close_trigger` | string | Trigger for closing the event Enum: `FILE_DELETED`, `CLOSED_BY_ADMIN`, `SUSPICIOUS_ACTIVITY`, `D_CLIENT_REMOVED` |
| `comment` | string | Comment on this event |
| `connectivity_status` | string |  |
| `description` | string | Event description |
| `destination_ip` | string |  |
| `destination_port` | integer |  |
| `device_id` * | integer | ID of the device from which this event originated. |
| `device_name` | string |  |
| `dll_certificate` | string |  |
| `dll_certificate_thumbprint` | string |  |
| `dll_path` | string |  |
| `dll_sha_256` | string |  |
| `dll_size` | string |  |
| `failure_reason_status` | string | Enum: `STATUS_OK`, `STATUS_NO_LOGON_SERVERS`, `STATUS_NO_SUCH_USER`, `STATUS_WRONG_PASSWORD`, `STATUS_LOGON_FAILURE`, `STATUS_ACCOUNT_RESTRICTION`, `STATUS_INVALID_LOGON_HOURS`, `STATUS_INVALID_WORKSTATION`, `STATUS_PASSWORD_EXPIRED`, `STATUS_ACCOUNT_DISABLED`, `STATUS_INVALID_SERVER_STATE`, `STATUS_TIME_DIFFERENCE_AT_DC`, `STATUS_LOGON_TYPE_NOT_GRANTED`, `STATUS_TRUSTED_DOMAIN_FAILURE`, `STATUS_NETLOGON_NOT_STATED`, `STATUS_ACCOUNT_EXPIRED`, `STATUS_PASSWORD_MUST_CHANGE`, `STATUS_NOT_FOUND`, `STATUS_ACCOUNT_LOCKED_OUT`, `STATUS_UNFINISHED_CONTEXT_DELETED`, `STATUS_AUTHENTICATION_FIREWALL_FAILED` |
| `failure_reason_sub_status` | string | Enum: `STATUS_OK`, `STATUS_NO_LOGON_SERVERS`, `STATUS_NO_SUCH_USER`, `STATUS_WRONG_PASSWORD`, `STATUS_LOGON_FAILURE`, `STATUS_ACCOUNT_RESTRICTION`, `STATUS_INVALID_LOGON_HOURS`, `STATUS_INVALID_WORKSTATION`, `STATUS_PASSWORD_EXPIRED`, `STATUS_ACCOUNT_DISABLED`, `STATUS_INVALID_SERVER_STATE`, `STATUS_TIME_DIFFERENCE_AT_DC`, `STATUS_LOGON_TYPE_NOT_GRANTED`, `STATUS_TRUSTED_DOMAIN_FAILURE`, `STATUS_NETLOGON_NOT_STATED`, `STATUS_ACCOUNT_EXPIRED`, `STATUS_PASSWORD_MUST_CHANGE`, `STATUS_NOT_FOUND`, `STATUS_ACCOUNT_LOCKED_OUT`, `STATUS_UNFINISHED_CONTEXT_DELETED`, `STATUS_AUTHENTICATION_FIREWALL_FAILED` |
| `file_description` | string |  |
| `file_host_url` | string |  |
| `file_name` | string |  |
| `file_path` | string |  |
| `file_product_name` | string |  |
| `file_referrer_url` | string |  |
| `file_sha_256` | string |  |
| `file_type` | string | Enum: `SCRIPT`, `POWERSHELL`, `POWERSHELL_INTERACTIVE`, `ACTIVE_SCRIPT`, `HTML_APPLICATION` |
| `file_version` | string |  |
| `file_zone_id` | integer |  |
| `id` * | integer | Event ID |
| `insertion_timestamp` * | string (date-time) | Time the event was received and saved by the server |
| `is_administrator` | boolean |  |
| `last_action` | string | The last action performed on the device related to this event Enum: `QUARANTINE_FAILED`, `RESTORATION_FAILED`, `QUARANTINE_SUCCESS`, `RESTORATION_SUCCESS`, `DELETE_SUCCESS`, `FILE_UPLOADED_SUCCESSFULLY`, `FILE_UPLOADED_FAILED`, `DELETE_FAILED` |
| `last_reoccurrence` | string (date-time) | Time the last re-occurrence occurred. |
| `logon_type` | string | Enum: `UNDEFINED_LOGON_TYPE`, `INTERACTIVE`, `NETWORK`, `BATCH`, `SERVICE`, `PROXY`, `UNLOCK`, `NETWORK_CLEARTEXT`, `NEW_CREDENTIALS`, `REMOTE_INTERACTIVE`, `CACHED_INTERACTIVE`, `CACHED_REMOTE_INTERACTIVE`, `CACHED_UNLOCK` |
| `mac_address` | string |  |
| `mitre_classifications` | array\<`MitreClassifications`\> | MITRE Classifications related to this event (List) |
| `msp_id` | integer | MSP ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this event belongs to. Value only relevant in multitenancy configuration. |
| `network_adapter_name` | string |  |
| `network_direction` | string | Enum: `Inbound`, `Outbound` |
| `new_registry_key` | string |  |
| `occurrence_count` | integer | Amount of occurrences of events with this same file hash. |
| `old_registry_key` | string |  |
| `parent_process_command_line` | string |  |
| `parent_process_path` | string |  |
| `path` | string | Full path of the script file, if applicable |
| `process_certificate` | string |  |
| `process_certificate_thumbprint` | string |  |
| `process_chain` | array\<`ProcessTreeEntryModel`\> | Process tree/chain for event (List) |
| `process_command_line` | string |  |
| `process_description` | string |  |
| `process_file_sha_256` | string |  |
| `process_file_size` | string |  |
| `process_id` | integer |  |
| `process_integrity_level` | string | Enum: `IntegrityLevelUnknown`, `IntegrityLevelUntrusted`, `IntegrityLevelLow`, `IntegrityLevelMedium`, `IntegrityLevelHigh` |
| `process_name` | string |  |
| `process_path` | string |  |
| `process_product_name` | string |  |
| `process_start_time` | string (date-time) |  |
| `process_token_elevation_type` | string | Enum: `TokenElevationTypeUnknown`, `TokenElevationTypeDefault`, `TokenElevationTypeFull`, `TokenElevationTypeLimited` |
| `process_version` | string |  |
| `recorded_device_info` |  | Information about the device at the time of the event |
| `registry_data` | string |  |
| `registry_data_type` | string | Enum: `REG_NONE`, `REG_SZ`, `REG_EXPAND_SZ`, `REG_BINARY`, `REG_DWORD`, `REG_DWORD_LITTLE_ENDIAN`, `REG_DWORD_BIG_ENDIAN`, `REG_LINK`, `REG_MULTI_SZ`, `REG_RESOURCE_LIST`, `REG_FULL_RESOURCE_DESCRIPTOR`, `REG_RESOURCE_REQUIREMENTS_LIST`, `REG_QWORD`, `REG_QWORD_LITTLE_ENDIAN` |
| `registry_path` | string |  |
| `remediation` | array\<string\> |  |
| `remote_device_name` | string |  |
| `remote_ip` | string |  |
| `remote_port` | integer |  |
| `reoccurrence_count` | integer | Amount of re-occurrences of events with this same hash, type and device ID. |
| `rule_trigger` * | string | Rule trigger Enum: `REGISTRY`, `NETWORK`, `PROCESS`, `FILE`, `API_CALL`, `LOGON`, `SERVICE_INSTALLED`, `WMI_ACTIVITY` |
| `service_account_name` | string |  |
| `service_file_name` | string |  |
| `service_name` | string |  |
| `service_start_type` | string | Enum: `Boot`, `System`, `Automatic`, `Manual`, `Disabled` |
| `service_type` | string | Enum: `KernelDriver`, `FileSystemDriver`, `Adapter`, `RecognizerDriver`, `Win32OwnProcess`, `Win32ShareProcess`, `InteractiveProcess` |
| `source` | object |  |
| `source_IPv4` | string |  |
| `source_IPv6` | string |  |
| `source_ip` | string |  |
| `source_port` | integer |  |
| `status` * | string | The event's status (open or closed) Enum: `OPEN`, `CLOSED`, `REOPEN` |
| `subject_account_name` | string |  |
| `subject_account_sid` | string |  |
| `subject_domain_name` | string |  |
| `subject_logon_id` | string |  |
| `target_domain_name` | string |  |
| `target_logon_id` | string |  |
| `target_user_name` | string |  |
| `target_user_sid` | string |  |
| `tenant_id` | integer | Tenant ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this event belongs to.Value only relevant in multitenancy configuration. |
| `threat_severity` | string | Enum: `LOW`, `MODERATE`, `HIGH`, `VERY_HIGH` |
| `timestamp` * | string (date-time) | Time the event took place (on the device) |
| `trigger` * | string | Event trigger Enum: `POWERSHELL_EXECUTION`, `POWERSHELL_INTERACTIVE_EXECUTION`, `ACTIVESCRIPT_EXECUTION`, `HTML_APPLICATION_JAVASCRIPT_EXECUTION`, `SUSPICIOUS_ACTIVITY` |
| `type` * | string | Event type Enum: `SUSPICIOUS_ACTIVITY`, `SCRIPT_CONTROL_COMMAND`, `SCRIPT_CONTROL_PATH`, `SUSPICIOUS_POWERSHELL_COMMAND_EXECUTION` |
| `username` | string |  |
| `wmi_event_consumer` | string |  |
| `wmi_event_subsystem` | string |  |
| `wmi_namespace` | string |  |
| `wmi_possible_cause` | string |  |
| `wmi_query` | string |  |
| `wmi_query_username` | string |  |

\* = required field

### DeviceList

Wrapper returned by `GET /devices/` and `POST /devices/search`:

| Field | Type | Description |
|-------|------|-------------|
| `devices` | array of `Device` | List of device objects |
| `last_id` | integer | Last device ID in this page (use as `after_device_id` for next page) |

### EventList

Wrapper returned by `GET /events/` and `POST /events/search`:

| Field | Type | Description |
|-------|------|-------------|
| `events` | array of `MaliciousEvent` | List of event objects |
| `last_id` | integer | Last event ID in this page (use as `after_event_id` for next page) |

### SuspiciousEventList

Wrapper returned by `GET /suspicious-events/` and `POST /suspicious-events/search`:

| Field | Type | Description |
|-------|------|-------------|
| `events` | array of `SuspiciousEvent` | List of suspicious event objects |
| `last_id` | integer | Last event ID in this page (use as `after_event_id` for next page) |

### Policy Data Models

These are the platform-specific policy data schemas returned by `GET /policies/{id}/data`
and sent via `PUT /policies/{id}/data` (wrapped in `{"data": {...}}`).

**IMPORTANT:** When updating policy data via PUT, you must include the `model` field and
must EXCLUDE `disable_password_hash` and `uninstall_password_hash` fields.

### PolicyData

| Field | Type | Description |
|-------|------|-------------|
| `model` * | string | Name of the model contained Enum: `WindowsPolicyData`, `WindowsNASPolicyData`, `AndroidPolicyData`, `MacOSPolicyData`, `IOSPolicyData`, `ChromeOSPolicyData`, `ApplicationSecurityPolicyData`, `LinuxPolicyData`, `CloudStoragePolicyData` |

\* = required field

### WindowsPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `action_on_prevented_files` | string | Action to perform when preventing a file Enum: `PREVENT_ONLY`, `DELETE_AND_QUARANTINE` |
| `activescript_action` | string | Action to take upon ActiveScript script usage (JavaScript, VBScript) Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `amsi_bypass` | string | Mode of operation for AMSI ByPass Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `arbitrary_shellcode_execution` | string | Mode of operation for Arbitrary Shellcode Execution Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `automatic_brain_upgrade` | boolean | Whether to upgrade brain to latest. |
| `automatic_upgrade` | boolean | Whether agents should attempt to upgrade. |
| `credentials_dump` | string | Mode of operation for Credentials Dump Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `deep_memory_scanning` | string | Mode of operation for Deep Memory Scanning Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `direct_system_calls` | string | Mode of operation for Direct SystemCalls Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `disable_password` | string | Disable password |
| `disable_password_hash` | string | Disable password hash |
| `dual_use` | string | Dual Use protection level Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `embedded_dde_object_in_office_document` | string | Embedded DDE object in Microsoft Office document. Enum: `ALLOW`, `PREVENT` |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `enable_scheduled_scan` | boolean | Whether to enable scheduled scanning |
| `gradual_deployment` | boolean | Whether all agents should update gradually. |
| `hide_d_client_ui` | boolean | Whether to show the D-Client UI (takes effect after reboot) |
| `html_applications_action` | string | Action to take upon HTA script usage Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `in_memory_protection` | boolean | Mode of operation for in process analysis |
| `integrate_agent_with_windows_security_center` | boolean | Whether agent should integrate with windows security center. |
| `known_payload_execution` | string | Mode of operation for Known Payload Execution Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `malicious_js_command_execution` | string | Action to Javascript command execution Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `malicious_powershell_command_execution` | string | Action to take upon a suspicious PowerShell command usage. Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `model` | string |  |
| `network_isolated_permitted_connections` | array\<any\> |  |
| `office_macro_script_action` | string | Action to take upon Office Macro script usage Enum: `USE_D_BRAIN`, `ALWAYS_PREVENT`, `ALLOW_ALL_MACROS` |
| `powershell_script_action` | string | Action to take upon PowerShell script usage Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `prevent_all_activescript_usage` | string | DETECT - Block all ActiveScripts using Windows, ALLOW - Use the default Windows action Enum: `ALLOW`, `PREVENT` |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `process_tampering` | string | Mode of operation for Process Tampering Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `protection_level_pua` | string | Known PUA protection level Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `ransomware_behavior` | string | Mode of operation for ransomware behavior Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `reflective_dll_loading` | string | Mode of operation for Reflective DLL Loading Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `reflective_dotnet_injection` | string | Mode of operation for Reflective .NET injection Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `remote_code_injection` | string | Mode of operation for remote code injection Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `scan_network_drives` | boolean | Whether to scan files on network drives |
| `scheduled_scan_day_of_month` | integer | Day of the month on which to perform scheduled scan Enum: `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`, `13`, `14`, `15`, `16`, `17`, `18`, `19`, `20`, `21`, `22`, `23`, `24`, `25`, `26`, `27`, `28`, `29`, `30`, `31` |
| `scheduled_scan_day_of_week` | string | Day of the week on which to perform scheduled scan Enum: `SUNDAY`, `MONDAY`, `TUESDAY`, `WEDNESDAY`, `THURSDAY`, `FRIDAY`, `SATURDAY` |
| `scheduled_scan_mode` | string | Mode to perform scheduled scan Enum: `DAILY`, `WEEKLY`, `MONTHLY_BY_DAY_OF_WEEK`, `MONTHLY_BY_DAY_OF_MONTH` |
| `scheduled_scan_time` | string | HH:MM of the day on which to perform scheduled scan Enum: `00:00`, `01:00`, `02:00`, `03:00`, `04:00`, `05:00`, `06:00`, `07:00`, `08:00`, `09:00`, `10:00`, `11:00`, `12:00`, `13:00`, `14:00`, `15:00`, `16:00`, `17:00`, `18:00`, `19:00`, `20:00`, `21:00`, `22:00`, `23:00` |
| `scheduled_scan_week` | integer | Number of the week in month on which to perform scheduled scan Enum: `1`, `2`, `3`, `4` |
| `suspicious_activity_detection` | boolean | Whether agents should report suspicious activity. |
| `suspicious_powershell_command_execution` | string | Action to take upon a suspicious PowerShell command usage. Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `suspicious_script_execution` | string | Action to take upon a suspicious script usage. Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `uninstall_password` | string | Uninstall password |
| `uninstall_password_hash` | string | Uninstall password hash |

### MacOSPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `automatic_brain_upgrade` | boolean | Whether to upgrade brain to latest. |
| `automatic_upgrade` | boolean | Whether agents should attempt to upgrade. |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `disable_password` | string | Disable password |
| `disable_password_hash` | string | Disable password hash |
| `embedded_dde_object_in_office_document` | string | Embedded DDE object in Microsoft Office document. Enum: `ALLOW`, `PREVENT` |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `gradual_deployment` | boolean | Whether all agents should update gradually. |
| `inherit_global_exceptions_list` | boolean | The ability to manage global allow lists and deny lists |
| `model` | string |  |
| `network_isolated_permitted_connections` | array\<any\> |  |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `protection_level_pua` | string | Known PUA protection level Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `ransomware_behavior` | string | Mode of operation for ransomware behavior Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `scan_network_drives` | boolean | Scan files accessed from network folders. |
| `scheduled_scan_day_of_month` | integer | Day of the month on which to perform scheduled scan Enum: `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`, `13`, `14`, `15`, `16`, `17`, `18`, `19`, `20`, `21`, `22`, `23`, `24`, `25`, `26`, `27`, `28`, `29`, `30`, `31` |
| `scheduled_scan_day_of_week` | string | Day of the week on which to perform scheduled scan Enum: `SUNDAY`, `MONDAY`, `TUESDAY`, `WEDNESDAY`, `THURSDAY`, `FRIDAY`, `SATURDAY` |
| `scheduled_scan_mode` | string | Mode to perform scheduled scan Enum: `DAILY`, `WEEKLY`, `MONTHLY_BY_DAY_OF_WEEK`, `MONTHLY_BY_DAY_OF_MONTH` |
| `scheduled_scan_time` | string | HH:MM of the day on which to perform scheduled scan Enum: `00:00`, `01:00`, `02:00`, `03:00`, `04:00`, `05:00`, `06:00`, `07:00`, `08:00`, `09:00`, `10:00`, `11:00`, `12:00`, `13:00`, `14:00`, `15:00`, `16:00`, `17:00`, `18:00`, `19:00`, `20:00`, `21:00`, `22:00`, `23:00` |
| `scheduled_scan_week` | integer | Number of the week in month on which to perform scheduled scan Enum: `1`, `2`, `3`, `4` |
| `show_d_client_ui` | boolean | Whether to show the D-Client UI (takes effect after reboot) |
| `uninstall_password` | string | Uninstall password |
| `uninstall_password_hash` | string | Uninstall password hash |

### LinuxPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `automatic_brain_upgrade` | boolean | Whether to upgrade brain to latest. |
| `automatic_upgrade` | boolean | Whether agents should attempt to upgrade. |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `disable_password` | string | Disable password |
| `disable_password_hash` | string | Disable password hash |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `gradual_deployment` | boolean | Whether all agents should update gradually. |
| `model` | string |  |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `uninstall_password` | string | Uninstall password |
| `uninstall_password_hash` | string | Uninstall password hash |

### AndroidPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `admin_contact_name` | string | Admin contact details name |
| `admin_email` | string | Admin contact details email |
| `admin_job_title` | string | Admin contact details title |
| `admin_phone` | string | Admin contact details mobile |
| `cloud_scanning` | boolean | When scanning applications, interface with Deep Instinct servers for performance optimization |
| `detect_hosts_file_modifications` | boolean | Scan for HOSTS file modifications |
| `detect_new_certificates` | boolean | Scan for new certificates installed on device |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `disable_camera_access` | boolean | Disable camera access |
| `enable_arp_mitm_analyzer` | boolean | Whether to scan for MitM attacks that use ARP poisoning |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `enforce_storage_encryption` | boolean | Enforce storage encryption |
| `inherit_global_exceptions_list` | boolean | The ability to manage global allow lists and deny lists |
| `minimum_android_version` | string | Minimum API version allowed. NOUGAT_70_24 means Nougat, 7.0, API version 24. For use with `report_unapproved_os_versions` Enum: `KITKAT_44_19`, `LOLLIPOP_50_21`, `LOLLIPOP_51_22`, `MARSHMALLOW_60_23`, `NOUGAT_70_24` |
| `model` | string |  |
| `password_complexity_level` | string | Password complexity level Enum: `COMPLEX`, `ALPHANUMERIC` |
| `password_expiration_timeout` | string | Password expiration timeout Enum: `NO_EXPIRATION`, `ONE_MONTH`, `THREE_MONTHS`, `SIX_MONTHS` |
| `password_history_length` | integer | Password history restriction Enum: `0`, `10`, `25`, `50` |
| `password_minimum_digits_required` | integer | Minimum numerical digits letters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_length` | integer | Minimum length in characters Enum: `4`, `6`, `8`, `12` |
| `password_minimum_letters_required` | integer | Minimum letters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_lowercase_letters_required` | integer | Minimum lowercase letters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_nonletter_characters_required` | integer | Minimum non-letter characters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_symbols_required` | integer | Minimum symbols required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_uppercase_letters_required` | integer | Minimum uppercase letters required Enum: `0`, `1`, `2`, `3` |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `report_rooted_devices` | boolean | Report rooted devices |
| `report_unapproved_os_versions` | boolean | Report devices with unapproved OS versions |
| `report_unknown_sources` | boolean | Report devices with Unknown Sources enabled |
| `report_usb_debugging` | boolean | Report devices allowing ADB debugging |
| `require_device_password` | boolean | Require device password |
| `screen_inactivity_lock` | integer | Idle time in seconds before locking the screen. 0 to disable Enum: `0`, `15`, `30`, `60`, `120`, `300`, `600` |

### IOSPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `admin_contact_name` | string | Admin contact details name |
| `admin_email` | string | Admin contact details email |
| `admin_phone` | string | Admin contact details mobile |
| `minimum_ios_version` | string | Minimum iOS version Enum: `11.0.0`, `11.0.1`, `11.0.2`, `11.0.3`, `11.1.0`, `11.1.1`, `11.1.2`, `11.2.0`, `11.2.1`, `11.2.2`, `11.2.5`, `11.2.6`, `11.3.0`, `11.3.1`, `11.4.0`, `11.4.1`, `12.0.0`, `12.0.1`, `12.1.0`, `12.1.1`, `12.1.2`, `12.1.3`, `12.1.4`, `12.2.0`, `12.3.0`, `12.3.1`, `12.3.2`, `12.4.0`, `13.0.0` |
| `model` | string |  |
| `report_jailbroken_devices` | boolean | Whether to report jailbroken devices |
| `report_unapproved_os_version` | boolean | Report devices with unapproved OS versions |

### ChromeOSPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `admin_contact_name` | string | Admin contact details name |
| `admin_email` | string | Admin contact details email |
| `admin_job_title` | string | Admin contact details title |
| `admin_phone` | string | Admin contact details mobile |
| `cloud_scanning` | boolean | When scanning applications, interface with Deep Instinct servers for performance optimization |
| `detect_hosts_file_modifications` | boolean | Scan for HOSTS file modifications |
| `detect_new_certificates` | boolean | Scan for new certificates installed on device |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `disable_camera_access` | boolean | Disable camera access |
| `enable_arp_mitm_analyzer` | boolean | Whether to scan for MitM attacks that use ARP poisoning |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `enforce_storage_encryption` | boolean | Enforce storage encryption |
| `inherit_global_exceptions_list` | boolean | The ability to manage global allow lists and deny lists |
| `model` | string |  |
| `password_complexity_level` | string | Password complexity level Enum: `COMPLEX`, `ALPHANUMERIC` |
| `password_expiration_timeout` | string | Password expiration timeout Enum: `NO_EXPIRATION`, `ONE_MONTH`, `THREE_MONTHS`, `SIX_MONTHS` |
| `password_history_length` | integer | Password history restriction Enum: `0`, `10`, `25`, `50` |
| `password_minimum_digits_required` | integer | Minimum numerical digits letters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_length` | integer | Minimum length in characters Enum: `4`, `6`, `8`, `12` |
| `password_minimum_letters_required` | integer | Minimum letters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_lowercase_letters_required` | integer | Minimum lowercase letters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_nonletter_characters_required` | integer | Minimum non-letter characters required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_symbols_required` | integer | Minimum symbols required Enum: `0`, `1`, `2`, `3` |
| `password_minimum_uppercase_letters_required` | integer | Minimum uppercase letters required Enum: `0`, `1`, `2`, `3` |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `report_rooted_devices` | boolean | Report rooted devices |
| `report_unapproved_os_versions` | boolean | Report devices with unapproved OS versions |
| `report_unknown_sources` | boolean | Report devices with Unknown Sources enabled |
| `report_usb_debugging` | boolean | Report devices allowing ADB debugging |
| `require_device_password` | boolean | Require device password |
| `screen_inactivity_lock` | integer | Idle time in seconds before locking the screen. 0 to disable Enum: `0`, `15`, `30`, `60`, `120`, `300`, `600` |

### WindowsNASPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `agent_user_interface_show_notifications` | boolean | Whether agent user interface show notifications. |
| `automatic_upgrade` | boolean | Whether agents should attempt to upgrade. |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `disable_password` | string | Disable password |
| `disable_password_hash` | string | Disable password hash |
| `dual_use` | string | Dual Use protection level Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `embedded_dde_object_in_office_document` | string | Embedded DDE object in Microsoft Office document. Enum: `ALLOW`, `PREVENT` |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `file_type_config_excel` | string | Level at which Excel files will be prevented Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `file_type_config_office` | string | Level at which Office files will be prevented Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `file_type_config_office_macro` | string | Level at which Office Macro files will be prevented Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `file_type_config_pdf` | string | Level at which PDF files will be prevented Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `file_type_config_pe` | string | Level at which PE files will be prevented Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `file_type_config_word` | string | Level at which Word files will be prevented Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `hide_d_client_ui` | boolean | Whether to show the D-Client UI (takes effect after reboot) |
| `model` | string |  |
| `prevention_action` | string | Quarantine or Delete Enum: `QUARANTINE`, `DELETE` |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `protection_level_pua` | string | Known PUA protection level Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `quarantine_folder_path` | string | The quarantine folder path. |
| `quarantine_folder_size_limit_in_gb` | integer | Quarantine Folder Size Limit. |
| `scan_log_file_size_limit_in_mb` | integer | Single scan log file size limit in mb. |
| `scan_log_folder_path` | string | The logs folder path. |
| `scan_network_drives` | boolean | Whether to scan files on network drives |
| `should_generate_scan_logs` | boolean | Turn the logging capability attribute on/off. |
| `single_file_scanning_timeout_in_seconds` | integer | Sets the time in seconds after which the Storage Agent stops scanning a file if scanning attempts fail. |
| `single_file_size_limit_in_mb` | integer | Files exceeding the max. defined limit are not scanned. |
| `uninstall_password` | string | Uninstall password |
| `uninstall_password_hash` | string | Uninstall password hash |

### Request/Response Models

### PolicyDataEnvelope

| Field | Type | Description |
|-------|------|-------------|
| `data` | `PolicyData` |  |

### Policy

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for this policy |
| `name` * | string | Policy name |

\* = required field

### PolicyCreateRequest

Extends: `Policy`

| Field | Type | Description |
|-------|------|-------------|
| `base_policy_id` | integer | Policy ID on which to base this policy. |

### PolicyReadModel

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for this policy |
| `id` | integer |  |
| `is_default_policy` | boolean | Whether the policy is a default group or a custom policy. |
| `msp_id` | integer | MSP ID to which this policy belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this group belongs to. Value only relevant in multitenancy configuration. |
| `name` * | string | Policy name |
| `os` | string | OS the policy is relevant for. Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `LINUX`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY` |

\* = required field

### DeviceGroupCreationModel

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for the group. |
| `msp_id` | integer | MSP ID to which this group belongs to. Ignored if not used by a multitenancy hub API connector. |
| `name` * | string | Name of the group |
| `policy_id` * | integer | Policy in use by this group. |
| `rules` | array\<object\> |  |

\* = required field

### DeviceGroupEditModel

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | Comment for the group. |
| `name` | string | Name of the group |
| `policy_id` | integer | Policy in use by this group. |
| `priority` | integer | Group's priority used in rule calculation. |

### DeviceGroupRulesEdit

| Field | Type | Description |
|-------|------|-------------|
| `rules` * | array\<object\> |  |

\* = required field

### DeviceGroupDeviceList

| Field | Type | Description |
|-------|------|-------------|
| `devices` * | array\<integer\> |  |

\* = required field

### MSPCreationModel

| Field | Type | Description |
|-------|------|-------------|
| `disable_password` | string |  |
| `license_limit` | integer | Maximum number of license for this MSP |
| `name` | string | Name of the MSP |
| `uninstall_password` | string |  |

### MSPUpdateModel

| Field | Type | Description |
|-------|------|-------------|
| `license_limit` | integer | Maximum number of license for this MSP |
| `name` | string | Name of the MSP |

### MSPModel

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | MSP ID |
| `license_limit` | integer | Maximum number of license for this MSP |
| `name` | string | Name of the MSP |

### MSPListModel

| Field | Type | Description |
|-------|------|-------------|
| `last_id` | integer |  |
| `msps` | array\<`MSPModel`\> |  |

### TenantModel

| Field | Type | Description |
|-------|------|-------------|
| `endpoint_installation_token` | string | Endpoint installation token used to register a new endpoint device to this tenant |
| `id` | integer | Tenant ID |
| `license_limit` | integer | Maximum number of license for this MSP |
| `mobile_installation_token` | string | Mobile installation token is used to register a new mobile device to this tenant |
| `msp_id` | integer | MSP ID |
| `name` | string | Name of the Tenant |

### TenantCreationModel

| Field | Type | Description |
|-------|------|-------------|
| `license_limit` | integer | Maximum number of license for this Tenant |
| `msp_id` | integer | ID of the MSP this Tenant belongs to |
| `name` | string | Name of the Tenant |

### AuditLogEntry

| Field | Type | Description |
|-------|------|-------------|
| `access_type` * | object | Type of access |
| `category` * | string | Event category Enum: `LOGIN`, `FAILED_LOGIN`, `LOGOUT`, `COMMENT`, `ADMINISTRATOR_MANAGEMENT`, `POLICY`, `ALLOW_LIST_DENY_LIST`, `GROUP`, `SYSTEM_SETTINGS`, `DEPLOYMENT`, `SYSTEM_REPORT_SEEN`, `SANDBOX_REPORT`, `REMEDIATION`, `SERVER_TLS_CERTIFICATE`, `REPORTING`, `DEVICE_TAG_MODIFIED`, `SCANNER_MANAGEMENT`, `PROTECTED_ENTITY_MANAGEMENT`, `PROTECTED_STORAGE_MANAGEMENT`, `DIANNA`, `STORAGE_AGENT_MODIFICATION` |
| `description` * | string | Log description |
| `id` * | integer | Audit log ID |
| `msp_id` | integer | MSP ID |
| `resource` * | object | Affected resource name |
| `source` * | object | Source (GUI or API) |
| `success` * | object | Success or failure of the event |
| `timestamp` * | string (date-time) | Date and time of event (ISO8601 formatted) |
| `type` * | object | Event type |
| `user_id` * | string | User ID of account performing the action |

\* = required field

### IdsList

| Field | Type | Description |
|-------|------|-------------|
| `ids` * | array\<integer\> |  |

\* = required field

### DeviceComment

| Field | Type | Description |
|-------|------|-------------|
| `comment` * | string | Comment for this device |

\* = required field

### DeviceTag

| Field | Type | Description |
|-------|------|-------------|
| `tag` * | string | tag for this device |

\* = required field

### ListItemInfo

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User comment |

### ListItemInfoModel

Extends: `ListItemInfo`

| Field | Type | Description |
|-------|------|-------------|
| `item` | string | The identifier for the item. Can be a hash, path, certificate thumbprint, etc. depending on context. |

### ListItemStringTestDataModel

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ListItemInfoModel`\> |  |

\* = required field

### ListStringDeleteItem

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`StringDeleteItem`\> |  |

\* = required field

### StringDeleteItem

| Field | Type | Description |
|-------|------|-------------|
| `item` * | string | The identifier for the item. Can be a hash, path, certificate thumbprint, etc. depending on context |

\* = required field

### ListIdItem

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`IdItem`\> |  |

\* = required field

### IdItem

| Field | Type | Description |
|-------|------|-------------|
| `id` * | integer | The id of the object |

\* = required field

### ListItemBehavioralAnalysisDataModel

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemBehavioralAnalysisDataModel`\> |  |

\* = required field

### ItemBehavioralAnalysisDataModel

Extends: `ItemBehavioralAnalysisData`

| Field | Type | Description |
|-------|------|-------------|
| `item` | string | The identifier for the item. Can be a hash, path, certificate thumbprint, etc. depending on context. |

### ItemBehavioralAnalysisData

| Field | Type | Description |
|-------|------|-------------|
| `behavior_ids` | array\<integer\> |  |
| `comment` | string | User comment |

### ListItemAdvancedBehavioralAnalysisDataModel

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemAdvancedBehavioralAnalysisDataModel`\> |  |

\* = required field

### ItemAdvancedBehavioralAnalysisDataModel

Extends: `ItemBehavioralAnalysisData`

| Field | Type | Description |
|-------|------|-------------|
| `grandparent_process_name` | string | Grandparent process name. |
| `group_name` | string | Group name |
| `id` | integer | Record id |
| `parent_process_name` | string | Parent process name. |
| `process` | string | The process name |
| `process_certificate` | string | The process certificate. |
| `process_parameters` | string | The process parameters |
| `user_name` | string | User name |

### ListItemDeleteScriptDataModel

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemScriptDataModel`\> |  |

\* = required field

### ItemScriptDataModel

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User's comment |
| `item` * | string | the item |
| `type` | string | item's type (path or command)[default - PATH]. Enum: `PATH`, `COMMAND` |

\* = required field

### RequestCreateMspApiConnector

| Field | Type | Description |
|-------|------|-------------|
| `msp_id` * | integer / null | For specific msp provide the msp id, use "null" for all msps. |
| `name` * | string |  |
| `permission` * | string | Enum: `READ_ONLY`, `READ_AND_REMEDIATION`, `FULL_ACCESS`, `ACCOUNT_ADMIN` |

\* = required field

### RequestCreateTenantApiConnector

| Field | Type | Description |
|-------|------|-------------|
| `msp_id` * | integer |  |
| `name` * | string |  |
| `permission` * | string | Enum: `READ_ONLY`, `READ_AND_REMEDIATION`, `FULL_ACCESS`, `ACCOUNT_ADMIN` |
| `tenants_ids` * | array\<integer\> | For specific tenants provide the tenants ids, use "[]" for all tenants. |

\* = required field

### ResponseCreateMspApiConnector

| Field | Type | Description |
|-------|------|-------------|
| `api_key` * | string |  |
| `id` * | integer |  |
| `last_updated` | string (date-time) |  |
| `msp` |  | The requested msp basic information. Can be "null" when no "msp_id" is specified. |
| `name` * | string |  |
| `permission` * | string | Enum: `READ_ONLY`, `READ_AND_REMEDIATION`, `FULL_ACCESS`, `ACCOUNT_ADMIN` |

\* = required field

### ResponseCreateTenantApiConnector

| Field | Type | Description |
|-------|------|-------------|
| `api_key` * | string |  |
| `id` * | integer |  |
| `last_updated` | string (date-time) |  |
| `msp` |  | The requested msp basic information. |
| `name` * | string |  |
| `permission` * | string | Enum: `READ_ONLY`, `READ_AND_REMEDIATION`, `FULL_ACCESS`, `ACCOUNT_ADMIN` |
| `tenants` | array\<any\> |  |

\* = required field

### Search Filter Models

### DeviceSearch

| Field | Type | Description |
|-------|------|-------------|
| `advertisement_id` | string | Advertisement ID of the device. |
| `agent_version` | string | Agent version |
| `brain_version` | string | Brain version |
| `comment` | string | Comment for this device |
| `connectivity_status` | array\<string\> |  |
| `deployment_status` | array\<string\> |  |
| `deployment_status_last_update` |  | Device deployment status last update. |
| `distinguished_name` | string | Distinguished device name |
| `domain` | string | Device's ActiveDirectory domain |
| `full_scan_in_progress` | boolean | Is full scan in progress |
| `group_id` | integer | Group ID that the device belongs to |
| `group_name` | string | Group that the device belongs to |
| `hostname` | string | Device's hostname |
| `id` | integer | Device ID |
| `ip_address` | string | Device's primary IP address |
| `last_contact` |  | Timestamp of last contact with device |
| `last_full_scan_end_timestamp` |  | Timestamp of last full scan |
| `last_registration` |  | Time this device last register. |
| `license_status` | array\<string\> |  |
| `log_status` | array\<string\> |  |
| `logged_in_users` | string | Comma-separated list of logged-in users |
| `mac_address` | string | Device's primary MAC address |
| `mobile_id` | string | Mobile ID of the device |
| `msp_id` | integer | MSP ID to which this device belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this device belongs to. Value only relevant in multitenancy configuration. |
| `os` | array\<string\> |  |
| `osv` | string | Operating system version |
| `policy_id` | integer | Policy ID that the device is using |
| `policy_name` | string | Policy that the device is using |
| `tag` | string | Deployment tag for this device |
| `tenant_id` | integer | Tenant ID to which this device belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this device belongs to. Value only relevant in multitenancy configuration. |

### EventSearch

| Field | Type | Description |
|-------|------|-------------|
| `action` | array\<string\> |  |
| `close_timestamp` |  | Time the event was closed |
| `close_trigger` | array\<string\> |  |
| `comment` | string | Comment on this event |
| `container_hash` | string | Container Hash aka Archive Hash. |
| `device_id` | integer | ID of the device from which this event originated. |
| `file_hash` | string | Hash of the file which caused the event |
| `file_size` | integer | File size in bytes |
| `file_status` | array\<string\> |  |
| `file_type` | array\<string\> |  |
| `id` | integer | Event ID |
| `insertion_timestamp` |  | Time the event was received and saved by the server |
| `last_action` | array\<string\> |  |
| `last_occurrence` |  | Time this event last occurred. |
| `last_reoccurrence` |  | Time the last re-occurrence occurred. |
| `msp_id` | integer | MSP ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this event belongs to. Value only relevant in multitenancy configuration. |
| `path` | string | Full path of the file, if applicable |
| `reoccurrence_count` | integer | Amount of re-occurrences of events with this same hash, type and device ID. |
| `sandbox_status` | array\<string\> |  |
| `script_command` | string | Script command |
| `status` | array\<string\> |  |
| `target_file` | string | File to be encrypted |
| `target_process_path` | string | Path of the target process |
| `tenant_id` | integer | Tenant ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this event belongs to. Value only relevant in multitenancy configuration. |
| `threat_severity` | array\<string\> |  |
| `threat_type` | array\<string\> |  |
| `timestamp` |  | Time the event took place (on the device) |
| `trigger` | array\<string\> |  |
| `type` | array\<string\> |  |

### SuspiciousEventSearch

| Field | Type | Description |
|-------|------|-------------|
| `action` | array\<string\> |  |
| `close_timestamp` |  | Time the event was closed |
| `close_trigger` | array\<string\> |  |
| `comment` | string | Comment on this event |
| `destination_ip` | string |  |
| `device_id` | integer | ID of the device from which this event originated. |
| `file_hash` | string | Hash of the file which caused the event |
| `file_path` | string |  |
| `file_status` | array\<string\> |  |
| `file_type` | array\<string\> |  |
| `id` | integer | Event ID |
| `insertion_timestamp` |  | Time the event was received and saved by the server |
| `is_administrator` | boolean |  |
| `last_action` | array\<string\> |  |
| `last_occurrence` |  | Time this event last occurred. |
| `logon_type` | array\<string\> |  |
| `msp_id` | integer | MSP ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `msp_name` | string | MSP which this event belongs to. Value only relevant in multitenancy configuration. |
| `path` | string | Full path of the file, if applicable |
| `process_command_line` | string |  |
| `process_file_sha256` | string |  |
| `process_name` | string |  |
| `process_path` | string |  |
| `remediation` | array\<string\> |  |
| `remote_device_name` | string |  |
| `remote_ip` | string |  |
| `reoccurrence_count` | integer | Amount of re-occurrences of events with this same hash, type and device ID. |
| `rule_trigger` | array\<string\> |  |
| `service_account_name` | string |  |
| `service_file_name` | string |  |
| `service_name` | string |  |
| `status` | array\<string\> |  |
| `tenant_id` | integer | Tenant ID to which this event belongs to. Ignored if not used by a multitenancy hub API connector. |
| `tenant_name` | string | Tenant which this event belongs to. Value only relevant in multitenancy configuration. |
| `threat_severity` | array\<string\> |  |
| `threat_type` | array\<string\> |  |
| `timestamp` |  | Time the event took place (on the device) |
| `trigger` | array\<string\> |  |
| `type` | array\<string\> |  |
| `username` | string |  |

### List/Envelope Models

### Other Models

### AgentVersionBaseModel

| Field | Type | Description |
|-------|------|-------------|
| `os` * | string | Installation file for this OS Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `WINDOWS_SERVER`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `RED_HAT`, `CENTOS`, `UBUNTU`, `RED_HAT8`, `AMAZON_LINUX_2`, `ORACLE_LINUX`, `AMAZON_LINUX_3`, `SUSE_12`, `SUSE_15`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY`, `RED_HAT9` |
| `version` * | string | Agent version |

\* = required field

### AgentVersionModel

| Field | Type | Description |
|-------|------|-------------|
| `createdDate` | integer | last update timestamp |
| `description` | string | version description |
| `installationFileName` | string | Installer file name |
| `os` * | string | Installation file for this OS Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `WINDOWS_SERVER`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `RED_HAT`, `CENTOS`, `UBUNTU`, `RED_HAT8`, `AMAZON_LINUX_2`, `ORACLE_LINUX`, `AMAZON_LINUX_3`, `SUSE_12`, `SUSE_15`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY`, `RED_HAT9` |
| `version` * | string | Agent version |

\* = required field

### ApplicationSecurityPolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `action_on_prevented_files` | string | Action to perform when preventing a file Enum: `PREVENT_ONLY`, `DELETE_AND_QUARANTINE` |
| `activescript_action` | string | Action to take upon ActiveScript script usage (JavaScript, VBScript) Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `detection_level` | string | Level at which files will be detected Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `disable_password_hash` | string | Disable password hash |
| `enable_dcloud_services` | boolean | Enable D-Cloud services. |
| `enable_scheduled_scan` | boolean | Whether to enable scheduled scanning |
| `hide_d_client_ui` | boolean | Whether to show the D-Client UI (takes effect after reboot) |
| `html_applications_action` | string | Action to take upon HTA script usage Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `model` | string |  |
| `non_compliant_file_action` | string | Non compliant file action Enum: `BENIGN`, `MALICIOUS` |
| `office_macro_script_action` | string | Action to take upon Office Macro script usage Enum: `USE_D_BRAIN`, `ALWAYS_PREVENT`, `ALLOW_ALL_MACROS` |
| `powershell_script_action` | string | Action to take upon a malicious PowerShell script usage Enum: `ALLOW`, `DETECT`, `PREVENT` |
| `prevent_all_activescript_usage` | string | Whether to completely prevent all ActiveScript usage Enum: `ALLOW`, `PREVENT` |
| `prevention_level` | string | Level at which files will be prevented Enum: `DISABLED`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH` |
| `scan_network_drives` | boolean | Whether to scan files on network drives |
| `scheduled_scan_day` | string | Day of the week on which to perform scheduled scan Enum: `SUNDAY`, `MONDAY`, `TUESDAY`, `WEDNESDAY`, `THURSDAY`, `FRIDAY`, `SATURDAY` |
| `scheduled_scan_time` | string | HH:MM of the day on which to perform scheduled scan Enum: `00:00`, `01:00`, `02:00`, `03:00`, `04:00`, `05:00`, `06:00`, `07:00`, `08:00`, `09:00`, `10:00`, `11:00`, `12:00`, `13:00`, `14:00`, `15:00`, `16:00`, `17:00`, `18:00`, `19:00`, `20:00`, `21:00`, `22:00`, `23:00` |
| `uninstall_password_hash` | string | Uninstall password hash |
| `unscanned_file_action` | string | Unscanned file action Enum: `BENIGN`, `MALICIOUS` |

### ArmedRpmStatusModel

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Current status of the requested rpm to arm Enum: `PENDING`, `GENERATING`, `CREATED`, `FAILED`, `EXPIRED` |

### ArmingRpmAgentVersionModel

| Field | Type | Description |
|-------|------|-------------|
| `agentVersionId` | integer | Agent version id |
| `createdDate` | integer | last update timestamp |
| `description` | string | version description |
| `os` * | string | Installation file for this OS Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `WINDOWS_SERVER`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `RED_HAT`, `CENTOS`, `UBUNTU`, `RED_HAT8`, `AMAZON_LINUX_2`, `ORACLE_LINUX`, `AMAZON_LINUX_3`, `SUSE_12`, `SUSE_15`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY`, `RED_HAT9` |
| `version` * | string | Agent version |

\* = required field

### CloudStoragePolicyData

Extends: `PolicyData`

| Field | Type | Description |
|-------|------|-------------|
| `archive_size_limit` | integer | Archive size limit |
| `d_cloud_connection_timeout` | integer | D Cloud connection timeout |
| `d_cloud_services` | boolean | D Cloud Services |
| `known_pua` | boolean | Known PUA protection level |
| `malicious_file_action` | string | Malicious file action Enum: `DETECT`, `PREVENT_AND_QUARANTINE`, `PREVENT_AND_DELETE` |
| `model` | string |  |
| `nesting_limit` | integer | Nesting limit |
| `non_compliant_file_action` | string | Non compliant file action Enum: `BENIGN`, `MALICIOUS` |
| `scan_dde` | boolean | Scan DDE |
| `single_file_size_limit` | integer | Single file size limit |
| `unscanned_file_action` | string | Unscanned file action Enum: `BENIGN`, `MALICIOUS` |

### CreateArmedRpmModel

| Field | Type | Description |
|-------|------|-------------|
| `abort_if_no_server_connection` | boolean | Check connectivity pre installation |
| `agent_disabled_after_installation` | boolean | Agent disabled after installation  |
| `agent_version_id` * | integer | Agent version id |
| `extraction_path` | string | Installer extraction folder  |
| `manual_proxy` |  | Proxy configuration |
| `no_initial_full_scan` | boolean | No initial full scan after installation  |
| `randomize_initial_full_scan` | integer / null | Randomize initial Full-scan. It's relevant only if no_initial_full_scan is False, otherwise this value has to be None or not exists in the request body at all. |
| `tag` | string | Device Tag |
| `tenant_id` * | integer | Tenant |

\* = required field

### DateRangeFilter

| Field | Type | Description |
|-------|------|-------------|
| `from` | string (date-time) | Beginning of the range |
| `to` | string (date-time) | End of the range |

### DeleteScriptDataModel

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | item's type (path or command)[default - PATH]. Enum: `PATH`, `COMMAND` |

### DeviceGroupCreation

Extends: `DeviceGroupCreationModel`

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer |  |
| `is_default_group` | boolean | Whether the group is a default group or a custom group. |
| `os` | string | OS the group is relevant for. Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `LINUX`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY` |
| `priority` | integer | Group's priority used in rule calculation. |

### FileDetails

| Field | Type | Description |
|-------|------|-------------|
| `affected_device_count` | integer | Affected device count |
| `certificate_thumbprint` | string | Thumbprint of the certificate that signs this file, if the file is signed |
| `certificate_vendor_name` | string | Vendor that owns the certificate that signs this file, if the file is signed |
| `event_actions` | array\<string\> |  |
| `event_count` | integer | Count of open events for this file |
| `file_hash` | string | Hash of the file which caused the event. |
| `file_size` | integer | File size in bytes |
| `file_status` | string | Whether the file was uploaded Enum: `UPLOADED`, `NOT_UPLOADED`, `NA` |
| `file_type` | string | Enum: `OTHER`, `PE`, `EXE`, `DLL`, `PDF`, `OFFICE`, `PPT`, `XLS`, `DOC`, `ZIP`, `RAR`, `VBA`, `RTF`, `TTF`, `TIFF`, `SCRIPT`, `EICAR`, `APK`, `IPA`, `NA`, `JAR`, `SWF`, `POWERSHELL`, `POWERSHELL_INTERACTIVE`, `ACTIVE_SCRIPT`, `HTML_APPLICATION`, `SEVEN_Z`, `MACHO`, `XAR`, `TAR`, `DMG`, `OTF`, `OOXML`, `PE64`, `PE32`, `ELF`, `SO`, `O`, `KO`, `LNK`, `JAVASCRIPT`, `MSG`, `EML`, `GZIP`, `BZIP2`, `ISO`, `HTML`, `MSI`, `UNSUPPORTED_ELF`, `AR`, `XZ`, `CSV` |
| `first_seen_date` | string (date-time) | Date file was first seen |
| `last_seen_date` | string (date-time) | Date file was last seen |
| `paths` | array\<string\> |  |
| `platforms` | array\<string\> |  |
| `sandbox_status` | string | Whether a sandbox report was created, is ready for creation, cannot be created, or failed creation. Enum: `IN_PROGRESS`, `FAILED`, `REPORT_CREATED`, `NOT_READY_TO_GENERATE`, `READY_TO_GENERATE` |
| `threat_type` | string | The threat type with the highest probability. Enum: `DUAL_USE_DUAL_USE_TOOL`, `DUAL_USE_REMOTE_ADMIN_TOOL`, `DUAL_USE_MONITORING_TOOL`, `DUAL_USE_INVESTIGATION_TOOL`, `DUAL_USE_SSH_TOOL`, `DUAL_USE_DISK_ENCRYPTION_TOOL`, `DUAL_USE_FILE_SHARING_TOOL`, `DUAL_USE_NETWORK_TOOL`, `DUAL_USE_PASSWORD_TOOL`, `DUAL_USE_SYSTEM_MODIFICATION_TOOL`, `DUAL_USE_HARDWARE_MODIFICATION_TOOL`, `DUAL_USE_SCRIPTING_TOOL`, `PUA_GENERIC_PUA`, `PUA_MINER_PUA`, `PUA_RISKWARE_HACKTOOL`, `PUA_FAKEAPP`, `PUA_TOOLBAR`, `PUA_DOWNLOADER`, `PUA_ADWARE`, `PUA_GAMING`, `PUA_GENERIC`, `MALWARE_TROJAN`, `MALWARE_BACKDOOR`, `MALWARE_RANSOMWARE`, `MALWARE_DROPPER`, `MALWARE_SPYWARE`, `MALWARE_VIRUS`, `MALWARE_WORM`, `MALWARE_MINER_MALWARE` |

### IsolatedConnection

| Field | Type | Description |
|-------|------|-------------|
| `ip` * | string | IP Address |
| `port` * | string | Port Number |
| `type` * | string | Connection Type Enum: `INCOMING`, `OUTGOING` |

\* = required field

### ListItemScriptDataModel

| Field | Type | Description |
|-------|------|-------------|
| `items` * | array\<`ItemScriptDataModel`\> |  |

\* = required field

### MitreClassifications

| Field | Type | Description |
|-------|------|-------------|
| `mitre_id` | string | MITRE ID |
| `sub_technique_id` | string | Sub Technique id for this rule |
| `sub_technique_name` | string | Sub Technique name for this rule |
| `tactic_id` | string | Tactic Id for this rule |
| `tactic_name` | string | Tactic name for this rule |
| `technique_id` | string | Technique id for this rule |
| `technique_name` | string | Technique name for this rule |

### ProcessTreeEntryModel

| Field | Type | Description |
|-------|------|-------------|
| `command` | string | Command that was executed |
| `executing_user` | string | User that was executing the process |
| `parent_id` | integer | Parent process id |
| `process_id` | integer | Process id |
| `process_name` | string | Process name |
| `process_start_time` | string (date-time) | The time process was started |
| `process_stop_time` | string (date-time) | The time process was stopped |

### ProxyPathModel

| Field | Type | Description |
|-------|------|-------------|
| `port` * | integer | Proxy server port. [1-65536] |
| `url` * | string | Proxy server ip address |

\* = required field

### RecordedDeviceData

| Field | Type | Description |
|-------|------|-------------|
| `agent_version` | string | Agent version |
| `brain_version` | string | Brain version |
| `distinguished_name` | string | Device's LDAP distinguished name, if available |
| `domain` | string | Device's ActiveDirectory domain |
| `hostname` | string | Device's hostname |
| `ip_address` | string | Device's primary IP address |
| `logged_in_users` | string | Comma-separated list of logged-in users |
| `mac_address` | string | Device's primary MAC address |
| `os` | string | Operating system Enum: `NA`, `ANDROID`, `IOS`, `WINDOWS`, `WINDOWS_SERVER`, `MAC`, `CHROME`, `NETWORK_AGENTLESS`, `RED_HAT`, `CENTOS`, `UBUNTU`, `RED_HAT8`, `AMAZON_LINUX_2`, `ORACLE_LINUX`, `AMAZON_LINUX_3`, `SUSE_12`, `SUSE_15`, `WINDOWS_NAS`, `CLOUD_STORAGE_SECURITY`, `RED_HAT9` |
| `osv` | string | Operating system version |
| `policy_id` | integer | Policy ID that the device is using |

### ScheduledRpmData

| Field | Type | Description |
|-------|------|-------------|
| `armed_rpm_id` | integer | Id of scheduled RPM to arm |

### ScriptDataModel

| Field | Type | Description |
|-------|------|-------------|
| `comment` | string | User's comment |
| `type` | string | item's type (path or command)[default - PATH]. Enum: `PATH`, `COMMAND` |

### SingleEvent

| Field | Type | Description |
|-------|------|-------------|
| `event` | `MaliciousEvent` |  |

### SingleSuspiciousEvent

| Field | Type | Description |
|-------|------|-------------|
| `event` * | `SuspiciousEvent` |  |

\* = required field

### TenantListModel

| Field | Type | Description |
|-------|------|-------------|
| `last_id` | integer |  |
| `tenants` | array\<`TenantModel`\> |  |

### TenantTokenListModel

| Field | Type | Description |
|-------|------|-------------|
| `last_id` | integer |  |
| `tenantTokens` | array\<`TenantTokenModel`\> |  |

### TenantTokenModel

| Field | Type | Description |
|-------|------|-------------|
| `endpoint_installation_token` | string | Endpoint installation token used to register a new endpoint device to this tenant |
| `id` | integer | Tenant ID |
| `mobile_installation_token` | string | Mobile installation token is used to register a new mobile device to this tenant |
| `msp_id` | integer | MSP ID |
| `name` | string | Name of the Tenant |

### TenantUpdateModel

| Field | Type | Description |
|-------|------|-------------|
| `license_limit` | integer | Maximum number of license for this Tenant |
| `name` | string | Name of the Tenant |

### UserBaseModel

| Field | Type | Description |
|-------|------|-------------|
| `email` * | string |  |
| `first_name` * | string | User's first name |
| `last_name` * | string | User's last name |

\* = required field

### UserReadModel

Extends: `UserBaseModel`

| Field | Type | Description |
|-------|------|-------------|
| `auth_type` | string | Enum: `LOCAL`, `ACTIVEDIRECTORY`, `SSO_ONLY` |
| `enable_sso_for_local_auth_type` | boolean |  |
| `id` | integer |  |
| `last_login` | string (date-time) | Last login timestamp |
| `msp_id` | integer | MSP ID to which the user belongs to |
| `role` | string | Enum: `MASTER_ADMINISTRATOR`, `ADMINISTRATOR`, `READ_ONLY`, `IT_ADMIN`, `SOC_ADMIN`, `HUB_ADMIN`, `TENANT_VIEWER`, `ACCOUNT_ADMINISTRATOR` |
| `tenant_id` | integer | Tenant ID to which the user belongs to |
| `username` | string |  |

### UserUpdateModel

| Field | Type | Description |
|-------|------|-------------|
| `auth_type` | string | Enum: `LOCAL`, `ACTIVEDIRECTORY`, `SSO_ONLY` |
| `email` | string |  |
| `enable_sso_for_local_auth_type` | boolean |  |
| `first_name` | string | User's first name |
| `last_name` | string | User's last name |
| `password` | string |  |
| `role` | string | Enum: `MASTER_ADMINISTRATOR`, `ADMINISTRATOR`, `READ_ONLY`, `IT_ADMIN`, `SOC_ADMIN`, `HUB_ADMIN`, `TENANT_VIEWER`, `ACCOUNT_ADMINISTRATOR` |

### UsersCreationModel

Extends: `UserBaseModel`

| Field | Type | Description |
|-------|------|-------------|
| `auth_type` | string | Enum: `LOCAL`, `ACTIVEDIRECTORY`, `SSO_ONLY` |
| `enable_sso_for_local_auth_type` | boolean |  |
| `msp_id` | integer | MSP ID to which the new user belongs to. Relevant only for hub account admins |
| `password` | string |  |
| `role` | string | Enum: `MASTER_ADMINISTRATOR`, `ADMINISTRATOR`, `READ_ONLY`, `IT_ADMIN`, `SOC_ADMIN`, `HUB_ADMIN`, `TENANT_VIEWER`, `ACCOUNT_ADMINISTRATOR` |
| `tenant_id` | integer | Tenant ID to which the new user belongs to. Relevant only for MSP account admins creating a Tenant Viewer |
| `username` | string |  |

### msp

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer |  |
| `name` | string |  |

### tenants

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer |  |
| `name` | string |  |
