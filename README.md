# audiax_frontend

## Build Android APK dengan Docker

Prasyarat di komputer:

- Docker
- Docker Compose

Build APK debug:

```bash
docker compose run --rm android-build
```

Output APK:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Build APK release:

```bash
BUILD_MODE=release docker compose run --rm android-build
```

Output APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Catatan:

- Teman yang clone repo tidak perlu install Flutter, Dart, Gradle, atau Android SDK secara lokal.
- Build pertama akan lebih lama karena Docker perlu download image dan dependency.
- Konfigurasi release Android saat ini masih memakai debug signing config dari template Flutter. Untuk publikasi Play Store, tambahkan release keystore sendiri.
- Jika Docker menampilkan error `read-only file system` pada `/var/lib/docker` atau `~/.docker/buildx`, restart Docker Desktop lalu jalankan ulang command build.
