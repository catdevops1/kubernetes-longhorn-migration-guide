# Migration Checklist

Use this checklist for each application migration.

## Pre-Migration

### Planning
- [ ] Document application details
  - [ ] Name and namespace
  - [ ] Current storage type and path
  - [ ] Storage size requirements
  - [ ] Data criticality level
  - [ ] Acceptable downtime window
- [ ] Verify Longhorn health
  - [ ] All Longhorn pods running
  - [ ] Sufficient cluster storage capacity
  - [ ] Replica count configured (default: 3)
- [ ] Create backup
  - [ ] Fresh backup completed
  - [ ] Backup verified/tested
  - [ ] Backup location documented
  - [ ] Restore procedure tested

### Git Repository
- [ ] Manifests updated
  - [ ] PVC updated (storageClassName: longhorn)
  - [ ] volumeName removed
  - [ ] Deployment updated if needed
- [ ] Changes committed to Git
- [ ] Changes pushed to remote
- [ ] ArgoCD sync verified (if applicable)

### Communication
- [ ] Team notified of maintenance window
- [ ] Users informed of potential downtime
- [ ] On-call schedule confirmed
- [ ] Rollback plan documented

## During Migration

### Backup Verification
- [ ] Final backup created
- [ ] Backup file size verified
- [ ] Backup timestamp noted

### Application Shutdown
- [ ] Backend scaled to 0 replicas
- [ ] All pods terminated
- [ ] Database connections closed

### Resource Deletion
- [ ] Deployment deleted (if needed)
- [ ] Old PVC deleted
- [ ] Old PV deleted
- [ ] Verify resources removed: `kubectl get pvc,pv -A`

### Longhorn Provisioning
- [ ] New manifests applied
- [ ] PVC created and bound
- [ ] Longhorn volume created
- [ ] Volume status: healthy
- [ ] Replicas: 3/3 running
- [ ] Volume attached to node

### Data Restoration
- [ ] Postgres pod running
- [ ] Database connectivity verified
- [ ] Backup copied to pod
- [ ] Database restored from backup
- [ ] Data integrity verified
- [ ] Row counts match
- [ ] Temp files cleaned up

### Application Startup
- [ ] Backend scaled to production replicas
- [ ] All pods running
- [ ] Database connections established
- [ ] Application health checks passing
- [ ] No error logs

## Post-Migration

### Verification
- [ ] Longhorn replicas verified
  - [ ] 3 replicas running
  - [ ] Distributed across nodes
  - [ ] Volume state: healthy
- [ ] Application functionality tested
  - [ ] Database queries working
  - [ ] API endpoints responding
  - [ ] Frontend loading
  - [ ] User workflows tested
- [ ] Performance verified
  - [ ] Response times acceptable
  - [ ] No increased latency
  - [ ] Resource usage normal

### Documentation
- [ ] Migration notes documented
- [ ] Issues encountered logged
- [ ] Solutions documented
- [ ] Git repository updated
- [ ] Team notified of completion

### Monitoring
- [ ] Set up volume monitoring
- [ ] Configure alerts
- [ ] Enable recurring snapshots
- [ ] Schedule backup verification

### Cleanup
- [ ] Old PV/PVC manifests removed from Git
- [ ] Old backup scripts updated
- [ ] Documentation updated
- [ ] Migration notes archived

## Rollback (If Needed)

- [ ] Stop new deployment
- [ ] Delete new Longhorn PVC
- [ ] Recreate old PV/PVC
- [ ] Restore from backup
- [ ] Verify application
- [ ] Document rollback reason

## Sign-off

- [ ] Migration completed successfully
- [ ] All tests passed
- [ ] Users notified
- [ ] Documentation complete

**Migration Date:** __________  
**Completed By:** __________  
**Application:** __________  
**Downtime:** __________ minutes  
