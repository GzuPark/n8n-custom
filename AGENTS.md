# n8n Automation Agents

n8n 워크플로우를 활용한 자동화 에이전트 가이드입니다.

## 🤖 주요 자동화 시나리오

### 1. 웹훅 기반 자동화

- **GitHub**: 코드 푸시, PR 생성 시 알림
- **Slack**: 메시지 수신 시 작업 트리거
- **HTTP 요청**: 외부 시스템과의 연동

### 2. 스케줄 기반 자동화

- **정기 백업**: 매일 자동 데이터베이스 백업
- **상태 모니터링**: 시스템 헬스체크
- **데이터 동기화**: 외부 API와 정기 동기화

### 3. 데이터 처리 자동화

- **파일 처리**: CSV, JSON 데이터 변환
- **이메일 자동화**: 조건부 이메일 발송
- **API 통합**: 여러 서비스 간 데이터 연동

## 🔧 설정 방법

### 웹훅 URL 설정

```bash
# .env 파일에서
WEBHOOK_URL=https://your-domain.com
```

### 외부 접근 활성화

```bash
# Cloudflare Tunnel 실행
./scripts/tunnel.sh
```

## 📋 권장 워크플로우

1. **모니터링 에이전트**: 시스템 상태 감시
2. **백업 에이전트**: 자동 데이터 백업
3. **알림 에이전트**: 중요 이벤트 알림
4. **데이터 동기화 에이전트**: 외부 시스템 연동

## 🔗 유용한 링크

- [n8n 워크플로우 템플릿](https://n8n.io/workflows/)
- [n8n 노드 문서](https://docs.n8n.io/integrations/)
- [웹훅 설정 가이드](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
