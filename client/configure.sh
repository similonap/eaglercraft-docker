#!/bin/sh
set -e

SERVER_HOST="${SERVER_HOST:-localhost}"
SERVER_PORT="${SERVER_PORT:-25565}"
SERVER_NAME="${SERVER_NAME:-EaglercraftX}"
SERVER_TLS="${SERVER_TLS:-true}"

if [ "${SERVER_TLS}" = "true" ]; then
    WS_SCHEME="wss"
else
    WS_SCHEME="ws"
fi
WS_URL="${WS_SCHEME}://${SERVER_HOST}:${SERVER_PORT}/"

# Use Object.defineProperty to intercept the assignment of window.eaglercraftXOpts.
# Injected into <head> so this runs before the game's config script.  When the
# config script does `window.eaglercraftXOpts = { ... }`, our setter fires and
# overrides the servers list before the game reads any of these values.
INJECT="<script>"
INJECT="${INJECT}(function(){"
INJECT="${INJECT}var _v;"
INJECT="${INJECT}Object.defineProperty(window,'eaglercraftXOpts',{"
INJECT="${INJECT}configurable:true,"
INJECT="${INJECT}set:function(v){"
INJECT="${INJECT}_v=v;"
INJECT="${INJECT}v.servers=[{addr:\"${WS_URL}\",name:\"${SERVER_NAME}\"}];"
INJECT="${INJECT}},"
INJECT="${INJECT}get:function(){return _v;}"
INJECT="${INJECT}});"
INJECT="${INJECT}})();"
INJECT="${INJECT}</script>"

# On mobile browsers inject EaglerMobile touch controls.
# We use document.write so the script loads synchronously (same as @run-at document-start).
# The isMobile() check mirrors EaglerMobile's own detection and prevents the desktop alert.
INJECT="${INJECT}<script>"
INJECT="${INJECT}(function(){"
INJECT="${INJECT}var m=false;"
INJECT="${INJECT}try{document.createEvent('TouchEvent');m=true;}catch(e){}"
INJECT="${INJECT}if(m){document.write('<scr'+'ipt src=\"/eaglermobile.user.js\"><\\/scr'+'ipt>');}"
INJECT="${INJECT}})();"
INJECT="${INJECT}</script>"

export INJECT

# Inject into a single HTML file. Usage: inject_html <path>
inject_html() {
    local html="$1"
    if [ ! -f "$html" ]; then
        echo "[client] Warning: $html not found, skipping"
        return
    fi
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
    ' "$html" > "${html}.tmp" && mv "${html}.tmp" "$html"
    echo "[client] Configured: $html"
}

inject_html /usr/share/nginx/html/index.html
inject_html /usr/share/nginx/html/mobile/index.html

echo "[client] Server: ${WS_URL}"
