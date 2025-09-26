# Security and Compliance Documentation

## Overview

This document outlines the comprehensive security and compliance processes implemented in the Suricata container project's CI/CD pipeline. Our security-first approach ensures that all container images undergo rigorous security validation before deployment to AWS ECR.

## Security Architecture

### Pipeline Security Model

```
BUILD → SCAN → ECR DEPLOY
  ↓       ↓         ↓
Tests   Trivy   AWS ECR Push
        Scan    (Temp Creds)
```

**Security Gates:**
- All builds must pass functional testing
- All images must pass vulnerability scanning
- No deployment without security validation
- Critical vulnerabilities block pipeline progression
- Temporary AWS credentials via IAM role assumption

## Vulnerability Management

### Automated Security Scanning

**Tool:** Aqua Security Trivy
- **Industry Standard:** CNCF-graduated security scanner
- **Coverage:** Comprehensive vulnerability and configuration scanning
- **Integration:** Automated in every build pipeline

**Scan Configuration:**
```bash
trivy image --security-checks vuln,config --exit-code 1 --severity CRITICAL suricata:latest
# or using image ID
trivy image --security-checks vuln,config --exit-code 1 --severity CRITICAL d5af216ef2d4
```

**Scan Parameters:**
- **Vulnerability Detection:** `vuln` - Scans for known CVEs
- **Configuration Analysis:** `config` - Validates container configuration
- **Severity Threshold:** `CRITICAL` - Fails on critical vulnerabilities
- **Exit Policy:** `--exit-code 1` - Pipeline fails if issues found

**Vulnerability Response:**
- **Critical vulnerabilities:** Immediate pipeline failure
- **Build blocking:** No artifacts created with critical issues
- **Audit trail:** Complete scan results logged
- **Remediation:** Automatic retry after vulnerability fixes

### Security Scanning Process

1. **Image Loading:** Built container loaded from workspace
2. **Trivy Installation:** Latest Trivy scanner installed
3. **Comprehensive Scan:** Full image vulnerability assessment
4. **Result Evaluation:** Critical vulnerabilities cause failure
5. **Gate Enforcement:** No progression without clean scan

## Security Report Access

### Downloading Security Scan Results

All security scan results are packaged in comprehensive artifacts available through CircleCI:

#### **Where to Find Security Reports**

1. **Navigate to CircleCI Pipeline**:
   - Go to [CircleCI](https://app.circleci.com/) → `suricata-container` project
   - Click on the latest successful pipeline run
   - Look for **artifacts jobs** (not build jobs):
     - `artifacts-7x-main-napatech` - Napatech variant security reports
     - `artifacts-7x-main-afpacket` - AF_PACKET variant security reports

2. **Access Security Reports**:
   - Click on an artifacts job → "Artifacts" tab
   - Download `complete/suricata-complete-artifacts-7.0.11.tar.gz` for everything
   - Or download individual files from `components/security/`:

#### **Security Report Types**

**Trivy Container Scanning**:
- `trivy-scan-report-napatech.json` - Detailed vulnerability report (JSON)
- `trivy-scan-report-napatech.txt` - Human-readable vulnerability summary

**Checkmarx SAST Scanning**:
- `checkmarx-scan-results.json` - Detailed SAST findings (JSON)
- `checkmarx-scan-results.txt` - Human-readable SAST report
- `checkmarx-scan-id.txt` - Scan identifier for Checkmarx console
- `checkmarx-scan-response.json` - Scan initiation response

**Combined Security Assessment**:
- `security-gate-summary.json` - Combined evaluation results and deployment decision

#### **Compliance Documentation**

Each security report includes:
- **Timestamps**: Scan execution time and version information
- **CVE References**: Complete vulnerability details with CVSS scores
- **Risk Assessment**: Severity levels and impact analysis
- **Remediation Guidance**: Recommended fixes and updates
- **Compliance Status**: Pass/fail status for security gates

**Important**: Always download from **artifacts jobs** (`artifacts-7x-main-*`) rather than build jobs (`build-7x-main-*`) to get complete security scan results.

## Access Control and Authentication

### AWS ECR Authentication

**Temporary Credentials via IAM Role:**
- **IAM Role:** `arn:aws:iam::YOUR-AWS-ACCOUNT-ID:role/Your-ECR-Push-Role`
- **Method:** STS assume-role-with-web-identity
- **Duration:** Temporary credentials with automatic expiration
- **Scope:** ECR push permissions only

**Security Benefits:**
- **No Long-term Secrets:** No AWS keys stored in CircleCI
- **Automatic Rotation:** Credentials expire automatically
- **Principle of Least Privilege:** Role-based access with minimal permissions
- **Audit Trail:** Complete CloudTrail logging of all actions

**Access Control Points:**
- Source code checkout (SSH key)
- AWS ECR authentication (temporary credentials)
- Docker image operations (IAM role permissions)
- ECR repository access (resource-based policies)

### ECR Deployment Configuration

**Target Repository:**
- **Registry:** `YOUR-AWS-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com`
- **Repository:** `ecoe/pe/engineering/suricata`
- **Region:** `us-east-1`
- **Authentication:** Temporary credentials via CircleCI OIDC

**IAM Role Permissions:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "arn:aws:ecr:us-east-1:YOUR-AWS-ACCOUNT-ID:repository/your-repo-name/suricata"
        }
    ]
}
```

## Container Security Hardening

### Runtime Security

**Base Image Security:**
- **Alpine Linux:** Minimal attack surface
- **Regular Updates:** Latest security patches
- **Minimal Packages:** Only essential runtime components

**Capability Management:**
```dockerfile
# Precise privilege assignment
RUN setcap cap_net_raw,cap_net_admin=eip /usr/bin/suricata
```

**Security Features:**
- **Non-root execution:** Container runs with specific capabilities
- **Minimal privileges:** Only network capabilities required
- **Capability isolation:** No unnecessary system access

### Build Security

**Multi-Stage Build Security:**
- **Separation:** Build and runtime environments isolated
- **Minimal runtime:** Only essential packages in final image
- **Layer optimization:** Reduced attack surface
- **Dependency isolation:** Build tools not in runtime image

**Security Libraries:**
```dockerfile
# Security capability libraries
libcap \
libcap-ng \
# SSL/TLS support
openssl \
```

## Configuration Validation

### Functional Security Testing

**Test Suite:**
1. **Binary Integrity:** Suricata version validation
2. **Configuration Security:** `suricata -T -c /etc/suricata/suricata.yaml`
3. **Tool Validation:** suricata-update functionality
4. **Health Monitoring:** Container runtime health checks

**Validation Process:**
```bash
# Security configuration test
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:latest sh -c "suricata -T -c /etc/suricata/suricata.yaml"
```

**Test Coverage:**
- Configuration syntax validation
- Security policy verification
- Rule loading validation
- Network capability testing

## Compliance and Governance

### Branch Protection and Workflow Isolation

**Security Workflow Enforcement:**
```yaml
workflows:
  build_scan_deploy_7x:
    jobs:
      - build-napatech
      - build-afpacket
      - scan-napatech:     # Mandatory security gate
          requires: [build-napatech, checkmarx-scan]
      - scan-afpacket:     # Mandatory security gate
          requires: [build-afpacket, checkmarx-scan]
      - security-gate:     # Combined security evaluation
          requires: [scan-napatech, scan-afpacket]
      - push-to-ecr:       # Deployment only after security validation
          requires: [build-variant, security-gate]
```

**Workflow Isolation Benefits:**
- **Build Isolation:** Each job runs in clean environment
- **Dependency Control:** Explicit job dependencies prevent bypassing security
- **Artifact Isolation:** Workspace persistence ensures clean artifact flow with variant-specific images
- **Variant Separation:** Each build variant maintains separate workspace artifacts to prevent conflicts
- **Security Gates:** Combined security evaluation from all variants before deployment

**Branch Isolation:**
- **main branch:** Production security standards with dual-variant builds
- **suricata-8.x:** Latest features with same security standards

### Audit Trail and Compliance

**Build Metadata Tracking:**
```json
{
  "version": "7.0.11",
  "branch": "main",
  "commit": "a1b2c3d",
  "build_date": "2025-07-29T19:35:00Z",
  "artifact_name": "suricata-v7.0.11-main-stable-a1b2c3d.tar",
  "image_size": "252MB"
}
```

**Compliance Features:**
- **Artifact retention:** 30-day retention for audit requirements
- **Traceable builds:** Complete commit-to-artifact traceability
- **Pipeline logs:** Full execution logs retained
- **Version tracking:** Comprehensive version and dependency tracking

## Security Incident Response

### Vulnerability Response Process

1. **Detection:** Automated Trivy scanning identifies vulnerabilities
2. **Assessment:** Critical vulnerabilities trigger immediate pipeline failure
3. **Notification:** Build failure alerts development team
4. **Remediation:** Update base images or dependencies
5. **Validation:** Re-run pipeline to confirm fix
6. **Deployment:** Only clean builds progress to deployment

### Security Monitoring

**Continuous Monitoring:**
- Every commit triggers security scan
- All branches subject to same security standards
- Failed scans prevent artifact creation
- Security metrics tracked in pipeline logs

## Current Security Posture

### Implemented Security Controls

**Strengths:**
- Automated vulnerability scanning with industry-standard tools
- Critical vulnerability blocking with immediate pipeline failure
- Multi-stage security validation process
- Minimal container attack surface with Alpine Linux
- Precise capability management for runtime security
- Complete audit trail with metadata tracking
- Security-first deployment with mandatory gates

**Security Metrics:**
- 100% build coverage with security scanning
- Zero critical vulnerabilities in deployed images
- Complete traceability from source to deployment
- Automated security validation in every pipeline

### Areas for Future Enhancement

**Potential Improvements:**
- **SAST/DAST Integration:** Static and dynamic application security testing
- **Dependency Scanning:** Source code dependency vulnerability analysis
- **Compliance Frameworks:** CIS Benchmark and NIST compliance validation
- **Secret Scanning:** Automated detection of exposed secrets
- **SBOM Generation:** Software Bill of Materials for supply chain security
- **Runtime Security:** Container runtime monitoring and protection

## Compliance Frameworks

### Current Compliance Alignment

**Security Standards:**
- **NIST Cybersecurity Framework:** Identify, Protect, Detect, Respond, Recover
- **Container Security:** CIS Docker Benchmark alignment
- **DevSecOps:** Security integrated throughout development lifecycle
- **Supply Chain Security:** Secure build and distribution process

**Audit Readiness:**
- Complete pipeline execution logs
- Vulnerability scan results retention
- Build artifact traceability
- Security control documentation

## Contact and Reporting

### Security Issues

For security vulnerabilities or concerns:
1. **Internal Issues:** Report through standard development channels
2. **Critical Vulnerabilities:** Immediate escalation to security team
3. **Pipeline Failures:** Automated notifications to development team
4. **Compliance Questions:** Reference this documentation

### Documentation Maintenance

This document is maintained alongside the codebase and updated with any security process changes. All security modifications require documentation updates to maintain compliance alignment.

---

**Document Version:** 1.0  
**Last Updated:** July 2025  
**Review Cycle:** Quarterly or with significant security changes
