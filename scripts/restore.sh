#!/bin/bash

# n8n 데이터베이스 복원 스크립트

set -e

# 사용법 확인
if [ "$#" -ne 1 ]; then
    echo "사용법: $0 <백업파일경로>"
    echo "예시: $0 ./backups/n8n_backup_20231201_123456.sql"
    exit 1
fi

BACKUP_FILE="$1"

# 백업 파일 존재 확인
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 백업 파일을 찾을 수 없습니다: $BACKUP_FILE"
    exit 1
fi

# .env 파일에서 환경 변수 로드
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env 파일을 찾을 수 없습니다."
    exit 1
fi

echo "⚠️  주의: 이 작업은 현재 데이터베이스의 모든 데이터를 삭제하고 백업으로 복원합니다."
echo "백업 파일: $BACKUP_FILE"
echo ""
read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "복원이 취소되었습니다."
    exit 1
fi

# PostgreSQL 컨테이너가 실행 중인지 확인
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "❌ PostgreSQL 컨테이너가 실행되지 않고 있습니다."
    echo "먼저 'docker-compose up -d postgres'로 데이터베이스를 시작해주세요."
    exit 1
fi

echo "🔄 데이터베이스 복원을 시작합니다..."

# n8n 서비스 중지 (데이터베이스 연결 차단)
echo "📋 n8n 서비스를 일시 중지합니다..."
docker-compose stop n8n n8n-worker

# 데이터베이스 복원 실행
echo "📦 백업 파일을 복원합니다..."
docker-compose exec -T postgres psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ 복원이 완료되었습니다."
    
    # n8n 서비스 재시작
    echo "🚀 n8n 서비스를 재시작합니다..."
    docker-compose up -d n8n n8n-worker
    
    echo "🎉 모든 작업이 완료되었습니다!"
    echo "브라우저에서 http://localhost:5678로 접속하여 확인해보세요."
else
    echo "❌ 복원 중 오류가 발생했습니다."
    echo "n8n 서비스를 수동으로 재시작해주세요: docker-compose up -d"
    exit 1
fi
