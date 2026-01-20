# Kubernetes Longhorn Storage Migration Guide

> A complete guide for migrating production Kubernetes applications from local hostPath storage to Longhorn distributed block storage with zero data loss.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.21+-blue.svg)](https://kubernetes.io/)
[![Longhorn](https://img.shields.io/badge/Longhorn-v1.10+-green.svg)](https://longhorn.io/)

## 📖 Overview

This repository documents the **real-world migration of 4 production applications** with active users from local storage to Longhorn, including:
- ✅ Pre-migration planning and backups
- ✅ Manifest updates for GitOps workflows
- ✅ Step-by-step migration procedures
- ✅ Data restoration and verification
- ✅ Common issues and solutions

**Migration Results:**
- ✅ **Zero data loss** across all applications
- ✅ **3x data replication** across cluster nodes
- ✅ **Automated daily backups** with 30-day retention
- ✅ **Protection against node failures**
- ✅ **All changes version-controlled** in Git

## 🎯 Why Migrate to Longhorn?

| Before Migration (Local Storage) | After Migration (Longhorn) |
|----------------------------------|----------------------------|
| ❌ Single point of failure | ✅ 3x data replication |
| ❌ No redundancy | ✅ Automatic failover |
| ❌ Pod tied to specific node | ✅ Pods can run on any node |
| ❌ Manual backup management | ✅ Built-in snapshots |
| ❌ No disaster recovery | ✅ Enterprise-grade DR |

## 🏗️ Architecture

### Before Migration
```
┌─────────────┐
│ master-node │
│             │
│  ┌────────┐ │
│  │App Pod │ │
│  └───┬────┘ │
│      │      │
│  ┌───▼────┐ │
│  │hostPath│ │ ← Single point of failure
│  │/mnt/data│ │
│  └────────┘ │
└─────────────┘
```

### After Migration
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│  node01  │  │  node02  │  │  node03  │
│          │  │          │  │          │
│ Replica1 │  │ Replica2 │  │ Replica3 │
│  ┌────┐  │  │  ┌────┐  │  │  ┌────┐  │
│  │Data│  │  │  │Data│  │  │  │Data│  │
│  └────┘  │  │  └────┘  │  │  └────┘  │
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │
     └─────────────┴─────────────┘
               │
          ┌────▼─────┐
          │ App Pod  │ ← Can run on any node
          │(attached)│
          └──────────┘
```

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Migration Process](#migration-process)
4. [Examples](#examples)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)
7. [Contributing](#contributing)

## 🔧 Prerequisites

### Required
- ✅ Kubernetes cluster (v1.21+)
- ✅ Longhorn installed and running
- ✅ Applications using local hostPath or static PVs
- ✅ `kubectl` access with admin privileges
- ✅ **Backup strategy** (critical!)

### Recommended
- ArgoCD or Flux for GitOps
- Test environment to practice
- Monitoring solution (Prometheus/Grafana)

### Tools Used in This Guide
```bash
Kubernetes:  v1.33.3
Longhorn:    v1.10.1
ArgoCD:      v2.x (optional)
PostgreSQL:  v15-16 (examples)
```

## 🚀 Quick Start

### 1. Check Longhorn Status
```bash
kubectl get pods -n longhorn-system
kubectl get storageclass longhorn
```

### 2. Create Backup
```bash
# See examples/postgresql-migration/scripts/backup-db.sh
./backup-db.sh
```

### 3. Update PVC Manifest
```yaml
# Before
spec:
  volumeName: my-local-pv

# After  
spec:
  storageClassName: longhorn
  # Remove volumeName
```

### 4. Execute Migration
```bash
# Scale down app
kubectl scale deployment my-app --replicas=0

# Delete old resources
kubectl delete pvc my-pvc
kubectl delete pv my-pv

# Apply new manifests
kubectl apply -f k8s/

# Restore data (see examples/)
```

## 📚 Migration Process

### Pre-Migration Checklist
```bash
# Use this checklist for each application
- [ ] Application documented (name, namespace, storage size)
- [ ] Longhorn installed and healthy
- [ ] Fresh backup created and verified
- [ ] Manifests updated in Git repository
- [ ] Maintenance window scheduled
- [ ] Rollback plan documented
- [ ] Team notified of migration
```

### Step-by-Step Guide

#### 1. Create Backup
```bash
# PostgreSQL example
kubectl exec -n my-app deployment/postgres -- \
  pg_dump -U user database > backup_$(date +%Y%m%d).sql
```

#### 2. Update Manifests

**Before:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  volumeName: my-app-postgres-pv  # Remove this
```

**After:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn  # Add this
  resources:
    requests:
      storage: 5Gi
```

#### 3. Execute Migration
```bash
# 1. Scale down
kubectl scale deployment my-app --replicas=0

# 2. Delete old resources
kubectl delete deployment postgres -n my-app
kubectl delete pvc postgres-pvc -n my-app
kubectl delete pv my-app-postgres-pv

# 3. Apply new manifests
kubectl apply -f k8s/

# 4. Wait for PVC to bind
kubectl get pvc -n my-app -w
```

#### 4. Restore Data
```bash
POD=$(kubectl get pod -n my-app -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl cp backup.sql my-app/$POD:/tmp/restore.sql
kubectl exec -n my-app $POD -- psql -U user -d db -f /tmp/restore.sql
```

#### 5. Verify
```bash
# Check replicas
kubectl get replicas -n longhorn-system | grep my-pvc

# Verify data
kubectl exec -n my-app $POD -- psql -U user -d db -c "SELECT COUNT(*) FROM my_table;"

# Scale back up
kubectl scale deployment my-app --replicas=2
```

## 📖 Examples

### [PostgreSQL Migration](examples/postgresql-migration/)
Simple single-volume PostgreSQL migration with backup and restore.

### [Multi-Volume Migration](examples/multi-volume-migration/)
Application with database + file uploads. Includes handling RWO limitations.

### [ArgoCD GitOps Migration](examples/argocd-gitops-migration/)
GitOps workflow with ArgoCD managing deployments.

## ⚠️ Troubleshooting

See [Common Issues Guide](docs/troubleshooting/common-issues.md) for detailed solutions:

- `lost+found` directory issues
- Multi-attach errors
- Permission denied
- PVC stuck in Terminating
- ArgoCD conflicts
- Performance issues

**Quick Fixes:**
```bash
# PVC stuck terminating
kubectl patch pvc my-pvc -p '{"metadata":{"finalizers":null}}'

# Check Longhorn health
kubectl get volumes -n longhorn-system
kubectl get events -n longhorn-system --sort-by='.lastTimestamp'
```

## 🎓 Best Practices

### Backup Strategy
- ✅ Automated daily backups
- ✅ 30-day retention minimum
- ✅ Verify backups regularly
- ✅ Test restore procedures
- ✅ Store backups off-cluster

### Migration Timing
- ✅ Schedule during low-traffic periods
- ✅ Communicate with users
- ✅ Have rollback plan ready
- ✅ Test in staging first

### Longhorn Configuration
- ✅ Use 3 replicas for production
- ✅ Monitor volume health
- ✅ Set up recurring snapshots
- ✅ Configure backup targets (S3/NFS)

### GitOps Workflow
- ✅ Commit changes to Git first
- ✅ Use ArgoCD for deployments
- ✅ Tag releases
- ✅ Document breaking changes

## 📊 Real-World Results

From our test cluster migration:

| Metric | Value |
|--------|-------|
| Applications migrated | 4 |
| Total data migrated | ~35GB |
| Average downtime per app | 5-10 minutes |
| Data loss | 0 bytes |
| Issues encountered | 2 |
| Time to resolution | <5 minutes |

**Performance Impact:**
- Storage latency: +3ms (negligible)
- Application performance: No degradation
- Replication overhead: Minimal

## 🤝 Contributing

Contributions welcome! 

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

**Ideas for contributions:**
- Additional migration examples
- Automation scripts
- Monitoring/alerting configs
- Disaster recovery procedures

## 📄 License

MIT License - See [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- [Longhorn](https://longhorn.io/) - Cloud native distributed block storage
- Kubernetes community
- Everyone who shared migration experiences

## 📚 Additional Resources

- [Longhorn Documentation](https://longhorn.io/docs/)
- [Kubernetes Storage](https://kubernetes.io/docs/concepts/storage/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/)

## ⭐ Star History

If this guide helped you, please star the repository!

---

**Built with ❤️ for the Kubernetes community**

**Questions?** Open an issue or discussion!
