#!/bin/bash

if [ -z "$FLASK_CODE_DIR" ]; then
    FLASK_CODE_DIR=/var/code
fi

if [ -z "$FLASK_HTTP_PORT" ]; then
    FLASK_HTTP_PORT=5000
fi

if [ -z "$FLASK_LOG" ]; then
    FLASK_LOG=/var/log/uwsgi/flask.log
fi

mkdir -p /var/log/uwsgi

# This file might not be mounted externally
if [ ! -e "/var/log/uwsgi/last_roll.txt" ]; then
	touch /var/log/uwsgi/last_roll.txt
fi

cd $FLASK_CODE_DIR
set -- gosu uwsgi stdbuf -o L -e L flask run --host=0.0.0.0 --port $FLASK_HTTP_PORT

# We only want to do this when running the UWSGI command
while /bin/true ; do
	echo 'Reloading' > /var/log/uwsgi/last_roll.txt;
	$@ 2>&1 | tee -a $FLASK_LOG || tail -100 $FLASK_LOG | tac | sed -e '/Traceback (most recent call last)/q' | tac > /var/log/uwsgi/last_roll.txt || sleep 1 || true;
done

exit 0

