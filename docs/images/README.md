# Images Directory

This directory contains images used in the project documentation.

## Required Images

### `circleci-dual-build-workflow.png`

**Description**: Screenshot of CircleCI pipeline showing dual-variant builds

**Source**: CircleCI dashboard showing the `build_scan_deploy_7x` workflow

**Content**: Should show the following jobs running in parallel:
- `build-7x-main-napatech` (PRIMARY)
- `scan-7x-main-napatech`
- `push-7x-main-napatech`
- `artifacts-7x-main-napatech`
- `build-7x-main-afpacket` (SECONDARY)
- `scan-7x-main-afpacket`
- `push-7x-main-afpacket`
- `artifacts-7x-main-afpacket`

**Usage**: Referenced in main README.md to show the dual-variant CI/CD workflow

**To Add**: Save the CircleCI screenshot as `circleci-dual-build-workflow.png` in this directory

## Adding Images

1. Save the image file in this directory
2. Use relative path in markdown: `![Alt Text](docs/images/filename.png)`
3. Commit the image file along with documentation updates
