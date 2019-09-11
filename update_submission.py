import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import sys

FIELDS = {
    'status': (3,'string'),
    'points': (4, 'int'),
    'time': (5, 'float'),
    'memory': (6, 'int'),
    'graded_at': (7,'string'),
}
INT_FIELDS = ['points', 'memory']
FLOAT_FIELDS = ['time']

def main():
    cred = credentials.Certificate(sys.argv[1])
    
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    submission_id = sys.argv[2]
    
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
