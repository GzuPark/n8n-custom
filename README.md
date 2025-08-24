# n8n with PostgreSQL and Worker

PostgreSQL 데이터베이스와 워커를 분리된 컨테이너로 실행하는 n8n 자동화 워크플로우 플랫폼입니다.

## 🚀 프로젝트 개요

이 프로젝트는 다음과 같은 구성으로 이루어져 있습니다:

- **nginx**: 리버스 프록시 (외부 접근 관리)
- **n8n 메인 서비스**: 웹 인터페이스 및 API 서버
- **n8n 워커**: 백그라운드 작업 처리
- **PostgreSQL**: 데이터베이스 (워크플로우, 실행 기록 등 저장)
- **Redis**: 큐 시스템 (워커와 메인 서비스 간 작업 분배)

## 📋 사전 요구사항

- Docker 및 Docker Compose 설치
- 최소 4GB RAM 권장
- `.env` 파일에서 설정한 외부 포트가 사용 가능해야 함

## 🚀 빠른 시작

### 1단계: 환경 변수 설정

```bash
# env.example을 .env로 복사
cp env.example .env

# .env 파일을 편집하여 보안을 위해 기본 값들을 변경하세요
nano .env
```

**반드시 변경해야 할 항목들:**

- `POSTGRES_USER`, `POSTGRES_PASSWORD`: PostgreSQL 관리자 계정
- `POSTGRES_NON_ROOT_USER`, `POSTGRES_NON_ROOT_PASSWORD`: n8n 전용 DB 계정
- `ENCRYPTION_KEY`: n8n 데이터 암호화 키 (32자 이상)
- `EXPOSE_PORT`: 외부 접근 포트 번호
- `TUNNEL_NAME`: Cloudflare Tunnel 이름 (터널 사용 시)
- `WEBHOOK_URL`: 웹훅용 외부 접근 URL (터널 사용 시)

### 2단계: 서비스 시작

```bash
docker-compose up -d
```

서비스가 시작되면 브라우저에서 `http://localhost:{EXPOSE_PORT}`로 접속할 수 있습니다.

## 🔄 워크플로우 실행 흐름

### nginx를 통한 접근 흐름

```mermaid
sequenceDiagram
    participant U as 👤 사용자
    participant N as 🌐 nginx<br/>(Port: {EXPOSE_PORT})
    participant W as 🔗 n8n Web UI<br/>(Internal: 5678)
    participant R as 📨 Redis Queue
    participant WK as ⚙️ n8n Worker
    participant DB as 🗄️ PostgreSQL

    Note over U,N: 외부 접근
    U->>N: 1. http://localhost:{EXPOSE_PORT} 접속
    N->>W: 2. 내부 네트워크로 프록시 (5678 포트)
    W->>U: 3. n8n 웹 인터페이스 응답
    
    Note over U,W: 워크플로우 관리
    U->>N: 4. 워크플로우 생성/편집 요청
    N->>W: 5. 요청 전달
    W->>DB: 6. 워크플로우 저장
    W->>N: 7. 응답
    N->>U: 8. 결과 전달
    
    Note over U,WK: 워크플로우 실행
    U->>N: 9. 워크플로우 실행 요청
    N->>W: 10. 요청 전달
    W->>R: 11. 실행 작업을 큐에 추가
    W->>DB: 12. 실행 기록 생성 (대기 상태)
    
    R->>WK: 13. 작업을 워커에게 전달
    WK->>DB: 14. 실행 상태 업데이트 (진행 중)
    
    loop 워크플로우 노드들
        WK->>WK: 15. 각 노드 실행
        WK->>DB: 16. 중간 결과 저장
    end
    
    WK->>DB: 17. 최종 실행 결과 저장 (완료/실패)
    WK->>W: 18. 실행 완료 알림
    W->>N: 19. 결과 응답
    N->>U: 20. 최종 결과 표시
```

### 네트워크 보안 흐름

```mermaid
graph TD
    A["🌍 외부 인터넷"] --> B["🌐 nginx<br/>(Port: {EXPOSE_PORT})<br/>공개 접근점"]
    B --> C["🔒 Docker 내부 네트워크"]
    
    subgraph "Docker Internal Network"
        C --> D["🔗 n8n Web UI<br/>(Port: 5678)<br/>내부 전용"]
        D --> E["📨 Redis<br/>(Port: 6379)<br/>내부 전용"]
        D --> F["🗄️ PostgreSQL<br/>(Port: 5432)<br/>내부 전용"]
        G["⚙️ n8n Worker<br/>내부 전용"] --> E
        G --> F
    end
    
    style A fill:#ffcdd2
    style B fill:#ffecb3
    style C fill:#e8f5e8
    style D fill:#e1f5fe
    style E fill:#fff3e0
    style F fill:#e8f5e8
    style G fill:#f3e5f5
```

## 🏗️ 아키텍처

```mermaid
graph TD
    A["🌐 nginx<br/>(Port: {EXPOSE_PORT})<br/>리버스 프록시"] --> B["🔗 n8n Web UI<br/>(Internal: 5678)<br/>워크플로우 편집 및 관리"]
    B --> C["📨 Redis<br/>Message Queue<br/>작업 큐 관리"]
    D["⚙️ n8n Worker<br/>Background Process<br/>워크플로우 실행"] --> C
    C --> E["🗄️ PostgreSQL<br/>Database<br/>워크플로우 & 실행 기록 저장"]
    
    F["👤 사용자"] --> A
    B --> G["📊 워크플로우 생성/편집"]
    G --> C
    C --> D
    D --> H["🔄 작업 실행"]
    H --> E
    
    style A fill:#ffecb3
    style B fill:#e1f5fe
    style D fill:#f3e5f5
    style C fill:#fff3e0
    style E fill:#e8f5e8
    style F fill:#fce4ec
```

## 🐳 Docker 서비스 구성

```mermaid
graph LR
    subgraph "Docker Compose Services"
        A["🌐 nginx<br/>Reverse Proxy<br/>Port: {EXPOSE_PORT}"]
        B["🔗 n8n<br/>Main Service<br/>Internal: 5678"]
        C["⚙️ n8n-worker<br/>Background Worker"]
        D["📨 Redis<br/>Queue Service<br/>Internal: 6379"]
        E["🗄️ PostgreSQL<br/>Database<br/>Internal: 5432"]
    end
    
    subgraph "Docker Volumes"
        V1["📦 n8n_storage<br/>n8n 데이터"]
        V2["📦 db_storage<br/>PostgreSQL 데이터"]
        V3["📦 redis_storage<br/>Redis 데이터"]
    end
    
    A --> B
    B --> D
    C --> D
    B --> E
    C --> E
    
    B --> V1
    E --> V2
    D --> V3
    
    style A fill:#ffecb3
    style B fill:#e1f5fe
    style C fill:#f3e5f5
    style D fill:#fff3e0
    style E fill:#e8f5e8
```

## 🔧 주요 명령어

### 서비스 관리

```bash
# 서비스 시작
docker-compose up -d

# 서비스 중지
docker-compose stop

# 서비스 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs

# 완전 제거 (데이터 유지)
docker-compose down

# 완전 제거 (데이터도 삭제)
docker-compose down -v
```

### 백업 및 복원

```bash
# 데이터베이스 백업
./scripts/backup.sh

# 데이터베이스 복원
./scripts/restore.sh ./backups/백업파일명.sql

# Cloudflare Tunnel 실행
./scripts/tunnel.sh
```

## 📁 파일 구조

```text
.
├── docker-compose.yaml     # Docker 서비스 정의
├── env.example            # 환경 변수 템플릿
├── init-data.sh          # PostgreSQL 초기화 스크립트
├── nginx/
│   └── nginx.conf        # nginx 리버스 프록시 설정
└── scripts/
    ├── backup.sh         # DB 백업 스크립트
    ├── restore.sh        # DB 복원 스크립트
    ├── tunnel.sh         # Cloudflare Tunnel 실행
    └── common.sh         # 공통 함수 라이브러리
```

## 🛠️ 고급 설정

### 포트 변경

외부 포트를 변경하려면 `.env` 파일에서 `EXPOSE_PORT` 값을 수정하세요:

```bash
# .env 파일에서
EXPOSE_PORT=8080  # 원하는 포트로 변경
```

### Cloudflare Tunnel 설정

1. **터널 생성**

   ```bash
   cloudflared tunnel create n8n-tunnel
   cloudflared tunnel route dns n8n-tunnel n8n.yourdomain.com
   ```

2. **터널 설정 파일 (`config.yml`)**

   ```yaml
   tunnel: n8n-tunnel
   credentials-file: /path/to/credentials.json
   ingress:
   - hostname: n8n.yourdomain.com
     service: http://localhost:{EXPOSE_PORT}
   - service: http_status:404
   ```

3. **환경변수 설정**

   ```bash
   # .env 파일에서
   WEBHOOK_URL=https://n8n.yourdomain.com
   TUNNEL_NAME=n8n-tunnel
   ```

### 웹훅 작동 원리

```mermaid
sequenceDiagram
    participant EXT as 🌍 외부 서비스<br/>(GitHub, Slack 등)
    participant CF as ☁️ Cloudflare Tunnel
    participant NGX as 🌐 nginx
    participant N8N as 🔗 n8n
    
    Note over N8N: 웹훅 트리거 생성 시
    N8N->>EXT: "웹훅 URL: https://n8n.yourdomain.com/webhook/abc123"
    
    Note over EXT: 이벤트 발생 시
    EXT->>CF: POST https://n8n.yourdomain.com/webhook/abc123
    CF->>NGX: 터널을 통해 localhost:{EXPOSE_PORT}/webhook/abc123로 전달
    NGX->>N8N: nginx가 내부 n8n:5678/webhook/abc123로 프록시
    N8N->>N8N: 워크플로우 실행
```

## 🐛 문제 해결

### 일반적인 문제들

1. **포트 충돌**

   ```bash
   # 포트 사용 확인
   lsof -i :${EXPOSE_PORT}   # nginx (외부 접근)
   lsof -i :5678             # n8n (내부)
   lsof -i :5432             # PostgreSQL (내부)
   lsof -i :6379             # Redis (내부)
   ```

2. **서비스별 로그 확인**

   ```bash
   docker-compose logs nginx
   docker-compose logs n8n
   docker-compose logs n8n-worker
   docker-compose logs postgres
   docker-compose logs redis
   ```

3. **서비스 상태 확인**

   ```bash
   docker-compose ps
   docker stats
   ```

## 🔒 보안 고려사항

- `.env` 파일을 버전 관리에서 제외
- 강력한 비밀번호 사용
- `ENCRYPTION_KEY`는 32자 이상의 임의 문자열 사용
- 웹훅 URL에 예측하기 어려운 토큰 포함
- 프로덕션에서는 방화벽 설정
- 정기적인 백업 및 업데이트

## 📜 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

**중요**: 이 프로젝트는 [n8n](https://github.com/n8n-io/n8n)을 사용하며, n8n은 [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) 하에 배포됩니다. 상업적 사용을 위해서는 n8n의 라이선스 조건을 확인하시기 바랍니다.

## 📚 추가 자료

- [n8n 공식 문서](https://docs.n8n.io/)
- [n8n 워크플로우 템플릿](https://n8n.io/workflows/)
- [n8n 커뮤니티](https://community.n8n.io/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Reference setup](https://github.com/n8n-io/n8n-hosting/tree/main/docker-compose/withPostgresAndWorker)
