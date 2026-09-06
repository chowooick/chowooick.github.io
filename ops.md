# 도구·운영 — 실측 사실

Docker, Git, GitHub, CI, macOS. ID 접두사 `OPS`. ID는 불변이다.

---

## OPS-001 — GitHub Pages는 index가 없으면 빌드 성공하고 404를 낸다

`측정 2026-09-06 · GitHub Pages legacy 빌드`

**증상:** `gh api repos/OWNER/REPO/pages/builds`가 `"status": "built", "error": null`을
반환하는데 사이트 루트가 404다.

포스트와 하위 페이지만 있고 `index.md`·`index.html`이 없으면 빌드는 성공하고 서빙할
루트가 없다.

**해결:** 루트에 index를 둔다.

---

## OPS-002 — LLM이 읽을 문서라면 Jekyll을 끈다

`측정 2026-09-06 · GitHub Pages`

`.nojekyll` 파일 하나로 정적 서빙이 되고 `.md`가 변환 없이 `text/markdown`으로 나간다.

테마가 씌우는 HTML·CSS·네비게이션은 LLM 입력에서 전부 노이즈다.
같은 내용에 토큰이 몇 배로 든다.

**주의:** 일부 브라우저·툴이 `.md`를 다운로드로 처리한다. 사람 진입로용으로
`index.html`을 최소 HTML로 하나 둔다.

---

## OPS-003 — 사용자 사이트 도메인은 `.io`다

`측정 2026-09-06 · GitHub Pages`

`USERNAME.github.io`. `.com`이 아니다.

---

## OPS-004 — GitHub 인증에 비밀번호를 쓰지 않는다

`측정 2026-09-06 · gh CLI`

GitHub은 2021년부터 git 인증에 비밀번호를 받지 않는다. 2FA가 켜져 있으면 로그인도 안 된다.

```
gh auth login --hostname github.com --git-protocol https --web
```

일회용 코드가 출력되고 브라우저에서 승인하면 토큰이 키체인에 저장된다.
**비대화형 셸에서도 코드 출력까지는 된다.**

**증상 (푸시 실패):**
```
fatal: could not read Username for 'https://github.com': Device not configured
```
**해결:** `gh auth setup-git`으로 자격 증명 헬퍼를 붙인다. 인증만으로는 git이 토큰을 쓰지 않는다.

---

## OPS-005 — Docker 빌드 캐시가 조용히 20GB를 넘는다

`측정 2026-09-06 · Docker Desktop macOS`

`docker system df`로 확인, `docker builder prune -af`로 회수.

관련: `down -v`는 컴포즈 프로젝트 소유 볼륨만 지운다. 별도로 만든 캐시 볼륨은 남는다.

---

## OPS-006 — 통합 테스트 포트를 하드코딩하면 동시에 하나만 돈다

`측정 2026-09-06`

**증상:** 두 작업이 같은 포트를 놓고 충돌한다. 재시도 로직이 없는 쪽은 그냥 실패한다.

**해결 — 슬롯 규약:**
```
서비스A  17349 + 10n
서비스B  17350 + 10n
DB       15432 + 10n
```
슬롯 `n`이 지정되면 그것을, 없으면 네 포트가 전부 비어 있는 첫 슬롯을 잡는다.

**주의:** compose는 `${VAR:-기본}`만 지원하고 산술을 못 한다. 계산은 셸에서 하고
compose에는 결과 값만 넘긴다.

---

## OPS-007 — exit 137은 OOM이다

`측정 2026-09-06 · Docker Desktop macOS`

빌드와 테스트가 같은 VM 메모리를 쓴다. 스택 여러 개가 동시에 떠 있으면 빠듯해진다.

**증상:** 프로세스가 출력 없이 죽고 종료 코드 137. trap이 실행되지 않아 컨테이너가
고아로 남고, 다음 실행이 포트 충돌로 실패한다.

**해결:** 재시도 전에 안 쓰는 스택을 `down -v`로 내린다.

---

## OPS-008 — YAML plain scalar 안의 `PASS: `가 매핑 키로 파싱된다

`측정 2026-09-06 · GitLab CI`

**증상:** `grep -c '^--- PASS: '`를 CI 설정에 그대로 쓰면 파일 전체가 파싱 오류.

콜론+공백이 매핑 구분자로 읽힌다.

**해결:** 패턴에서 콜론+공백을 뺀다 (`'^--- PASS'`). 또는 따옴표 방식을 바꾼다.

---

## OPS-009 — 스모크 테스트는 스택을 띄우지 않는다

`측정 2026-09-06`

**증상:** 스모크 스크립트가 스스로 `docker compose up --build`를 실행해, 다른 작업이
쓰는 상시 스택을 재빌드했다.

스모크는 이미 떠 있는 스택에 대고 검증만 해야 병렬·CI에서 안전하다.

**이미 그렇게 만들어진 스크립트를 못 고치는 상황이면** 환경변수로 우회한다:
```
COMPOSE_PROJECT_NAME=… COMPOSE_FILE=… BASE_URL=… ./smoke.sh
```
왜 필요한지 주석으로 남긴다. 지우면 상시 스택이 날아간다.

---

## OPS-010 — 마이그레이션 개수를 정확히 단언하지 마라

`측정 2026-09-06`

`schema_migrations == [1]` 같은 단언은 다음 마이그레이션이 추가되는 순간
**그 작업의 잘못 없이** CI를 빨간불로 만든다.

**해결:** "포함되어 있음"으로 완화한다.

---

## OPS-011 — macOS Retina에서 창 크기와 프레임버퍼 크기가 다르다

`측정 2026-09-06 · macOS`

렌더 결과의 정확한 해상도가 필요하면 고정 크기 오프스크린 버퍼에 그려야 한다.

함께 걸림: GDT-006

---

## OPS-012 — TUI 앱의 로그 덤프는 파싱하지 않는다

`측정 2026-09-06`

ANSI 이스케이프 시퀀스 범벅이라 사람도 기계도 읽기 어렵다.

**해결:** 구조화된 원본(JSON 등)이 따로 있으면 그쪽을 쓴다. 없으면 애초에 파싱하지 않는
설계로 간다.

---

## OPS-013 — 단축키가 "전부" 안 먹으면 설정이 아니라 포커스를 먼저 본다

`측정 2026-09-06 · macOS · VS Code`

**증상:** VS Code에서 `Cmd +`/`Cmd -`가 안 듣고, 명령 팔레트(`Cmd+Shift+P`)도 반응하지 않는다.

**원인:** VS Code가 최전면이 아니었다. 다른 앱(브라우저)이 포커스를 쥐고 있어 키가 전부
그쪽으로 갔다. 인증·검색 등으로 브라우저를 띄운 뒤 포커스가 남아 있을 때 흔하다.

**진단 순서 — 이 순서가 중요하다:**

1. 최전면 앱 확인:
   `osascript -e 'tell application "System Events" to name of first application process whose frontmost is true'`
2. macOS 보안 입력 잠금 확인 (비밀번호 필드를 띄운 앱이 잠금을 안 풀면 다른 앱의 단축키가 먹통이 된다):
   `ioreg -l -w 0 | grep -i kCGSSessionSecureInputPID` — 0이 아니면 그 PID가 범인
3. 앱 프로세스가 멈췄는지: `ps -eo pid,stat,command | grep <앱>` — `T`(정지)·`Z`(좀비) 확인
4. 그 다음에야 keybindings·확장 충돌을 본다

**판별 기준:** 명령 팔레트처럼 **앱의 가장 기본적인 단축키까지** 안 먹으면 설정 문제가
아니다. 설정 충돌은 특정 키만 골라서 죽인다. 전부 죽었으면 이벤트가 앱에 도달하지 않는
것이고, 원인은 포커스·보안 입력·프로세스 정지 셋 중 하나다.

---

## OPS-014 — 생성물을 커밋하는 CI는 로컬 푸시와 충돌한다

`측정 2026-09-06 · GitHub Actions`

**증상:** 로컬에서 생성물을 만들어 커밋하고 푸시하면
`! [rejected] main -> main (fetch first)`.
CI가 먼저 같은 파일을 재생성해 커밋해 두어 원격이 앞서 있다.

빌드 산출물을 리포에 커밋하는 CI(예: 색인·번들 자동 생성)를 쓰면, 사람과 CI가
같은 파일을 각자 만들어 필연적으로 갈라진다.

**해결:** `git rebase origin/main` 후 충돌 파일을 **다시 생성**해서 해결한다.
생성물은 병합하는 것이 아니라 재생성하는 것이다.

```
git rebase origin/main      # 생성물에서 충돌
./build.sh                  # 병합 대신 재생성
git add <생성물> <원본>
git rebase --continue
```

**주의:** 스크립트에서 `git push … | head -2 && echo "성공"` 같은 형태를 쓰면
푸시가 거부돼도 `head`가 0으로 끝나 "성공"이 출력된다. 종료 코드는
파이프 마지막 명령의 것이다. `${PIPESTATUS[0]}`을 보거나 파이프를 쓰지 않는다.

**더 나은 구조:** 생성물을 리포에 커밋하지 않고 배포 단계에서만 만든다.
그러면 충돌 자체가 없다. 커밋해야 한다면 CI만 쓰거나 사람만 쓰고, 둘 다 쓰지 않는다.


## OPS-015 — dind에서 bind mount는 실패하지 않고 빈 디렉터리가 된다

`측정 2026-09-06 · GitLab CI · docker:27-dind · Docker Compose v2`

**증상:** 로컬에서 통과하는 스모크가 CI에서만 깨진다. 스택은 healthy로 뜨고
`/healthcheck`도 200인데, 설정을 읽는 첫 요청에서만 죽는다.

```
==> docker compose -p X ... -f /tmp/tmp.CoOigN/config.override.yml up -d --build
FAIL: character.create returned HTTP 500: {"code":13,"message":"config_unavailable"}
```

런타임에 조립한 설정 디렉터리를 `- $CONFIG_DIR:/app/config` 로 넘겼다. **dind 데몬은
잡 컨테이너와 파일시스템을 공유하지 않는다.** 데몬은 그 호스트 경로를 자기 파일시스템에서
찾고, 없으면 **에러 대신 빈 디렉터리를 만들어 마운트한다.** compose 출력에 경고 한 줄 없다.
노트북에서는 데몬과 스크립트가 같은 파일시스템이라 영원히 안 드러난다.

**해결:** 경로 대신 **이름 있는 볼륨 + `docker cp`**. `docker cp`는 API로 나가는 tar
스트림이라 공유 경로가 필요 없다.

```bash
helper="$(docker create -v "$VOL:/config" alpine:3.20 true)"
docker cp "$CONFIG_DIR/." "$helper:/config"
docker rm -f "$helper"
# compose 쪽: volumes: [ "$VOL:/app/config:ro" ] + volumes: { $VOL: { external: true } }
```

**주의:** 여기서 "CI에서만 볼륨, 로컬은 bind mount"로 갈라 놓고 싶어진다. 갈라 놓으면
**로컬이 CI에서 도는 것을 더 이상 테스트하지 않는다** — 이 함정이 러너까지 간 이유가
정확히 그것이다. 환경마다 진짜로 다른 것(호스트 이름 같은)만 갈라라. 그리고 암묵적 pull은
컨테이너 id를 캡처하는 스트림을 오염시키니 `docker pull`을 별도 줄로 먼저 돌린다.

## OPS-016 — `|| true`로 감싼 정리 명령은 실패해도 로그가 성공처럼 보인다

`측정 2026-09-06 · bash · Docker Compose v2`

**증상:** 스모크가 끝날 때마다 스택이 살아 있다. 그런데 로그는 정상 종료와 글자 하나 다르지
않다.

```bash
cleanup() {
  rm -rf "$WORK"                                     # ← -f 로 넘길 파일이 여기 있었다
  echo "==> ${COMPOSE[*]} down -v"                   # ← 명령보다 먼저 찍힌다
  "${COMPOSE[@]}" down -v >/dev/null 2>&1 || true    # ← 실패를 삼킨다
}
```

`$COMPOSE`에 `-f $WORK/override.yml`이 들어 있었다. 디렉터리를 먼저 지우니 compose가
`open ...: no such file or directory`로 죽는데, `2>&1`이 감추고 `|| true`가 종료 코드를
지운다. 남는 것은 **명령이 돌기도 전에 찍힌 성공처럼 보이는 줄**이다. 몇 주 동안 스택이
쌓였고, 매번 "다른 세션이 남긴 것"으로 오해했다.

**해결:** 순서를 뒤집고(정리 명령 먼저, 삭제 나중), 로그 줄은 **명령 뒤에** 결과와 함께 찍는다.

```bash
if "${COMPOSE[@]}" down -v >/dev/null 2>&1; then echo "==> down -v ok"; else echo "==> down -v FAILED" >&2; fi
rm -rf "$WORK"
```

**주의:** `|| true`는 "실패해도 계속한다"이지 "실패해도 괜찮다"가 아니다. 정리 경로에 쓸
때는 실패를 **보이게** 남겨라. 이 버그가 드러난 계기도 실패 자체가 아니라, 볼륨이
`volume is in use`로 안 지워져서 붙잡은 컨테이너를 봤더니 정리했다고 로그에 찍힌 그
컨테이너였던 것이다. 조용한 실패는 무관해 보이는 증상으로만 나타난다. AGT-017과 같은 계열이다.

---

## OPS-017 — 같은 이름의 compose 프로젝트에 `up` 하면 실패가 아니라 **남의 스택에 붙는다**

`측정 2026-09-06 · docker compose v2 · macOS`

**증상:** 병렬 테스트 두 벌이 서버 하나를 조용히 공유한다. 어느 쪽도 오류를 내지 않는다.
그리고 **전혀 다른 파일의 단언이 깨진다** — "이 채널에 나 혼자여야 한다" 같은 것이.
실패 지점과 원인이 완전히 따로 논다.

포트 슬롯을 배정받아 프로젝트 이름을 `myapp-t026-0`처럼 슬롯 번호로만 만들면, 슬롯 배정이
겹쳤을 때 진 쪽의 `docker compose -p myapp-t026-0 up -d`가 **이미 떠 있는 그 프로젝트에
붙어서 성공한다.** 포트 충돌도 없다. 같은 프로젝트니까 새로 바인딩할 게 없다.

기대하는 그림은 "슬롯이 겹치면 포트 충돌로 죽고 재시도한다"인데, 이름이 같으면 그 방어가
통째로 사라진다. 슬롯 배정 로직이 아무리 정교해도 이 지점에서 무력해진다.

**해결:** 프로젝트 이름에 **실행마다 다른 값**을 넣는다. 셸이면 `$$`면 충분하다.

```bash
project="myapp-${TAG}-${SLOT}-$$"     # 슬롯만으로 만들지 않는다
volume="myapp-config-${TAG}-${SLOT}-$$"
```

그러면 겹쳤을 때 발행 포트에서 충돌하고, 그건 **볼 수 있는 실패**라 재시도가 잡는다.
`compose up` 성공을 스택을 소유했다는 증거로 쓰지 마라. 이름이 같으면 성공은 소유가 아니라
공유를 뜻한다.

**같이 볼 것:** 마운트하는 볼륨 이름도 같은 규칙을 따라야 한다. 프로젝트만 분리하고 config
볼륨을 슬롯으로만 지으면, 한쪽이 쓴 설정을 다른 쪽이 읽는다. OPS-016과 같은 계열 —
조용한 성공이 조용한 실패보다 오래 숨는다.

## OPS-018 — `docker ps --filter ancestor=<image>`는 CI 잡 컨테이너까지 잡는다

`측정 2026-09-06 · gitlab-runner 19.3.0 · docker 27 · Ubuntu 24.04`

**증상:** 러너가 도는 호스트에서 임시 컨테이너를 정리하려고

```bash
docker rm -f $(docker ps -q --filter ancestor=docker:27-cli)
```

를 돌렸더니, 도중이던 GitLab 잡이 **`ERROR: Job failed: exit code 137`**(SIGKILL)로 죽었다.
잡 로그는 명령 한가운데서 끊기고 실패 사유가 아무 데도 없다 — 러너도 GitLab도 "누가 밖에서
컨테이너를 지웠다"는 말을 하지 않으므로, 코드 문제로 오진하기 쉽다.

GitLab docker executor의 잡 컨테이너는 `.gitlab-ci.yml`의 `image:`를 그대로 쓴다. 그래서
`image: docker:27-cli`인 잡이 도는 동안 이 필터는 내 임시 컨테이너와 잡 컨테이너를
구분하지 못한다. 이름(`runner-<토큰>-project-<id>-concurrent-<n>-...-build`)만이 둘을 가른다.

**해결:** 러너 호스트에서는 ancestor·image로 일괄 삭제하지 않는다. 이름으로 지운다.

```bash
docker rm -f $(docker ps -q --filter name=^/my-drill-)      # 내가 붙인 접두사
docker ps -q --filter ancestor=X --filter name=runner-      # 지우기 전에 뭐가 걸리는지 먼저 본다
```

임시 컨테이너는 처음부터 `--name my-drill-$$`로 띄워 이름으로 지울 수 있게 한다.

**같이 볼 것:** SIGKILL은 트랩이 안 돌아, 잡 스크립트가 `trap ... EXIT`로 지우던 보조
컨테이너가 호스트에 남는다. 잡을 밖에서 죽였다면 그 고아도 같이 찾아 지운다.
