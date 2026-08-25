FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /workspace

ENV PUB_CACHE=/root/.pub-cache

RUN flutter config --no-analytics \
    && flutter precache --android \
    && (yes | flutter doctor --android-licenses >/dev/null || true)

CMD ["sh", "-lc", "flutter clean && flutter pub get && flutter build apk --${BUILD_MODE:-debug}"]
