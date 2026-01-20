# ArgoCD GitOps Migration

This example shows how to migrate with ArgoCD managing your deployments.

## Key Difference

With ArgoCD, the process is:
1. **Commit changes to Git first** (updated PVC manifests)
2. **ArgoCD detects changes** (auto-sync or manual)
3. **You handle deletion manually** (ArgoCD can't delete bound PVCs)
4. **ArgoCD recreates resources** from Git automatically

## Migration Workflow

### Step 1: Update Git Repository
```bash
cd your-app-repo
# Update PVC manifest (see after/pvc.yaml)
git add k8s/pvc.yaml
git commit -m "Migrate to Longhorn storage"
git push origin main
```

### Step 2: Verify ArgoCD Sync
```bash
kubectl get app your-app -n argocd
# Should show: SYNC STATUS: Synced
```

### Step 3: Manual Deletion (ArgoCD can't do this)
```bash
# Scale down
kubectl scale deployment your-app-backend -n your-app --replicas=0

# Delete postgres
kubectl delete deployment postgres -n your-app

# Delete old PVC and PV
kubectl delete pvc postgres-pvc -n your-app
kubectl delete pv your-app-postgres-pv
```

### Step 4: ArgoCD Auto-Recreates
ArgoCD will automatically:
- Create new Longhorn PVC
- Recreate postgres deployment
- Bind to new PVC

### Step 5: Restore Data
```bash
POD=$(kubectl get pod -n your-app -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl cp backup.sql your-app/$POD:/tmp/restore.sql
kubectl exec -n your-app $POD -- psql -U user -d db -f /tmp/restore.sql
```

## Important Notes

- ArgoCD will try to keep cluster in sync with Git
- Manual `kubectl apply` changes may be reverted
- Always commit to Git first for GitOps workflows
- Use `kubectl patch app` to trigger manual sync if needed

## Trigger Manual Sync
```bash
kubectl patch app your-app -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```
