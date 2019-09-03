import firebase_admin
from firebase_admin import auth

UID = 'cafe-grader-judge'

def main():
    firebase_admin.initialize_app()
    print(auth.create_custom_token(UID).decode('utf-8'))

if __name__ == '__main__':
    main()
