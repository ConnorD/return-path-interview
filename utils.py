
from datetime import datetime
from email.utils import parseaddr
import tarfile
import os

from settings import *


def extract_tar_file(filename):
    file_ref = tarfile.open(os.path.join(UPLOAD_FOLDER, filename))
    directory_name = file_ref.getnames()[0]
    file_ref.extractall(path=UPLOAD_FOLDER)
    file_ref.close()

    return directory_name


def get_msg_files_in_dir(dirname):
    directory = os.fsencode(os.path.join(UPLOAD_FOLDER, dirname))
    return set(os.fsdecode(f) for f in os.listdir(directory) if os.fsdecode(f).endswith('.msg'))


def parse_msg_file(filename):
    def _parse_date_line(line_str):
        pass

    file_ref = open(os.path.join(UPLOAD_FOLDER, filename))
    msg_data = {}

    for line in file_ref:
        line_split = line.split(':', 1)
        print(line_split)
        if line_split[0] == 'To':
            msg_data['to_address'] = parseaddr(line_split[1])[1]
        elif line_split[0] == 'From':
            parsed_address = parseaddr(line_split[1])
            msg_data['from_name'] = parsed_address[0]
            msg_data['from_address'] = parsed_address[1]
        elif line_split[0] == 'Date':
            try:
                msg_data['sent_date'] = datetime.strptime(line_split[1].strip(), '%a, %d %b %Y %H:%M:%S %z')
            except:
                msg_data['sent_date'] = None
        elif line_split[0] == 'Subject':
            msg_data['subject'] = line_split[1].strip()
        elif line_split[0] == 'Message-ID':
            msg_data['message_id'] = line_split[1].strip().replace('<', '').replace('>', '')

    return msg_data
