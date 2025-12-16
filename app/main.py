import requests
from fastapi import FastAPI

app = FastAPI()

@app.get("/{username}")
def get_gists(username: str):
    response = requests.get(f"https://api.github.com/users/{username}/gists")
    if response.status_code == 200:
        gists = response.json()
        return {"gists": [gist["html_url"] for gist in gists]}
    else:
        return {"error": "User not found or API error"}