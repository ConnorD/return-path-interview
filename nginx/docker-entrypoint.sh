#!/bin/bash

if [ "$1" = 'nginx' ]; then

  UWSGI_PROXY_FILE=/etc/nginx/conf.d/uwsgi_proxy.conf

  # shellcheck disable=SC2153
  if [ ! -f "$UWSGI_PROXY_FILE" ] && [ -n "$UWSGI_UPSTREAM_HOST" ]; then

    echo 'NGinx creating uwsgi proxy file'

    if [ -z "$SERVER_NAME" ]; then
      SERVER_NAME=_
    fi

    if [ -z "$UWSGI_UPSTREAM_PORT" ]; then
      UWSGI_UPSTREAM_PORT=3031
    fi

    cat <<- EOF > "$UWSGI_PROXY_FILE"

    map \$http_x_forwarded_proto \$thescheme {
      default \$http_x_forwarded_proto;
      '' \$scheme;
    }

     server {
        listen       80 default_server;
        server_name  $SERVER_NAME;
        root    /www/;
        
        if (\$http_x_forwarded_proto = "http") {
          return 302 https://\$host\$request_uri;
        }

        client_max_body_size       100m;
        client_body_buffer_size    128k;

        error_page 502 /uwsgi.log;
        location /uwsgi.log {
          root  /var/log/uwsgi;
        }

        error_page 503 @maintenance;
        location @maintenance {
          rewrite ^(.*)\$ /maintenance.html break;
        }

        location @upstream {
          internal;

          include uwsgi_params;
          uwsgi_pass  $UWSGI_UPSTREAM_HOST:$UWSGI_UPSTREAM_PORT;
          uwsgi_read_timeout 300;
        }

        location = /health/ping/ {
          rewrite ^(.*)\$ /pong.html break;
        }
        
        location / {

          if (-f \$document_root/maintenance.html) {
            return 503;
          }

          try_files \$uri @upstream;
        }
      }

EOF

fi

  HTTP_PROXY_FILE=/etc/nginx/conf.d/http_proxy.conf

  # shellcheck disable=SC2153
  if [ ! -f "$HTTP_PROXY_FILE" ] && [ -n "$HTTP_UPSTREAM_HOST" ]; then

    echo 'NGinx creating HTTP proxy file'

    if [ -z "$SERVER_NAME" ]; then
      SERVER_NAME=_
    fi

    if [ -z "$HTTP_UPSTREAM_PORT" ]; then
      HTTP_UPSTREAM_PORT=80
    fi

    cat <<- EOF > "$HTTP_PROXY_FILE"

      map \$http_x_forwarded_proto \$thescheme {
        default \$http_x_forwarded_proto;
        '' \$scheme;
      }

      upstream backend {
        server $HTTP_UPSTREAM_HOST:$HTTP_UPSTREAM_PORT   max_fails=8 fail_timeout=3s;
      }

      server {
        listen       80 default_server;
        server_name  $SERVER_NAME;
        root    /www/;
        
        if (\$http_x_forwarded_proto = "http") {
          return 302 https://\$host\$request_uri;
        }

        client_max_body_size       100m;
        client_body_buffer_size    128k;

        error_page 502 /502.html;
        location = /502.html {
          root  /www;
          internal;
        }

        error_page 503 @maintenance;
        location @maintenance {
          rewrite ^(.*)\$ /maintenance.html break;
        }

        location /last_roll.txt {
          root  /var/log/uwsgi;
        }

        location @upstream {
          internal;
          proxy_next_upstream error timeout http_502;
          proxy_set_header X-Real-IP \$remote_addr;
          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Host \$http_host;
          proxy_set_header Host \$http_host;

          proxy_pass http://backend;
        }

        location = /health/ping/ {
          rewrite ^(.*)\$ /pong.html break;
        }

        location / {

          if (-f \$document_root/maintenance.html) {
            return 503;
          }

          try_files \$uri @upstream;
        }

      }

EOF

  fi

    echo
    echo 'Nginx init process done. Ready for start up.'
    echo

fi

exec "$@"
