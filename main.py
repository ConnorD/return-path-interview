# coding: utf-8

import logging
import os
import re

from flask import abort, Flask, g, render_template, request, url_for

logger = logging.getLogger(__name__)

translation_re = re.compile('_\((.*?)\)')


def create_app(import_name):
    app = Flask(import_name, instance_relative_config=True)

    log_level = logging.INFO
    logging.basicConfig(level=log_level)

    @app.route('/')
    def index():
        haha = False
        return render_template('test.html', haha=haha)

    @app.route('/ping/')
    def ping():
        return 'pong', 200

    return app

app = create_app(__package__.split('.')[0])
