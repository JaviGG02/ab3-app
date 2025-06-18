from locust import HttpUser, task, between

class CloudFrontUser(HttpUser):
    # Wait between 1 and 5 seconds between tasks
    wait_time = between(1, 5)
    
    @task
    def get_homepage(self):
        # Send GET request to the root path
        self.client.get("/")
    
    @task(3)  # This task runs 3x more frequently
    def get_api_endpoint(self):
        # Replace with actual API endpoints your application has
        self.client.get("/api/data")
        
    @task(2)  # This task runs 2x more frequently than get_homepage
    def get_static_assets(self):
        # Simulate requests to static assets
        self.client.get("/static/css/main.css")
        self.client.get("/static/js/app.js")
        self.client.get("/static/images/logo.png")