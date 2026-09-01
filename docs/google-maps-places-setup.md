# Google Maps + Places setup

The app renders Google Maps on Android/iOS. Place searches are sent to the
NestJS backend so the Places key is never bundled into Flutter.

## Shared architecture

- `lib/shared/widgets/guia_google_map.dart` is the only direct Google Maps
  surface. Map previews and the full picker compose this shared component.
- `lib/shared/location/` contains the reusable location subsystem, separated
  into `domain`, `data`, and `presentation` layers.
- `backend/src/shared/places/` is the server-side Google adapter and is
  registered through `SharedModule`; it is not modeled as business logic.

## Development keys

### Backend Places key

In `GuIA-HN-Backend/backend/.env` add:

```dotenv
GOOGLE_PLACES_API_KEY=replace_with_the_backend_places_key
```

Restrict this key to **Places API**. Keep it out of Flutter and Git. When the
production server has stable egress IP addresses, add an IP application
restriction. If it does not, protect the public endpoint with infrastructure
rate limiting and Google Cloud quotas/budget alerts.

### Android Maps key

In `android/local.properties` add:

```properties
MAPS_API_KEY=replace_with_the_android_maps_key
```

The key must be restricted to **Maps SDK for Android** and to the Android app:

- Package: `com.example.guiautomotriz_mobile`
- Development SHA-1: use `./gradlew signingReport` from `android/`

Create a separate production key after configuring the release keystore. Its
restriction must use the release signing certificate SHA-1, not the debug SHA-1.

### iOS Maps key

Copy the ignored local config template:

```sh
cp ios/Flutter/GoogleMapsSecrets.xcconfig.example \
  ios/Flutter/GoogleMapsSecrets.xcconfig
```

Then replace the placeholder in that new file. Restrict the key to **Maps SDK
for iOS** and bundle identifier `com.example.guiautomotrizMobile`. iOS does not
use an Android SHA-1.

## Run

Start the backend from `GuIA-HN-Backend/backend`, then run Flutter normally.
The location picker searches through `GET /api/places/search?query=...` and
moves the Google map to the selected result's latitude and longitude.

Do not commit `.env`, `android/local.properties`, or
`ios/Flutter/GoogleMapsSecrets.xcconfig`.
