# 도구·운영에서 실측한 사실

Docker, Git, GitHub, CI. 프로젝트 무관.

## GitHub Pages

**`index.md`나 `index.html`이 없으면 빌드는 성공하고 404가 뜬다.**
포스트와 하위 페이지만 있으면 빌드 로그에 오류가 없는데 루트가 서빙되지 않는다.
`gh api repos/OWNER/REPO/pages/builds`는 `"status": "built", "error": null`을 반환한다.

**LLM이 읽을 문서라면 Jekyll을 끄는 편이 낫다.**
`.nojekyll` 파일 하나로 정적 서빙이 되고, `.md`가 변환 없이 원문 그대로 나간다.
테마가 씌우는 HTML·CSS·네비게이션은 LLM 입력에서 전부 노이즈다.

**사용자 사이트 도메인은 `.io`다.** `USERNAME.github.io`. `.com`이 아니다.

## GitHub CLI 인증

비밀번호를 대화나 스크립트에 넣지 않는다. GitHub은 2021년부터 git 인증에 비밀번호를
받지 않는다.

```
gh auth login --hostname github.com --git-protocol https --web
```

일회용 코드가 출력되고, 브라우저에서 승인하면 토큰이 키체인에 저장된다.
비대화형 셸에서도 코드 출력까지는 된다.

푸시 전에 자격 증명 헬퍼를 붙여야 한다:

```
gh auth setup-git
```

이걸 빼면 `fatal: could not read Username for 'https://github.com': Device not configured`.

## Docker

**빌드 캐시가 조용히 20GB를 넘는다.** `docker system df`로 확인, `docker builder prune -af`로 회수.

**exit 137은 OOM이다.** 빌드와 테스트가 같은 VM 메모리를 쓴다. 스택 여러 개가 동시에
떠 있으면 빠듯해진다. 재시도 전에 안 쓰는 스택을 `down -v`로 내릴 것.

**`down -v`는 컴포즈 프로젝트 소유 볼륨만 지운다.** 별도로 만든 캐시 볼륨은 남는다.

**죽은 프로세스는 스택을 남긴다.** SIGKILL로 죽으면 trap이 실행되지 않아 컨테이너가
고아로 남는다. 다음 실행이 포트 충돌로 실패한다.

## 통합 테스트 포트

포트를 하드코딩하면 동시에 한 작업만 통합 테스트를 돌릴 수 있다.
**슬롯 규약**으로 가른다:

```
서비스A  17349 + 10n
서비스B  17350 + 10n
DB       15432 + 10n
```

슬롯 `n`이 지정되면 그것을, 없으면 네 포트가 전부 비어 있는 첫 슬롯을 잡는다.
compose는 `${VAR:-기본}`만 지원하고 산술은 못 하므로, 계산은 셸에서 하고
compose에는 결과 값만 넘긴다.

## GitLab CI

**YAML plain scalar 안의 `PASS: `가 매핑 키로 파싱된다.**
`grep -c '^--- PASS: '`를 그냥 쓰면 `.gitlab-ci.yml` 전체가 깨진다. 패턴에서 콜론+공백을 뺄 것.

**러너 없이 검증하는 스크립트를 같이 만든다.** CI가 하는 일을 그대로 로컬에서 실행하는
스크립트가 있으면 러너 등록 전에 파이프라인 로직을 확인할 수 있다.

## 스모크 스크립트 설계

**스모크는 스택을 띄우지 않는다.** 이미 떠 있는 스택에 대고 검증만 한다.
스크립트가 스스로 `docker compose up --build`를 하면 다른 작업이 쓰는 상시 스택을
재빌드해 버린다.

이미 그렇게 만들어진 스크립트를 못 고치는 상황이면 환경변수로 우회한다:

```
COMPOSE_PROJECT_NAME=... COMPOSE_FILE=... BASE_URL=... ./smoke.sh
```

주석으로 왜 필요한지 남긴다. 지우면 상시 스택이 날아간다.

**마이그레이션 개수를 정확히 단언하지 마라.** `schema_migrations == [1]` 같은 단언은
다음 마이그레이션이 추가되는 순간 그 작업의 잘못 없이 CI를 빨간불로 만든다.
"포함되어 있음"으로 완화할 것.

## macOS

**Retina에서 창 크기와 프레임버퍼 크기가 다르다.** 렌더 결과의 해상도가 필요하면
고정 크기 오프스크린 버퍼에 그려야 한다.

**터미널 제어문자가 섞인 로그는 파싱하지 말 것.** TUI 앱의 로그 덤프는 ANSI 이스케이프
범벅이다. 구조화된 원본(JSON 등)이 따로 있으면 그쪽을 쓴다.
