#!/bin/sh
set -e

HTML=/usr/share/nginx/html/index.html
SERVER_HOST="${SERVER_HOST:-localhost}"
SERVER_PORT="${SERVER_PORT:-25565}"
SERVER_NAME="${SERVER_NAME:-EaglercraftX}"

if [ ! -f "$HTML" ]; then
    echo "[client] Warning: index.html not found, skipping server configuration"
    exit 0
fi

WS_URL="wss://${SERVER_HOST}:${SERVER_PORT}/"

# Use Object.defineProperty to intercept the assignment of window.eaglercraftXOpts.
# Injected into <head> so this runs before the game's config script.  When the
# config script does `window.eaglercraftXOpts = { ... }`, our setter fires and
# overrides the servers list, sets joinServer for auto-connect, and disables
# the built-in countdown timer before the game reads any of these values.
INJECT="<script>"
INJECT="${INJECT}(function(){"
INJECT="${INJECT}var _v;"
INJECT="${INJECT}Object.defineProperty(window,'eaglercraftXOpts',{"
INJECT="${INJECT}configurable:true,"
INJECT="${INJECT}set:function(v){"
INJECT="${INJECT}_v=v;"
INJECT="${INJECT}v.servers=[{addr:\"${WS_URL}\",name:\"${SERVER_NAME}\"}];"
INJECT="${INJECT}v.joinServer=\"${WS_URL}\";"
INJECT="${INJECT}v.joinServerTimeout=0;"
INJECT="${INJECT}},"
INJECT="${INJECT}get:function(){return _v;}"
INJECT="${INJECT}});"
INJECT="${INJECT}})();"
INJECT="${INJECT}</script>"

export INJECT

# Inject immediately after <head> tag (case-insensitive via character classes).
# Falls back to injecting before the first <script> if there is no <head> tag.
awk '
    BEGIN { inject = ENVIRON["INJECT"]; done = 0 }
    done { print; next }
    /[<][Hh][Ee][Aa][Dd]/ {
        print
        print inject
        done = 1
        next
    }
    /[<][Ss][Cc][Rr][Ii][Pp][Tt]/ {
        print inject
        print
        done = 1
        next
    }
    { print }
' "$HTML" > "${HTML}.tmp" && mv "${HTML}.tmp" "$HTML"

echo "[client] Pre-configured server: ${WS_URL}"
