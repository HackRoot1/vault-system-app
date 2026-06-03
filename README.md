# vault_system

# API Requests

Base URL: `https://palegreen-eagle-487743.hostingersite.com/api`

> These examples are derived from `routes/api.php` and the request validation rules in the application.

## Test Endpoint

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/test
```

## Register User

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "MySecure@Pass123",
    "password_confirmation": "MySecure@Pass123",
    "master_password": "MyMaster@Pass123",
    "master_password_confirmation": "MyMaster@Pass123"
  }'
```

## Login User

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "MySecure@Pass123"
  }'
```

## Get Authenticated User

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/user \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```


## Dashboard

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/dashboard \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```


## Logout User

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/logout \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Setup Two-Factor Authentication

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/2fa/setup \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Verify Two-Factor Authentication

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/2fa/verify \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "123456"
  }'
```

## Disable Two-Factor Authentication

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/2fa/disable \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "123456"
  }'
```

## Get Device History

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/devices \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Sync Items

```bash
curl -X GET "https://palegreen-eagle-487743.hostingersite.com/api/items/sync?last_sync=2026-04-23T12:00:00Z" \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Vaults

### List Vaults

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Create Vault

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/vaults \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Personal Vault"
  }'
```

### Get Vault

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults/1 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Update Vault

```bash
curl -X PUT https://palegreen-eagle-487743.hostingersite.com/api/vaults/1 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Vault Name"
  }'
```

### Delete Vault

```bash
curl -X DELETE https://palegreen-eagle-487743.hostingersite.com/api/vaults/1 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Items

### List Items in a Vault

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/items \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Create Item

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/items \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "encrypted_data": "BASE64_ENCRYPTED_PAYLOAD",
    "iv": "BASE64_IV",
    "tag": "BASE64_TAG"
  }'
```

### Get Item

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/items/3 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Update Item

```bash
curl -X PUT https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/items/3 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "encrypted_data": "UPDATED_BASE64_ENCRYPTED_PAYLOAD",
    "iv": "UPDATED_BASE64_IV",
    "tag": "UPDATED_BASE64_TAG"
  }'
```

### Delete Item

```bash
curl -X DELETE https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/items/3 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Files

### Upload File

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/files \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -F "file=@/path/to/document.pdf" \
  -F "file_name=document.pdf" \
  -F "iv=BASE64_IV" \
  -F "tag=BASE64_TAG"
```

### List Files in a Vault

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/files \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Get File Metadata

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/files/5 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Update File

```bash
curl -X POST https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/files/5 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f" \
  -F "_method=PUT" \
  -F "file=@/path/to/new-document.pdf" \
  -F "file_name=new-document.pdf" \
  -F "iv=UPDATED_BASE64_IV" \
  -F "tag=UPDATED_BASE64_TAG"
```

### Delete File

```bash
curl -X DELETE https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/files/5 \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

### Get File Download URL

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/vaults/1/files/5/download-url \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```

## Download File by Token

```bash
curl -X GET "https://palegreen-eagle-487743.hostingersite.com/api/files/download/abc123def456..." \
  --output downloaded-file.enc
```


## Recent Dashboard Data

```bash
curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/dashboard/recent-vaults \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"

curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/dashboard/recent-items \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"

curl -X GET https://palegreen-eagle-487743.hostingersite.com/api/dashboard/recent-files \
  -H "Authorization: Bearer 20|Y2xbwFbVgllYKQ4rX2qUwv0PAFV5w2rh335w9lOc14d7552f"
```