from locust import HttpUser, task, between
import random
import time
import uuid

class WebsiteUser(HttpUser):
    # Wait between 2 and 8 seconds between tasks to be more realistic
    wait_time = between(2, 8)
    
    # Define the host URL
    host = "https://d34q6clef3mm3t.cloudfront.net"
    # host = "http://k8s-default-uiingres-24a499ec52-71359617.eu-west-1.elb.amazonaws.com"
    
    def on_start(self):
        """Setup for each simulated user"""
        # Generate a session ID similar to the one in the request
        session_id = str(uuid.uuid4())
        
        # Add cookies that might be needed
        self.client.cookies.update({
            "SESSIONID": session_id,
        })
        
        # Visit homepage first like a real user would
        with self.client.get("/", name="Initial Homepage Visit") as response:
            if response.status_code != 200:
                print(f"Initial homepage visit failed: {response.status_code}")
    
    @task(10)
    def visit_homepage(self):
        # Add common headers that browsers send
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Cache-Control": "no-cache"
        }
        self.client.get("/", headers=headers, name="Homepage")
    
    @task(5)
    def visit_catalog(self):
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Referer": f"{self.host}/"
        }
        self.client.get("/catalog", headers=headers, name="Catalog")
    
    @task(3)
    def visit_product_detail(self):
        product_id = "a1258cd2-176c-4507-ade6-746dab5ad625"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Referer": f"{self.host}/catalog"
        }
        self.client.get(f"/catalog/{product_id}", headers=headers, name="Product Detail")
    
    @task(4)
    def add_to_cart(self):
        """Simulate adding a product to cart with POST request"""
        # Product IDs to randomly select from
        product_ids = [
            "79bce3f3-935f-4912-8c62-0d2f3e059405",
            "a1258cd2-176c-4507-ade6-746dab5ad625"
        ]
        
        # Select a random product
        product_id = random.choice(product_ids)
        
        # Headers as specified in the example_calls
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Content-Type": "application/x-www-form-urlencoded",
            "Origin": self.host,
            "Connection": "keep-alive",
            "Referer": f"{self.host}/catalog",
            "Upgrade-Insecure-Requests": "1",
            "Priority": "u=0, i",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        }
        
        # Form data
        data = {
            "productId": product_id
        }
        
        # Make the POST request to add item to cart
        with self.client.post(
            "/cart", 
            data=data,
            headers=headers,
            name="Add to Cart",
            catch_response=True
        ) as response:
            if response.status_code != 200 and response.status_code != 302 and response.status_code != 303:
                print(f"Add to cart failed: {response.status_code}")
                response.failure(f"Add to cart failed with status code: {response.status_code}")
            else:
                response.success()
        
        # Follow redirect to cart page
        cart_headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Referer": f"{self.host}/catalog",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Priority": "u=0, i",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        }
        
        self.client.get("/cart", headers=cart_headers, name="View Cart After Add")
    
    @task(1)
    def view_checkout(self):
        """Simulate viewing the checkout page"""
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Connection": "keep-alive",
            "Referer": f"{self.host}/cart",
            "Upgrade-Insecure-Requests": "1",
            "Priority": "u=0, i",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        }
        
        self.client.get("/checkout", headers=headers, name="View Checkout")
    
    @task(2)
    def checkout_flow(self):
        """Simulate the checkout process with all steps"""
        # Common headers for all requests
        base_headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Content-Type": "application/x-www-form-urlencoded",
            "Origin": self.host,
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Priority": "u=0, i",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        }
        
        # First add a product to cart
        product_id = "79bce3f3-935f-4912-8c62-0d2f3e059405"
        cart_headers = base_headers.copy()
        cart_headers["Referer"] = f"{self.host}/catalog"
        
        self.client.post(
            "/cart",
            data={"productId": product_id},
            headers=cart_headers,
            name="Checkout Flow: Add to Cart"
        )
        time.sleep(random.uniform(1, 2))
        
        # View checkout page
        self.client.get("/checkout", headers=base_headers, name="Checkout Flow: View Checkout")
        time.sleep(random.uniform(1, 2))
        
        # Step 1: Submit customer information
        checkout_headers = base_headers.copy()
        checkout_headers["Referer"] = f"{self.host}/checkout"
        
        checkout_data = {
            "firstName": "John",
            "lastName": "Doe",
            "streetAddress": "100 Main Street",
            "city": "Anytown",
            "state": "CA",
            "zipCode": "11111",
            "email": "john_doe@example.com"
        }
        
        self.client.post(
            "/checkout",
            data=checkout_data,
            headers=checkout_headers,
            name="Checkout Flow: Customer Info"
        )
        time.sleep(random.uniform(1, 2))
        
        # Step 2: Select delivery method
        delivery_headers = base_headers.copy()
        delivery_headers["Referer"] = f"{self.host}/checkout"
        
        self.client.post(
            "/checkout/delivery",
            data={"token": "priority-mail"},
            headers=delivery_headers,
            name="Checkout Flow: Delivery Method"
        )
        time.sleep(random.uniform(1, 2))
        
        # Step 3: Submit payment information
        payment_headers = base_headers.copy()
        payment_headers["Referer"] = f"{self.host}/checkout/delivery"
        
        payment_data = {
            "cardHolder": "John Doe",
            "cardNumber": "1234567890123456",
            "expiryDate": "01/35",
            "cvc": "123"
        }
        
        self.client.post(
            "/checkout/payment",
            data=payment_data,
            headers=payment_headers,
            name="Checkout Flow: Payment"
        )
    
    @task(2)
    def user_flow(self):
        """Simulate a complete user flow with proper sequencing"""
        # Visit homepage
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Upgrade-Insecure-Requests": "1",
            "Priority": "u=0, i",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        }
        
        self.client.get("/", headers=headers, name="Flow: Homepage")
        time.sleep(random.uniform(1, 3))
        
        # Visit catalog
        catalog_headers = headers.copy()
        catalog_headers["Referer"] = f"{self.host}/"
        
        self.client.get("/catalog", headers=catalog_headers, name="Flow: Catalog")
        time.sleep(random.uniform(1, 3))
        
        # Visit product
        product_id = "a1258cd2-176c-4507-ade6-746dab5ad625"
        product_headers = headers.copy()
        product_headers["Referer"] = f"{self.host}/catalog"
        
        self.client.get(f"/catalog/{product_id}", headers=product_headers, name="Flow: Product Detail")
        time.sleep(random.uniform(1, 3))
        
        # Add to cart with POST request
        cart_headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate",
            "Content-Type": "application/x-www-form-urlencoded",
            "Origin": self.host,
            "Connection": "keep-alive",
            "Referer": f"{self.host}/catalog/{product_id}",
            "Upgrade-Insecure-Requests": "1",
            "Priority": "u=0, i",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        }
        
        data = {
            "productId": product_id
        }
        
        self.client.post("/cart", data=data, headers=cart_headers, name="Flow: Add to Cart")
        time.sleep(random.uniform(1, 2))
        
        # View cart
        view_cart_headers = headers.copy()
        view_cart_headers["Referer"] = f"{self.host}/catalog/{product_id}"
        
        self.client.get("/cart", headers=view_cart_headers, name="Flow: View Cart")
        time.sleep(random.uniform(1, 2))
        
        # Sometimes remove an item from cart
        if random.random() < 0.5:  # 50% chance to remove item
            remove_headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.5",
                "Accept-Encoding": "gzip, deflate",
                "Content-Type": "application/x-www-form-urlencoded",
                "Origin": self.host,
                "Connection": "keep-alive",
                "Referer": f"{self.host}/cart",
                "Upgrade-Insecure-Requests": "1",
                "Priority": "u=0, i",
                "Pragma": "no-cache",
                "Cache-Control": "no-cache"
            }
            
            self.client.post(
                "/cart/remove",
                data={"productId": product_id},
                headers=remove_headers,
                name="Flow: Remove from Cart"
            )