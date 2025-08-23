#!/bin/bash

# n8n with PostgreSQL and Worker 설정 스크립트
echo "🚀 n8n 프로젝트 설정을 시작합니다..."

# .env 파일이 존재하는지 확인
if [ ! -f ".env" ]; then
    echo "📋 .env 파일을 생성합니다..."
    cp env.example .env
    echo "⚠️  중요: .env 파일의 기본 비밀번호와 키를 보안을 위해 변경해주세요!"
    echo "   편집: nano .env 또는 code .env"
else
    echo "✅ .env 파일이 이미 존재합니다."
fi

# Docker 및 Docker Compose 설치 확인
if ! command -v docker &> /dev/null; then
    echo "❌ Docker가 설치되어 있지 않습니다. Docker를 먼저 설치해주세요."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose가 설치되어 있지 않습니다. Docker Compose를 먼저 설치해주세요."
    exit 1
fi

echo "✅ Docker 및 Docker Compose가 설치되어 있습니다."

# 포트 5678 사용 가능 여부 확인
if lsof -Pi :5678 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  포트 5678이 이미 사용 중입니다. docker-compose.yaml에서 포트를 변경하거나 해당 프로세스를 종료해주세요."
else
    echo "✅ 포트 5678이 사용 가능합니다."
fi

# Docker 볼륨 생성 (이미 존재하면 무시됨)
echo "📦 Docker 볼륨을 생성합니다..."
docker volume create gzu_n8n_db_storage 2>/dev/null || true
docker volume create gzu_n8n_n8n_storage 2>/dev/null || true
docker volume create gzu_n8n_redis_storage 2>/dev/null || true

echo "🎉 설정 완료!"
echo ""
echo "다음 단계:"
echo "1. .env 파일을 편집하여 보안 설정을 변경하세요"
echo "   편집: nano .env 또는 code .env"
echo "2. 'docker-compose up -d' 명령어로 서비스를 시작하세요"
echo "3. 브라우저에서 http://localhost:5678로 접속하세요"
echo ""
echo "📚 자세한 내용은 README.md 파일을 참고하세요."
echo "🔧 백업/복원은 scripts/backup.sh, scripts/restore.sh를 사용하세요."
echo ""
echo "문제가 발생하면 'docker-compose logs' 명령어로 로그를 확인하세요."
