# vault_system

# API Requests

Base URL: `http://localhost:8000/api`

> These examples are derived from `routes/api.php` and the request validation rules in the application.

## Test Endpoint

```bash
curl -X GET http://localhost:8000/api/test
```

## Register User

```bash
curl -X POST http://localhost:8000/api/register \
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
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "MySecure@Pass123"
  }'
```

## Get Authenticated User

```bash
curl -X GET http://localhost:8000/api/user \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Logout User

```bash
curl -X POST http://localhost:8000/api/logout \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Setup Two-Factor Authentication

```bash
curl -X POST http://localhost:8000/api/2fa/setup \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Verify Two-Factor Authentication

```bash
curl -X POST http://localhost:8000/api/2fa/verify \
  -H "Authorization: Bearer 1|abc123def456..." \
  -H "Content-Type: application/json" \
  -d '{
    "code": "123456"
  }'
```

## Disable Two-Factor Authentication

```bash
curl -X POST http://localhost:8000/api/2fa/disable \
  -H "Authorization: Bearer 1|abc123def456..." \
  -H "Content-Type: application/json" \
  -d '{
    "code": "123456"
  }'
```

## Get Device History

```bash
curl -X GET http://localhost:8000/api/devices \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Sync Items

```bash
curl -X GET "http://localhost:8000/api/items/sync?last_sync=2026-04-23T12:00:00Z" \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Vaults

### List Vaults

```bash
curl -X GET http://localhost:8000/api/vaults \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Create Vault

```bash
curl -X POST http://localhost:8000/api/vaults \
  -H "Authorization: Bearer 1|abc123def456..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Personal Vault"
  }'
```

### Get Vault

```bash
curl -X GET http://localhost:8000/api/vaults/1 \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Update Vault

```bash
curl -X PUT http://localhost:8000/api/vaults/1 \
  -H "Authorization: Bearer 1|abc123def456..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Vault Name"
  }'
```

### Delete Vault

```bash
curl -X DELETE http://localhost:8000/api/vaults/1 \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Items

### List Items in a Vault

```bash
curl -X GET http://localhost:8000/api/vaults/1/items \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Create Item

```bash
curl -X POST http://localhost:8000/api/vaults/1/items \
  -H "Authorization: Bearer 1|abc123def456..." \
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
curl -X GET http://localhost:8000/api/vaults/1/items/3 \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Update Item

```bash
curl -X PUT http://localhost:8000/api/vaults/1/items/3 \
  -H "Authorization: Bearer 1|abc123def456..." \
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
curl -X DELETE http://localhost:8000/api/vaults/1/items/3 \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Files

### Upload File

```bash
curl -X POST http://localhost:8000/api/vaults/1/files \
  -H "Authorization: Bearer 1|abc123def456..." \
  -F "file=@/path/to/document.pdf" \
  -F "file_name=document.pdf" \
  -F "iv=BASE64_IV" \
  -F "tag=BASE64_TAG"
```

### List Files in a Vault

```bash
curl -X GET http://localhost:8000/api/vaults/1/files \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Get File Metadata

```bash
curl -X GET http://localhost:8000/api/vaults/1/files/5 \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Update File

```bash
curl -X POST http://localhost:8000/api/vaults/1/files/5 \
  -H "Authorization: Bearer 1|abc123def456..." \
  -F "_method=PUT" \
  -F "file=@/path/to/new-document.pdf" \
  -F "file_name=new-document.pdf" \
  -F "iv=UPDATED_BASE64_IV" \
  -F "tag=UPDATED_BASE64_TAG"
```

### Delete File

```bash
curl -X DELETE http://localhost:8000/api/vaults/1/files/5 \
  -H "Authorization: Bearer 1|abc123def456..."
```

### Get File Download URL

```bash
curl -X GET http://localhost:8000/api/vaults/1/files/5/download-url \
  -H "Authorization: Bearer 1|abc123def456..."
```

## Download File by Token

```bash
curl -X GET "http://localhost:8000/api/files/download/abc123def456..." \
  --output downloaded-file.enc
```


