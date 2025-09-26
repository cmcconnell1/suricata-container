# Checkmarx Integration for Suricata Container Pipeline

## Overview

This document describes the integration of Checkmarx SAST (Static Application Security Testing) into the CircleCI pipeline for the suricata-container project. The integration provides comprehensive security scanning alongside the existing Trivy container vulnerability scanning.

## Architecture

### Pipeline Flow
```
┌─────────────┐    ┌─────────────┐
│build-napatech│    │checkmarx-scan│
└─────┬───────┘    └─────┬───────┘
      │                  │
┌─────────────┐          │
│build-afpacket│          │
└─────┬───────┘          │
      │                  │
      └─────┬────────────┘
            ▼
    ┌─────────────┐    ┌─────────────┐
    │scan-napatech│    │scan-afpacket│
    └─────┬───────┘    └─────┬───────┘
          │                  │
          └─────┬────────────┘
                ▼
        ┌─────────────┐
        │security-gate│
        └─────┬───────┘
              ▼
        ┌─────────────┐
        │push-to-ecr  │
        └─────────────┘
```

### Key Features

1. **Parallel Execution**: Checkmarx SAST scanning runs in parallel with dual-variant container builds for efficiency
2. **Early Security Feedback**: Source code security issues are identified before container deployment
3. **Combined Security Gate**: Both Trivy (from both variants) and Checkmarx results are evaluated before deployment
4. **Comprehensive Reporting**: All security scan results are stored as CircleCI artifacts
5. **Workspace Isolation**: Each build variant maintains separate workspace artifacts to prevent conflicts

## Environment Variables

The following environment variables must be configured in CircleCI project settings:

| Variable | Description | Example |
|----------|-------------|---------|
| `CX_BASE_AUTH_URI` | Checkmarx authentication endpoint | `https://your-checkmarx-server.example.com` |
| `CX_BASE_URI` | Checkmarx API base URI | `https://your-checkmarx-server.example.com` |
| `CX_CLIENT_ID` | Checkmarx client identifier | `your-client-id` |
| `CX_CLIENT_SECRET` | Checkmarx client secret | `your-client-secret` |
| `CX_PROJECT_NAME` | Project name in Checkmarx | `your-project-name` |
| `CX_TENANT` | Checkmarx tenant identifier | `your-tenant-id` |
| `CX_VERSION` | Checkmarx CLI version to use | `2.0.16` |

## Jobs

### checkmarx-scan

**Purpose**: Performs SAST scanning of the source code using Checkmarx CLI

**Key Steps**:
1. Downloads and installs Checkmarx CLI
2. Initiates scan with project configuration
3. Waits for scan completion
4. Retrieves and stores scan results
5. Generates both JSON and text reports

**Artifacts Generated**:
- `checkmarx-scan-response.json`: Initial scan creation response
- `checkmarx-scan-results.json`: Detailed scan results in JSON format
- `checkmarx-scan-results.txt`: Human-readable scan results
- `checkmarx-scan-id.txt`: Scan ID for reference

### security-gate

**Purpose**: Evaluates combined security results from both Trivy and Checkmarx scans

**Security Policy**:
- **Trivy**: Critical vulnerabilities block deployment
- **Checkmarx**: High/Critical findings are reported but do not block deployment
- **Combined**: Deployment proceeds only if Trivy passes (Checkmarx provides advisory information)

**Decision Logic**:
```bash
if trivy_critical_vulns > 0:
    BLOCK_DEPLOYMENT = true
else:
    BLOCK_DEPLOYMENT = false

# Checkmarx findings are logged but don't block deployment
# This allows for manual review of SAST findings
```

## Workflow Integration

### Suricata 7.x (main branch)
- Supports both Napatech and AF_PACKET variants
- Single Checkmarx scan covers both build variants
- Security gate evaluates results from both Trivy scans

### Suricata 8.x (suricata-8.x branch)
- Single AF_PACKET variant
- Streamlined security pipeline
- Same security gate logic applies

## Security Reports

All security scan results are available in CircleCI artifacts under the `security/` directory:

### Trivy Container Scanning
- `trivy-scan-report.json`: Detailed vulnerability report
- `trivy-scan-report.txt`: Human-readable summary

### Checkmarx SAST Scanning
- `checkmarx-scan-response.json`: Scan initiation response
- `checkmarx-scan-results.json`: Detailed SAST findings
- `checkmarx-scan-results.txt`: Human-readable SAST report
- `checkmarx-scan-id.txt`: Scan identifier for Checkmarx console

### Combined Security Gate
- `security-gate-summary.json`: Combined evaluation results

## Accessing Security Reports

### How to Download Security Scan Results

Security reports are packaged in comprehensive artifacts created by the pipeline:

#### **Step 1: Navigate to CircleCI**
1. Go to [CircleCI](https://app.circleci.com/) and open the `suricata-container` project
2. Click on the latest successful pipeline run
3. Look for the **artifacts jobs** (not the build jobs):
   - `artifacts-7x-main-napatech` - Comprehensive Napatech variant artifacts
   - `artifacts-7x-main-afpacket` - Comprehensive AF_PACKET variant artifacts

#### **Step 2: Download Security Reports**
1. Click on one of the artifacts jobs (e.g., `artifacts-7x-main-napatech`)
2. Go to the **"Artifacts"** tab
3. Download options:
   - **Complete Package**: `complete/suricata-complete-artifacts-7.0.11.tar.gz` (recommended)
   - **Individual Reports**: From `components/security/` directory

#### **Step 3: Extract and Review**
The complete package contains all security reports in the `components/security/` directory:
- `checkmarx-scan-results.json` - SAST findings (machine-readable)
- `checkmarx-scan-results.txt` - SAST findings (human-readable)
- `trivy-scan-report-napatech.json` - Container vulnerabilities (JSON)
- `trivy-scan-report-napatech.txt` - Container vulnerabilities (text)
- `security-gate-summary.json` - Combined security assessment

#### **Important Note**
Always download from **artifacts jobs** (`artifacts-7x-main-*`) rather than **build jobs** (`build-7x-main-*`). Build jobs only contain basic container images, while artifacts jobs contain the comprehensive packages with all security scan results.

## Troubleshooting

### Common Issues

1. **Checkmarx CLI Download Fails**
   - Verify `CX_VERSION` environment variable is correct
   - Check network connectivity to GitHub releases

2. **Authentication Errors**
   - Verify all Checkmarx environment variables are set correctly
   - Check client credentials with Checkmarx administrator

3. **Scan Timeout**
   - Large codebases may require longer scan times
   - Monitor scan progress in Checkmarx console using scan ID

4. **Security Gate Failures**
   - Review Trivy scan results for critical vulnerabilities
   - Check security-gate-summary.json for detailed failure reasons

### Monitoring

- **Scan IDs**: Stored in artifacts for tracking in Checkmarx console
- **Execution Time**: Monitor job duration for performance optimization
- **Failure Rates**: Track security gate pass/fail rates

## Future Enhancements

1. **Configurable Security Policies**: Make security gate thresholds configurable
2. **Checkmarx Result Integration**: Parse and enforce Checkmarx findings
3. **Notification Integration**: Add Slack/email notifications for security findings
4. **Trend Analysis**: Track security metrics over time
