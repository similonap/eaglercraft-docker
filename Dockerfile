FROM eclipse-temurin:17-jre-focal

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /server

# ── Paper 1.12.2 ──────────────────────────────────────────────────────────────
ARG PAPER_VERSION=1.12.2
ARG PAPER_BUILD=1620
RUN curl -fsSL \
    "https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar" \
    -o paper.jar

RUN mkdir -p plugins

# ── EaglercraftX v1.1.0 ───────────────────────────────────────────────────────
ARG EAGLER_BASE=https://github.com/lax1dude/eaglerxserver/releases/download/v1.1.0
RUN curl -fsSL -o plugins/EaglerXServer.jar "${EAGLER_BASE}/EaglerXServer.jar" && \
    curl -fsSL -o plugins/EaglerXRewind.jar "${EAGLER_BASE}/EaglerXRewind.jar" && \
    curl -fsSL -o plugins/EaglerMOTD.jar    "${EAGLER_BASE}/EaglerMOTD.jar"

# ── Via-family ────────────────────────────────────────────────────────────────
# ViaVersion/ViaBackwards 5.x requires Java 17+; ViaRewind 4.x is compatible
# with both 5.x and works on Paper 1.12.2 as the backend
RUN curl -fsSL -o plugins/ViaVersion.jar \
        "https://github.com/ViaVersion/ViaVersion/releases/download/5.9.1/ViaVersion-5.9.1.jar" && \
    curl -fsSL -o plugins/ViaBackwards.jar \
        "https://github.com/ViaVersion/ViaBackwards/releases/download/5.9.1/ViaBackwards-5.9.1.jar" && \
    curl -fsSL -o plugins/ViaRewind.jar \
        "https://github.com/ViaVersion/ViaRewind/releases/download/4.1.1/ViaRewind-4.1.1.jar" && \
    curl -fsSL -o plugins/ViaRewindLegacySupport.jar \
        "https://github.com/ViaVersion/ViaRewind-Legacy-Support/releases/download/1.5.4/ViaRewind-Legacy-Support-1.5.4.jar"

# ── Auth & Skins ──────────────────────────────────────────────────────────────
RUN curl -fsSL -o plugins/AuthMe.jar \
        "https://github.com/AuthMe/AuthMeReloaded/releases/download/6.0.0/AuthMe-6.0.0-Spigot-Legacy.jar" && \
    curl -fsSL -o plugins/SkinsRestorer.jar \
        "https://github.com/SkinsRestorer/SkinsRestorer/releases/download/15.12.0/SkinsRestorer.jar"

# Accept EULA so the server can start without interactive prompt
RUN echo "eula=true" > /server/eula.txt.default

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25565

VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]
