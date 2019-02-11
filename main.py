# coding: utf-8

import logging
import os
import re

from flask import abort, Flask, flash, g, render_template, request, url_for
import gzip
from werkzeug.utils import secure_filename

logger = logging.getLogger(__name__)

translation_re = re.compile('_\((.*?)\)')


UPLOAD_FOLDER = '{}/tmp'.format(os.path.dirname(os.path.realpath(__file__)))
ALLOWED_EXTENSIONS = ['zip', 'tar']

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def create_app(import_name):
    app = Flask(import_name, instance_relative_config=True)

    app.secret_key = 'super secret key'
    app.config['SESSION_TYPE'] = 'filesystem'

    log_level = logging.INFO
    logging.basicConfig(level=log_level)

    @app.route('/', methods=['GET', 'POST'])
    def index():
        if request.method == 'POST':
            file = request.files['uploaded_file']
            filename = secure_filename(file.filename)
            file.save(os.path.join(UPLOAD_FOLDER, filename))
            file_ref = gzip.GzipFile(
                os.path.join(UPLOAD_FOLDER, filename), 'r')
            
            print(file_ref.read())

        return render_template('upload.html')


    @app.route('/ping/')
    def ping():
        return 'pong', 200

    return app

app = create_app(__package__.split('.')[0])
