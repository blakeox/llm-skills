# MSP360 Backup Management API Reference

> Scraped from https://api.mspbackups.com/Help on 2026-03-08

## Practical Notes

- **Auth**: POST `/api/Provider/Login` returns a token. Use as `Authorization: Bearer {token}` on all subsequent calls.
- **Base URL**: `https://api.mspbackups.com/api`
- **API docs**: https://api.mspbackups.com/Help
- The API is hosted on **IIS/ASP.NET** (Windows stack)
- **403 on login** may indicate IP restriction or API access not enabled in the MSP360 web console
- **ICCI credentials**: provided at session start (not stored on disk)
- This is the **MSP360 backup management API** -- separate from the Deep Instinct API
- **MSP360** was formerly **CloudBerry Lab**
- The same company (MSP360) hosts the Deep Instinct MSP console at `msp360.customers.deepinstinctweb.com`
- All endpoints accept and return `application/json` (also support XML and form-encoded where noted)
- GUIDs are used extensively for IDs (users, companies, licenses, destinations, accounts, administrators)
- Sizes are typically in **KB** (SpaceUsed) or **bytes** (Monitoring/Billing data fields) unless noted otherwise
- Storage limits in Packages are in **GB**

---

## Table of Contents

1. [Provider (Authentication)](#1-provider-authentication)
2. [Users](#2-users)
3. [Companies](#3-companies)
4. [Packages](#4-packages)
5. [Licenses](#5-licenses)
6. [Destinations](#6-destinations)
7. [Accounts (Storage)](#7-accounts-storage)
8. [Computers (Endpoints)](#8-computers-endpoints)
9. [Monitoring](#9-monitoring)
10. [Billing](#10-billing)
11. [Administrators](#11-administrators)
12. [Builds](#12-builds)
13. [CloudBackup](#13-cloudbackup)

---

## 1. Provider (Authentication)

### POST /api/Provider/Login

Retrieves API authentication information. The authentication parameters are provided to the customer.

**Request Body** (`ProviderLoginModel`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| UserName | string | Yes | Login parameter |
| Password | string | Yes | Length: 3-100 characters |

```json
{
  "UserName": "admin@example.com",
  "Password": "secretpassword"
}
```

**Response**: Returns an access token string. Use as `Authorization: Bearer {token}` header on all subsequent requests.

---

## 2. Users

### GET /api/Users

Retrieves a list of all users.

**Parameters**: None

**Response** (array of `UsersModels`):

| Field | Type | Description |
|-------|------|-------------|
| ID | string (GUID) | User unique identifier |
| Email | string | User login (email) |
| FirstName | string | First name |
| LastName | string | Last name |
| NotificationEmails | string[] | Notification email addresses |
| Company | string | Company name |
| Enabled | boolean | Account enabled status |
| LicenseManagmentMode | integer (UserModeType) | License management mode |
| DestinationList | UserDestinationsModel[] | Backup destinations (see below) |
| SpaceUsed | integer | Space used in KB |

**UserDestinationsModel**:

| Field | Type |
|-------|------|
| ID | string (GUID) |
| CurrentVolume | integer |
| PackageID | integer |
| AccountID | string (GUID) |
| AccountDisplayName | string |
| Destination | string |
| DestinationDisplayName | string |

---

### GET /api/Users/{id}

Retrieves user metadata by user ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: Single `UsersModels` object (same schema as GET /api/Users).

---

### PUT /api/Users/Authenticate

Retrieves a user by login credentials.

**Request Body** (`UserAuthData`):

| Field | Type | Required |
|-------|------|----------|
| Email | string | Yes |
| Password | string | Yes |

**Response**: Single `UsersModels` object.

---

### POST /api/Users

Creates a new user.

**Request Body** (`UsersAddModels`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Email | string | Yes | User login (email) |
| Password | string | Yes | Length: 6-100 characters |
| Enabled | boolean | Yes | Account status |
| FirstName | string | No | |
| LastName | string | No | |
| Company | string | No | |
| NotificationEmails | string[] | No | |
| DestinationList | DestinationForNewUser[] | No | AccountID, Destination, PackageID |
| SendEmailInstruction | boolean | No | Send setup email to user |
| LicenseManagmentMode | integer (UserModeType) | No | |

**Response**: string -- ID of the new user, or error message.

---

### PUT /api/Users

Changes user properties.

**Request Body** (`UsersEditModels`):

| Field | Type | Required |
|-------|------|----------|
| ID | string (GUID) | Yes |
| Email | string | No |
| FirstName | string | No |
| LastName | string | No |
| NotificationEmails | string[] | No |
| Company | string | No |
| Enabled | boolean | Yes |
| Password | string | No |
| LicenseManagmentMode | integer (UserModeType) | No |

**Response**: IHttpActionResult (success/error status).

---

### DELETE /api/Users/{id}/Account

Removes user account metadata **without** deleting backup data from storage.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: IHttpActionResult.

---

### DELETE /api/Users/{id}

Removes user account metadata **and** associated backup data.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: IHttpActionResult.

---

### GET /api/Users/{userid}/Computers

Retrieves a list of a user's computers (endpoints).

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| userid | string (GUID) | Yes |

**Response** (array of `UserComputerData`):

| Field | Type | Description |
|-------|------|-------------|
| DestinationId | string (GUID) | Policy identifier |
| ComputerName | string | Computer name |

---

### DELETE /api/Users/{userId}/Computers

Deletes computer metadata along with backup data.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| userId | string (GUID) | Yes |

**Request Body** (array of `UserComputerData`):

| Field | Type | Required |
|-------|------|----------|
| DestinationId | string (GUID) | Yes |
| ComputerName | string | Yes |

```json
[
  {
    "DestinationId": "f1aa9e58-ee3a-4ab2-a73b-e86b48561e19",
    "ComputerName": "WORKSTATION-01"
  }
]
```

**Response**: IHttpActionResult.

---

## 3. Companies

### GET /api/Companies

Retrieves a list of companies.

**Parameters**: None

**Response** (array of `CompanyModel`):

| Field | Type | Description |
|-------|------|-------------|
| Id | string (GUID) | Company identifier |
| Name | string | Company name |
| StorageLimit | integer | Backup storage quota; negative = unlimited |
| LicenseSettings | integer (LicensingMode) | 0=Custom, 1=Global Pool, 2=Company Pool |
| DefaultLicense | integer (MBSLicenseType) | Default license type |
| AllowedLicenses | MBSLicenseType[] | Available license types |
| Destinations | CompanyDestinationModel[] | DestinationId (GUID), PlanId (integer) |

---

### GET /api/Companies/{id}

Retrieves a company by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: Single `CompanyModel` object (same schema as above).

---

### POST /api/Companies

Creates a new company.

**Request Body** (`CompanyCreateModel`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Name | string | Yes | Company name |
| StorageLimit | integer | No | Negative = unlimited |
| LicenseSettings | integer (LicensingMode) | No | 0=Custom, 1=Global Pool, 2=Company Pool |
| DefaultLicense | integer (MBSLicenseType) | No | |
| AllowedLicenses | MBSLicenseType[] | No | |
| Destinations | CompanyDestinationModel[] | No | DestinationId (GUID), PlanId (integer) |

**Response**: IHttpActionResult.

---

### PUT /api/Companies

Changes company properties.

**Request Body** (`CompanyModel`):

| Field | Type | Required |
|-------|------|----------|
| Id | string (GUID) | Yes |
| Name | string | Yes |
| StorageLimit | integer | No |
| LicenseSettings | integer (LicensingMode) | No |
| DefaultLicense | integer (MBSLicenseType) | No |
| AllowedLicenses | MBSLicenseType[] | No |
| Destinations | CompanyDestinationModel[] | No |

**Response**: IHttpActionResult.

---

### DELETE /api/Companies/{id}

Deletes a company by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: IHttpActionResult.

---

## 4. Packages

### GET /api/Packages

Retrieves a list of available packages.

**Parameters**: None

**Response** (array of `PackagesModels`):

| Field | Type | Description |
|-------|------|-------------|
| ID | integer | Package unique identifier |
| Name | string | Package name |
| Enabled | boolean | Active status |
| Cost | decimal | Price |
| Description | string | Description |
| StorageLimit | decimal | Limit in GB |
| RestoreLimit | decimal | Restore limit in GB |
| isGlacierRestoreLimit | boolean | Glacier restore limit flag |
| UseRestoreLimit | boolean | User restore limit (default: false) |
| GlacierRestoreType | string (enum) | "Standard" (default) or "No" -- Amazon Glacier accounts only |

---

### GET /api/Packages/{id}

Retrieves a package by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | integer | Yes |

**Response**: Single `PackagesModels` object (same schema as above).

---

### POST /api/Packages

Creates a new package.

**Request Body** (`PackageCreate`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Name | string | Yes | |
| Description | string | No | |
| StorageLimit | decimal | Yes | In GB |
| Cost | decimal | Yes | |
| isGlacierRestoreLimit | boolean | Yes | |
| RestoreLimit | decimal | No | In GB |
| GlacierRestoreType | string (enum) | No | "Standard" or "No" -- Amazon Glacier only |
| UseRestoreLimit | boolean | No | Default: false |

**Response**: IHttpActionResult.

---

### PUT /api/Packages

Changes package properties.

**Request Body** (`PackagesModels`):

| Field | Type | Required |
|-------|------|----------|
| ID | integer | Yes |
| Name | string | Yes |
| Enabled | boolean | Yes |
| isGlacierRestoreLimit | boolean | Yes |
| Cost | decimal | No |
| Description | string | No |
| StorageLimit | decimal | No |
| RestoreLimit | decimal | No |
| UseRestoreLimit | boolean | No |
| GlacierRestoreType | string (enum) | No |

**Response**: IHttpActionResult.

---

### DELETE /api/Packages/{id}

Removes a package by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | integer | Yes |

**Response**: IHttpActionResult.

---

## 5. Licenses

### GET /api/Licenses

Retrieves a list of licenses.

**Query Parameters**:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| isAvailable | boolean | false | Filter to available (unassigned) licenses only |

**Response** (array of `LicensesModels`):

| Field | Type | Description |
|-------|------|-------------|
| ID | string (GUID) | License unique identifier |
| Number | integer | License number |
| ComputerName | string | Computer name |
| OperatingSystem | string | Operating system |
| IsTrial | boolean | true=trial, false=paid |
| IsTaken | boolean | License in use or not |
| LicenseType | string | Type of license |
| DateExpired | date | Expiration date |
| Transaction | string | Transaction identifier |
| User | string | User of license |
| UserID | string (GUID) | User unique identifier |

---

### GET /api/Licenses/{id}

Retrieves a license by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: Single `LicensesModels` object (same schema as above).

---

### POST /api/Licenses/Grant

Grants a license to an existing user.

**Request Body** (`LicenseOperation`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| LicenseID | string (GUID) | Yes | License identifier |
| UserID | string (GUID) | Yes | User identifier |

**Response**: IHttpActionResult.

---

### POST /api/Licenses/Release

Releases a license from a user.

**Request Body** (`LicenseOperation`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| LicenseID | string (GUID) | Yes | License identifier |
| UserID | string (GUID) | Yes | User identifier |

**Response**: IHttpActionResult.

---

### POST /api/Licenses/Revoke

Revokes a license (releases info about the computer).

**Request Body** (`LicenseOperation`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| LicenseID | string (GUID) | Yes | License identifier |
| UserID | string (GUID) | Yes | User identifier |

**Response**: IHttpActionResult.

---

## 6. Destinations

### GET /api/Destinations/{userEmail}

Retrieves backup destinations for a user by email.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| userEmail | string | Yes |

**Response** (array of `UserDestinationsModel`):

| Field | Type | Description |
|-------|------|-------------|
| ID | string (GUID) | Destination identifier |
| CurrentVolume | integer | Current storage volume used |
| PackageID | integer | Associated package ID |
| AccountID | string (GUID) | Storage account ID |
| AccountDisplayName | string | Storage account display name |
| Destination | string | Destination path/reference |
| DestinationDisplayName | string | Display name |

---

### POST /api/Destinations

Adds a backup destination to a user.

**Request Body** (`AddUserDestination`):

| Field | Type | Required |
|-------|------|----------|
| UserID | string (GUID) | Yes |
| AccountID | string (GUID) | Yes |
| Destination | string | Yes |
| PackageID | integer | Yes |

**Response** (`UserDestinationsModel`): Returns the created destination with ID, CurrentVolume, PackageID, AccountID, AccountDisplayName, Destination, DestinationDisplayName.

---

### PUT /api/Destinations

Changes a backup destination for a user.

**Request Body** (`EditUserDestination`):

| Field | Type | Required |
|-------|------|----------|
| ID | string (GUID) | Yes |
| UserID | string (GUID) | Yes |
| AccountID | string (GUID) | Yes |
| Destination | string | Yes |
| PackageID | integer | Yes |

**Response**: IHttpActionResult.

---

### DELETE /api/Destinations/{id}?userId={userId}

Removes a backup destination from a user.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Query Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| userId | string (GUID) | Yes |

**Response**: IHttpActionResult.

---

## 7. Accounts (Storage)

### GET /api/Accounts

Retrieves a list of storage accounts.

**Parameters**: None

**Response** (array of `ProviderAccountsModel`):

| Field | Type | Description |
|-------|------|-------------|
| ResellerAccountID | string (GUID) | Reseller storage account identifier |
| AccountID | string (GUID) | Account unique identifier |
| DateCreated | date | Account creation date |
| DisplayName | string | Display name |
| StorageType | string | Storage type |
| Destinations | DestinationOfAccount[] | Nested destinations |

**DestinationOfAccount**:

| Field | Type |
|-------|------|
| DestinationID | string (GUID) |
| AccountID | string (GUID) |
| Destination | string |
| DestinationDisplayName | string |

---

### GET /api/Accounts/{id}

Retrieves account properties by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response** (`AccountsModels`): Same fields as above (minus ResellerAccountID on single-account responses).

---

### POST /api/Accounts

Adds a new storage account.

**Request Body** (`Account`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| DisplayName | string | Yes | |
| Type | string (AccountType) | Yes | See enum values below |
| AccountSettings | object | Yes | Provider-specific settings |

**AccountType enum values**: `AmazonS3`, `Azure`, `GoogleCloudPlatform`, `OpenStack`, `Oracle`, `S3Compatible`, `Cloudian`, `FS`, `Wasabi`, `Minio`

**AccountSettings by provider**:

- **AmazonS3**: `AccessKey`, `SecretKey`, `IsGovCloud` (boolean)
- **Azure**: `AccountName`, `SharedKey`, `AccountType`, `CustomEndpoint`
- **GoogleCloudPlatform**: `ServiceAccountEmail`, `BinaryKeyAsBase64`, `ProjectID`
- **OpenStack**: `UserName`, `ApiKey`, `AuthService`, `KeyStoneVersion`, `TenantType`, `Tenant`, `Domain`, `DomainType`, `Project`, `ProjectType`, plus boolean flags
- **Oracle**: Similar to OpenStack
- **S3Compatible**: `AccessKey`, `SecretKey`, `HTTPEndpoint`, `HTTPSEndpoint`, `SignatureVersion`, plus boolean flags for certs/versioning
- **Cloudian**: Same as S3Compatible
- **FS** (File System): `Login`, `Pass`, `Path`
- **Wasabi**: `AccessKey`, `SecretKey`
- **Minio**: `AccessKey`, `SecretKey`, endpoints, cert/credential flags

**Response**: HttpResponseMessage with status.

---

### PUT /api/Accounts

Changes account properties.

**Request Body** (`EditAccount`):

| Field | Type | Required |
|-------|------|----------|
| AccountID | string (GUID) | Yes |
| DisplayName | string | Yes |
| Type | string (AccountType) | Yes |
| AccountSettings | object | Yes |

AccountSettings schema same as POST /api/Accounts.

**Response**: HttpResponseMessage with status.

---

### POST /api/Accounts/AddDestination

Adds a backup destination (bucket) to an existing storage account.

**Request Body** (`DestinationOfAccountCreate`):

| Field | Type | Required |
|-------|------|----------|
| AccountID | string (GUID) | Yes |
| Destination | string | Yes |
| DestinationDisplayName | string | No |

**Response** (`DestinationOfAccount`):

| Field | Type |
|-------|------|
| DestinationID | string (GUID) |
| AccountID | string (GUID) |
| Destination | string |
| DestinationDisplayName | string |

---

### POST /api/Accounts/CreateDestination

Creates a new backup destination for existing storage accounts (with provider-specific settings like region and bucket configuration).

**Request Body** (`AccountDestinationCreateModel`):

| Field | Type | Required |
|-------|------|----------|
| AccountID | string (GUID) | Yes |
| DisplayName | string | Yes |
| DestinationSettings | object | Yes |

**DestinationSettings by provider**:

- **GoogleCloudPlatform**: `StorageClass`, `RegionalLocation`, `BucketName`, `UseImmutability`
- **AmazonS3**: `UseS3TransferAcceleration`, `Region`, `BucketName`, `UseImmutability`
- **Wasabi**: `Region`, `BucketName`, `UseImmutability`
- **S3Compatible**: `BucketName`, `UseImmutability`
- **Azure**: `BucketName`, `UseImmutability`
- **B2**: `BucketName`, `UseImmutability`

**Response** (`DestinationOfAccount`): DestinationID, AccountID, Destination, DestinationDisplayName.

---

### PUT /api/Accounts/EditDestination

Changes a backup destination.

**Request Body** (`DestinationOfAccount`):

| Field | Type | Required |
|-------|------|----------|
| DestinationID | string (GUID) | Yes |
| AccountID | string (GUID) | Yes |
| Destination | string | Yes |
| DestinationDisplayName | string | No |

**Response**: IHttpActionResult.

---

### PUT /api/Accounts/RemoveDestination

Removes a backup destination from a storage account.

**Request Body** (`DestinationOfAccount`):

| Field | Type | Required |
|-------|------|----------|
| DestinationID | string (GUID) | Yes |
| AccountID | string (GUID) | Yes |
| Destination | string | Yes |
| DestinationDisplayName | string | No |

**Response**: IHttpActionResult.

---

## 8. Computers (Endpoints)

### GET /api/Computers/{offset}/{count}

Retrieves a paginated list of managed computers (endpoints).

**Path Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| offset | integer | Yes | Number of records to skip |
| count | integer | Yes | Number of records to return |

**Response**: IHttpActionResult -- returns array of computer objects (schema not detailed in official docs; test to discover fields).

---

### GET /api/Computers/{hid}

Retrieves computer info by hardware ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |

**Response**: IHttpActionResult -- computer detail object.

---

### GET /api/Computers/{hid}/Disks

Retrieves disk information for a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| profile | string | Yes | Profile setting |
| isOffline | boolean | Yes | true=from settings service; false=live from computer |

**Response**: IHttpActionResult -- disk inventory data.

---

### GET /api/Computers/{hid}/Plans

Retrieves backup/restore plans on a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |

**Response**: IHttpActionResult -- array of plan objects.

---

### GET /api/Computers/{hid}/Plans/{id}

Retrieves details for a specific plan on a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Response**: IHttpActionResult -- plan detail object.

---

### POST /api/Computers/{hid}/Plans

Creates a new plan on a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |

**Request Body** (`CreatePlanRequest`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| PlanType | string | Yes | Plan classification |
| Plan | object | Yes | Plan configuration (provider-specific) |

**Response**: IHttpActionResult.

---

### PUT /api/Computers/{hid}/Plans/{id}

Changes plan settings.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Request Body** (`UpdatePlanRequest`):

| Field | Type | Required |
|-------|------|----------|
| Plan | object | No |

**Response**: IHttpActionResult.

---

### DELETE /api/Computers/{hid}/Plans/{id}

Removes a plan. Backup data is deleted according to backup storage policies.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Response**: IHttpActionResult.

---

### POST /api/Computers/{hid}/Plans/{id}/start

Starts a plan on a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Request Body** (`StartPlanRequest`):

| Field | Type | Required |
|-------|------|----------|
| Mode | string | No |

**Response**: IHttpActionResult.

---

### POST /api/Computers/{hid}/Plans/{id}/stop

Stops a running plan on a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Request Body** (`StopPlanRequest`):

| Field | Type | Required |
|-------|------|----------|
| Force | boolean | No |

**Response**: IHttpActionResult.

---

### GET /api/Computers/{hid}/Plans/{id}/info

Retrieves plan info by computer HID and plan ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Response**: IHttpActionResult -- plan info object.

---

### GET /api/Computers/Plans/history/{offset}/{count}

Retrieves backup history across all managed computers.

**Path Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| offset | integer | Yes | Records to skip |
| count | integer | Yes | Records to return |

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| companyId | string (GUID) | Yes | Company identifier |
| year | integer | No | Year filter |
| month | integer | No | Month filter |

**Response**: IHttpActionResult -- array of history records.

---

### GET /api/Computers/{hid}/Plans/history/{offset}/{count}

Retrieves plan history for a specific computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| offset | integer | Yes |
| count | integer | Yes |

**Query Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| year | integer | No |
| month | integer | No |

**Response**: IHttpActionResult -- array of history records.

---

### GET /api/Computers/{hid}/Plans/{id}/history

Retrieves history for a specific plan on a specific computer for a specific day.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |
| id | string (GUID) | Yes |

**Query Parameters**:

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| Year | integer | Yes | Range: 2023-9999 |
| Month | integer | Yes | Range: 1-12 |
| Day | integer | Yes | Range: 1-31 |

**Response**: IHttpActionResult -- history records for that day.

---

### POST /api/Computers/{hid}/authorization

Creates or updates endpoint authorization for an online computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |

**Request Body** (`AuthorizeComputerRequest`):

| Field | Type | Required |
|-------|------|----------|
| UserId | string | No |
| CompanyId | string | No |

**Response**: IHttpActionResult.

---

### DELETE /api/Computers/{hid}/authorization

Removes authorization from a computer.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| hid | string | Yes |

**Response**: IHttpActionResult.

---

## 9. Monitoring

### GET /api/Monitoring

Retrieves status data for the latest plan runs on all endpoints (all users).

**Parameters**: None

**Response** (array of `MonitoringModels`):

| Field | Type | Description |
|-------|------|-------------|
| PlanName | string | Plan name |
| CompanyName | string | Company name |
| UserName | string | User email |
| UserID | string (GUID) | User unique identifier |
| ComputerName | string | Computer name |
| ComputerHid | string | Computer hardware identifier |
| BuildVersion | string | Build version |
| StorageType | string | Storage type |
| LastStart | date | Last execution timestamp |
| NextStart | date | Next scheduled execution |
| Status | integer (MonitoringPlanStatus) | Plan execution status |
| ErrorMessage | string | Error details |
| FilesCopied | integer | Successfully backed up files |
| FilesFailed | integer | Failed files |
| DataCopied | integer | Backup data size (bytes) |
| Duration | string | Operation elapsed time |
| DataToBackup | integer | Data to backup size (bytes) |
| TotalData | integer | Total data size (bytes) |
| FilesScanned | integer | Scanned files count |
| FilesToBackup | integer | Files eligible for backup |
| PlanId | string (GUID) | Plan unique identifier |
| PlanType | integer (MonitoringPlanType) | Plan classification |
| DetailedReportLink | string | URL to detailed execution report |

---

### GET /api/Monitoring/{userId}

Retrieves status data for the latest plan runs, filtered by user ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| userId | string (GUID) | Yes |

**Response**: Same `MonitoringModels` array as above, filtered to the specified user.

---

## 10. Billing

### GET /api/Billing

Retrieves billing information for the current reporting month.

**Parameters**: None

**Response** (`BillingModels`):

| Field | Type | Description |
|-------|------|-------------|
| CurrentSpaceUsed | integer | Space used by all users (updated once/day) |
| AverageSpaceUsed | integer | Average space used for the month |
| TotalRestore | integer | Total restore volume |
| StatisticBilling | StatisticBillingModels[] | Per-user billing breakdown |

**StatisticBillingModels**:

| Field | Type |
|-------|------|
| UserId | string (GUID) |
| Email | string |
| FirstName | string |
| LastName | string |
| CompanyName | string |
| AverageSpace | integer |
| TotalVolumeRestore | integer |
| PlanCost | decimal |
| StorageCost | decimal |
| RestoreCost | decimal |
| TotalCost | decimal |

---

### PUT /api/Billing

Retrieves billing information for specified dates/companies.

**Request Body** (`FilterTotalModels`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| CompanyName | string | No | If empty, filter is ignored |
| Date | date | No | If empty, defaults to current month |

**Response**: Same `BillingModels` schema as GET /api/Billing.

---

### PUT /api/Billing/Details

Retrieves detailed billing for backup and restore operations per user.

**Request Body** (`FilterDetailModels`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| UserID | string (GUID) | Yes | |
| Date | date | No | Defaults to current month |

**Response** (`DetailModels`):

| Field | Type | Description |
|-------|------|-------------|
| TotalBackupBytes | integer | Total backup data size |
| TotalRestoreBytes | integer | Total restore data size |
| UserID | string (GUID) | User identifier |
| UserDetailList | UserDetailModels[] | Per-computer/destination breakdown |

**UserDetailModels**:

| Field | Type |
|-------|------|
| Computer | string |
| SizeBackup | integer |
| SizeRestore | integer |
| Prefix | string |
| AccountID | string (GUID) |
| Destination | string |

---

## 11. Administrators

### GET /api/Administrators

Retrieves a list of administrators.

**Parameters**: None

**Response** (array of `AdministratorsModels`):

| Field | Type | Description |
|-------|------|-------------|
| AdminID | string (GUID) | Administrator unique identifier |
| Email | string | Email address |
| FirstName | string | First name |
| LastName | string | Last name |
| Enabled | boolean | Active/inactive status |
| PermissionsModels | object (dict) | Permission key-value pairs (40+ permission types) |
| LastLogin | date | Last login timestamp |
| DateCreated | date | Account creation date |
| Companies | string[] | Associated company names |
| AccessToCompaniesMode | string (enum) | "SpecifiedCompanies" or "AllCompanies" |
| AccountType | string (enum) | "Internal" (employee) or "External" (third-party); nullable |

---

### GET /api/Administrators/{id}

Retrieves administrator by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: Single `AdministratorsModels` object.

---

### POST /api/Administrators

Creates a new administrator.

**Request Body** (`AdministratorsNewModels`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Email | string | Yes | |
| InitialPassword | string | Yes | |
| Enabled | boolean | Yes | |
| PermissionsModels | object (dict) | Yes | Permission key-value pairs |
| SendInstruction | boolean | No | Send instruction email |
| FirstName | string | No | |
| LastName | string | No | |
| AccountType | string (enum) | No | "Internal" or "External" |
| Companies | string[] | No | Company names |
| AccessToCompaniesMode | string (enum) | No | Default: "SpecifiedCompanies" |

**Response**: string -- ID of the new administrator.

---

### PUT /api/Administrators

Changes administrator properties.

**Request Body** (`AdministratorsEditModels`):

| Field | Type | Required |
|-------|------|----------|
| AdminID | string (GUID) | Yes |
| Enabled | boolean | Yes |
| PermissionsModels | object (dict) | Yes |
| Password | string | No |
| FirstName | string | No |
| LastName | string | No |
| Companies | string[] | No |
| AccountType | string (enum) | No |
| AccessToCompaniesMode | string (enum) | No |

**Response**: IHttpActionResult.

---

### DELETE /api/Administrators/{id}

Deletes an administrator by ID.

**Path Parameters**:

| Parameter | Type | Required |
|-----------|------|----------|
| id | string (GUID) | Yes |

**Response**: IHttpActionResult.

---

## 12. Builds

### GET /api/Builds

Retrieves a list of available builds.

**Query Parameters**:

| Parameter | Type | Required | Default |
|-----------|------|----------|---------|
| companyId | string (GUID) | Yes | |
| includeSandbox | boolean | No | false |

**Response** (array of build objects):

| Field | Type | Description |
|-------|------|-------------|
| Type | string | Build classification |
| Version | string | Version identifier |
| DownloadLink | string | Download URL |
| IsSandbox | boolean | Sandbox build flag |

---

### POST /api/Builds/RequestCustomBuilds

Requests custom builds of specified editions.

**Request Body** (`RequestBuilds`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Editions | BuildEdition[] | Yes | Array of build editions (e.g., "Windows") |
| Type | string (BuildType) | Yes | Build type (e.g., "Custom") |

**Response**: HttpResponseMessage with status.

---

### GET /api/Builds/AvailableVersions

Retrieves the latest available build versions.

**Parameters**: None

**Response** (array of `BuildEditionModel`):

| Field | Type | Description |
|-------|------|-------------|
| Type | integer (BuildEdition enum) | Build edition type (0=Windows, etc.) |
| Version | string | Version string |

---

## 13. CloudBackup

### GET /api/apps/domains

Retrieves backup storage information for domains.

**Parameters**: None

**Response** (array of `DomainModel`):

| Field | Type | Description |
|-------|------|-------------|
| Domain | string | Domain identifier |
| Storage | string | Storage designation |
| StorageLimit | object | `TotalLimit` (integer), `CommandDriveLimit` (integer), `OtherServicesLimit` (integer) |
| StorageUsage | object | `Total` (integer) |
| ActivatedLicenses | integer | Count of active licenses |

---

## Enum Reference

### UserModeType (LicenseManagmentMode)
Used on User objects to control license management behavior.

### LicensingMode (Company LicenseSettings)
| Value | Meaning |
|-------|---------|
| 0 | Custom |
| 1 | Global Pool |
| 2 | Company Pool |

### MonitoringPlanStatus
Plan execution status enum -- values returned in Monitoring responses.

### MonitoringPlanType
Plan classification type enum -- values returned in Monitoring responses.

### MBSLicenseType
License type enum -- used in Company AllowedLicenses and DefaultLicense fields.

### AccountType (Storage Accounts)
| Value | Description |
|-------|-------------|
| AmazonS3 | Amazon S3 |
| Azure | Microsoft Azure Blob |
| GoogleCloudPlatform | Google Cloud Platform |
| OpenStack | OpenStack-based |
| Oracle | Oracle Cloud |
| S3Compatible | S3-compatible storage |
| Cloudian | Cloudian HyperStore |
| FS | File System (local/network) |
| Wasabi | Wasabi Hot Cloud Storage |
| Minio | MinIO object storage |

### GlacierRestoreType
| Value | Description |
|-------|-------------|
| Standard | Standard Glacier restore (default) |
| No | Disable Glacier restores |

### AccessToCompaniesEnum (Administrators)
| Value | Description |
|-------|-------------|
| SpecifiedCompanies | Access only to listed companies (default) |
| AllCompanies | Access to all companies |

### AdministratorAccountType
| Value | Description |
|-------|-------------|
| Internal | Employee |
| External | Third-party |
| (null) | Backward compatibility |

### BuildEdition
| Value | Description |
|-------|-------------|
| 0 | Windows |
| (others) | Other platforms (test to discover) |
