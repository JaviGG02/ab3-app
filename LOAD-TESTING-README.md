# CloudFront and EKS Load Testing

This directory contains tools to help you simulate load against your CloudFront distribution and monitor how your EKS cluster auto-scales in response.

## Prerequisites

- AWS CLI configured with access to your EKS cluster
- kubectl configured to access your EKS cluster
- Python 3.7+ (for Locust)
- JMeter (optional, for advanced testing)

## Setup

1. Configure kubectl to connect to your EKS cluster:
   ```
   aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
   ```

2. Install required Python packages:
   ```
   pip install -r requirements.txt
   ```

## Option 1: Using Locust (Recommended)

Locust is a simple, Python-based load testing tool that's easy to use and provides a web UI for controlling tests.

### Steps:

1. Edit the `locustfile.py` to customize the request patterns if needed
2. Run the PowerShell script:
   ```
   .\run-locust-test.ps1
   ```
3. Choose option 1 to configure your CloudFront URL
4. Choose option 2 to start the Locust web UI
5. In your browser (http://localhost:8089):
   - Set the number of users to simulate
   - Set the spawn rate (users started per second)
   - Click "Start swarming" to begin the test
6. While the test is running, use option 3 in the PowerShell script to monitor EKS scaling

### Customizing Tests

Edit the `locustfile.py` to add more realistic request patterns that match your application:

- Add more `@task` methods to simulate different API calls
- Adjust the weight of tasks by changing the number in `@task(n)`
- Modify the `wait_time` to simulate different user behaviors

## Option 2: Using JMeter (Advanced)

JMeter provides more advanced load testing capabilities but requires more setup.

### Steps:

1. Install Apache JMeter from https://jmeter.apache.org/download_jmeter.cgi
2. Add JMeter's bin directory to your PATH
3. Run the PowerShell script:
   ```
   .\cloudfront-load-test.ps1
   ```
4. Follow the menu options to configure and run your test

## Monitoring Auto-Scaling

Both scripts include an option to monitor EKS scaling. This will show:

- Node status (to see new nodes being added)
- Pod status (to see pods being scheduled)
- HPA status (to see scaling decisions)

## Direct EKS Load Testing

If you want to test EKS auto-scaling directly without going through CloudFront:

1. Apply the Kubernetes manifest:
   ```
   kubectl apply -f load-test.yaml
   ```

2. Run the monitoring script:
   ```
   .\run-load-test.ps1
   ```

3. Use the menu to increase load and monitor scaling

## Tips for Effective Testing

1. **Start small**: Begin with a small number of users and gradually increase
2. **Monitor CloudWatch**: Check CloudWatch metrics for your EKS cluster during testing
3. **Watch for bottlenecks**: Look for signs of resource constraints in your monitoring
4. **Test different patterns**: Try different request patterns to simulate real-world usage
5. **Allow time for scaling**: Auto-scaling isn't instantaneous, so run tests long enough to see the full scaling behavior

## Cleanup

When you're done testing, make sure to clean up resources:

```
kubectl delete -f load-test.yaml
```

Or use the cleanup option in the scripts.