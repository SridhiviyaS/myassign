import pytest
from unittest.mock import patch, MagicMock
from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

@patch('app.main.requests.get')
def test_get_gists_success(mock_get):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [
        {"html_url": "https://gist.github.com/octocat/1"},
        {"html_url": "https://gist.github.com/octocat/2"}
    ]
    mock_get.return_value = mock_response

    response = client.get("/octocat")
    assert response.status_code == 200
    assert response.json() == {"gists": ["https://gist.github.com/octocat/1", "https://gist.github.com/octocat/2"]}

@patch('app.main.requests.get')
def test_get_gists_user_not_found(mock_get):
    mock_response = MagicMock()
    mock_response.status_code = 404
    mock_get.return_value = mock_response

    response = client.get("/nonexistentuser")
    assert response.status_code == 200
    assert response.json() == {"error": "User not found or API error"}