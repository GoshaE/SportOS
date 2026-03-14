import urllib.request
import zipfile
import io
import os

url = "https://fonts.google.com/download?family=Orbitron"
try:
    print("Downloading Orbitron...")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    response = urllib.request.urlopen(req)
    with zipfile.ZipFile(io.BytesIO(response.read())) as z:
        z.extractall("assets/fonts/Orbitron")
    print("Downloaded Orbitron successfully.")
except Exception as e:
    print(f"Error: {e}")
