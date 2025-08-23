#!/bin/bash

# Cloudflare Tunnel 실행 스크립트

# 공통 함수 로드
source "$(dirname "$0")/common.sh"

# 초기화
init_common

log_rocket "Cloudflare Tunnel을 시작합니다..."
log_info "포트: ${EXPOSE_PORT}"
log_info "터널명: ${TUNNEL_NAME}"
log_info "URL: http://localhost:${EXPOSE_PORT}"

# cloudflared 명령어 존재 확인
if ! command -v cloudflared &> /dev/null; then
    log_error "cloudflared 명령어를 찾을 수 없습니다."
    log_info "Cloudflare Tunnel을 설치해주세요:"
    log_info "https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
    exit 1
fi

cloudflared tunnel run --url http://localhost:${EXPOSE_PORT} ${TUNNEL_NAME}
