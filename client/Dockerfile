FROM nginx:alpine AS extractor-wasm

WORKDIR /client
COPY eaglercraft.dev_Release_1.12.2_WASM.zip eaglercraft.zip
RUN apk add --no-cache unzip && \
    unzip eaglercraft.zip && \
    rm eaglercraft.zip && \
    mv *.html index.html && \
    sed -i 's/var launchSkipCountdown = false;/var launchSkipCountdown = true;/' index.html

FROM nginx:alpine AS extractor-js

WORKDIR /client
COPY eaglercraft.dev_Release_1.12.2_JS.zip eaglercraft.zip
RUN apk add --no-cache unzip && \
    unzip eaglercraft.zip && \
    rm eaglercraft.zip && \
    mv *.html index.html && \
    sed -i 's/var launchSkipCountdown = false;/var launchSkipCountdown = true;/' index.html

FROM nginx:alpine
COPY --from=extractor-wasm /client /usr/share/nginx/html
COPY --from=extractor-js /client /usr/share/nginx/html/mobile
COPY eaglermobile.user.js /usr/share/nginx/html/eaglermobile.user.js
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY configure.sh /docker-entrypoint.d/40-configure-server.sh
RUN chmod +x /docker-entrypoint.d/40-configure-server.sh
EXPOSE 80
