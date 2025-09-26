# Usage Guide

## Container Ready

Both Suricata 7.0.11 container variants are successfully built and ready for production use with modern security features!

## Running the Container

### Alpine Linux Variant (252MB) - Recommended for Modern Deployments

Production usage (Linux):
```sh
docker run -d --name suricata-alpine \
  --net=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -v suricata-logs:/var/log/suricata \
  suricata:7.0.11
```

### Oracle Linux Variant (490MB) - Recommended for Enterprise Deployments

Production usage (Linux):
```sh
docker run -d --name suricata-enterprise \
  --net=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -v suricata-logs:/var/log/suricata \
  suricata:7.0.11-ol9-afpacket
```

### Development (macOS)

For local testing on macOS, use bridge networking since `--net=host` doesn't work:
```sh
# Alpine variant
docker run -d --name suricata-alpine \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -p 8080:8080 \
  -v suricata-logs:/var/log/suricata \
  suricata:7.0.11

# Oracle Linux variant
docker run -d --name suricata-enterprise \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -p 8080:8080 \
  -v suricata-logs:/var/log/suricata \
  suricata:7.0.11-ol9-afpacket
```

**Note**: Network monitoring capabilities are limited on macOS due to Docker Desktop's virtualization layer.

## Configuration Options

### Environment Variables

- `INTERFACE=eth0` - Network interface to monitor
- `UPDATE_RULES=false` - Update rules on startup
- `LOG_LEVEL=info` - Logging verbosity
- `SKIP_CONFIG_TEST=true` - Skip configuration validation (useful for custom configs)

### Skip Configuration Test

If you're using custom configurations that may not pass the built-in validation:

```sh
docker run -d --name suricata \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e SKIP_CONFIG_TEST=true \
  -e INTERFACE=eth0 \
  yourusername/suricata
```

## Monitoring

View logs:
```sh
docker logs -f suricata
```

Check health:
```sh
docker inspect --format='{{json .State.Health}}' suricata
```

## Updating Rules

Manual update:
```sh
docker exec suricata /usr/local/bin/update-rules.sh
```

Automatic updates (weekly):
```sh
docker run -d --name suricata \
  ... \
  -e UPDATE_RULES=true \
  -e UPDATE_SCHEDULE="0 3 * * 0" \
  yourusername/suricata
```

## Version Management

### Running Specific Versions

You can run specific versions of the container:

```bash
# Run latest version
docker run -d --name suricata \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcc123/suricata:latest

# Run specific version by commit hash
docker run -d --name suricata \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcc123/suricata:7e7b878

# Run locally built version
docker run -d --name suricata \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.6
```

### Building Custom Versions

```bash
# Build with specific Suricata version
docker build --build-arg SURICATA_VERSION=7.0.6 \
  -f docker/Dockerfile -t suricata:7.0.6 .

# Run your custom build
docker run -d --name suricata \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.6
```

### Version Verification

```bash
# Check Suricata version in running container
docker exec suricata suricata -V

# Check container image details
docker inspect cmcc123/suricata:latest | grep -A 5 "Labels"
```

## Performance Tuning

For high traffic networks:
- Increase memory limit (`-m 4G`)
- Adjust `af-packet` settings in suricata.yaml
- Consider disabling expensive rules
- Use specific versions tested for your environment
