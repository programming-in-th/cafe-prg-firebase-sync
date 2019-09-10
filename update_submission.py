import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import sys

FIELDS = {
    'status': (2,'string'),
    'points': (3, 'int'),
    'time': (4, 'float'),
    'memory': (5, 'int'),
    'graded_at': (6,'string'),
}
INT_FIELDS = ['points', 'memory']
FLOAT_FIELDS = ['time']

def main():
    cred = credentials.Certificate('service_account_private_key.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    submission_id = sys.argv[1]
    
    data = {}
    for f in FIELDS.keys():
        v = sys.argv[FIELDS[f][0]]
        try:
            if FIELDS[f][1] == 'string':
                data[f] = v
            elif FIELDS[f][1] == 'int':
                data[f] = int(v)
            else:
                data[f] = float(v)
        except:
            data[f] = v

    transaction = db.transaction()
    doc_ref = db.collection(u'submissions').document(submission_id)

    @firestore.transactional
    def update_submission_transactional(transaction, data):
        transaction.update(doc_ref, data)

    update_submission_transactional(transaction, data)


if __name__ == '__main__':
    main()
