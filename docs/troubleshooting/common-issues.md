# Common Issues and Solutions

## Issue 1: lost+found Directory

**Error:**
```
initdb: error: directory "/var/lib/postgresql/data" exists but is not empty
initdb: detail: It contains a lost+found directory
```

**Cause:** Longhorn volumes (ext4 filesystem) include a `lost+found` directory by default.

**Solution A: Use PGDATA environment variable**
```yaml
containers:
- name: postgres
  env:
  - name: PGDATA
    value: /var/lib/postgresql/data/pgdata
  volumeMounts:
  - name: postgres-storage
    mountPath: /var/lib/postgresql/data
```

**Solution B: Use subPath**
```yaml
volumeMounts:
- name: postgres-storage
  mountPath: /var/lib/postgresql/data
  subPath: postgres
```

---

## Issue 2: Multi-Attach Error

**Error:**
```
Multi-Attach error for volume "pvc-xxx" Volume is already used by pod(s) pod-1
```

**Cause:** ReadWriteOnce (RWO) volumes can only be attached to one pod at a time.

**Solutions:**

1. **Single replica** (simplest):
```bash
kubectl scale deployment your-app --replicas=1
```

2. **Use object storage** for shared files:
```yaml
# Use S3/MinIO for uploads instead of PVC
env:
- name: S3_BUCKET
  value: my-uploads
```

3. **ReadWriteMany** (if supported):
```yaml
spec:
  accessModes:
    - ReadWriteMany  # Requires RWX-capable storage
```

---

## Issue 3: Permission Denied

**Error:**
```
mkdir: cannot create directory '/var/lib/postgresql/data': Permission denied
```

**Cause:** Longhorn volumes default to root ownership, but Postgres runs as UID 999.

**Solution: Add initContainer**
```yaml
initContainers:
- name: fix-permissions
  image: busybox:latest
  command: ['sh', '-c', 'chown -R 999:999 /var/lib/postgresql/data']
  volumeMounts:
  - name: postgres-storage
    mountPath: /var/lib/postgresql/data
```

---

## Issue 4: PVC Stuck in Terminating

**Symptom:**
```bash
kubectl delete pvc my-pvc
# PVC stays in "Terminating" state
```

**Solution: Remove finalizers**
```bash
kubectl patch pvc my-pvc -p '{"metadata":{"finalizers":null}}'
```

**Or edit manually:**
```bash
kubectl edit pvc my-pvc
# Remove the finalizers section
```

---

## Issue 5: ArgoCD Reverting Manual Changes

**Symptom:** Manual changes get reverted by ArgoCD.

**Solution: Always commit to Git first**
```bash
# 1. Update manifests in Git
git add k8s/
git commit -m "Update storage"
git push

# 2. Then do manual deletions
kubectl delete pvc my-pvc

# 3. ArgoCD will sync from Git
```

---

## Issue 6: Data Not Restored After Migration

**Check:**
1. Was backup created successfully?
2. Was restore command executed?
3. Check postgres logs for errors

**Verify:**
```bash
# Check if database exists
kubectl exec -n your-app deployment/postgres -- psql -U user -l

# Check table counts
kubectl exec -n your-app deployment/postgres -- \
  psql -U user -d dbname -c "SELECT COUNT(*) FROM your_table;"
```

---

## Issue 7: Slow Performance After Migration

**Check Longhorn replica locality:**
```bash
kubectl get volumes -n longhorn-system -o yaml | grep dataLocality
```

**Enable data locality for better performance:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    volume.kubernetes.io/selected-node: node01  # Pin to specific node
```

---

## Debugging Commands
```bash
# Check Longhorn volume status
kubectl get volumes -n longhorn-system

# Check replica distribution
kubectl get replicas -n longhorn-system | grep your-pvc

# Check Longhorn events
kubectl get events -n longhorn-system --sort-by='.lastTimestamp'

# Check PVC/PV binding
kubectl describe pvc your-pvc -n your-app

# Check pod volume mounts
kubectl describe pod your-pod -n your-app | grep -A 10 Mounts
```
