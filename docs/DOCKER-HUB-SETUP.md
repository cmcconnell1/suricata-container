# Docker Hub Push Setup Guide

## Overview

This guide explains how to enable Docker Hub image pushing in the CircleCI pipeline. The functionality is currently commented out but ready to be activated when needed.

## Legacy Compatibility

The Docker Hub push functionality is designed to match the authentication pattern from the legacy `albert_build_scripts` codebase:

- **Authentication Pattern**: Uses `DOCKER_HUB_RW_PASSWORD` environment variable
- **Registry Namespace**: `engineering2` (matches legacy convention)
- **Image Naming**: Follows legacy naming conventions for different variants

## Prerequisites

### 1. Docker Hub Account Setup

Ensure you have:
- Docker Hub account with push permissions to `engineering2` namespace
- Docker Hub username (legacy default: `example-user`)
- Docker Hub password or access token

### 2. CircleCI Environment Variables

Set the following environment variables in your CircleCI project settings:

```bash
DOCKER_HUB_RW_USERNAME=example-user
DOCKER_HUB_RW_PASSWORD=your_docker_hub_password_or_token
```

**Security Note**: Use Docker Hub access tokens instead of passwords for better security.

## Enabling Docker Hub Push

### Step 1: Uncomment the Push Job

In `.circleci/config.yml`, find and uncomment the `push-to-docker-hub` job:

```yaml
# Remove the comment markers (#) from lines 306-391
push-to-docker-hub:
  executor: suricata-builder
  parameters:
    image-tag:
      type: string
    suricata-version:
      type: string
    build-variant:
      type: string
      default: "alpine"
  steps:
    # ... (rest of the job definition)
```

### Step 2: Uncomment Desired Workflow

Choose and uncomment one of the example workflows at the end of `.circleci/config.yml`:

#### Option A: Oracle Linux AF_PACKET Variant
```yaml
# Uncomment lines for build_scan_push_dockerhub_main workflow
build_scan_push_dockerhub_main:
  jobs:
    - build:
        name: "build-main-dockerhub"
        suricata-version: "7.0.11"
        oracle-version: "9"
        build-variant: "afpacket"
        # ... (rest of workflow)
```

#### Option B: Oracle Linux Multiple Variants (AF_PACKET and Napatech)
```yaml
# Uncomment lines for build_scan_push_dockerhub_oracle workflow
build_scan_push_dockerhub_oracle:
  jobs:
    - build:
        name: "build-oracle-dockerhub"
        suricata-version: "7.0.11"
        oracle-version: "9"
        build-variant: "afpacket"  # or "napatech"
        # ... (rest of workflow)
```

#### Option C: Both ECR and Docker Hub
```yaml
# Uncomment lines for build_scan_push_both_registries workflow
build_scan_push_both_registries:
  jobs:
    - build:
        name: "build-dual-registry"
        # ... (rest of workflow)
```

### Step 3: Customize Configuration

Modify the uncommented workflow to match your requirements:

```yaml
# Example customization
- push-to-docker-hub:
    name: "push-main-dockerhub"
    image-tag: "v7.0.11-main"           # Customize tag
    suricata-version: "7.0.11"          # Match your version
    build-variant: "oracle"             # oracle|napatech
    requires:
      - "scan-main-dockerhub"
    filters:
      branches:
        only: main                       # Customize branch
```

## Image Naming Conventions

The Docker Hub push follows legacy naming conventions:

### Oracle Linux Standard Variant
- **Registry**: `engineering2`
- **Image Name**: `suricata`
- **Tags**:
  - `engineering2/suricata:9-oracle-linux`
  - `engineering2/suricata:7.0.11`
  - `engineering2/suricata:v7.0.11-main`

### Oracle Linux AF_PACKET Variant (Alternative Tags)
- **Registry**: `engineering2`
- **Image Name**: `suricata`
- **Tags**:
  - `engineering2/suricata:9-oracle-linux-afpacket`
  - `engineering2/suricata:7.0.11-afpacket`
  - `engineering2/suricata:v7.0.11-ol9-afpacket`

### Oracle Linux Napatech Variant
- **Registry**: `engineering2`
- **Image Name**: `suricata-nt`
- **Tags**:
  - `engineering2/suricata-nt:9-oracle-linux`
  - `engineering2/suricata-nt:7.0.11`
  - `engineering2/suricata-nt:v7.0.11-ol9-napatech`

## Authentication Flow

The Docker Hub authentication follows the legacy pattern:

1. **Password File Creation**: Creates `.docker_hub_rw_password` file
2. **Docker Login**: Uses `cat .docker_hub_rw_password | docker login --username ${DOCKER_HUB_RW_USERNAME} --password-stdin`
3. **Image Push**: Pushes tagged images to Docker Hub
4. **Cleanup**: Removes password file for security

This matches the exact pattern used in:
- `cisappdev/albert_build_scripts/ansible/roles/build_image_ol9_suricata_napatech_container/tasks/main.yml`

## Testing the Setup

### 1. Verify Environment Variables

Check that CircleCI environment variables are set:
- Go to CircleCI project settings
- Navigate to Environment Variables
- Verify `DOCKER_HUB_RW_USERNAME` and `DOCKER_HUB_RW_PASSWORD` are present

### 2. Test Authentication

You can test Docker Hub authentication locally:

```bash
# Create test password file
echo "your_docker_hub_password" > .docker_hub_rw_password

# Test login
cat .docker_hub_rw_password | docker login --username example-user --password-stdin

# Cleanup
rm .docker_hub_rw_password
```

### 3. Monitor Pipeline

After enabling, monitor the CircleCI pipeline:
- Check build logs for authentication success
- Verify images appear in Docker Hub registry
- Confirm all expected tags are created

## Troubleshooting

### Authentication Failures

```bash
# Error: unauthorized: authentication required
```
**Solution**: Verify `DOCKER_HUB_RW_USERNAME` and `DOCKER_HUB_RW_PASSWORD` are correctly set

### Permission Denied

```bash
# Error: denied: requested access to the resource is denied
```
**Solution**: Ensure the Docker Hub account has push permissions to `engineering2` namespace

### Image Not Found

```bash
# Error: image not found
```
**Solution**: Verify the build job completed successfully and the image was saved to workspace

## Security Considerations

1. **Use Access Tokens**: Prefer Docker Hub access tokens over passwords
2. **Limit Scope**: Create tokens with minimal required permissions
3. **Rotate Regularly**: Update tokens periodically
4. **Monitor Usage**: Review Docker Hub access logs

## Migration from Legacy

When migrating from `albert_build_scripts`:

1. **Environment Variables**: Use the same `DOCKER_HUB_RW_PASSWORD` pattern
2. **Registry Namespace**: Maintain `engineering2` namespace
3. **Image Names**: Follow existing naming conventions
4. **Authentication**: Use identical login pattern

This ensures seamless transition from the legacy build system to the new containerized approach.

## Future Enhancements

Potential improvements when fully enabled:

1. **Multi-Architecture**: Add ARM64 support
2. **Vulnerability Scanning**: Integrate Docker Hub vulnerability scanning
3. **Automated Cleanup**: Remove old image versions
4. **Notification**: Add Slack/email notifications for successful pushes

The commented-out code provides a solid foundation for these enhancements.
