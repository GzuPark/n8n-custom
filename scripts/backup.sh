#!/bin/bash

# n8n 데이터베이스 백업 스크립트

# 공통 함수 로드
source "$(dirname "$0")/common.sh"

# 초기화
init_common

# 백업 설정
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="n8n_backup_${DATE}.sql"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

log_step "n8n 데이터베이스 백업을 시작합니다..."
log_info "백업 파일: $BACKUP_DIR/$BACKUP_FILE"

# PostgreSQL 서비스 실행 확인
ensure_service_running "postgres" "PostgreSQL"

# 데이터베이스 백업 실행
docker-compose exec -T postgres pg_dump \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    --no-password \
    --clean \
    --if-exists \
    > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    log_success "백업이 완료되었습니다: $BACKUP_DIR/$BACKUP_FILE"
    
    # 백업 파일 크기 표시
    show_file_size "$BACKUP_DIR/$BACKUP_FILE" "백업 파일 크기"
    
    # 7일 이상된 백업 파일 자동 삭제
    cleanup_old_files "$BACKUP_DIR" "n8n_backup_*.sql" 7
else
    log_error "백업 중 오류가 발생했습니다."
    exit 1
fi
