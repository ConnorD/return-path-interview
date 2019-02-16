# coding: utf-8

import logging
import os
import re

from flask import abort, Flask, flash, g, render_template, request, url_for
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
import gzip
from werkzeug.utils import secure_filename

from settings import UPLOAD_FOLDER, ALLOWED_EXTENSIONS

logger = logging.getLogger(__name__)

app = Flask(__name__, instance_relative_config=True)
app.secret_key = 'super secret key'
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://web_user:fake_password@127.0.0.1:3306/rp_app'

db = SQLAlchemy(app)
migrate = Migrate(app, db)

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.Text, nullable=True)


class Contact(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email_address = db.Column(db.String(120), unique=True, nullable=False)
    name = db.Column(db.String(256), unique=False, nullable=True)


log_level = logging.INFO
logging.basicConfig(level=log_level)


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/', methods=['GET', 'POST'])
def index():
    print(db.session)
    if request.method == 'POST':
        file = request.files['uploaded_file']
        filename = secure_filename(file.filename)
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        file_ref = gzip.GzipFile(
            os.path.join(UPLOAD_FOLDER, filename), 'r')

        while True:
            line = file_ref.readline()

            if not line:
                break

            if 'From:' in str(line):
                print(line)

    return render_template('upload.html')

@app.route('/ping/')
def ping():
    return 'pong', 200
