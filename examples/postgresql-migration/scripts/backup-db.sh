#!/bin/bash
# PostgreSQL Database Backup Script
NAMESPACE="your-app"
DB_USER="your_user"
DB_NAME="your_db"
BACKUP_DIR="/backups/your-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"
echo "Creating backup: ${DB_NAME}_${TIMESTAMP}.sql"

kubectl exec -n "$NAMESPACE" deployment/postgres -- \
  pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

if [ $? -eq 0 ]; then
    echo "✅ Backup successful: $BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
    du -h "$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql" | cut -f1
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql" -mtime +$RETENTION_DAYS -delete
    echo "Cleaned old backups (kept last $RETENTION_DAYS days)"
else
    echo "❌ Backup failed!"
    exit 1
fi
