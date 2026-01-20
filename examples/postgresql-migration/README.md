# PostgreSQL Application Migration

This example shows migrating a PostgreSQL database from local storage to Longhorn.

## Before Migration
- Local storage: `/mnt/postgres-data` on master-node
- Single point of failure
- No replication

## After Migration
- Longhorn distributed storage
- 3x replication across nodes
- Automatic failover

## Steps

See the parent [README.md](../../README.md) for detailed steps.

Quick summary:
1. Run backup script
2. Update PVC manifest
3. Delete old resources
4. Apply new manifests
5. Restore data
6. Verify
