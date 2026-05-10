#!/bin/bash
set -e

DATA=/data
PLUGINS_SRC=/server/plugins

# ── First-run bootstrap ───────────────────────────────────────────────────────
mkdir -p "$DATA/plugins" "$DATA/logs"

# Copy paper.jar once so the server can be updated without rebuilding the image
if [ ! -f "$DATA/paper.jar" ]; then
    cp /server/paper.jar "$DATA/paper.jar"
fi

# Copy each plugin JAR only if it isn't already present (preserves manual updates)
for jar in "$PLUGINS_SRC"/*.jar; do
    dest="$DATA/plugins/$(basename "$jar")"
    if [ ! -f "$dest" ]; then
        cp "$jar" "$dest"
    fi
done

# Accept EULA unconditionally — required by Mojang, acknowledged by running this image
echo "eula=true" > "$DATA/eula.txt"

# Use mounted server.properties if present, otherwise fall back to the default
if [ ! -f "$DATA/server.properties" ]; then
    if [ -f "/config/server.properties" ]; then
        cp /config/server.properties "$DATA/server.properties"
    fi
fi

# ── Start the server ──────────────────────────────────────────────────────────
cd "$DATA"

MEMORY="${MEMORY:-2G}"

exec java \
    -Xmx"${MEMORY}" \
    -Xms"${MEMORY}" \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dcom.mojang.eula.agree=true \
    -jar paper.jar \
    nogui
