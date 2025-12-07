# Offsite Backup

Encrypted offsite backup system for personal data using Restic and Hetzner Storage Box.

## ADDED Requirements

### Requirement: Encrypted Backup Storage

The system SHALL store backups on a Hetzner Storage Box with client-side encryption using Restic's AES-256 encryption. The storage provider SHALL NOT have access to unencrypted data.

#### Scenario: Backup data is encrypted before transmission
- **GIVEN** a backup is initiated
- **WHEN** data is sent to the Storage Box
- **THEN** all data is encrypted locally before transmission using the Restic repository password

#### Scenario: Storage provider cannot read backup contents
- **GIVEN** backups exist on the Storage Box
- **WHEN** accessed directly via SFTP without Restic credentials
- **THEN** the data is unreadable (encrypted blobs only)

### Requirement: Automated Daily Backups

The system SHALL automatically execute backups daily via a NixOS systemd timer. Backups SHALL include Documents, Photos, Obsidian vaults, KeePass databases, and Syncthing-synced phone data.

#### Scenario: Daily backup execution
- **GIVEN** the laptop is powered on and connected to the internet
- **WHEN** the scheduled backup time occurs
- **THEN** Restic backs up all configured directories to the Storage Box

#### Scenario: Backup includes all configured paths
- **GIVEN** a backup completes successfully
- **WHEN** listing the backup contents
- **THEN** it contains files from Documents, Photos, Obsidian, KeePass, and Syncthing directories

### Requirement: Backup Retention Policy

The system SHALL retain backup snapshots according to the policy: 7 daily, 4 weekly, 6 monthly, and 1 yearly. Old snapshots exceeding this policy SHALL be automatically pruned.

#### Scenario: Recent snapshots are preserved
- **GIVEN** backups have run for 30 days
- **WHEN** viewing available snapshots
- **THEN** at least 7 daily snapshots from the past week are available

#### Scenario: Old snapshots are pruned
- **GIVEN** backups have run for over a year
- **WHEN** Restic prune executes
- **THEN** snapshots exceeding the retention policy are removed

### Requirement: Declarative NixOS Configuration

The backup system SHALL be fully configured via NixOS modules using `services.restic.backups`. All secrets (Restic password, SSH keys, SMTP credentials) SHALL be managed via sops-nix with age encryption.

#### Scenario: Backup configuration is declarative
- **GIVEN** the NixOS configuration is rebuilt
- **WHEN** the system boots
- **THEN** backup services and timers are automatically configured without manual intervention

#### Scenario: Secrets are encrypted at rest
- **GIVEN** secrets are stored in the repository
- **WHEN** viewing the secrets files
- **THEN** they are encrypted with age and only decryptable on the target system

### Requirement: Backup Failure Alerting

The system SHALL send an email notification via Postmark when a backup fails. The email SHALL be sent to a configured recipient address.

#### Scenario: Email sent on backup failure
- **GIVEN** a backup job fails (network error, storage full, etc.)
- **WHEN** the systemd service exits with failure status
- **THEN** an email is sent via Postmark to the configured address

#### Scenario: No alert on successful backup
- **GIVEN** a backup job completes successfully
- **WHEN** the systemd service exits
- **THEN** no failure email is sent

### Requirement: Backup Restore Capability

The system SHALL support restoring files from any retained snapshot. Users SHALL be able to mount a snapshot as a FUSE filesystem or restore specific files/directories.

#### Scenario: Mount snapshot for browsing
- **GIVEN** a user wants to recover a file
- **WHEN** running `restic mount /mnt/backup`
- **THEN** all snapshots are browsable as directories organized by date

#### Scenario: Restore specific file
- **GIVEN** a user identifies a file to restore
- **WHEN** running `restic restore --include /path/to/file`
- **THEN** the file is restored to the specified location

### Requirement: Backup Integrity Verification

The system SHALL support verifying backup integrity using `restic check`. This ensures backup data has not been corrupted in storage.

#### Scenario: Integrity check passes
- **GIVEN** backups are stored on the Storage Box
- **WHEN** running `restic check`
- **THEN** the command reports no errors if data is intact

#### Scenario: Integrity check detects corruption
- **GIVEN** backup data has been corrupted
- **WHEN** running `restic check`
- **THEN** the command reports errors identifying the corruption
