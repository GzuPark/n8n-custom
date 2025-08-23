#!/bin/bash

# n8n 데이터베이스 백업 스크립트

set -e

# 설정
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="n8n_backup_${DATE}.sql"

# .env 파일에서 환경 변수 로드
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env 파일을 찾을 수 없습니다."
    exit 1
fi

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

echo "📦 n8n 데이터베이스 백업을 시작합니다..."
echo "백업 파일: $BACKUP_DIR/$BACKUP_FILE"

# PostgreSQL 컨테이너가 실행 중인지 확인
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "❌ PostgreSQL 컨테이너가 실행되지 않고 있습니다."
    echo "먼저 'docker-compose up -d'로 서비스를 시작해주세요."
    exit 1
fi

# 데이터베이스 백업 실행
docker-compose exec -T postgres pg_dump \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    --no-password \
    --clean \
    --if-exists \
    > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ 백업이 완료되었습니다: $BACKUP_DIR/$BACKUP_FILE"
    
    # 백업 파일 크기 표시
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "📊 백업 파일 크기: $BACKUP_SIZE"
    
    # 7일 이상된 백업 파일 자동 삭제
    find "$BACKUP_DIR" -name "n8n_backup_*.sql" -mtime +7 -delete
    echo "🗑️  7일 이상된 백업 파일을 정리했습니다."
else
    echo "❌ 백업 중 오류가 발생했습니다."
    exit 1
fi
