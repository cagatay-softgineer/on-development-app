import pytest

pytest.skip("Load test requires locust module", allow_module_level=True)

from locust import HttpUser, TaskSet, task, between
from dotenv import load_dotenv
import os

load_dotenv()

ADMIN = os.getenv("ADMIN")
ADMIN_PWORD = os.getenv("ADMIN_PWORD")
TEST_USER = os.getenv("TEST_USER")
TEST_USER_PWORD = os.getenv("TEST_USER_PWORD")

class UserBehavior(TaskSet):
    # ---------------- Healthchecks ----------------
    @task(1)
    def auth_healthcheck(self):
        self.client.get("/auth/healthcheck")

    @task(1)
    def profile_healthcheck(self):
        self.client.get("/profile/healthcheck")

    @task(1)
    def messaging_healthcheck(self):
        self.client.get("/apps/healthcheck")

    @task(1)
    def friendship_healthcheck(self):
        self.client.get("/spotify/healthcheck")

    @task(1)
    def api_healthcheck(self):
        self.client.get("/spotify-micro-service/healthcheck")
        
    @task(10)
    def app_healthcheck(self):
        self.client.get("/healthcheck")

class WebsiteUser(HttpUser):
    # Change the host to point to the load balancer
    host = "http://127.0.0.1:8080"  # Replace with your load balancer's address

    tasks = [UserBehavior]
    wait_time = between(3, 10)  # Random wait time between requests (1-2 seconds)
