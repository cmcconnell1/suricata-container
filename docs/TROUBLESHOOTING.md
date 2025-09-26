# Troubleshooting Guide

## Build Success

Both container variants have been successfully built and tested! Most common issues have been resolved in this version.

## Common Issues

### Container Health Check Failures

If your container shows as "unhealthy":

```bash
# Check health status - Alpine variant
docker inspect --format='{{.State.Health.Status}}' suricata-alpine

# Check health status - Oracle Linux variant
docker inspect --format='{{.State.Health.Status}}' suricata-enterprise

# View detailed health check logs
docker inspect --format='{{json .State.Health}}' suricata-alpine
```

**Common health check issues and solutions:**

#### **"Suricata control socket not responding" (older images)**
- **Cause**: Missing suricatasc Python module or control socket not configured
- **Error**: `ModuleNotFoundError: No module named 'suricata.sc'`
- **Solution**: Use current images (January 2025) with fixed health checks
- **Workaround**: Manually update healthcheck.sh in running container

#### **"Suricata logs not being updated" (older images)**
- **Cause**: Overly strict log activity check (expected updates every 5 minutes)
- **Issue**: Health check failed even when Suricata was running normally
- **Solution**: Updated health check uses process responsiveness instead of log activity

#### **"Process in bad state" (older images)**
- **Cause**: BusyBox ps compatibility issues in Alpine Linux
- **Error**: `ps: unrecognized option: p` or empty process state
- **Solution**: Health check now uses `kill -0` signal test instead of `ps -o stat`

#### **Current Health Check Validation (fixed versions)**
The updated health check validates:
- Suricata process is running (`pgrep -x "suricata"`)
- Process responds to signals (`kill -0 $PID`)
- Log directory exists and is writable
- Main log file is created

**Manual health check test:**
```bash
# Test the health check manually - Alpine variant
docker exec suricata-alpine /usr/local/bin/healthcheck.sh

# Test the health check manually - Oracle Linux variant
docker exec suricata-enterprise /usr/local/bin/healthcheck.sh

# Expected output for healthy container:
# HEALTH CHECK PASSED: Suricata is running and healthy
```

### Container Startup Issues

**Suricata fails to start**
- Check capabilities (`NET_ADMIN` and `NET_RAW`)
- Verify interface exists in container
- Check logs with `docker logs suricata`
- Try skipping config test: `-e SKIP_CONFIG_TEST=true`

**Rule updates failing**
- Ensure internet access from container
- Check DNS resolution
- Verify disk space

**High CPU usage**
- Disable expensive rules
- Adjust pattern matcher settings
- Consider hardware acceleration

**Configuration validation fails**
- Use `SKIP_CONFIG_TEST=true` to bypass validation
- Check configuration syntax with `suricata -T -c /etc/suricata/suricata.yaml`
- Ensure all referenced files exist in the container

## Platform-Specific Issues

### macOS

**Build fails with "401 Unauthorized" or "failed to authorize"**
- Docker Hub now requires authentication for image pulls
- Log in to Docker Hub: `docker login`
- Or create a free Docker Hub account at https://hub.docker.com
- Alternative: Use `docker logout` then `docker login` to refresh credentials

**Build fails with architecture errors**
- Ensure you're using `make build` which sets `--platform linux/amd64`
- If building manually, use: `docker build --platform linux/amd64 -t suricata .`

**Network monitoring not working**
- macOS Docker Desktop runs in a VM, limiting network access
- Use bridge networking instead of `--net=host`
- Consider using Docker Desktop's network debugging tools

**Performance issues**
- Allocate more resources to Docker Desktop (CPU/Memory)
- Enable VirtioFS for better file system performance

## Version-Related Issues

**Build fails with dependency errors**
- Check version compatibility matrix in SETUP.md
- Ensure Alpine version supports required Rust version
- For Suricata 8.x, use Alpine 3.20+
- For older Suricata versions, use compatible Alpine versions

**Suricata features missing**
- Verify you're using the correct Suricata version
- Check build arguments: `docker build --build-arg SURICATA_VERSION=8.0.0`
- Some features require specific minimum versions

**Container won't start after version change**
- Rebuild the image completely: `docker build --no-cache`
- Check configuration compatibility with new version
- Verify all dependencies are available for the target version

**Version verification**
```bash
# Check what version is actually built
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:latest suricata -V

# Check build arguments used
docker inspect suricata:latest | grep -A 10 "BuildArgs"
```

## Debugging

### Health Check Debugging

**Check health check script version:**
```bash
# View current health check script
docker exec suricata cat /usr/local/bin/healthcheck.sh | head -20

# Look for version indicators:
# - Old version: contains "suricatasc -c uptime"
# - New version: contains "kill -0" and no suricatasc dependency
```

**Manual health check components:**
```bash
# Test individual health check components
docker exec suricata sh -c '
  echo "1. Process check:"
  pgrep -x "suricata" && echo "PASS: Process found" || echo "FAIL: Process not found"

  echo "2. Signal responsiveness:"
  PID=$(pgrep -x "suricata")
  kill -0 "$PID" 2>/dev/null && echo "PASS: Process responsive" || echo "FAIL: Process not responsive"

  echo "3. Log directory:"
  [ -d /var/log/suricata ] && echo "PASS: Log directory exists" || echo "FAIL: Log directory missing"

  echo "4. Main log file:"
  [ -f /var/log/suricata/suricata.log ] && echo "PASS: Log file exists" || echo "FAIL: Log file missing"
'
```

**Update health check in running container (temporary fix):**
```bash
# Copy updated health check to running container
docker cp scripts/healthcheck.sh suricata:/usr/local/bin/healthcheck.sh
docker exec suricata chmod +x /usr/local/bin/healthcheck.sh

# Test the updated health check
docker exec suricata /usr/local/bin/healthcheck.sh
```

### General Debugging

Run in foreground:
```sh
docker run --rm -it --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e LOG_LEVEL=debug \
  yourusername/suricata -i eth0 -v
```

Test configuration:
```sh
docker exec suricata suricata -T -c /etc/suricata/suricata.yaml
```

Check Suricata process status:
```bash
# View running processes
docker exec suricata ps aux | grep suricata

# Check Suricata logs
docker exec suricata tail -f /var/log/suricata/suricata.log

# Check for errors in logs
docker exec suricata grep -i error /var/log/suricata/suricata.log
```

## Resources

- [Suricata Documentation](https://suricata.readthedocs.io)
- [Emerging Threats Rules](https://rules.emergingthreats.net)
- [Suricata Update](https://suricata-update.readthedocs.io)
