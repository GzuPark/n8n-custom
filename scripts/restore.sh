#!/bin/bash

# n8n 데이터베이스 복원 스크립트

# 공통 함수 로드
source "$(dirname "$0")/common.sh"

# 사용법 확인
if [ "$#" -ne 1 ]; then
    show_usage "$0" "<백업파일경로>"
    echo "예시: $0 ./backups/n8n_backup_20231201_123456.sql"
    exit 1
fi

BACKUP_FILE="$1"

# 백업 파일 존재 확인
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "백업 파일을 찾을 수 없습니다: $BACKUP_FILE"
    exit 1
fi

# 초기화
init_common

# 복원 확인
confirm_action "이 작업은 현재 데이터베이스의 모든 데이터를 삭제하고 백업으로 복원합니다.\n백업 파일: $BACKUP_FILE"

# PostgreSQL 서비스 실행 확인
ensure_service_running "postgres" "PostgreSQL"

log_step "데이터베이스 복원을 시작합니다..."

# n8n 서비스 중지 (데이터베이스 연결 차단)
log_info "n8n 서비스를 일시 중지합니다..."
docker-compose stop n8n n8n-worker

# 데이터베이스 복원 실행
log_step "백업 파일을 복원합니다..."
docker-compose exec -T postgres psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    log_success "복원이 완료되었습니다."
    
    # n8n 서비스 재시작
    log_rocket "n8n 서비스를 재시작합니다..."
    docker-compose up -d n8n n8n-worker
    
    echo -e "${GREEN}${EMOJI_PARTY} 모든 작업이 완료되었습니다!${NC}"
    log_info "브라우저에서 http://localhost:${EXPOSE_PORT}로 접속하여 확인해보세요."
else
    log_error "복원 중 오류가 발생했습니다."
    log_info "n8n 서비스를 수동으로 재시작해주세요: docker-compose up -d"
    exit 1
fi
