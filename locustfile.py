from locust import HttpUser, task, between
import random
import time

class WebsiteUser(HttpUser):
    # Wait between 2 and 8 seconds between tasks to be more realistic
    wait_time = between(2, 8)
    
    # Define the host URL
    host = "https://d225fcosmp3iu3.cloudfront.net"
    
    def on_start(self):
        """Setup for each simulated user"""
        # Add cookies that might be needed
        self.client.cookies.update({
            "session_id": f"test_session_{random.randint(1000, 9999)}",
        })
        
        # Visit homepage first like a real user would
        with self.client.get("/", name="Initial Homepage Visit") as response:
            if response.status_code != 200:
                print(f"Initial homepage visit failed: {response.status_code}")
    
    @task(10)
    def visit_homepage(self):
        # Add common headers that browsers send
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Cache-Control": "no-cache"
        }
        self.client.get("/", headers=headers, name="Homepage")
    
    @task(5)
    def visit_catalog(self):
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Referer": f"{self.host}/"
        }
        self.client.get("/catalog", headers=headers, name="Catalog")
    
    @task(3)
    def visit_product_detail(self):
        product_id = "a1258cd2-176c-4507-ade6-746dab5ad625"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Referer": f"{self.host}/catalog"
        }
        self.client.get(f"/catalog/{product_id}", headers=headers, name="Product Detail")
    
    @task(2)
    def user_flow(self):
        """Simulate a complete user flow with proper sequencing"""
        # Visit homepage
        self.client.get("/", name="Flow: Homepage")
        time.sleep(random.uniform(1, 3))
        
        # Visit catalog
        self.client.get("/catalog", name="Flow: Catalog")
        time.sleep(random.uniform(1, 3))
        
        # Visit product
        product_id = "a1258cd2-176c-4507-ade6-746dab5ad625"
        self.client.get(f"/catalog/{product_id}", name="Flow: Product Detail")
        time.sleep(random.uniform(1, 3))
        
        # Add to cart (this would normally be a POST request)
        self.client.get("/cart", name="Flow: Cart")
        
        # We'll skip checkout flows as they likely require authentication