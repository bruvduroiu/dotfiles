# Change: Add Offsite Backup System

## Why

Personal data on laptop and phone (synced via Syncthing) currently has no offsite redundancy. A local disk failure, theft, or disaster would result in permanent data loss. An encrypted offsite backup system provides protection against these scenarios while maintaining privacy.

## What Changes

- Provision Hetzner Storage Box BX21 (5TB) as offsite backup target
- Configure Restic for encrypted, deduplicated backups over SFTP
- Set up sops-nix with age keys for secrets management (Restic password, SSH keys, Postmark API key)
- Create NixOS module for declarative backup configuration using `services.restic.backups`
- Configure msmtp with Postmark for email alerts on backup failures
- Back up: Documents, Photos, Obsidian vaults, KeePass databases, and Syncthing-synced phone data

## Impact

- Affected specs: `offsite-backup` (new capability)
- Affected code:
  - `flake.nix` - add sops-nix input
  - `system/services/restic.nix` - backup service configuration (new)
  - `system/services/msmtp.nix` - email relay for alerts (new)
  - `system/default.nix` - import new service modules
  - `secrets/backup.yaml` - sops-encrypted secrets (new directory)
  - Hetzner Robot - external provisioning (manual)

## Design Decisions

### Restic over Borg/Rclone
- Best NixOS integration via `services.restic.backups`
- Built-in encryption (AES-256) and deduplication
- FUSE mount for easy restores
- Active community and development

### Hetzner Storage Box over Object Storage
- Flat-fee pricing (€12.90/mo for 5TB) vs. usage-based billing
- Native SFTP support works well with Restic
- No egress fees for restores or integrity checks
- Sub-account support for future expansion

### sops-nix over agenix
- sops-nix is more widely adopted
- Better documentation and ecosystem
- age keys are simpler than GPG
- `.sops.yaml` already configured with age key for framework13

### Postmark over self-hosted email
- Reliable transactional email delivery
- Free tier (100 emails/mo) sufficient for alerts
- Simple SMTP relay configuration
- No email server maintenance

### Daily backups with standard retention
- 7 daily, 4 weekly, 6 monthly, 1 yearly snapshots
- Balances storage usage with restore flexibility
- Can recover from gradual data corruption (not just latest state)

## Out of Scope

- Syncthing configuration (already working)
- Phone backup software (relies on Syncthing sync to laptop)
- Backup monitoring dashboard
- Multiple machine backups (laptop only for now)
