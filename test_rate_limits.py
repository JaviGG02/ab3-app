import subprocess
import sys
import time

def run_test(users, spawn_rate, duration_seconds):
    """Run a short test with specified parameters"""
    print(f"Starting test with {users} users, spawn rate {spawn_rate}/sec for {duration_seconds} seconds")
    
    cmd = [
        sys.executable,
        "-m",
        "locust",
        "--headless",
        "-f", "locustfile.py",
        "--users", str(users),
        "--spawn-rate", str(spawn_rate),
        "--run-time", f"{duration_seconds}s",
        "--html", f"report_rate_test_{users}users.html"
    ]
    
    subprocess.run(cmd)
    print(f"Test completed. Report saved to report_rate_test_{users}users.html")
    time.sleep(5)  # Wait between tests

# Run a series of tests with increasing user counts
# Start with small numbers to see where the 403s begin
run_test(10, 1, 30)   # 10 users, very slow ramp-up
run_test(25, 2, 30)   # 25 users
run_test(50, 5, 30)   # 50 users

print("All rate limit tests completed.")