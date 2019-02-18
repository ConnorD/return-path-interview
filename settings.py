# coding: utf-8

import os

MYSQL_USER = 'web_user'
MYSQL_PASS = 'fake_password'
MYSQL_ADDRESS = 'db'
MYSQL_PORT = '3306'
MYSQL_DB = 'rp_app'

UPLOAD_FOLDER = '{}/tmp'.format(os.path.dirname(os.path.realpath(__file__)))
ALLOWED_EXTENSIONS = ['zip', 'tar']
