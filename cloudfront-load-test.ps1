# PowerShell script to run load test against CloudFront distribution

# Configuration - Update these values
$CLOUDFRONT_URL = "https://your-distribution-id.cloudfront.net" # Replace with your CloudFront URL
$TEST_DURATION = 300 # Duration in seconds
$CONCURRENT_USERS = 50 # Number of concurrent users
$RAMP_UP_PERIOD = 60 # Ramp-up period in seconds

# Function to check if JMeter is installed
function Check-JMeter {
    try {
        $jmeterVersion = & jmeter -v 2>&1
        if ($jmeterVersion -match "Apache JMeter") {
            Write-Host "JMeter is installed."
            return $true
        }
    }
    catch {
        Write-Host "JMeter is not installed or not in PATH."
        Write-Host "Please download and install Apache JMeter from https://jmeter.apache.org/download_jmeter.cgi"
        Write-Host "After installation, add the JMeter bin directory to your PATH environment variable."
        return $false
    }
}

# Function to create JMeter test plan
function Create-JMeterTestPlan {
    $testPlanPath = "cloudfront-load-test.jmx"
    
    Write-Host "Creating JMeter test plan at $testPlanPath..."
    
    $testPlanContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.5">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="CloudFront Load Test" enabled="true">
      <stringProp name="TestPlan.comments"></stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments" guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables" enabled="true">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="CloudFront Users" enabled="true">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="Loop Controller" enabled="true">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <intProp name="LoopController.loops">-1</intProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">$CONCURRENT_USERS</stringProp>
        <stringProp name="ThreadGroup.ramp_time">$RAMP_UP_PERIOD</stringProp>
        <boolProp name="ThreadGroup.scheduler">true</boolProp>
        <stringProp name="ThreadGroup.duration">$TEST_DURATION</stringProp>
        <stringProp name="ThreadGroup.delay">0</stringProp>
        <boolProp name="ThreadGroup.same_user_on_next_iteration">true</boolProp>
      </ThreadGroup>
      <hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="CloudFront Request" enabled="true">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" testname="User Defined Variables" enabled="true">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPSampler.domain"></stringProp>
          <stringProp name="HTTPSampler.port"></stringProp>
          <stringProp name="HTTPSampler.protocol"></stringProp>
          <stringProp name="HTTPSampler.contentEncoding"></stringProp>
          <stringProp name="HTTPSampler.path">$CLOUDFRONT_URL</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
          <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
          <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
          <stringProp name="HTTPSampler.connect_timeout"></stringProp>
          <stringProp name="HTTPSampler.response_timeout"></stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <UniformRandomTimer guiclass="UniformRandomTimerGui" testclass="UniformRandomTimer" testname="Uniform Random Timer" enabled="true">
            <stringProp name="ConstantTimer.delay">1000</stringProp>
            <stringProp name="RandomTimer.range">500</stringProp>
          </UniformRandomTimer>
          <hashTree/>
        </hashTree>
        <ResultCollector guiclass="ViewResultsFullVisualizer" testclass="ResultCollector" testname="View Results Tree" enabled="true">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class="SampleSaveConfiguration">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
              <message>true</message>
              <threadName>true</threadName>
              <dataType>true</dataType>
              <encoding>false</encoding>
              <assertions>true</assertions>
              <subresults>true</subresults>
              <responseData>false</responseData>
              <samplerData>false</samplerData>
              <xml>false</xml>
              <fieldNames>true</fieldNames>
              <responseHeaders>false</responseHeaders>
              <requestHeaders>false</requestHeaders>
              <responseDataOnError>false</responseDataOnError>
              <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
              <assertionsResultsToSave>0</assertionsResultsToSave>
              <bytes>true</bytes>
              <sentBytes>true</sentBytes>
              <url>true</url>
              <threadCounts>true</threadCounts>
              <idleTime>true</idleTime>
              <connectTime>true</connectTime>
            </value>
          </objProp>
          <stringProp name="filename"></stringProp>
        </ResultCollector>
        <hashTree/>
        <ResultCollector guiclass="SummaryReport" testclass="ResultCollector" testname="Summary Report" enabled="true">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class="SampleSaveConfiguration">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
              <message>true</message>
              <threadName>true</threadName>
              <dataType>true</dataType>
              <encoding>false</encoding>
              <assertions>true</assertions>
              <subresults>true</subresults>
              <responseData>false</responseData>
              <samplerData>false</samplerData>
              <xml>false</xml>
              <fieldNames>true</fieldNames>
              <responseHeaders>false</responseHeaders>
              <requestHeaders>false</requestHeaders>
              <responseDataOnError>false</responseDataOnError>
              <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
              <assertionsResultsToSave>0</assertionsResultsToSave>
              <bytes>true</bytes>
              <sentBytes>true</sentBytes>
              <url>true</url>
              <threadCounts>true</threadCounts>
              <idleTime>true</idleTime>
              <connectTime>true</connectTime>
            </value>
          </objProp>
          <stringProp name="filename">cloudfront-load-test-results.csv</stringProp>
        </ResultCollector>
        <hashTree/>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
"@

    $testPlanContent | Out-File -FilePath $testPlanPath -Encoding UTF8
    return $testPlanPath
}

# Function to run JMeter test
function Run-JMeterTest {
    param (
        [string]$testPlanPath
    )
    
    Write-Host "Running JMeter test plan..."
    Write-Host "Test will run for $TEST_DURATION seconds with $CONCURRENT_USERS concurrent users."
    
    # Create results directory if it doesn't exist
    if (-not (Test-Path -Path "results")) {
        New-Item -Path "results" -ItemType Directory | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = "results\jmeter-$timestamp.log"
    $resultsFile = "results\results-$timestamp.jtl"
    
    # Run JMeter in non-GUI mode
    & jmeter -n -t $testPlanPath -l $resultsFile -j $logFile
    
    Write-Host "Test completed. Results saved to $resultsFile"
    Write-Host "Log file: $logFile"
}

# Function to monitor EKS scaling during the test
function Monitor-EKSScaling {
    Write-Host "`nMonitoring EKS scaling (Press Ctrl+C to stop)..."
    
    try {
        while ($true) {
            Write-Host "`n--- $(Get-Date) ---"
            
            # Get node status
            Write-Host "`nNode Status:"
            kubectl get nodes
            
            # Get pod status
            Write-Host "`nPod Status:"
            kubectl get pods --all-namespaces | Select-String -Pattern "Running|Pending"
            
            # Get HPA status if any
            Write-Host "`nHPA Status:"
            kubectl get hpa --all-namespaces
            
            # Wait before checking again
            Start-Sleep -Seconds 15
        }
    }
    finally {
        Write-Host "`nStopped monitoring."
    }
}

# Main menu
function Show-Menu {
    Write-Host "`n=== CloudFront Load Testing Menu ==="
    Write-Host "1. Configure test parameters"
    Write-Host "2. Run load test"
    Write-Host "3. Monitor EKS scaling"
    Write-Host "4. Exit"
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" {
            $CLOUDFRONT_URL = Read-Host "Enter your CloudFront URL (e.g., https://d123456abcdef8.cloudfront.net)"
            $TEST_DURATION = Read-Host "Enter test duration in seconds (default: 300)"
            $CONCURRENT_USERS = Read-Host "Enter number of concurrent users (default: 50)"
            $RAMP_UP_PERIOD = Read-Host "Enter ramp-up period in seconds (default: 60)"
            
            # Set defaults if empty
            if ([string]::IsNullOrWhiteSpace($TEST_DURATION)) { $TEST_DURATION = 300 }
            if ([string]::IsNullOrWhiteSpace($CONCURRENT_USERS)) { $CONCURRENT_USERS = 50 }
            if ([string]::IsNullOrWhiteSpace($RAMP_UP_PERIOD)) { $RAMP_UP_PERIOD = 60 }
            
            Write-Host "Configuration updated."
        }
        "2" {
            if ([string]::IsNullOrWhiteSpace($CLOUDFRONT_URL) -or $CLOUDFRONT_URL -eq "https://your-distribution-id.cloudfront.net") {
                Write-Host "Please configure your CloudFront URL first (option 1)."
            }
            else {
                if (Check-JMeter) {
                    $testPlanPath = Create-JMeterTestPlan
                    Run-JMeterTest -testPlanPath $testPlanPath
                }
            }
        }
        "3" { Monitor-EKSScaling }
        "4" { return $false }
        default { Write-Host "Invalid choice. Try again." }
    }
    
    return $true
}

# Main loop
Write-Host "CloudFront Load Testing Tool"
Write-Host "============================"
Write-Host "This script will help you generate load against your CloudFront distribution"
Write-Host "and monitor how your EKS cluster auto-scales in response."

$continue = $true
while ($continue) {
    $continue = Show-Menu
}

Write-Host "Exiting script."