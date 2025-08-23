#!/bin/bash

# n8n 프로젝트 공통 함수 라이브러리

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 이모지
EMOJI_ERROR="❌"
EMOJI_SUCCESS="✅"
EMOJI_WARNING="⚠️"
EMOJI_INFO="ℹ️"
EMOJI_ROCKET="🚀"
EMOJI_PACKAGE="📦"
EMOJI_RECYCLE="🔄"
EMOJI_CLEANUP="🗑️"
EMOJI_PARTY="🎉"

# 로그 함수들
log_error() {
    echo -e "${RED}${EMOJI_ERROR} $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}${EMOJI_SUCCESS} $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}${EMOJI_WARNING} $1${NC}"
}

log_info() {
    echo -e "${BLUE}${EMOJI_INFO} $1${NC}"
}

log_step() {
    echo -e "${CYAN}${EMOJI_PACKAGE} $1${NC}"
}

log_rocket() {
    echo -e "${PURPLE}${EMOJI_ROCKET} $1${NC}"
}

# .env 파일 로드 함수
load_env() {
    local env_file="${1:-.env}"
    
    if [ ! -f "$env_file" ]; then
        log_error ".env 파일을 찾을 수 없습니다: $env_file"
        log_info "env.example을 복사하여 .env 파일을 생성해주세요:"
        log_info "cp env.example .env"
        exit 1
    fi
    
    # 안전한 방식으로 .env 파일 로드
    set -a
    source "$env_file"
    set +a
    
    log_info ".env 파일이 로드되었습니다: $env_file"
}

# Docker Compose 서비스 상태 확인
check_service_running() {
    local service_name="$1"
    
    if ! docker-compose ps "$service_name" 2>/dev/null | grep -q "Up"; then
        return 1
    fi
    return 0
}

# Docker Compose 서비스 실행 확인 및 안내
ensure_service_running() {
    local service_name="$1"
    local service_display_name="${2:-$service_name}"
    
    if ! check_service_running "$service_name"; then
        log_error "$service_display_name 컨테이너가 실행되지 않고 있습니다."
        log_info "먼저 서비스를 시작해주세요:"
        log_info "docker-compose up -d $service_name"
        exit 1
    fi
    
    log_info "$service_display_name 서비스가 실행 중입니다."
}

# 프로젝트 루트 디렉토리로 이동
cd_to_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    cd "$project_root"
    
    log_info "프로젝트 루트 디렉토리로 이동: $(pwd)"
}

# 필수 환경변수 확인 함수
validate_required_env() {
    local missing_vars=()
    
    # 필수 환경변수 목록
    local required_vars=(
        "EXPOSE_PORT"
        "TUNNEL_NAME" 
        "POSTGRES_USER"
        "POSTGRES_PASSWORD"
        "POSTGRES_DB"
        "POSTGRES_NON_ROOT_USER"
        "POSTGRES_NON_ROOT_PASSWORD"
        "ENCRYPTION_KEY"
    )
    
    # 각 변수가 설정되어 있는지 확인
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    # 누락된 변수가 있으면 에러 출력
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "다음 환경변수들이 .env 파일에 설정되지 않았습니다:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        log_info ".env 파일을 확인하고 누락된 값들을 설정해주세요."
        log_info "참고: env.example 파일을 확인하세요."
        exit 1
    fi
}

# 선택적 환경변수 기본값 설정 함수
set_optional_defaults() {
    # 백업 디렉토리만 기본값 설정 (프로젝트 구조상 고정값)
    BACKUP_DIR=${BACKUP_DIR:-./backups}
}

# 초기화 함수 (모든 스크립트에서 공통으로 호출)
init_common() {
    # 에러 발생 시 스크립트 중단
    set -e
    
    # 프로젝트 루트로 이동
    cd_to_project_root
    
    # .env 파일 로드
    load_env
    
    # 필수 환경변수 확인
    validate_required_env
    
    # 선택적 기본값 설정
    set_optional_defaults
}

# 도움말 표시 함수
show_usage() {
    local script_name="$1"
    local usage_text="$2"
    
    echo "사용법: $script_name $usage_text"
    echo ""
    echo "이 스크립트는 n8n 프로젝트의 일부입니다."
    echo "자세한 정보는 README.md를 참조하세요."
}

# 확인 프롬프트 함수
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    
    if [ "$default" = "Y" ] || [ "$default" = "y" ]; then
        local prompt="(Y/n)"
        local default_reply="Y"
    else
        local prompt="(y/N)"
        local default_reply="N"
    fi
    
    echo -e "${YELLOW}${EMOJI_WARNING} $message${NC}"
    read -p "계속하시겠습니까? $prompt: " -n 1 -r
    echo
    
    if [ -z "$REPLY" ]; then
        REPLY="$default_reply"
    fi
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "작업이 취소되었습니다."
        exit 0
    fi
}

# 파일 크기 표시 함수
show_file_size() {
    local file_path="$1"
    local label="${2:-파일 크기}"
    
    if [ -f "$file_path" ]; then
        local size=$(du -h "$file_path" | cut -f1)
        log_info "$label: $size"
    fi
}

# 오래된 파일 정리 함수
cleanup_old_files() {
    local directory="$1"
    local pattern="$2"
    local days="${3:-7}"
    
    if [ -d "$directory" ]; then
        local count=$(find "$directory" -name "$pattern" -mtime +$days -type f | wc -l)
        if [ "$count" -gt 0 ]; then
            find "$directory" -name "$pattern" -mtime +$days -delete
            log_success "${days}일 이상된 파일 ${count}개를 정리했습니다."
        else
            log_info "정리할 오래된 파일이 없습니다."
        fi
    fi
}
