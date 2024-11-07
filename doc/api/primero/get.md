<!-- Copyright (c) 2014 - 2023 UNICEF. All rights reserved. -->

# Query for public Primero information

Retrieve agency logos and other public bootstrap information as JSON without authentication

**URL** : `/api/v2/primero`

**Method** : `GET`

**Authentication** : NO

**Parameters** : No parameters

## Success Response

**Code** : `200 OK`

**Content** :

```json
{
  "data": {
    "sandbox_ui": true|false,
    "config_ui": "full"|"limited",
    "webpush_enabled": true|false,
    "agencies": [
      {
        "unique_id": "agency-unique-id",
        "name": "Agency Name",
        "logo_full": "<logo-full-base64>",
        "logo_icon": "<logo-icon-base64>",
      },
      ...
    ]
  }
}
```
