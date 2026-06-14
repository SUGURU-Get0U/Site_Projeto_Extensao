from app.app import app
from app.backup import make_backup

with app.app_context():
    ok, info = make_backup()
    print('RESULT:', ok, info)