# Tasks: Add Offsite Backup System

## 1. Infrastructure Setup

- [ ] 1.1 Provision Hetzner Storage Box BX21 (5TB) via Hetzner Robot
- [ ] 1.2 Generate SSH keypair for Restic SFTP access
- [ ] 1.3 Configure Storage Box SSH access (upload public key, enable SFTP on port 23)
- [ ] 1.4 Test SFTP connectivity from laptop

## 2. Secrets Management (sops-nix)

- [x] 2.1 Age keypair exists (`.sops.yaml` already configured with framework13 key)
- [ ] 2.2 Add sops-nix to `flake.nix` inputs
- [x] 2.3 `.sops.yaml` already exists with correct path regex for `secrets/`
- [ ] 2.4 Create `secrets/backup.yaml` with encrypted secrets:
  - Restic repository password
  - SSH private key for Storage Box
  - Postmark SMTP credentials
- [ ] 2.5 Configure sops-nix module in `hosts/framework13/default.nix`

## 3. Email Alerting (Postmark)

- [ ] 3.1 Create Postmark account and verify `buduroiu.com` domain
- [ ] 3.2 Create sender signature (e.g., `alerts@buduroiu.com`)
- [ ] 3.3 Obtain SMTP credentials from Postmark
- [ ] 3.4 Create `system/services/msmtp.nix` with Postmark SMTP settings
- [ ] 3.5 Add `./services/msmtp.nix` to `system/default.nix` laptop imports
- [ ] 3.6 Test email delivery with `echo "test" | msmtp recipient@email.com`

## 4. Restic Backup Configuration

- [ ] 4.1 Initialize Restic repository on Storage Box (`restic init`)
- [ ] 4.2 Create `system/services/restic.nix` using `services.restic.backups`
- [ ] 4.3 Configure backup paths (based on syncthing config in `system/services/syncthing.nix`):
  - `/home/bogdan/Documents`
  - `/home/bogdan/Pictures`
  - KeePass database location
- [ ] 4.4 Configure exclusions (caches, temp files, `.git` internals)
- [ ] 4.5 Configure retention policy (7 daily, 4 weekly, 6 monthly, 1 yearly)
- [ ] 4.6 Configure connection limits (`--limit-upload`, `-o sftp.connections=4`)
- [ ] 4.7 Add `./services/restic.nix` to `system/default.nix` laptop imports
- [ ] 4.8 Systemd timer is auto-created by `services.restic.backups`

## 5. Failure Alerting

- [ ] 5.1 Create systemd service for email notification on failure
- [ ] 5.2 Configure `OnFailure=` in Restic backup service
- [ ] 5.3 Test failure alerting by simulating a backup failure

## 6. Validation & Documentation

- [ ] 6.1 Run full backup and verify completion
- [ ] 6.2 Test restore: mount repository and recover a file
- [ ] 6.3 Verify backup integrity with `restic check`
- [ ] 6.4 Document restore procedure in repository README or wiki
- [ ] 6.5 Rebuild NixOS configuration and confirm no errors

## Dependencies

- Task 2 (sops-nix) must complete before Task 4 (secrets needed for Restic config)
- Task 3 (Postmark) must complete before Task 5 (email alerting)
- Task 1 (Storage Box) must complete before Task 4.1 (repository init)

## Parallelizable Work

- Tasks 1, 2, and 3 can be done in parallel (no dependencies between them)

## File Summary

New files to create:
- `secrets/backup.yaml` - encrypted secrets (restic password, SSH key, SMTP creds)
- `system/services/restic.nix` - backup service configuration
- `system/services/msmtp.nix` - email relay configuration

Files to modify:
- `flake.nix` - add sops-nix input
- `system/default.nix` - add restic.nix and msmtp.nix to laptop imports
- `hosts/framework13/default.nix` - configure sops-nix module
