# Usage Guide

## Container Ready!

The Suricata 8.0.0 container is successfully built and ready for production use with all modern security features!

## Running the Container

### Production (Linux)

Basic usage:
```sh
docker run -d --name suricata \
  --net=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -v suricata-logs:/var/log/suricata \
  yourusername/suricata
```

### Development (macOS)

For local testing on macOS, use bridge networking since `--net=host` doesn't work:
```sh
docker run -d --name suricata \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -p 8080:8080 \
  -v suricata-logs:/var/log/suricata \
  yourusername/suricata
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

## Performance Tuning

For high traffic networks:
- Increase memory limit (`-m 4G`)
- Adjust `af-packet` settings in suricata.yaml
- Consider disabling expensive rules
