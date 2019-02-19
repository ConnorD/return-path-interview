# coding: utf-8

import logging
import os
import re
import tarfile

from flask import abort, Flask, flash, g, render_template, request, url_for
from flask_migrate import Migrate, upgrade as upgrade_migrate
from flask_sqlalchemy import SQLAlchemy
import gzip
from sqlalchemy.exc import IntegrityError
from werkzeug.utils import secure_filename

from settings import *
from utils import *

logger = logging.getLogger(__name__)

app = Flask(__name__, instance_relative_config=True)
app.secret_key = 'super secret key'
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://{}:{}@{}:{}/{}'.format(MYSQL_USER, MYSQL_PASS, MYSQL_ADDRESS, MYSQL_PORT, MYSQL_DB)

db = SQLAlchemy(app)
migrate = Migrate(app, db)

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.String(512), unique=True, nullable=False)

    from_address = db.Column(db.String(320), nullable=False)
    from_name = db.Column(db.String(512))
    to_address = db.Column(db.String(320), nullable=False)

    subject = db.Column(db.Text)
    sent_date = db.Column(db.DateTime)


log_level = logging.INFO
logging.basicConfig(level=log_level)

@app.before_first_request
def init_app():
    upgrade_migrate()

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        file = request.files['uploaded_file']
        filename = secure_filename(file.filename)
        new_directory_name = UPLOAD_FOLDER
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        
        # try to extract a tar file
        if 'tar.gz' in filename:
            try:
                new_directory_name = extract_tar_file(filename)
            except:
                flash('Unable to extract tarfile')
        
        try:
            msg_files = get_msg_files_in_dir(new_directory_name)
        except:
            msg_files = [filename]

        for msg_file_name in msg_files:
            parsed_msg = parse_msg_file(os.path.join(new_directory_name, msg_file_name))

            if Message.query.filter(Message.message_id == parsed_msg['message_id']).one_or_none():
                flash('Message-ID {} has already been parsed.'.format(parsed_msg['message_id']))
            else:
                new_message = Message(**parsed_msg)
                db.session.add(new_message)


        db.session.commit()

    messages = Message.query.all()
    return render_template('upload.html', messages=messages)


@app.route('/ping/')
def ping():
    return 'pong', 200
