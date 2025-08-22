import time
import requests
import os

redmine_url = os.environ.get('REDMINE_URL', 'http://redmine:3000')

print("Waiting for Redmine to start...")

while True:
    try:
        response = requests.get(f"{redmine_url}/issues", timeout=10)
        if response.status_code == 200:
            print("Redmine is up and running!")
            break
    except requests.exceptions.RequestException:
        print("Redmine not available, waiting...")
    
    time.sleep(5)