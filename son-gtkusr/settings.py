import os

SQL_CONNECTION = 'postgresql://sonata:sonata@192.168.99.100:5432/usermanagement'

BASE_DIR = os.path.dirname(os.path.realpath(__file__))

HOST = "0.0.0.0"
PORT = 5001


GITHUB_CLIENT_ID = "968e05c4efcf263fb01d"
GITHUB_CLIENT_SECRET = "a98adb5567705876b9610a0bbc33d23d52568a5c"

GITHUB_AUTH_URL = "https://github.com/login/oauth/authorize"
GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token"
GITHUB_USER_INFO_URL = "https://api.github.com/user/emails"
