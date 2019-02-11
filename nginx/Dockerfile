FROM ubuntu:xenial

ENV NGINX_VERSION 1.14.0*

RUN echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
    ca-certificates \
    nginx="$NGINX_VERSION" \
    nginx-module-xslt="$NGINX_VERSION" \
    nginx-module-geoip="$NGINX_VERSION" \
    nginx-module-image-filter="$NGINX_VERSION" \
    nginx-module-perl="$NGINX_VERSION" \
    nginx-module-njs="$NGINX_VERSION" \
    gettext-base

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Remove the default site
RUN rm /etc/nginx/conf.d/default.conf

RUN mkdir /www

EXPOSE 80 443

COPY docker-entrypoint.sh /
RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]