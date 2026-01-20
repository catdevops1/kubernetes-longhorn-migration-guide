# Multi-Volume Application Migration

This example shows migrating an application with multiple volumes (database + file uploads).

## Volumes
1. **postgres-pvc** - PostgreSQL database
2. **uploads-pvc** - User file uploads

## Important Notes

### RWO Volume Limitation
If your app has multiple replicas sharing an uploads volume, you'll encounter:
```
Multi-Attach error for volume "pvc-xxx" Volume is already used by pod(s)
```

**Solutions:**
1. **Single replica**: Set `replicas: 1` (simplest)
2. **Object storage**: Use S3/MinIO for uploads
3. **RWX storage**: Use NFS or other RWX-capable storage

## Migration Steps

1. Backup both database and uploads directory
2. Update both PVC manifests
3. Delete old resources for both volumes
4. Apply new Longhorn PVCs
5. Restore data
6. Adjust replica count if needed
