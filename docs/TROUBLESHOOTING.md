# Troubleshooting Guide

## Build Success!

The container has been successfully built and tested! Most common issues have been resolved in this version.

## Common Issues

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

## Debugging

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

## Resources

- [Suricata Documentation](https://suricata.readthedocs.io)
- [Emerging Threats Rules](https://rules.emergingthreats.net)
- [Suricata Update](https://suricata-update.readthedocs.io)
