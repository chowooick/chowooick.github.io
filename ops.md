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

## OPS-019 — 소켓 마운트 GitLab 러너에서 compose 바인드 마운트가 조용히 빈 디렉터리가 된다

`측정 2026-09-06 · gitlab-runner 19.3.0 · docker 27 · Ubuntu 24.04`

**증상:** dind를 privileged 문제로 버리고 docker executor에 `/var/run/docker.sock`을 마운트한
뒤, 그때까지 초록이던 스모크 잡이 죽었다. 서버 컨테이너는 healthy하고 `/healthcheck`도 200을
주는데, 설정을 읽는 첫 RPC만 실패한다.

```
FAIL: character.create HTTP 500: {"code":13,"message":"config_unavailable"}
```

compose 출력에도 러너 로그에도 마운트가 잘못됐다는 말이 없다. 이유는 **바인드 마운트의 경로를
해석하는 쪽이 데몬**이기 때문이다. 소켓을 마운트하면 데몬은 호스트의 것이고, 잡의 체크아웃은
잡 컨테이너 안에만 있다. `- ./config:/app/config` 같은 줄은 데몬에게 호스트에 없는
`/builds/<러너>/0/<그룹>/<프로젝트>/config`를 넘기고, 데몬은 **실패 대신 빈 디렉터리를 만든다.**
그래서 컨테이너는 정상적으로 뜨고, 설정이 필요한 첫 호출에서야 드러난다.

dind에서는 안 겪는다. GitLab이 builds 볼륨을 dind **서비스 컨테이너에도** 붙여 주므로
`/builds`가 양쪽에서 같은 것을 뜻한다. 소켓 방식에는 그런 배려가 없다.

**해결:** 체크아웃을 양쪽에서 같은 경로로 만든다. 러너 등록에 한 줄이면 된다.

```bash
gitlab-runner register --executor docker \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --docker-volumes /builds:/builds        # 이것
```

`builds_dir`을 바꿨다면 그 경로로 맞춘다. 확인은 잡이 도는 동안 호스트에서:

```bash
ls /builds/*/*/*/     # 체크아웃이 보이면 맞다. 비어 있으면 위 줄이 빠진 것이다
```

**같이 볼 것:** 볼륨을 못 붙이는 환경이면 경로 대신 스트림으로 넣는다 — `docker create` +
`docker cp`는 tar 스트림이라 경로 해석이 없고 양쪽에서 똑같이 동작한다(OPS-015). 설정 파일을
이름 있는 볼륨에 `docker cp`로 채우는 방법도 같은 이유로 안전하다.

## OPS-020 — 러너 컨테이너를 재시작하면 도는 잡이 죽고 GitLab에는 `running`으로 남는다

`측정 2026-09-06 · gitlab-runner 19.3.0 · docker executor(소켓 마운트) · GitLab.com`

**증상:** `concurrent` 값을 바꾸려고 `docker restart <runner>`를 했더니, 그 순간 실행 중이던
잡 2개(sim-test·smoke-fast)의 trace가 재시작 시각에서 끊긴 채 GitLab에서는 15분 넘게
`running`으로 표시됐다. 잡 타임아웃도 집행되지 않았다 — 타임아웃을 세는 주체가 러너인데 그
러너가 없어졌기 때문이다. 재시작된 러너는 옛 잡을 이어받지 않는다. 잡 컨테이너만 죽고 코드·
데이터 손상은 없다.

**해결:** 러너를 재시작·재배포하기 전에 `glab ci list --status running`(또는 프로젝트
파이프라인 페이지)으로 도는 파이프라인이 없는지 확인하고, 있으면 끝날 때까지 기다린다. 이미
죽은 잡은 파이프라인을 취소해 정리한다(`glab ci cancel`), 그대로 두면 러너 슬롯 계산은 맞아도
GitLab 화면이 계속 `running`을 보여 다음 분석을 흐린다.

## OPS-021 — `timeout N cmd &` 뒤 `kill -9 $!`는 래퍼만 죽이고 자식은 고아가 된다

`측정 2026-09-07 · macOS 15 · bash 5 · Godot 4.7.2 headless`

**증상:** 스모크가 헤드리스 클라이언트를 `timeout 60 godot … &`로 띄우고 정리 단계에서
`kill -9 $!`를 부른다. `$!`는 `timeout`의 pid다. SIGKILL은 전달할 수 없으므로
`timeout`만 죽고 그 밑의 Godot은 부모 없이 계속 돈다. 맥 과열을 조사하다 8시간 된
Godot 1개와 방금 끝난 스모크의 Godot 3개가 좌석을 쥔 채 살아 있는 것을 찾았다. 같은
패턴이 스모크 4개에 있었다.

**해결:** 자식을 먼저 죽인다 — `pkill -9 -P "$pid"` 뒤에 래퍼를 죽이거나, 스모크가
자기 실행에만 있는 고유 문자열(예: `--net-config $WORK/network.json`)로 `pkill -9 -f`
한다. `$WORK`가 실행마다 유일하므로 남의 클라이언트는 매칭되지 않는다. 정리 트랩이
끝난 뒤 `pgrep -fl Godot`가 비어 있는지가 진짜 검증이다.

## OPS-022 — 부팅된 Android 에뮬레이터는 `pkill -f "emulator -avd"`로 죽지 않는다

`측정 2026-09-07 · macOS 15 · Android Emulator(cmdline-tools 최신) · Pixel AVD`

**증상:** 스크립트가 `emulator -avd <이름>`으로 띄운 에뮬레이터를 정리 트랩에서
`pkill -f "emulator -avd <이름>"`으로 죽이려 했지만 `adb devices`에 `emulator-5554`가
그대로 남았다. 부팅이 끝나면 실제 프로세스는 `qemu-system-*`이고 명령줄 패턴이 다르다.
`adb -s emulator-5554 emu kill`도 같은 함수 안에서 두 번 실패했다(원인 미상).

**해결:** 인자 없는 `adb emu kill`이 두 번 다 즉시 먹었다. 그 뒤 `adb devices`가
빌 때까지 짧게 폴링하고, 그래도 남으면 `pkill -f -- "-avd <이름>"`·`pkill -f qemu-system`을
폴백으로 둔다. `[ 조건 ] && kill_fn` 형태의 정리 줄은 `|| true`가 없으면 `set -e`에서
조건이 거짓일 때 스크립트가 거기서 끝나 뒤 정리를 건너뛴다(OPS-016과 같은 함정).

## OPS-023 — 패키지 밖 파일을 상대 경로로 읽는 테스트는 로컬에서만 통과한다

`측정 2026-09-07 · GitLab CI go-test 잡 · 하루 2회 재현`

**증상:** Go 테스트가 마이그레이션 SQL을 `../../migrations/011_party.sql`로 열어
UNIQUE 인덱스 정의를 검사한다. 로컬과 스모크는 전체 체크아웃이라 통과한다. CI의
go-test 잡은 `nakama/modules/`만 컨테이너에 복사하므로 그 경로가 없어 100% 실패한다.
검수 세션이 스모크만 돌리고 `go test`를 안 돌려 첫 번째는 커밋 뒤에야 잡혔고, 같은
날 두 번째 티켓이 같은 방식으로 다시 썼다.

**해결:** 검사할 SQL 조각을 테스트 상수로 두거나, 후보 경로를 두 개 이상 탐색하고
전부 없으면 이유를 로그에 남기며 `t.Skip`한다(조용히 통과는 아니다). 검수 절차에
"서버 파일이 든 티켓은 `go test ./...` 1회"를 넣는다 — 스모크는 CI go-test 잡을
대신하지 못한다.

## OPS-024 — CI에서 벽시계 한도 단언은 숫자를 올려도 발산한다

`측정 2026-09-07 · GitLab 러너 concurrent 2 · 클라 스모크 10개 · 하루 4회 초과`

**증상:** 클라이언트 스모크가 "케이스 N이 10초 안에 끝난다"를 단언한다. 러너가 잡
2개를 동시에 돌리면서 t009·t025·t026이 차례로 한도를 넘겼다. 10초를 13초로 올린
t026이 같은 날 14.23초로 다시 넘겼다. 한도의 원래 목적은 성능이 아니라 "클라이언트가
멈췄나"였는데 성능 기준처럼 쓰이면서 잡 수가 늘 때마다 발산한다.

**해결:** 개별 숫자를 그만 올린다. 행 감지 한도는 하한 30초 × 배수로 통일하고, 실제
성능 주장이 필요한 곳은 벽시계가 아니라 서버 시각 차(`server_time`, `ready_at`)나
서버 응답 코드로 판정한다(예: "일찍 수령 → `9 not_ready`"는 시간을 재지 않는다).
동시 실행 수를 1로 낮추는 것은 답이 아니다 — 실측 결과 문제는 동시성이 아니라
단언이었다.

## OPS-025 — `adb shell input swipe`는 종점에서 즉시 뗀다. 홀드는 길이 0 스와이프로 한다

`측정 2026-09-07 · Android Emulator · Godot 4.7.2 가상 조이스틱`

**증상:** 가상 조이스틱을 "3초 드래그"하려고 `input swipe x1 y1 x2 y2 3000`을 보냈다.
포인터가 3초에 걸쳐 종점까지 움직인 뒤 **즉시 release**되므로 스틱을 밀고 있는
상태는 만들어지지 않는다.

**해결:** 시작과 끝을 같은 좌표로 두고 duration만 준다(`input swipe x y x y 3000`).
누른 채 3초를 버티는 이벤트가 되며, 조이스틱은 터치다운 지점과 중심의 거리로 편향을
계산하므로 중심에서 반경만큼 떨어진 점을 잡으면 최대 편향이 유지된다.

## OPS-026 — `docker compose`의 프로젝트 디렉터리(상대경로·`.env` 기준)는 첫 `-f` 파일의 위치다

`측정 2026-09-07 · Docker Compose v2 · macOS`

**증상:** 스모크 스택을 `git archive HEAD`로 만든 스냅샷(`$WORK/src/docker-compose.yml`)에서
빌드하려고 `docker compose -f $WORK/src/docker-compose.yml -f $WORK/src/ops/compose/test.override.yml ...`로
띄웠다. `up -d --build`가 `required variable NAKAMA_CONSOLE_USERNAME is missing a value`로
즉시 죽었다. 리포 루트에서 실행했고 리포 루트 `.env`도 멀쩡한데도 그렇다.

Compose는 `.env` 자동 로드와 컴포즈 파일 안의 상대경로(빌드 컨텍스트·볼륨 바인드)를
**현재 작업 디렉터리가 아니라 "프로젝트 디렉터리"** 기준으로 푼다. `--project-directory`를
안 주면 프로젝트 디렉터리는 **가장 먼저 지정한 `-f` 파일이 있는 디렉터리**다. 리포 루트의
`docker-compose.yml`을 그대로 쓸 때는 첫 파일 위치가 우연히 cwd와 같아서 안 보이던 동작이,
파일을 다른 경로로 옮기자마자 드러났다. (반면 두 번째 이후 `-f` 파일 자신의 상대경로는
정상적으로 그 파일 자기 위치가 아니라 여전히 첫 파일 기준 프로젝트 디렉터리로 풀린다 —
`docker compose ... config`로 `context:`·볼륨 `source:`를 직접 찍어 확인.)

**해결:** 첫 `-f`가 실제 리포 루트 밖에 있는 호출에는 `--env-file "$REPO_ROOT/.env"`를
명시로 넣는다(파일이 있을 때만 — CI처럼 `.env` 없이 프로세스 환경변수만 export하는
환경에서는 `--env-file`에 없는 경로를 주면 그 자체로 에러가 나므로 조건부로 추가한다).
`--project-directory`로 통째로 지정하는 것도 같은 효과지만, 상대경로 해석까지 강제로
바뀌는 범위가 더 크다.

## OPS-027 — `git checkout-index -a`는 대상이 이미 있으면 경고가 아니라 exit 1이다

`측정 2026-09-07 · git 2.4x`

**증상:** 스냅샷 디렉터리 하나를 `git archive HEAD | tar -x`(head 모드)와
`git checkout-index -a --prefix=`(staged 모드)가 순서대로 채우는 스모크 헬퍼에서,
staged 쪽 호출이 `set -e` 스크립트를 아무 `FAIL:` 메시지도 없이 조용히 죽였다.

`git checkout-index -a`는 `--prefix` 대상에 이미 존재하는 파일을 만나면
`<path> already exists, no checkout`을 stderr에 찍고 **건너뛴 뒤 exit 1로 끝난다** —
말은 경고지만 종료 코드는 실패다. `tar -x`(head 모드가 쓰는 쪽)는 같은 상황에서
군말 없이 덮어쓰고 exit 0을 낸다. 두 명령이 "이미 있는 파일" 앞에서 정반대로
행동한다는 점이 어느 쪽 문서에도 나란히 적혀 있지 않다.

**해결:** `git checkout-index -a -f --prefix=...`로 강제 덮어쓰기를 준다. 대상
디렉터리가 매번 새로 만드는 임시 디렉터리라도, 같은 프로세스에서 그 헬퍼를
두 번 이상 부르는 호출(예: head 모드로 한 번 채운 뒤 같은 디렉터리에 staged 모드로
다시 채우는 테스트)이 있다면 `-f` 없이는 재현조차 안 되는 채로 죽는다.

## OPS-028 — `time.Duration(0.02 * float64(time.Hour))`는 72초가 아니라 71.999…초다

`측정 2026-09-07 · Go 1.2x`

**증상:** config가 주기를 시간 단위 실수로 준다(`"period_hours": 0.02`). 서버는
`time.Duration(h * float64(time.Hour))`로 바꾸고, 그 주기를 초로 나눠
해시 모듈로 연산의 법으로 쓴다. 테스트 스크립트가 같은 계산을
`round(0.02 * 3600)` = 72로 독립 재현하는데 서버와 답이 계속 어긋났다.

0.02는 이진수로 정확히 표현되지 않는다. `0.02 * 3.6e12`는 `71999999999.99999`가
되고 `time.Duration(...)`은 **버림**이므로 71999999999ns가 된다. 여기까지는
0.001초 차이라 아무 영향이 없다. 문제는 그다음이다 — `d / time.Second`는 정수
나눗셈이라 **71**이 나온다. 1초가 아니라 **주기 자체가 하나 줄어든** 값으로
모듈로를 돌리므로, 서버가 고른 시각과 스크립트가 고른 시각이 매번 다르다.
같은 함정이 `*_minutes` · `*_days` · `*_hours` 어느 접미사에서든 난다.

버림이 물리는 조건은 좁다. 곱의 결과가 정수 바로 **아래**로 떨어져야 하고
(0.02·0.05·0.1은 그렇고 0.25·0.5는 아니다), 그 Duration을 다시 더 큰 단위로
정수 나눗셈 해야 한다. 그래서 배포 설정값(정수 시간)에서는 절대 안 나오고
테스트 설정에서 처음 나온다.

**해결:** 실수 config를 Duration으로 바꿀 때 항상 반올림한다 —
`time.Duration(math.Round(h * float64(time.Hour)))`. 그리고 그 Duration을
`d / time.Second`처럼 정수로 되돌려 쓰는 코드가 있으면 그 자리를 근사가 아니라
**정확값**이 필요한 지점으로 보고 단위 테스트에 소수 배율(0.02 같은 값)을 한 줄
넣는다. 정수 배율만 넣은 테스트는 이 버그를 영원히 못 잡는다.

## OPS-029 — pkill로 만든 "클라이언트 하나 죽이기" 헬퍼는 같은 임시 디렉터리를 쓰는 다른 클라이언트도 같이 죽인다

`측정 2026-09-07 · bash · pkill -f`

**증상:** `timeout N godot ... &`로 띄운 클라이언트를 죽이는 헬퍼를 만들면서,
"pid의 자식까지 pkill -9 -P로 죽이고, 혹시 놓친 게 있으면 `pkill -9 -f "$WORK"`로
쓸어 담는다"를 한 함수에 합쳤다. 이 함수를 스크립트 종료 시 전체 정리(모든
클라이언트가 이미 끝났어야 하는 시점)에 쓸 때는 문제없지만, **스크립트 중간에서
클라이언트 하나만 골라 죽이고 같은 `$WORK`를 쓰는 다른 클라이언트는 계속 띄워
둬야 하는 시나리오**에 그대로 썼더니, `pkill -9 -f "$WORK"` 부분이 `--net-config
$WORK/network.json`를 커맨드라인에 공유하는 **다른 살아있는 클라이언트까지** 죽였다.
증상은 애먼 곳에 떴다 — 방금 죽인 클라이언트가 아니라, 그다음에 실행한 클라이언트가
"기대한 로그 줄이 안 뜬다"로 타임아웃되면서 실패했다(원인이 몇 단계 전 kill 호출인
줄 모르고 한참 다른 코드를 의심했다).

**해결:** "이 pid 하나만 죽이기"(pkill -P + kill -9, sweep 없음)와 "정리 끝, 아무도
안 남아야 한다"(위 동작 + `$WORK` 전체 sweep)를 처음부터 별개 함수로 나눈다. 후자가
전자를 감싸는 건 괜찮지만, 전자가 필요한 자리에 후자를 넣으면 컴파일 에러도
런타임 에러도 없이 그냥 "옆에 있던 프로세스가 사라진다" — 실패 로그에는 죽은
프로세스의 흔적조차 안 남고(bash job-control의 "Killed: 9" 메시지가 몇 줄 뒤에야
비동기로 출력되어, 그 시점의 코드와 상관없어 보인다), 재현할 때마다 "다음 단계가
실패"로만 보인다.

## OPS-030 — `set -euo pipefail` + `grep`은 "찾은 게 없음"에서 스크립트를 **메시지 없이** 죽인다. `|| true`는 파이프 안에 넣는다

`측정 2026-09-07 · bash 5 · macOS·GNU grep 공통`

**증상:** 스모크 스크립트가 단계 제목만 찍고 조용히 끝났다. `FAIL:` 줄도, 오류도, 종료 이유도
없고 종료 코드만 1이다. 문제의 줄은 "나쁜 것이 없음을 확인하는" 평범한 단언이었다:

```bash
CLIENT_WRITES="$(grep -rlE "INSERT INTO reports" client/ 2>/dev/null | wc -l | tr -d ' ')"
[ "$CLIENT_WRITES" = "0" ] || fail "..."
```

`grep`은 **일치가 0건일 때 종료 코드 1**이다. 여기서 0건은 원하는 결과다. 그런데
`set -o pipefail`이 켜져 있으면 파이프라인 상태가 마지막 명령(`tr`, 0)이 아니라
0이 아닌 것(`grep`, 1)이 되고, 대입문의 상태가 곧 명령 치환의 상태이므로 `set -e`가
그 자리에서 스크립트를 끝낸다. **`trap`이 정리를 돌기 때문에 로그는 정상 종료처럼 보인다.**
`grep -c`도 같다(0을 출력하고 1을 반환한다). 같은 실행에서 두 번 반복해 밟았다.

**해결:** `|| true`를 **파이프라인 안쪽**에 붙인다 — 바깥에 붙이면 이미 늦다.

```bash
CLIENT_WRITES="$( { grep -rlE "..." client/ 2>/dev/null || true; } | wc -l | tr -d ' ')"
COUNT="$(grep -c "패턴" file || true)"      # grep이 파이프 끝이면 이렇게로 충분하다
```

진단은 `bash -x script.sh > trace.log 2>&1` 뒤 트레이스 꼬리를 읽는 것이 유일하게 빠른 길이다
— 마지막 `+ VAR=값` 다음에 `+ cleanup`이 바로 나오면 그 대입이 범인이다. 규칙으로 하면:
`set -o pipefail` 스크립트에서 **0건을 정상으로 취급하는 `grep`은 전부** 이 처리를 해야 한다.

## OPS-031 — 부하 측정에서 "계약이 정한 거절"을 오류로 세면 정상 서버가 바로 바를 못 넘는다

`측정 2026-09-07 · Nakama 3.40 · CCU 300 3분`

**증상:** 봇 300개로 게임 루프를 돌리는 부하 도구를 만들고 "오류율 < 1%"를
바로 걸었다. CCU 30·100·300 어디서도 이동 p95는 100ms 안이고 서버 CPU도
여유가 있는데 오류율만 세 구간 모두 **3.9%**로 똑같이 나왔다. 부하와 무관하게
같은 값이 나오는 것이 단서였다.

전부 `mission_cooldown` 한 종류였다. 채집 쿨다운이 1시간인데 부하
프로파일은 1분마다 채집을 시도하므로, 59번은 서버가 규칙대로 거절한다.
거절도 요청 처리이므로 부하로는 유효하지만 **장애가 아니다.** HTTP 4xx나
gRPC non-OK를 그대로 "오류"로 집계하는 부하 도구는 전부 이 함정에 걸린다 —
쿨다운·정원·레이트 리밋·재고 부족이 있는 게임 서버에서는 정상 동작이
오류율을 지배한다.

**해결:** 식별자를 세 통으로 나눈다. **장애**(타임아웃·소켓 끊김·5xx·내부
오류), **정원/레이트 거절**(`channel_full`·`rate_limited` — 장애는 아니지만
"이 CCU가 한계에 닿았다"는 신호라 따로 본다), **계약 거절**(쿨다운·재고
부족 등, 서버가 제때 규칙대로 답한 것). 바는 장애에만 건다. 분모는 세 통을
모두 합친 전체 시도로 둔다 — 성공만으로 나누면 서버가 나빠질수록 오류율이
내려간다. **분류표에 없는 식별자는 장애로 센다**: 새로 생긴 서버 오류가
"예상됨"으로 조용히 분류되는 것이 반대 방향 실수보다 훨씬 비싸다.

같은 실측에서 덧붙은 것: p95만 보면 CCU 30과 300이 같았지만(100ms vs 104ms)
p99는 101 → 348ms, 최대 863ms였다. **꼬리가 갈라지는 것이 큐가 생기는
신호**이고 p95는 그것을 끝까지 안 보여준다. 부하표에는 p95와 p99를 같이
싣는다.

## OPS-032 — `godot --check-only --quit`에 `--script`를 안 주면 아무 스크립트도 검사하지 않는다 — 깨진 트리가 "parse ok"로 통과한다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** 편집 뒤 게이트로 쓰던 `godot --headless --path client --check-only --quit`
(`ops/check.sh gd`)가 `godot parse ok`를 냈는데, 같은 트리에서 헤드리스 플레이
실행은 첫 씬 로드에서 죽었다:
```
SCRIPT ERROR: Parse Error: Cannot find member "STRIDE_M" in base "res://features/world/player.gd".
SCRIPT ERROR: Parse Error: Assigned value for constant "CLIP_SPECS" isn't a constant expression.
ERROR: Failed to load script "res://features/world/world.gd" with error "Compilation failed".
```
다른 세션이 `player.gd`의 상수를 지웠고 `sync.gd`가 그것을 `PlayerScript.STRIDE_M`
으로 참조하는 상태였다. `--check-only`의 출력에는 프로젝트 설정 로드 한 줄
(`[config] root=...`)뿐이고 exit 0. 같은 명령에 `--script res://features/world/sync.gd`
를 붙이자 위 `SCRIPT ERROR`가 그대로 나왔다. 즉 `--check-only`는 **`--script`로
지정한 파일 하나**를 검사하는 옵션이고, 없으면 프로젝트만 열고 종료한다 —
"프로젝트 전체 파싱"이 아니다.

**해결:** 게이트는 둘 중 하나로 만든다. (1) `git ls-files 'client/**/*.gd'`를 돌며
파일마다 `--check-only --script res://<path>`를 부른다 — 파일 수만큼 프로세스가
뜨고, **오토로드(`Nakama`·`MarsNet` 같은 싱글턴)는 이 모드에서 올라오지 않아**
그것을 참조하는 파일마다 `Compile Error: Identifier not found: Nakama`가 거짓
양성으로 난다(같은 날 실측). 그 패턴을 제외하고 grep 해야 쓸 수 있다. (2) 실제
진입 씬을 `--headless --quit-after 2`로 로드해 `SCRIPT ERROR|Failed to load script`
를 grep 한다 — 한 번에 끝나고 오토로드도 정상이며, 씬이 실제로 끄는 스크립트만
검사한다(도달 불가 파일은 빠진다). 게이트로는 (2)가 낫다. 새 `class_name`은 어느 쪽이든 `.godot/global_script_class_cache.cfg`에
있어야 보인다(GDT-027) — 세션에서 처음 추가했으면 `godot --headless --import
--path client`를 한 번 돌린다.

## OPS-033 — 인덱스를 만들기 전에 그 크기에서 플래너가 쓰는지 확인한다

`측정 2026-09-07 · postgres 16.8`

**증상:** `pg_stat_user_tables`가 순차 스캔을 크게 찍는다 — 3분 부하에 스캔 4,801회, 읽은 행
297,279개. 술어 컬럼에는 인덱스가 없고(복합 PK가 다른 컬럼으로 시작한다), 게다가 그 테이블의
행 수가 동시접속자 수라 "비용이 CCU 제곱으로 자란다"는 그림이 깔끔하게 그려진다. 인덱스를
만들고 싶어진다.

만들어도 안 쓴다. 같은 스키마를 독립 postgres에 만들고 `EXPLAIN (ANALYZE)`로 재면:

```
행 300     : 인덱스 없음 0.033ms · 인덱스 있음 0.019ms · 플래너는 Seq Scan을 고른다
행 10,000  : 인덱스 없음 0.440ms · 인덱스 있음 0.032ms · Index Only Scan (13.8배)
```

한 페이지에 들어가는 테이블은 인덱스를 타는 것이 더 비싸다. 순차 스캔 **횟수**가 크다고
문제가 큰 것이 아니다 — 한 번에 읽는 행이 몇 개인지(`seq_tup_read / seq_scan`)와 그 테이블이
실제로 몇 페이지인지를 같이 봐야 한다.

측정을 공정하게 하려면 **찾는 값이 없는 경우**로 재야 한다. 값이 있으면 `EXISTS`는 첫 일치에서
멈추므로 순차 스캔이 실제보다 싸게 나온다. 위 10,000행 숫자는 좌석이 없는 사용자로 잰 것이고,
있는 사용자로 재면 0.024ms로 인덱스보다 빨라 보인다.

**해결:** 인덱스는 "인덱스가 없다"가 아니라 "이 크기에서 플래너가 인덱스를 고르고, 그래서
빨라진다"를 확인한 뒤에 만든다. 도커 컨테이너 하나에 스키마와 목표 규모의 더미 행을 넣고
`EXPLAIN (ANALYZE)`를 두 번 돌리는 데 1분이면 된다. 그 1분이 없으면 원인이 아닌 것을 고치고
고쳤다고 보고하게 된다.

## OPS-034 — `set -e` 아래 EXIT trap의 마지막 줄이 `[ cond ] && exit 1`이면 정상 종료도 exit 1이 된다

`측정 2026-09-07 · bash 3.2 / 5.x`

**증상:** `trap cleanup EXIT`로 등록한 함수 끝을 `[ "$flag" = "1" ] && exit 1`로 마무리하면,
`$flag`가 "1"이 아닌 정상 경로에서도 스크립트 exit code가 1이 된다. 함수 안에서는 `echo`도
찍히고 다른 명령도 다 성공하는데 최종 종료 코드만 틀리다 — 원인 줄을 못 찾고 한참 헤맨다.

원인: `[ "$flag" = "1" ]`가 거짓이면 그 자체로 exit status 1을 반환한다. `&&`의 왼쪽이라
`&&` 뒤의 `exit 1`은 실행되지 않지만, 이 줄이 함수의 **마지막 명령**이면 함수의 반환값은 그
테스트의 exit status(1)가 된다. 이 함수가 `trap ... EXIT` 핸들러일 때, bash는 트랩 실행 후
스크립트의 원래 종료 코드를 복원하지 않고 트랩 핸들러의 마지막 명령 종료 코드를 그대로
스크립트 exit code로 쓴다. `if`/`&&` 체인 안에서 실패가 "무시"되는 것은 그 명령이 조건문·
파이프라인 중간 등 `set -e`가 면제하는 위치에 있을 때뿐이고, "함수의 마지막 명령"은 면제
대상이 아니다.

재현:
```bash
set -euo pipefail
cleanup() { local x=0; echo ok; [ "$x" = "1" ] && exit 1; }
trap cleanup EXIT
echo main
# 출력: main / ok, 그런데 $? = 1
```

**해결:** 트랩 핸들러의 마지막 줄에 조건부 종료를 쓸 때는 `&&`가 아니라 `if`로 감싼다:
```bash
if [ "$flag" = "1" ]; then exit 1; fi
```
이렇게 하면 `if` 블록 자체가 정상 종료(exit 0)로 끝나 트랩의 최종 exit status에 영향을 주지
않는다. `[ cond ] && exit N` 관용구는 함수·트랩의 **마지막 줄이 아닐 때만** 안전하다.

## OPS-035 — `pg_stat_statements`는 락 문장을 호출자별로 못 나누고 보유 시간도 못 준다 — 문장 로그로 PID별 트랜잭션을 복원해야 진짜 병목이 보인다

`측정 2026-09-07 · PostgreSQL 16.8 · Nakama 3.40(pgx) · CCU 100 부하`

**증상:** 부하 조사에서 `SELECT 1 FROM channel_locks WHERE channel_id=$1 FOR UPDATE`가
평균 8.8ms·최대 79ms로 대기 1위로 잡혀, 그 락을 쓰는 "입장(channel.join) 임계 구간"을
줄이는 티켓이 나왔다. 실측해 보니 그 문장을 부르는 트랜잭션은 **두 종류**였다 —
입장(join)과 캐릭터 생성(create, 같은 테이블의 다른 행 `@assign`을 잠근다) — 그리고
`pg_stat_statements`는 문장 텍스트가 같으면 한 행으로 합친다. 실제로는:

| 트랜잭션 | 락 안 문장 수 | 보유 평균/p95 | 대기 평균/p95/max |
|---|---:|---:|---:|
| character.create | 13 | 4.2 / 9.0 ms | **39 / 92 / 110 ms** |
| channel.join | 4 | 1.9 / 3.0 ms | 0.03 / 0.06 / 0.11 ms |

8.8ms의 정체는 create였고 join은 사실상 경합이 없었다(봇이 50ms 간격으로 입장). 또
`pg_stat_statements`의 `mean_exec_time`은 **문장 실행 시간**이라, 락 안 4문장의 exec 합이
0.1ms인데 실제 보유는 1.9ms였다 — 나머지는 왕복(문장당 ~0.3ms)과 커밋이다. 문장을
줄여도 exec 합은 거의 안 변하고 왕복 수만 줄어든다. 두 사실 모두 `pg_stat_statements`
만 보면 절대 안 보인다.

**해결:** 트랜잭션 단위로 복원한다. postgres가 healthy가 된 직후(nakama가 마이그레이션을
도는 동안, 재시작 없이) 켠다:
```
ALTER SYSTEM SET log_min_duration_statement = 0;   -- 모든 문장을 끝난 시점에 duration과 함께
ALTER SYSTEM SET log_lock_waits = on;  ALTER SYSTEM SET deadlock_timeout = '1ms';
SELECT pg_reload_conf();
```
그 뒤 `docker logs <postgres>`를 PID별로 훑는다: `FOR UPDATE` 줄의 타임스탬프 = 락 획득,
그 줄의 duration = **대기**, 이후 `commit` 줄까지 = **보유**, 사이의 줄 수 = 락 안 왕복 수.
트랜잭션 안에 어떤 문장이 있는지로 호출자를 가른다(`FROM channels c`면 create, `INSERT
INTO channel_seats`면 join). 파싱 함정 둘: pgx는 `execute stmtcache_<hash>: ` 뒤 **다음 줄**
(탭 들여쓰기)에 SQL을 쓰므로 연속 줄을 앞 LOG 줄에 붙여야 하고, `bind` 줄도 duration을
달고 오지만 실행이 아니니 버린다. `%m`은 ms 해상도라 1ms 근처 보유 시간은 양자화된다 —
평균은 쓸 수 있고 개별 값은 못 믿는다. `pg_locks`를 0.2초마다 찍는 방식은 이 부하에서
800 샘플 중 대기자 0을 냈다 — 대기가 수십 ms 이하면 폴링으로는 못 잡는다;
`log_lock_waits`가 이벤트마다 남긴다.

## OPS-036 — `curl -w %{time_total}`은 RTT가 아니다 — HTTPS면 4.4배 부풀고, 순수 왕복은 `%{time_connect}`다

`측정 2026-09-07 · curl 8.7.1(macOS) · 미국(덴버) ↔ 한국(서울) 태평양 횡단 링크`

**증상:** 부하 봇을 다른 대륙의 호스트로 옮길 수 있는지 판정하려고 두 기계 사이 지연을
`curl -s -o /dev/null -w "%{time_total}\n" https://<host>/` 20회로 쟀다. p50 **735ms**가 나왔다.
"왕복 735ms면 어떤 실시간 측정도 불가"로 결론이 날 뻔했는데, 같은 링크의 ICMP는
`min/avg/max = 157.3/161.7/174.4ms`였다. 4.5배 차이다.

`%{time_total}`은 DNS + TCP 3-way + TLS 핸드셰이크 + HTTP 요청·응답 전부의 합이다.
TLS 1.3만 해도 왕복이 추가로 2번 이상 들어가고, 서버가 리버스 프록시(traefik 등)면
백엔드 왕복까지 얹힌다. 같은 20회를 항목별로 쪼개면:

| 지표 | 뜻 | p50 | p95 |
|---|---|---:|---:|
| `%{time_connect}` | TCP 3-way 완료 = **순수 RTT 1회** | **166ms** | 188ms |
| `%{time_appconnect}` | + TLS 핸드셰이크 완료 | 500ms대 | — |
| `%{time_total}` | + HTTP 응답 완료 | 735ms | 811ms |
| ICMP `ping` avg | 참조값 | 161.7ms | — |

`%{time_connect}`가 ICMP와 4.3ms 안에서 일치한다. 이것이 찾던 숫자다.

**해결:** 네트워크 왕복을 재려면 `%{time_connect}`를 쓴다.
`curl -w "%{time_connect} %{time_appconnect} %{time_total}\n"`로 세 개를 같이 받아
어디서 시간이 붙는지 눈으로 확인하고, `%{time_total}` 하나만 적힌 측정은 신뢰하지 않는다.
ICMP가 열려 있으면 `ping`으로 교차 검증한다 — 두 값이 크게 다르면 프로토콜 오버헤드지 링크 문제가 아니다.
반대 방향도 마찬가지다: `%{time_total}`로 "링크가 느리다"고 결론 내면 실제로는 TLS·프록시가 느린 것이다.

## OPS-037 — 부하 생성기를 옮길 기계는 코어 수가 아니라 단일코어 성능으로 고른다 — asyncio 드라이버는 1코어 100%가 물리적 상한이다

`측정 2026-09-07 · Python 3.12.3(Intel i7-2635QM, 4C8T) vs Python 3.9.6(Apple M1 Max) · asyncio 단일 프로세스 드라이버`

**증상:** "서버와 부하 봇이 같은 기계에 있어 측정이 오염된다"를 고치려고 봇을 옮길 후보 호스트를 골랐다.
후보는 8스레드·RAM 8GB로 스펙 표만 보면 충분해 보였다. 실제로는 CCU 100도 못 돌린다.

`asyncio.run()` 기반 드라이버는 **단일 스레드 이벤트 루프**라, 코어가 몇 개든 한 프로세스는
1코어의 100%를 넘을 수 없다. 그래서 후보 판정은 코어 수·RAM이 아니라 **단일코어 성능 배수** 하나로 결정된다.
공개 벤치 점수 대신 드라이버가 실제로 하는 일 세 가지를 같은 스크립트로 양쪽에서 돌려 배수를 냈다:

| 작업 (봇이 반복하는 것) | 신형(M1 Max) | 구형(i7-2635QM, best of 3) | 배수 |
|---|---:|---:|---:|
| 파이썬 루프 3M회 (이벤트 루프 부기) | 0.230s | 1.459s | **6.3배** |
| json 왕복 200K회 (모든 RPC) | 0.867s | 6.605s | **7.6배** |
| struct 왕복 500K회 (바이너리 프레임) | 0.102s | 0.519s | **5.1배** |

구형 쪽이 Python 3.12(더 빠른 인터프리터)인데도 이 결과다. 하드웨어 격차는 이 숫자보다 크다.
드라이버가 보고하는 자기 CPU(`ru_utime + ru_stime` ÷ 경과, 1코어=100%)에 배수를 곱하면 판정이 끝난다:

| 부하 | 신형에서 드라이버 CPU | 구형 환산 | 1프로세스 상한 100% |
|---|---:|---:|---|
| CCU 30 | 8% | 50% | 통과 |
| CCU 100 | 18% | **113%** | **초과** |
| CCU 300 | 41% | **258%** | **초과 — 3프로세스 필요** |

**해결:** 부하 생성기 이전 후보는 이 순서로 거른다.
(1) 드라이버가 자기 CPU를 1코어 기준 %로 보고하는지 확인한다 — 없으면 그것부터 넣는다(90% 넘으면 그 측정은 서버가 아니라 드라이버를 잰 것이다).
(2) 목표 부하에서의 드라이버 CPU에 **90 ÷ 그 값 = 허용 배수**를 구한다(41% → 2.2배).
(3) 후보의 배수를 합성 벤치가 아니라 **드라이버의 실제 작업**(루프·json·직렬화)으로 잰다. 코어 수·RAM은 그 다음이다.
멀티프로세스로 쪼개는 것은 코드 변경이고, 프로세스마다 다른 코어의 스로틀·스케줄 지연이 백분위에 섞여 측정이 더 나빠진다.

## OPS-040 — 부하 봇이 자기 타이머를 놓치면 그 지각이 서버 지연으로 기록된다

`측정 2026-09-07 · 봇은 단일 파이썬 asyncio 프로세스, 서버와 같은 맥`

**증상:** 동시접속을 올리다 보면 어느 지점에서 왕복 p95가 두 배로 뛴다(97ms → 190ms). 서버
CPU에는 여유가 있고, 락 대기도 쿼리 시간도 그대로다. 코드를 이등분해도 범인 커밋이 안 나온다.

봇이 초당 몇 번 보냈는지를 같이 세면 보인다.

```
CCU  전송/초/봇(목표 10)  목표대비  봇CPU  왕복 p95
 30        9.95            99.5%    4.5%    97.6ms
100        9.95            99.5%   14.4%    96.0ms
200        9.82            98.2%   27.9%    98.4ms
300        8.40            84.0%   49.6%   190.5ms
```

**왕복이 뛰는 지점과 봇이 전송을 놓치는 지점이 정확히 같다.** 왕복을 봇 시계로 재기 때문이다 —
보내는 쪽이 늦으면 그 지각분이 전부 서버 지연으로 적힌다. 봇 CPU가 코어의 50%도 안 되는데
타이머가 깨지는 것은 단일 asyncio 루프가 코어를 다 쓰기 전에 먼저 밀리기 때문이다(매치당
인원이 늘수록 수신 프레임 처리량이 봇 하나당 커진다).

**해결:** 부하 측정 보고서에 **봇의 실제 전송률을 목표와 나란히** 싣는다. 이 열이 없으면 측정
장치의 포화를 서버 회귀로 읽게 되고, 없는 범인을 커밋에서 찾게 된다. 목표의 98% 아래로
떨어지는 CCU가 그 장비로 신뢰할 수 있는 상한이고, 그 위의 지연 수치는 서버 판정에 쓰지 않는다.
봇과 서버를 같은 기계에 두는 한 이 상한은 서버 성능과 무관하게 존재한다.

## OPS-041 — Apple Silicon에는 열 지표가 없다: 고정 연산 시간으로 대신 잰다

`측정 2026-09-07 · macOS Darwin 25.6.0 · arm64`

**증상:** 성능 측정에서 열 스로틀을 배제하려고 흔히 쓰는 두 명령이 Apple Silicon에서 아무것도
주지 않는다.

```
$ pmset -g therm
Note: No thermal warning level has been recorded
Note: No performance warning level has been recorded
$ sysctl machdep.xcpm.cpu_thermal_level
sysctl: unknown oid 'machdep.xcpm.cpu_thermal_level'      # Intel 전용
```

`powermetrics`는 값을 주지만 sudo가 필요해서, 남의 기계에서 도는 자동화라면 쓸 수 없다.

**해결:** 열 등급 대신 **유효 CPU 속도**를 잰다 — 고정된 연산(정수 루프 300만 회 정도)의 실행
시간을 측정 직전마다 찍는다. 스로틀이 실제로 바꾸는 것은 라벨이 아니라 속도이므로 이쪽이
측정 대상에 더 가깝다. **단일 스레드로 돌린다**: 멀티코어 프로브는 "다른 프로세스가 코어를
몇 개 쥐고 있나"를 같이 재는데 그것은 다른 질문이다. 부하 평균 1·5·15분도 같이 남긴다.

한 기계에서 같은 조건으로 5회 찍어 편차를 먼저 확인한다(여기서는 ±5%). 그보다 큰 변동이
측정 사이에 생기면 그것이 신호다. 실제로 이 프로브가 기준선의 1.57배(350→549ms)까지 흔들리는
동안 대상 지표는 2ms 안에 머물러, "열 때문"이라는 가설을 반증하는 증거가 됐다.

## OPS-038 — Docker Desktop(macOS)은 루프백보다 LAN 바인딩을 늦게 연다 — `/healthcheck` 200을 믿고 다른 기계에서 접속하면 5초를 진다

`측정 2026-09-08 · Docker Desktop(macOS 26.3, Apple Silicon) · Nakama 3.40`

**증상:** `compose up -d` 뒤 `curl http://127.0.0.1:17350/healthcheck`가 2초 만에 200을 준다.
같은 순간 **다른 기계**에서 `http://<맥 LAN IP>:17350/healthcheck`를 치면 `curl` exit 7(연결 거부),
`%{http_code}`는 `000`이다. 200으로 바뀌기까지 5초가 더 걸렸다(1초 간격 프로브 5회 연속 000).
포트 발행은 `- "17350:7350"`으로 바인드 주소가 없어 0.0.0.0이고, 방화벽·경로 문제가 아니다 —
포워더가 루프백 리스너를 먼저 열고 LAN 리스너를 나중에 여는 것뿐이다.

증상이 접속 실패로 나타나지 않는 것이 함정이다. 원격 클라이언트는 TCP 실패를 3회 재시도한 뒤
`HTTPRequest failed` 하나만 남기고 로그인 없이 계속 진행하므로, 터지는 것은 한참 뒤의
**엉뚱한 기능 단언**이다(실측: "no swing clip played" — 스윙 애니메이션과 아무 상관이 없었다).

**해결:** 준비 판정을 **접속할 기계에서** 한다. 컨테이너를 띄운 기계의 루프백 healthcheck는
"컨테이너가 살아 있다"까지만 증명한다.

```sh
for i in $(seq 1 60); do
  code=$(ssh "$CLIENT_HOST_SSH" "curl -s -o /dev/null -w %{http_code} --max-time 3 http://$LAN_IP:$PORT/healthcheck")
  [ "$code" = 200 ] && break; sleep 1
done
```

## OPS-039 — macOS에서 창 모드 GPU 앱을 ssh로 띄울 수 있다 — ssh 사용자가 콘솔 사용자와 같으면 `launchctl asuser`가 필요 없다

`측정 2026-09-08 · macOS 26.3 · Apple Silicon · Godot 4.7.2`

**증상:** "GUI 앱은 ssh 세션에서 WindowServer에 붙지 못하므로 `launchctl asuser $(id -u) ...`로
콘솔 세션에 부트스트랩해야 한다"가 통설이다. 실측은 다르다. `stat -f "%Su" /dev/console`이
ssh 로그인 사용자와 같으면(둘 다 uid 501) 순수 `ssh host 'app ...'`으로 창이 뜨고 **렌더링까지 된다** —
`--headless` 없이 실행해 `draw_calls=192 triangles=79868`, 뷰포트 캡처 `save_png` `err=0`,
720x1280 PNG 621KB. 화면이 잠겨 있어도 된다. `launchctl asuser`는 콘솔 사용자가 **다를** 때 필요한 것이다.

같이 걸리는 것 둘: macOS에는 `timeout`이 없고(coreutils 미설치 기본), 원격 로그인 셸이 zsh라
`${PIPESTATUS[0]}`가 빈 문자열로 나온다. 원격 명령을 `ssh host 'bash -s' <<'EOF'`로 표준입력에
넣으면 인용 지옥과 이 둘을 한 번에 피한다.

**해결:** 먼저 `stat -f "%Su" /dev/console`과 `id -un`을 비교한다. 같으면 그냥 실행한다.
타임아웃은 원격이 아니라 **로컬에서** ssh를 감싸고, 원격에는 `trap 'kill 0' EXIT HUP TERM INT`를
둔다 — ssh는 시그널을 전달하지 않으므로 로컬 `timeout`이 죽여도 원격 프로세스는 살아남는다.

## OPS-042 — 단일 프로세스 asyncio 부하 봇은 CPU 42%에서 이미 포화다. 인터프리터를 올려도 안 풀린다
`측정 2026-09-08 · CPython 3.9.6/3.12.14 · websockets 15.0.1/17.1 · macOS 15 arm64`

**증상:** WebSocket 부하 드라이버가 10Hz 송신 계약을 지키지 못하고 초당 8.4회만 보낸다.
같은 판에서 프로세스 CPU는 코어의 49.6%다. 코어가 절반 넘게 놀고 있으므로 "CPU가 모자란 게
아니다"로 읽기 쉽고, 실제로는 이미 포화다. 파이썬을 올리면 풀린다고 보기도 쉽다 —
마이크로벤치(정수 루프·json 왕복)에서 3.12는 3.9.6보다 1.4~1.6배 빠르다.

인터프리터만 3.12로 바꾼 실측(코드·프로파일 바이트 불변, 같은 서버·같은 격자):

| | 3.9.6 + ws 15.0.1 | 3.12.14 + ws 17.1 |
| --- | --- | --- |
| 송신률 (목표 10/초) | 8.40 | **8.53** |
| 프로세스 CPU (코어 1개 대비) | 49.6% | **41.9%** |
| 왕복 p50 / p99 | — | 55.2ms / 558.8ms |

**CPU는 예고대로 15.5% 내려갔는데 송신률은 1.5%만 올랐다.** 미달분 16.0%p 중 1.3%p다.
CPU 시간이 구속 조건이었다면 이 비율이 나올 수 없다.

진짜 한계는 **수신 프레임 디코드가 이벤트 루프를 점유해 다음 송신 타이머를 지나치는 것**이다.
이 판에서 한 프로세스가 초당 67,591건의 위치 갱신을 디코드했고, 그 부하는 접속 수의 **제곱**에
비례했다(브로드캐스트 그룹 인원 × 접속 수). 접속 200 → 300은 디코드량 2.25배인데 송신 계약은
10Hz 고정이다.

**판별법 — CPU%가 아니라 지연 분포를 본다.** p50이 저부하 때와 같은 바닥에 붙어 있는데
p99만 p50의 10배로 튀면 그것은 CPU 고갈이 아니라 루프의 순간 정체다. CPU가 마른 프로세스는
p50부터 통째로 밀린다. 여기서는 p50 55.2ms(저부하 60.4ms와 동률) · p99 558.8ms였다.

**해결:** 인터프리터 업그레이드는 하되(공짜로 CPU 8%p) 그것으로 한계가 풀린다고 기대하지 않는다.
단일 asyncio 루프의 수신 처리량이 벽이므로 **클라이언트를 프로세스로 쪼개는 것이 답이다** —
N개 프로세스로 나누면 각 프로세스는 1/N 접속의 조건에 놓인다(이 실측에서 접속 100 조건은
9.95회/초 · CPU 14.4%로 계약을 지켰다). 기계를 더 사기 전에 이것부터 시험한다.

## OPS-043 — `exec > >(tee ...)` makes a bare `wait` hang forever on bash 5.2
`측정 2026-09-08 · bash 5.2.37 (alpine) vs bash 5.3 (macOS) · GitLab CI docker:27-cli + apk add bash`

**증상:** A script that logs itself with `exec > >(tee -a "$LOG") 2>&1` and later
runs concurrent work with `... &` followed by a bare `wait` never returns. On
GitLab CI three pipelines in a row died at the 10-minute job timeout, always at
the same line: a smoke that took 1s green took 583s, 584s and 572s. Nothing is
printed — the script is simply parked in `wait`.

Bash records the process-substitution child in its job table, so a bare `wait`
(which waits for *all* known jobs, not just the ones you backgrounded) waits for
the `tee` too — and the `tee` cannot exit while the script still holds the write
end. It is version-dependent: bash 5.3 on macOS does not reproduce it, alpine's
bash 5.2.37 does, so a developer machine will show the script working.

Minimal reproduction, 8-second timeout, alpine bash: `rc=143` (killed) for the
process-substitution form, `rc=0` for the FIFO form below.

**해결:** Replace the process substitution with an explicit FIFO and `disown`
the `tee`, which removes it from the job table so no spelling of `wait` can see
it:

```sh
f="${TMPDIR:-/tmp}/log-$$-$RANDOM.fifo"; rm -f "$f"; mkfifo "$f"
tee -a "$LOG" <"$f" & TEE=$!; disown "$TEE"
exec >"$f" 2>&1
rm -f "$f"        # both ends are open; the name is no longer needed
```

Because the `tee` is disowned, `wait "$TEE"` can no longer flush it at the end.
Restore the saved fds (`exec 1>&3 2>&4`) — that gives the `tee` EOF — and poll
`kill -0 "$TEE"` with an upper bound instead.

## OPS-044 — `ssh` reports a signal-killed remote command as exit 255, with no message
`측정 2026-09-08 · OpenSSH 10.3p1 · macOS 26.6.2`

**증상:** A remote command run over `ssh` returns 255 and prints nothing at all —
no `client_loop`, no `Connection closed`. 255 is normally read as "ssh itself
failed", so the search goes to the network, and the actual cause is that the
remote process was killed by a signal: the SSH protocol has no way to carry a
signal exit, so the client substitutes 255. `ssh -E <file> -o LogLevel=DEBUG1`
shows a clean channel teardown, which confirms the link was never the problem.

The two things that separate this from a real connection failure, both checkable
on the remote host: no crash report appears in `~/Library/Logs/DiagnosticReports`
(so it was not a crash), and the remote process's own log file stops mid-stream
rather than at a shutdown line (so it was not a clean exit).

**해결:** Look for whatever kills processes by name on the remote host. In our
case a shared teardown ran `pkill -9 -f 'Godot.app/Contents/MacOS/Godot'`, which
swept every run's clients, not just its own; scoping the pattern to the run's own
working directory — which appears in every argument that run's processes were
given — fixed it. Any `pkill -f` on a shared machine has this shape.

## OPS-045 — uv가 관리하는 파이썬에는 pip install이 거부된다
`측정 2026-09-08 · uv 0.12.10 · CPython 3.12.14 · macOS 15`

**증상:** `uv python install 3.12`로 인터프리터를 깔고 거기에 패키지를 넣으려 하면
거부된다. 가상환경 얘기가 아니라 그 인터프리터 자체다.

```
uv pip install --python "$(uv python find 3.12)" websockets
error: The interpreter at /Users/x/.local/share/uv/python/cpython-3.12.14-macos-aarch64-none
is externally managed, and indicates the following:
  This Python installation is managed by uv and should not be modified.
hint: Consider creating a virtual environment, e.g., with `uv venv`
```

uv가 관리 인터프리터에 `EXTERNALLY-MANAGED` 마커(PEP 668)를 심어 둔다. 힌트는
venv를 권하지만, `python3`를 그냥 부르는 기존 스크립트에 PATH로만 끼어들려는
경우에는 venv가 오히려 층을 하나 더 만든다.

**해결:** `--break-system-packages`를 붙이면 관리 인터프리터에 그대로 들어간다.

```
uv pip install --break-system-packages --python "$(uv python find 3.12)" websockets
```

uv 관리 인터프리터의 `bin/`에는 `python3`·`python` 심볼릭 링크가 `python3.12`와
함께 들어 있다. 그래서 그 디렉터리를 PATH 앞에 붙이는 것만으로 스크립트의 맨
`python3` 호출이 전부 그쪽으로 간다 — 스크립트는 한 줄도 안 고친다.

주의: uv가 인터프리터를 재설치·업그레이드하면 이렇게 넣은 패키지는 사라진다.
재현이 필요한 환경이면 설치 명령을 리포의 설치 문서에 남겨 둔다.

## OPS-046 — 파이썬 의존성을 `grep '^import'`로 세면 조건부 import를 통째로 놓친다
`측정 2026-09-08 · CPython 3.9.6 / 3.12.14`

**증상:** 인터프리터를 바꾸기 전에 "3rd-party 의존이 있나"를 확인하려고
`grep -hn '^import \|^from ' **/*.py`를 돌렸다. 결과가 전부 표준 라이브러리라
의존이 없다고 판단했는데, 실제로는 `websockets` 패키지가 필수였다. 그 패키지가
없는 인터프리터로 바꿨으면 소켓을 쓰는 스크립트 8개가 전부 죽었다.

`try`/`except ImportError` 안의 import는 들여쓰기가 있어 `^import`에 안 걸린다.
이 형태는 "친절한 에러 메시지를 주려는" 코드에서 특히 흔하다 — 즉 **가장 중요한
의존일수록 이 패턴으로 숨는다.**

```python
try:
    import websockets
except ImportError:
    sys.stderr.write("needs the websockets package: pip3 install websockets\n")
    sys.exit(2)
```

**해결:** 정규식 대신 AST로 센다. `ast.walk`는 위치와 무관하게 전부 잡는다.

```python
import ast, pathlib
mods = set()
for f in pathlib.Path('.').rglob('*.py'):
    for n in ast.walk(ast.parse(f.read_text())):
        if isinstance(n, ast.Import):
            mods |= {a.name.split('.')[0] for a in n.names}
        elif isinstance(n, ast.ImportFrom) and n.level == 0 and n.module:
            mods.add(n.module.split('.')[0])
```

venv·`site-packages`를 `rglob`가 같이 훑으면 표준 라이브러리와 남의 의존까지
섞여 목록이 수백 개가 되고 쓸모가 없어진다. 스캔 경로에서 먼저 제외한다.

더 확실한 답은 바꿀 인터프리터로 실제 진입점을 돌려 보는 것이다. 정적 분석은
`importlib.util.spec_from_file_location`으로 동적 로드하는 코드를 못 따라간다.

## OPS-047 — asyncio 부하 봇의 벽은 CPU가 아니라 수신 디코드다. 프로세스로 쪼개면 풀린다

`측정 2026-09-08 · python 3.12.14 + websockets 17.1, macOS 15 (M-series)`

**증상:** 봇 300개를 단일 asyncio 루프로 돌리면 10Hz 송신 계약을 못 지킨다 —
초당 8.53회, 이동 왕복 p50 55.2ms인데 p99 558.8ms(**p50의 10.1배**). 그런데
프로세스 CPU는 코어 하나의 **41.9%**뿐이다. 인터프리터를 3.9.6 → 3.12로 올려도
CPU만 49.6 → 41.9%로 내려가고 전송률은 8.40 → 8.53에 그친다(OPS-042).

CPU 여유를 보고 "아직 여유 있다"고 읽으면 안 된다. 구속 조건은 CPU 시간이 아니라
**한 루프가 초당 디코드할 수 있는 프레임 수**다. 수신량은 봇 수의 제곱에 비례해
늘고(N명이 각자 M명의 갱신을 받으면 N×M) 송신 계약은 10Hz로 고정이라, 루프가
프레임 뭉치를 푸는 동안 다음 타이머를 지나쳐 버린다.

**판별 지표는 CPU%가 아니라 p50 대 p99의 벌어짐이다.** CPU가 마른 프로세스는
p50부터 통째로 밀린다. 바닥(p50)은 그대로인데 꼬리만 튀면 디코드 정체다.

**해결:** 같은 봇 수를 프로세스 N개로 나눈다. 서버가 받는 부하는 동일하다.

| | 단일 프로세스 300 | 3프로세스 × 100 |
| --- | --- | --- |
| 전송률 | 8.53회/초 | **9.98회/초** |
| 프로세스 CPU | 41.9% | 14.9 / 14.8 / 14.9% |
| 왕복 p95 | 178.7ms | **96.3ms** |
| 왕복 p99 | 558.8ms | **101.3ms** |
| p99 ÷ p50 | 10.1배 | **1.90배** |
| 서버 CPU | 평균 27.6% | 평균 30.4% |

서버는 17% 더 많은 트래픽을 받고 CPU가 2.8%p 올랐을 뿐인데 클라가 본 꼬리는
5.5배 짧아졌다. **꼬리는 서버가 아니라 측정 도구가 만들고 있었다.**

**인터프리터는 쪼갠 뒤에도 지렛대가 아니다(추가 실측 2026-09-08, python 3.9.6).**
같은 3프로세스 × 100 격자를 시스템 파이썬 3.9.6으로 다시 돌리면 전송률 9.98회/초,
왕복 p95 97.5ms, 장애율 0%로 3.12.14와 같은 자리에 선다. 위 표의 8.40 → 8.53(단일,
3.9 → 3.12)과 나란히 놓으면 결론이 한 방향이다 — **버전은 어느 쪽으로도 움직이지
않고, 움직이는 것은 프로세스 수뿐이다.** 3.12를 못 쓰는 환경이라고 측정을 미룰 이유가
없고, 반대로 3.12로 올려 단일 프로세스를 구제하려는 시도도 하지 않는다.

## OPS-048 — 부하 드라이버를 프로세스로 쪼갤 때 배리어가 없으면 측정 구간이 혼합 CCU가 된다

`측정 2026-09-08 · python 3.12.14`

**증상:** 프로세스 N개가 각자 자기 몫을 접속시키고 곧바로 측정을 시작하면, 먼저
끝난 프로세스는 나머지가 아직 입장 중인 구간을 함께 잰다. 보고서에는 CCU 300이라
적히지만 앞 구간은 CCU 200이다. **오류가 나지 않고 숫자만 조용히 낙관적이 된다.**

**해결:** 마지막 입장 직후·측정 시작 직전에 파일 배리어를 둔다. 디렉터리 하나를
공유하고 각자 `ready-<오프셋>` 파일에 자기 착석 시각을 쓴 뒤 파일 수가 N이 될
때까지 폴링한다. 타임아웃이 지나면 경고를 찍고 그냥 측정한다 — 부하 창 한가운데서
멈추는 것보다 낫다. 보고서에 **배리어 대기 시간과 착석 시각 폭**을 열로 남기면
읽는 사람이 그 구간이 진짜 CCU N이었는지 검증할 수 있다(실측 0.1초).

아울러, 자식을 `sys.executable`로 다시 띄우는 방식은 `uv run --with <pkg>`
아래에서도 동작한다. `sys.executable`이 임시 venv가 아니라 기반 인터프리터를
가리키는데도 자식이 패키지를 찾는다 — 환경 변수로 경로가 상속되기 때문이다.

## OPS-049 — Tailscale exit node가 켜져 있으면 같은 LAN의 기기에 닿지 못한다 (한 방향만 죽어 원인을 오판하기 쉽다)
`측정 2026-09-08 · Tailscale 1.102.3, macOS 26.6.2`

**증상:** 같은 Wi-Fi의 맥 A(192.168.0.109)에서 맥 B(192.168.0.123)로 `ping`도 `ssh`도 전부 timeout.
그런데 **B → A 방향은 살아 있다**(`ssh`가 `Connection refused`를 돌려준다 = 패킷이 도달했다는 뜻).
A의 ARP 캐시에는 B의 MAC이 정상으로 들어 있고, 그 값은 B의 실제 Wi-Fi 주소와 일치한다.
A에서 게이트웨이(192.168.0.1) ping은 성공한다. B의 방화벽·pf·sshd·라우팅은 전부 정상이다.

**함정:** 위 증거들이 전부 "B가 인바운드를 막는다"를 가리키는 것처럼 보인다. 실제로는 반대로
**A에서 나가는 패킷이 LAN에 도달조차 하지 않는다.** B에서 `netstat -s -p icmp`를 보면 Input
histogram의 `echo request`가 부팅 이후 **0건**이다(`echo reply`만 쌓인다). 이 카운터가 방향을
가르는 결정적 증거다.

**원인:** A가 Tailscale **exit node**를 쓰는 상태에서 `ExitNodeAllowLANAccess`가 꺼져 있었다.
그러면 `192.168.0.0/24` 전체가 터널 인터페이스로 라우팅된다:
```
$ route -n get 192.168.0.123
  interface: utun7          # en0가 아니다
$ tailscale debug prefs | grep -E 'ExitNode|RouteAll'
  "RouteAll": true,
  "ExitNodeID": "...",
  "ExitNodeAllowLANAccess": false
```
게이트웨이와 **이미 통신하던 호스트**는 `/32` 경로가 en0에 남아 있어 계속 통한다. 그래서 "게이트웨이는
되니까 네트워크는 정상"이라는 오판이 나온다. 새로 접속하려는 호스트만 터널로 새서 조용히 사라진다.
ARP 캐시도 증거가 못 된다 — **상대가 보낸 패킷만으로도 채워지기 때문이다.**

**해결:** exit node는 그대로 두고 LAN 접근만 연다.
```
tailscale set --exit-node-allow-lan-access=true
```
GUI는 메뉴바 아이콘 → Exit Node → "Allow Local Network Access".

**전원·랜·공유기를 먼저 만지지 마라.** 유선 연결도 고정 IP도 이 증상을 고치지 못한다.

**진단 순서(이 순서로 하면 5분이면 갈린다):** ① `route -n get <상대 IP>`로 나가는 인터페이스가
`en0`인지 `utun*`인지 본다 — 이것 하나로 끝난다 ② 상대 기기에서 `netstat -s -p icmp`의 echo request
카운터를 본다 ③ 제3의 기기에서 상대로 ping해 본다. **양쪽 방화벽부터 뒤지면 시간을 버린다**(이 건에서
방화벽·MAC·라우터 격리를 차례로 의심하다 약 2시간을 썼고 셋 다 무관했다).

## OPS-050 — `smoke_stack_up`은 스택을 띄우지 않는다 (COMPOSE 배열만 만든다)

`측정 2026-09-08 · mars ops/smoke/lib/smoke.sh`

**증상:** 새 스모크 스크립트가 `smoke_stack_up` → `wait_healthy` 순으로만
쓰면 90초를 기다린 뒤 `FAIL: healthcheck never returned 200 (last: 000)`으로
끝난다. 컨테이너가 하나도 안 떠 있는데 로그에는 실패 줄 하나뿐이라 원인이
플러그인 빌드 오류나 마이그레이션 실패처럼 보인다 — 진단이 통째로 헛다리다.

이름과 달리 `smoke_stack_up`이 하는 일은 슬롯 락 획득과 `COMPOSE=(docker
compose -p ... -f ...)` 배열 조립까지다. `up -d --build`는 **호출자가 직접**
한다. 기존 스크립트가 전부 그 블록을 각자 갖고 있어서, 하나를 베끼지 않고
헬퍼 이름만 보고 쓰면 정확히 이 자리에서 빠진다.

```bash
if [ "${SMOKE_SKIP_UP:-0}" != "1" ]; then
  step "${COMPOSE[*]} up -d --build"
  "${COMPOSE[@]}" up -d --build >"$WORK/compose.log" 2>&1 \
    || { tail -40 "$WORK/compose.log" >&2; fail "compose up failed"; }
fi
wait_healthy
```

**해결:** 새 스모크는 헬퍼 목록이 아니라 **기존 스크립트 한 개를 베껴서**
시작한다. `healthcheck ... (last: 000)`에서 000은 연결 자체가 안 됐다는
뜻이므로(HTTP 코드가 아니다) 서버 로그를 파기 전에 `docker ps`로 컨테이너
존재부터 확인한다.

## OPS-051 — 세션 기록은 transcript 말고 `~/.claude/jobs/`에도 남는다
`측정 2026-09-08 · Claude Code 2.1.263`

**증상:** `~/.claude/projects/<슬러그>/*.jsonl`을 지웠는데도 UI의 세션 목록(시계 아이콘)에 옛 세션이 그대로 보인다.
프로세스도 죽였고 `/tmp/cc-socks/*.sock`도 지운 뒤였다.

**해결:** 배경 세션은 `~/.claude/jobs/<세션 id 앞 8자>/`에 `state.json`·`timeline.jsonl`·`tmp/`를 따로 남긴다.
목록은 이쪽도 읽는다. 완전히 지우려면 셋 다 지운다 — 프로세스(`bg-spare`와 그 부모 `bg-pty-host`),
`projects/<슬러그>/<uuid>.jsonl`, `jobs/<앞 8자>/`. `jobs/` 안의 `ops`·`pins.json`은 설정이므로 남긴다.

## OPS-052 — 맥이 LAN에서 사라졌을 때 ARP가 라우팅과 절전을 가른다
`측정 2026-09-08 · macOS 26.6.2`

**증상:** ssh·ping이 100% 손실. 이전 사고(OPS-049)가 Tailscale exit node였던 탓에 라우팅을 먼저 의심하게 된다.

**해결:** `arp -a | grep <IP>`가 `(incomplete)`면 **그 IP가 이 서브넷에서 응답하지 않는 것**이고
라우팅·방화벽 문제가 아니다(`route -n get <IP>`가 `en0`인지 함께 보면 5초에 갈린다). 원인은 절전이거나
**상대가 다른 네트워크에 붙은 것**이다 — 09-08에는 후자였고, 라우팅을 2시간 팠던 OPS-049와 증상이 같다.
찾는 법 둘: `dns-sd -B _ssh._tcp local`이 맥의 Bonjour 이름을 그대로 보여준다(IP가 바뀌었어도 보인다),
그리고 서브넷 ping 스윕 뒤 `arp -a`. **Wake-on-LAN 매직 패킷은 Wi-Fi 맥에 기대하지 마라** —
"Wake for network access"가 꺼져 있으면 무응답이고, 브로드캐스트 9·7 포트 양쪽 다 소용없다.

## OPS-053 — 원격 스모크는 남이 추가한 `class_name`에서 통째로 깨진다
`측정 2026-09-08 · Godot 4.7.2 · rsync 원격 실행`

**증상:** 에어에서 도는 클라 스모크 전부가 갑자기 빨개진다. 로그는
`Parse Error: Could not find type "MarsSubscriptionTerminal"` →
`Failed to load script ... with error "Parse error"` →
`Invalid call. Nonexistent function 'new' in base 'GDScript'`. 그 타입을 선언한 파일은
로컬에도 원격에도 **분명히 있고** rsync도 보냈다. 내 변경과 무관한 세션이 원인이라 각자 자기 코드를 판다.

**해결:** 범인은 소스가 아니라 원격의 `client/.godot/global_script_class_cache.cfg`다.
동기화 스크립트는 임포트 캐시를 살리려고 `.godot`을 rsync 제외에 두고, **캐시 파일이 아예 없을 때만**
`--headless --import`를 한 번 돌린다. 그래서 새 `class_name`이 생기면 원격 캐시는 낡은 채로 남고
그 타입을 쓰는 모든 씬이 파싱에서 죽는다. 파일이 하나라도 새 `class_name`을 들고 오면
`ssh <원격> "cd <루트> && \$HOME/<godot> --headless --path client --import"`를 한 번 돌려 캐시를 다시 만든다
(3초). 판정 전에 로그의 첫 `SCRIPT ERROR`가 **내 파일인지**부터 본다 — 남의 미커밋 `class_name` 하나가
내 스모크를 빨갛게 만든다.

## OPS-054 — `git add`에 없는 경로가 하나라도 있으면 add 전체가 실패한다 — `git mv`가 미리 스테이징한 rename 때문에 커밋은 "성공"한다

`측정 2026-09-12 · git 2.50.1 (macOS)`

**증상:** `git mv docs/a.md docs/b.md` 뒤 본문을 고치고
`git add CLAUDE.md docs/b.md docs/a.md tasks/x.md 2>/dev/null; git commit -m ...` — 커밋이 성공해 push까지
됐는데 `git status`에 `M CLAUDE.md`, `M tasks/x.md`가 그대로 남아 있다. 커밋에는 `docs/{a.md => b.md} | 0`
**rename 한 줄만** 들어갔다. 다른 세션이 "네 파일이 워킹트리에 남아 있다"고 물어와서 알았다.

`git add`는 pathspec 하나가 안 맞으면 `fatal: pathspec 'docs/a.md' did not match any files`를 내고 **아무것도
스테이징하지 않는다**. 그 에러를 `2>/dev/null`로 삼켰고, `git mv`가 이미 인덱스에 올려 둔 rename만 커밋됐다.
자기가 세운 "`git add -A` 금지, 경로 명시" 규칙을 지키다가 정작 add 실패를 숨긴 것이다.

**해결:** `git add`의 stderr를 절대 버리지 않는다. 여러 경로를 add할 땐 `git add -- <경로들> && git commit`로
`&&`를 걸어 add 실패가 커밋을 막게 한다. 커밋 직후 `git show --stat --format="" HEAD`로 들어간 파일 수를
의도와 대조한다 — rename만 있으면 0 insertions가 신호다. `git mv`한 옛 경로는 add 목록에 넣지 않는다.

## OPS-055 — macOS Docker Desktop에서 `network_mode: host`는 localhost로 안 닿고, WebRTC UDP 범위 50000-60000은 macOS 임시 포트와 겹쳐 기동이 실패한다

`측정 2026-09-12 · Docker Desktop 29.7.2 (macOS, Apple M1 Max) · livekit/livekit-server v1.13.6 · coturn 4.18.0`

**증상 1:** LiveKit 자체 호스팅 compose 예제대로 `network_mode: host`를 주면 컨테이너는 뜨는데
`ws://localhost:7880`이 연결 거부. macOS의 Docker는 리눅스 VM 안에서 돌아서 "host"가 맥 호스트가 아니라
VM이다. 리눅스 서버용 예제를 그대로 가져온 것이 원인.

**증상 2:** `network_mode`를 빼고 포트 매핑으로 바꿔도 `rtc.port_range_start: 50000 / end: 60000`이면
livekit이 기동 중 죽는다. macOS의 임시 포트 범위가 49152-65535라 이미 쓰이는 포트가 범위 안에 있다.

**해결:** `network_mode: host`를 지우고 `ports: ["7880:7880", "7881:7881", "40000-40100:40000-40100/udp"]`로
명시한다. `livekit.yaml`의 `rtc.port_range_start/end`도 같은 40000-40100으로 맞춘다 — 두 파일이 어긋나면
매핑 안 된 포트로 ICE 후보를 광고해 미디어만 조용히 실패한다. 이 설정은 로컬 검증용이다.
Dokploy/리눅스 프로덕션에서는 반대로 `network_mode: host` + 넓은 UDP 범위가 맞고, Traefik은 HTTP만
프록시하므로 UDP와 TURN(3478/5349)은 호스트 레벨에서 따로 열어야 한다.
coturn은 같은 상황에서 `turnutils_uclient -W`로 allocate까지는 되고, 채널 바인드는 루프백 피어 거부로
403이 난다 — 할당 자체의 실패가 아니다.

---

## OPS-056 — Claude Code 세션에서 LiveKit Cloud 룸에 붙인 에이전트가 오디오를 발행하지 않고 조용히 걸린다 — 시그널링은 되고 미디어(UDP)만 막힌 것으로 보인다

`측정 2026-09-12 · Claude Code 세션(에이전트가 실행한 Bash) · livekit-agents 1.8.1 · LiveKit Cloud`

**증상:** `AgentSession.say()`를 `await`하면 에러도 타임아웃도 없이 무한정 걸린다. 워커 로그는
`registered worker` → `received job request` → `process initialized` → (TTS/STT 모델 로드 로그) →
`adaptive interruption session created` / `audio turn detector initialized`까지는 정상 출력되고
거기서 뚝 끊긴다. `lk room participants list`로 보면 에이전트는 참가자로 들어가 있는데 `tracks: 0` —
오디오 트랙이 끝내 발행되지 않는다. 2~3분 뒤에야 `livekit::rtc_engine - resuming connection... attempt: 1`
이 찍힌다 — 시그널링 웹소켓 자체는 등록·잡 할당까지 문제없이 오갔으므로(HTTPS는 뚫려 있다) 막힌 것은
그 뒤의 미디어(SRTP/UDP) 경로로 보인다.

**빠지기 쉬운 오진:** 걸리는 지점이 TTS 어댑터를 만들고 바로 다음이라 "내 TTS 코드가 멈췄다"로 보인다.
실제로는 TTS를 `session.say()` 밖에서 단독으로 돌리면(`tts.synthesize(text).collect()`, 그리고 프레임워크가
실제로 쓰는 `tts.StreamAdapter`로 감싼 경로까지) 1초 안에 정상 완료됐다 — 어댑터 코드는 무죄였다.
같은 세션에서 STT/TTS 모델을 엔트리포인트 안에서 동기 로드하면(onnxruntime 세션 생성이 GIL을 오래 잡는
C++ 호출이라) 이벤트 루프가 2초 넘게 막혀 시그널링 하트비트를 놓치는 **별개의 진짜 버그**도 같이
발견됐다 — `WorkerOptions(prewarm_fnc=...)`로 무거운 모델 로드를 잡 배정 전 워커 프로세스 준비 단계로
옮겨 고쳤다(경고 문구 자체가 "import it at process warm-up (prewarm) instead of on first use"라고 알려준다).
그런데 이 수정 이후에도 같은 지점에서 여전히 걸렸다 — 즉 이벤트 루프 블록은 부수적으로 고칠 가치가
있는 별도 결함이었을 뿐, 오디오가 안 나가는 근본 원인은 아니었다.

**진단 순서(이 증상을 다시 보면):**
1. TTS/STT 어댑터를 `AgentSession` 밖에서 직접 돌려 코드 자체가 무죄인지 먼저 확인한다(위 방식).
2. `lk room participants list <room>`으로 `tracks: 0`인지 확인 — 0이면 로컬 트랙 발행/미디어 협상 단계다.
3. 워커 로그에서 `resuming connection`이 늦게라도 찍히는지 찾는다 — 찍히면 시그널링이 아니라 미디어다.
4. 이 셋이 다 맞으면 **코드를 더 고치지 않는다.** 이 실행 환경(Claude Code가 돌리는 Bash 샌드박스)이
   LiveKit Cloud로 나가는 WebRTC 미디어(UDP, 또는 TURN/TCP 폴백)를 막고 있을 가능성이 높다 — 이
   환경에서는 "사람 귀로 들리는지"를 애초에 검증할 수 없다. `docs/ticket-session.md` 계열 티켓이
   "Conduct가 실제 룸에서 확인한다"고 못박아 둔 것은 이 때문일 수 있다: 사람이 쓰는 실제 브라우저·클라이언트
   네트워크에서 돌려야 미디어 경로까지 검증된다.

**해결(이 세션에서 할 수 있는 것과 없는 것):** LLM/STT/TTS 어댑터의 정확성은 단위 테스트 +
`AgentSession` 밖에서의 수동 왕복으로 검증하고, "실제로 오디오가 들린다"는 사람이 실제 네트워크에서
`RUNBOOK` 명령으로 확인하게 넘긴다. 이 세션에서 붙잡고 재시도해도 네트워크 계층 문제면 코드를 아무리
고쳐도 재현되지 않는다 — 몇 분 이상 같은 지점에서 걸리면 "코드가 아니라 이 실행 환경의 네트워크"를
먼저 의심한다.

---

## OPS-057 — 포커스 없는 문서에서 `getUserMedia`는 권한 팝업 없이 거부된다 — 팝업 로그인 직후가 정확히 그 순간이다

`측정 2026-09-12 · Chrome 140 (macOS) · Firebase JS SDK 10.14.1`

**증상:** Google 로그인(`signInWithPopup`) 성공 직후 마이크를 열면 권한 팝업이 아예 뜨지 않고 실패한다.
같은 페이지를 새로고침하면 그때는 팝업이 정상으로 뜬다. 콘솔에 에러도 경고도 남지 않아 "로그인하면
마이크를 안 물어본다"는 증상만 보인다.

크롬은 포커스가 없는 문서에 권한 프롬프트를 띄우지 않고 `getUserMedia`를 그대로 거절한다.
`signInWithPopup`의 프라미스는 팝업 창이 **닫히는 중**에 resolve되므로, 그 직후 이어지는 마이크 요청이
정확히 포커스가 없는 창에 들어간다. 새로고침 경로는 포커스가 이미 돌아와 있어서 성공한다.

**해결:** 마이크를 열기 전에 포커스를 기다린다. `document.hasFocus()`가 false면 `window`의 `focus`
이벤트를 한 번 기다리고(타임아웃 몇 초), 그 다음에 `getUserMedia`를 부른다. Safari는 포커스에 더해
사용자 제스처까지 요구하므로 "허용하고 시작" 버튼 폴백은 그대로 둔다.

---

## OPS-058 — 소켓이 열리기 전에 보낸 WebSocket 프레임은 조용히 사라진다 — 앱이 그 프레임 하나를 신호로 쓰면 기능 전체가 죽는다

`측정 2026-09-12 · Chromium 140 · FastAPI WebSocket`

**증상:** 브라우저가 서버에 "오디오 준비됨"을 한 번 보내고, 서버는 그 프레임을 받아야 먼저 말을 건다.
마이크는 정상으로 열리는데 서버는 영원히 조용하다. 새로고침하면 동작한다.

전형적인 방어 코드가 원인이다.

```js
function send(obj) {
  if (socket && socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(obj));
}
```

이 가드는 끊긴 소켓에 쓰다 예외가 나는 것을 막지만, **아직 안 열린** 소켓에도 똑같이 적용된다.
부팅 순서가 「마이크 열기 → … → 소켓 열기」면 준비 신호는 매번 버려지고, 로그도 예외도 남지 않는다.
새로고침이 고쳐 보이는 이유는 그 경로가 버튼 클릭으로 마이크를 여는 다른 순서를 타기 때문이다.

**해결:** 한 번만 보내야 하는 상태 신호는 "보내는 쪽"이 아니라 **조건이 갖춰진 시점**에 건다.
전송 함수를 하나 만들고 마이크 준비와 소켓 open **양쪽에서** 호출한 뒤, 플래그로 1회만 나가게 한다.
소켓의 첫 프레임을 핸드셰이크(인증)로 읽는 서버라면 반드시 인증 프레임 **뒤에** 보낸다.
검증은 `WebSocket.prototype.send`를 감싸 실제로 나간 프레임 목록을 찍어 보는 것이 확실하다 —
"호출했다"와 "나갔다"는 다르다.

---

## OPS-059 — Docker Desktop(macOS)에서 `docker network disconnect`는 이미 열린 TCP 연결을 끊지 않는다

`측정 2026-09-13 · Docker Desktop for Mac, Docker Engine 27.x, macOS`

**증상:** 컨테이너 하나(Nakama, WebSocket 서버)에 클라이언트가 이미 연결된 상태에서
`docker network disconnect <network> <container>`로 10초간 끊었다가 `docker network connect`로
복구해도, 클라이언트 쪽에서는 연결이 끊긴 적 없는 것처럼 계속 정상 동작한다. 재접속 로직(소켓
`closed`/`connection_error` 이벤트에 의존하는 것)이 전혀 발동하지 않는다.

직접 재현: 파이썬 `socket.create_connection`으로 컨테이너의 게시된 포트에 연결해 두고, `sendall`
직후 `docker network disconnect`, 10초 대기, `docker network connect`, 그다음 `recv`. disconnect
동안 보낸 바이트는 커널 송신 버퍼에 남아 있다가 네트워크가 돌아오자마자 그대로 재전송되어 정상
응답이 도착한다 — 애플리케이션 레벨에서는 에러도 타임아웃도 전혀 관측되지 않는다. `docker network
disconnect`는 컨테이너를 그 브리지 네트워크에서 떼어 **새 연결**은 확실히 막지만(같은 테스트에서
`curl`은 즉시 타임아웃), Docker Desktop의 포트 포워딩 경로(호스트 ↔ VM ↔ 컨테이너) 위에 이미 만들어진
연결의 패킷 흐름은 끊지 못한다 — TCP가 재전송으로 조용히 흡수해 버린다. 몇 초짜리 단절 시뮬레이션
용도로는 사실상 no-op.

대조: 같은 연결에 `docker compose stop <service>`를 실행하면 0.3초 안에 소켓에 정상 FIN(`recv`가
0바이트)이 도착한다 — 컨테이너 프로세스가 죽으며 커널이 열린 소켓을 실제로 닫기 때문에 즉시·확실하게
감지된다.

**해결:** "클라이언트가 짧은 시간 안에 반드시 재접속을 감지해야 하는" 테스트에는 `docker network
disconnect`를 쓰지 않는다. 대신 `docker compose stop <service>` → 대기 → `start`(또는 `restart`)로
컨테이너 프로세스 자체를 내렸다 올린다. `docker network disconnect`는 서버 쪽 세션 타임아웃(예:
WebSocket ping/pong wait)보다 충분히 긴 시간(그 타임아웃보다 길게) 유지했을 때 "서버가 세션을 먼저
죽였는데 클라이언트는 조용히 아무것도 못 받는" 시나리오를 재현하는 용도로는 여전히 유효하다 — 단
그 경우 클라이언트가 몇 초 안에 반드시 알아챈다는 보장은 없고(하트비트가 없다면 네트워크가 복구된
뒤에야 지연된 서버 종료 신호가 도착함), "탐지 안 됨"이 실패가 아니라 하트비트 필요성의 신호일 수
있다는 것을 테스트 설계에 반영해야 한다.

## OPS-060 — OrbStack의 host↔VM 포트 릴레이는 유저스페이스 프록시라 STUN/TURN이 클라이언트의 진짜 공인 IP를 못 본다

`측정 2026-09-13 · OrbStack(macOS, Apple Silicon) Ubuntu 24.04 VM · coturn 4.18.0 · docker compose bridge 네트워크`

**증상:** VM 안에 `docker compose`로 띄운 coturn(`-p 3478:3478/udp` 포트 매핑, 기본 브리지 네트워크)에
진짜 외부(다른 리전의 별도 서버)에서 `turnutils_stunclient <공인IP>`로 STUN Binding을 쏘면 응답은
정상적으로 온다(닫힌 포트에 쏘면 `STUN receive timeout after 3000 ms`로 명확히 실패하는 것과 대조돼
왕복 자체는 진짜다). 그런데 응답에 담긴 reflexive address가 요청자의 실제 공인 IP가 아니라
`172.19.0.1` 같은 **docker compose의 내부 브리지 게이트웨이 주소**로 찍힌다. 같은 VM 안에 매핑 안 해둔
포트(`--network host`로 임시 bind)를 열어도 외부에서 바로 도달하는데, 그때 수신 측이 보는 발신지는
`127.0.0.1`(loopback)이다.

**원인:** OrbStack의 `machines.forward_ports`(+ `expose_ports_to_lan`)는 사전에 정의한 포트 목록을
포워딩하는 게 아니라, **VM 안에서 리슨하는 포트를 감지해 맥 쪽에 같은 포트를 자동으로 미러링하는
유저스페이스 프록시**다(Docker Desktop의 vpnkit과 같은 부류). 이 프록시가 외부 연결을 받아 VM 안으로
중계할 때 자기 자신(로컬)에서 새 연결을 맺으므로, VM 안 프로세스가 보는 발신 주소는 항상 로컬(호스트
포트 매핑이면 docker 브리지 게이트웨이, host 네트워크면 127.0.0.1)이지 실제 인터넷 저편 클라이언트의
주소가 아니다. `network_mode: host`로 바꿔도 172.19.0.1이 127.0.0.1로 바뀔 뿐 근본 문제(진짜 공인 IP
소실)는 그대로다 — OPS-055가 다룬 macOS Docker Desktop 리눅스 VM과 같은 모양이지만, OPS-055는 "포트
범위가 안 맞아 기동 자체가 실패"하는 문제였고 이건 "기동은 되고 응답도 오는데 주소 정보가 구조적으로
틀리는" 다른 층의 문제다. coturn의 `--external-ip`는 TURN 릴레이가 광고하는 후보 주소만 고칠 뿐 STUN
Binding 응답의 reflexive address(요청자가 실제로 관측되는 주소)는 못 고친다.

**해결:** STUN/TURN처럼 "서버가 클라이언트의 진짜 공인 IP를 정확히 돌려줘야" 동작하는 서비스는
OrbStack(또는 이와 같은 유저스페이스 포트 릴레이를 쓰는 가상화)의 VM 안에 두면 안 된다. 물리 호스트가
LAN에 직접 붙어 있다면(공유기 포트포워딩이 물리 호스트의 실제 NIC로 바로 온다) 미디어 경로(coturn·
LiveKit RTC)만 VM 밖 물리 호스트에 네이티브로 띄우고, 시그널링(HTTPS)만 Traefik 뒤 VM에 두는 구성이
왕복이 짧다. 대안은 TURN을 아예 클라우드 VM처럼 유저스페이스 릴레이가 없는 호스트에 두는 것.
판별 방법: VM 안에서 `network_mode: host`로 같은 STUN 요청을 다시 쏴서 reflexive address가 172.19.0.1
대신 127.0.0.1로 바뀌기만 하면(클라이언트 공인 IP로는 안 바뀌면) 이 유저스페이스 릴레이가 원인임이
확정된다.

## OPS-061 — OrbStack은 VM 컨테이너가 내린 뒤에도 아니라, VM이 그 포트를 계속 쓰는 동안 맥 호스트에 같은 포트를 와일드카드로 물고 있어 네이티브 프로세스가 못 붙는다

`측정 2026-09-13 · OrbStack(macOS, Apple Silicon) · livekit-server 1.13.6(brew) · coturn 4.18.0(brew) · launchd`

**증상:** OPS-060 해결책대로 coturn·LiveKit RTC를 OrbStack VM 컨테이너에서 물리 호스트(맥) 네이티브
launchd 프로세스로 옮기는 도중, VM의 기존 컨테이너(같은 포트 7880·7881·3478·40000-40100을 publish)를
아직 내리지 않은 상태에서 네이티브 프로세스를 먼저 띄우면 LiveKit이 `listen tcp :7881: bind: address
already in use`로 즉시 죽는다. `lsof -nP -iTCP:7881`로 보면 점유자가 우리 프로세스가 아니라
**`OrbStack` 앱 프로세스 자신**이 `*:7881`(와일드카드)로 리슨 중이다. coturn은 같은 상황에서 안
죽었다 — `turnserver.conf`에 명시적 IP만 나열해서 특정-주소 리슨(`172.30.1.111:3478` 등)으로 붙었고,
macOS는 와일드카드 리슨과 특정-주소 리슨이 같은 포트에서 공존 가능하기 때문. LiveKit은
`bind_addresses`에 특정 IP 두 개를 명시했는데도 안 됐다 — `rtc.tcp_port`(RTC-TCP 폴백) 리스너는
`bind_addresses` 설정을 안 타고 별도로 와일드카드(`:포트`)로 붙는 것으로 보인다(메인 HTTP/WS 포트
7880은 지정한 IP로 정상 바인딩됨, 로그의 `bindAddresses` 필드가 7880에만 적용).

**원인:** OrbStack의 host↔VM 포트 릴레이(OPS-060 참고)는 VM 컨테이너가 그 포트를 publish하고 있는 한
맥 호스트에도 같은 포트를 계속 와일드카드로 열어 둔다 — VM 쪽 서비스를 아직 안 내렸다면 이 릴레이가
여전히 살아있어 호스트 자체의 새 리스너와 충돌한다. OPS-060은 "릴레이가 살아있을 때 발신 주소가
틀리는" 문제였고, 이건 "릴레이가 살아있는 동안은 같은 포트를 호스트에서 못 쓴다"는 다른 증상이다.

**해결:** 미디어를 VM에서 물리 호스트로 옮길 땐 순서가 중요하다 — **VM 쪽 컨테이너(포트를 publish하는
쪽)를 먼저 내려야** 그 포트가 호스트에서 풀린다. `launchd`에 `KeepAlive: true`를 걸어 두면 VM을 내린
뒤 자동으로 재기동해 순서를 엄격히 맞출 필요는 없다(실측: VM 쪽 compose 재배포로 컨테이너가 사라지자
5분 내 네이티브 프로세스가 스스로 붙었다 — 별도 `launchctl kickstart` 불필요). 포트 충돌 여부를 미리
가르려면 `lsof -nP -iTCP:<포트> -sTCP:LISTEN`으로 점유 프로세스 이름을 확인 — `OrbStack`이 잡고 있으면
VM 쪽이 원인, 다른 이름이면 진짜 다른 프로세스와의 충돌이다.

## OPS-062 — 한 워크트리에서 세션 여럿이 동시에 커밋하면 `git add`를 경로로 명시해도 남의 스테이지 변경이 삼켜진다

`측정 2026-09-13 · git 2.51 · macOS`

**증상:** 세션 A가 자기 파일 10개만 `git add <경로>`로 스테이지하고 커밋하려는 사이,
세션 B가 자기 파일을 `git add` 하고 먼저 `git commit` 했다. B의 커밋에 A의 파일 10개가 전부 실려
들어갔다. A의 커밋 명령은 "nothing to commit"이 아니라 성공했지만 `git log`에 A의 커밋이 없고,
B의 커밋 diff에 A의 파일이 들어 있다. A는 `git add -A`를 쓰지 않았다 — 경로를 하나씩 명시했는데도
당했다.

**원인:** 인덱스(`.git/index`)는 워크트리 하나당 하나다. `git add`는 "내 파일을 내 커밋에 예약"하는
연산이 아니라 **공용 인덱스를 갱신**하는 연산이다. `git commit`(경로 인자 없이)은 그 시점의 인덱스
전체를 커밋한다. 그래서 A의 add와 B의 commit이 겹치면 A의 스테이지 내용이 B의 커밋에 들어간다.
`git add -A` 금지는 이 사고를 줄이지만 막지는 못한다. 인덱스 락(`index.lock`)은 개별 명령만
직렬화할 뿐, add와 commit 사이의 구간은 보호하지 않는다.

**해결:** 커밋할 때 경로를 `git commit`에도 준다 — `git commit -m "..." -- <경로들>`은 인덱스 상태와
무관하게 그 경로만 커밋한다(스테이지되지 않은 변경도 함께 커밋하므로 의도한 경로만 적어야 한다).
이게 안 되는 상황이면 `git commit` 직전에 `git diff --cached --name-only`로 내 파일만 있는지 확인한다.
삼켜진 뒤에는 이력을 고치지 말고(다른 세션이 그 위에 쌓고 있다) 삼킨 커밋을 그대로 두거나,
그 커밋이 버려졌다면 인덱스에 남은 변경을 다시 커밋해 복구한다.

## OPS-063 — `docker kill`/`stop`은 dockerd에 "수동 정지" 플래그를 남겨 `restart: unless-stopped`가 자동복구를 안 한다

`측정 2026-09-13 · Docker 28.5.0 · Linux(호스트 커널)`

**증상:** `restart: unless-stopped`가 실제로 적용된 컨테이너를 `docker kill <컨테이너>`로 죽여
"프로세스가 죽으면 자동복구되는지" 검증하려 했더니 20분 넘게 컨테이너가 그대로 죽어 있었다(프로덕션
컨테이너라 실제 다운타임 발생, `docker start`로 수동 복구). `journalctl -u docker`에
`ShouldRestart failed, container will not be restarted ... hasBeenManuallyStopped=true`가 킬 직후
정확히 찍혀 있었다.

**원인:** `docker kill`·`docker stop`은 컨테이너 프로세스가 그냥 죽는 것과 dockerd 관점에서 다르다 —
둘 다 Docker API를 거쳐 "사람이 의도적으로 멈췄다"는 상태를 컨테이너에 남긴다. `unless-stopped`는
정의상 이 경우 재시작하지 않는다("컨테이너가 정지 상태였다면 데몬 재시작 시에도 안 올린다"는 동작과
같은 플래그 하나로 구현돼 있다). 즉 **`docker kill`로 자동복구를 검증하면 항상 가짜로 실패한다** —
dockerd가 "의도된 정지"와 "크래시"를 구분해 전자는 절대 자동복구 대상이 아니기 때문이다.

실제 크래시를 흉내 내려고 컨테이너 안에서 `docker exec <컨테이너> kill -9 1`을 시도해도 안 통한다
(exit 0으로 성공한 것처럼 보이지만 프로세스는 살아있다) — 리눅스 `pid_namespaces(7)`에 PID
네임스페이스의 init(PID 1)은 **같은 네임스페이스 안에서 온** SIGKILL/SIGSTOP을 핸들러 없이도 커널이
무시하는 특례가 있다. 네임스페이스 밖(호스트)에서 오는 SIGKILL은 이 면제 대상이 아니다.

**해결:** "죽었을 때 자동복구되는지"를 검증하려면 dockerd의 관리된 정지 경로를 거치지 않고 컨테이너
메인 프로세스를 지워야 한다 — 호스트에서 `docker inspect <컨테이너> --format '{{.State.Pid}}'`로 호스트
PID를 얻어 **호스트에서 직접 `kill -9 <PID>`**. 이러면 dockerd는 이를 크래시로 보고
`unless-stopped`가 정상적으로 재시작한다(실측: 재시작까지 1~2초). `docker kill`은 "정지가 되는지"
검증에는 맞고, "죽으면 살아나는지" 검증에는 안 맞는다 — 목적에 따라 다른 도구를 써야 한다.

## OPS-064 — adb 서버는 머신에 하나뿐이라 한 세션의 `kill-server`가 다른 세션의 기기를 30분 날린다

`측정 2026-09-14 · adb 1.0.41(37.0.1), macOS 호스트, Pixel 7 Pro(Android 17) USB 연결`

**증상:** 여러 프로젝트의 에이전트 세션이 같은 맥에서 한 안드로이드 기기를 공유하는 상황. 한 세션이
연결이 이상하다고 판단해 `adb kill-server && adb start-server`를 돌렸다. 그 순간부터 **다른 세션들에서
기기가 `offline`으로 굳었다.**

```
33251FDH3002AE   offline   usb:17825792X   transport_id:1
```

`adb kill-server`+`start-server` 재시도, `adb reconnect`, `adb reconnect offline` 전부 실패.
`ioreg`에는 기기가 정상으로 잡히고 `~/.android/adbkey`도 멀쩡하다. `unauthorized`가 아니라 `offline`이라
승인 팝업 대기 상태도 아니다. **결국 사람이 폰에서 USB 디버깅을 껐다 켜야 풀렸다** — 30분을 잃었다.

원인은 adb 아키텍처다. `adb` 명령은 전부 **호스트의 단일 adb 서버 데몬(기본 tcp:5037)**을 거친다.
어느 세션이 `kill-server`를 부르든 그 데몬은 프로세스 하나뿐이라 **모든 세션의 기기 연결이 함께 끊긴다.**
USB transport가 재수립되지 못하면 기기는 `offline`으로 남고, 이 상태는 호스트 쪽 재시도로는 복구되지 않는다.

**해결:** 기기를 공유하는 환경에서는 규칙으로 막는다. 실측으로 합의한 것.

- **`adb kill-server` 금지.** 연결이 이상하면 `adb reconnect` / `adb reconnect device`까지만 쓴다.
- **남의 앱을 `am force-stop` 하지 않는다.** 자기 앱만 `am start`로 앞에 띄운다 — 남의 앱을 내리면
  그쪽 세션은 "앱이 죽었다"고 오진한다.
- **테스트가 끝나면 자기 앱을 종료하고 바꾼 시스템 설정을 전부 되돌린다**
  (`screen_off_timeout`·`accelerometer_rotation`·`user_rotation`·회전 잠금). 확인값을 출력으로 남긴다 —
  "되돌렸다"는 말이 아니라 읽은 값이 근거다.
- **기기를 쓰기 전에 다른 세션에 알린다.** 누가 언제까지 쓰는지만 맞춰도 경합이 사라진다.

기기가 `offline`으로 굳으면 그건 **호스트에서 못 푸는 신호다** — 재시도를 반복하지 말고 사람에게
"USB 디버깅을 껐다 켜달라"고 요청하는 편이 빠르다.

## OPS-065 — 생성물을 커밋하는 CI는 자기 자신도 밀려난다: 푸시가 거부되면 잡이 죽는다

`측정 2026-09-14 · GitHub Actions, 세션 여럿이 같은 저장소에 푸시하는 지식 베이스`

**증상:** 산출물을 재생성해 커밋·푸시하는 워크플로가 4초 만에 실패한다. 로그 마지막은
`! [rejected] main -> main (fetch first)` / `Process completed with exit code 1`. OPS-014는 **사람**이
CI에 밀리는 경우인데, 이것은 **CI가 사람(또는 다른 CI 실행)에 밀리는** 반대 방향이다. 워크플로가
`git commit && git push`를 그대로 쓰면 그 사이 원격에 새 커밋이 들어온 순간 잡이 죽는다.
여러 프로젝트 세션이 같은 저장소에 몇 분 간격으로 푸시하는 환경에서는 드물지 않다 —
이 저장소에서 같은 실패가 5번 반복됐다.

산출물이 타임스탬프나 커밋 해시를 품으면(예: 헤더에 생성 시각) 내용이 매번 달라져
"변경 없음" 분기가 사실상 죽고, 푸시가 항상 일어나 경쟁 확률이 더 올라간다.

**이 실패는 조용하다.** 올린 세션 입장에서는 자기 `git push`가 성공했으므로 "올렸다"고 보고하고 끝난다.
Action이 죽은 것은 알림을 보는 사람만 안다. 그 사이 원본 `.md`에는 새 항목이 있고 산출물에는 없으므로,
**웹이나 산출물로 읽는 쪽은 조용히 낡은 사본을 본다** — 항목이 없다고 나오지, 오류가 나지 않는다.
원본을 직접 grep하는 쪽은 영향이 없다. 로컬 원본을 읽는 것이 이 실패에 대해서도 더 안전하다.

**해결:** 두 겹으로 막는다. ① 워크플로에 `concurrency: {group: <이름>, cancel-in-progress: false}`를
줘서 같은 워크플로끼리는 직렬화한다. ② 푸시를 재시도 루프로 감싸되, **매 시도를 원격 최신에서
다시 시작**한다 — rebase나 merge가 아니라 재생성이다(OPS-014와 같은 원칙).

```bash
for attempt in 1 2 3 4 5; do
  git fetch origin main
  git checkout -B main origin/main
  ./build.sh                      # 원격 최신 소스 위에서 산출물 재생성
  git add <소스> <산출물>
  git commit -m "build: ... [skip ci]"
  if git push origin main; then exit 0; fi
  sleep $((RANDOM % 5 + 2))       # 랜덤 백오프로 동시 재시도를 흩는다
done
exit 1
```

커밋 메시지의 `[skip ci]`를 빼면 이 커밋이 워크플로를 다시 불러 무한 루프가 된다.

## OPS-066 — 중복 ID를 자동 재번호하는 빌드는 제목만 고친다: 본문의 상호 참조는 깨진 채 남는다

`측정 2026-09-14 · 세션 여럿이 같은 문서 저장소에 올리는 지식 베이스(build.sh)`

**증상:** 여러 세션이 같은 문서에 "다음 번호"를 각자 골라 동시에 올리면 ID가 겹친다. 이를 막으려고
빌드가 중복을 자동 재번호하면(뒤에 오는 항목을 접두사의 다음 빈 번호로 이동) 충돌 자체는 사라지지만,
**치환 대상이 제목 줄 하나뿐**이라 두 가지가 어긋난 채 남는다.

1. 본문에서 다른 항목을 ID로 참조한 문장(`GDT-066 참고`, `이것은 OPS-014의 반대 방향이다`)은
   그대로다. 재번호된 항목을 가리키던 참조는 엉뚱한 사실을 가리키게 된다.
2. 올린 세션이 보고한 ID와 최종 ID가 달라진다. 세션은 `GDT-064`로 올렸다고 보고하고 탭이 닫혔는데
   저장소에는 `GDT-070`으로 들어가 있다. 리더가 그 보고를 믿고 인용하면 틀린다.

**해결:** 자동 재번호는 **최후의 안전망으로만** 두고, 번호는 애초에 겹치지 않게 고른다 —
**올리기 직전에** `git pull` 후 해당 파일의 마지막 번호를 다시 확인한다. 리더가 티켓·프롬프트에 미리
배정해 둔 번호는 믿지 않는다(그 사이 다른 세션이 올린다). 상호 참조는 재번호에 흔들리므로,
글을 쓸 때 "바로 위 항목" 같은 위치 표현 대신 ID로 쓰되, 참조한 ID가 방금 올린 것이면
푸시 후 실제 저장된 번호를 한 번 확인한다.

## OPS-067 — 공유 배포 호스트에서 일반 유저는 `docker` 명령에 `sudo`가 필요할 수 있다

`측정 2026-09-14 · busan(OrbStack VM, Dokploy raw compose)`

**증상:** `ssh <호스트> "docker ps"`가 `permission denied while trying to connect to the Docker
daemon socket at unix:///var/run/docker.sock`로 즉시 실패한다. 로그인 유저가 `sudo` 그룹엔
있는데 `docker` 그룹엔 없어서다(`id` 확인: `groups=...,27(sudo),...` — `docker`(999 등) 없음).

**해결:** 그 유저를 `docker` 그룹에 넣을 권한·필요가 없다면(공유 운영 호스트라 그룹 변경은 리더·
대표님 승인 없이 하지 않는 게 안전) 매 호출에 `sudo`를 붙인다 — `ssh <호스트> "sudo docker logs
--tail 500 <컨테이너>"`. 컨테이너 이름 자체도 Dokploy가 무작위 슬러그로 짓는 프로젝트라면
고정 문자열로 스크립트에 박지 말고 `sudo docker ps --format '{{.Names}}' | grep -i <서비스>`로
매번 찾는다.

## OPS-068 — Dokploy raw compose를 ssh로 직접 고치면 DB `composeFile`과 라이브 파일이 어긋난다

`측정 2026-09-14 · busan(Dokploy v0.30.6, sourceType: raw)`

**증상:** 이전 티켓(T-071)이 GM 워커 컨테이너의 `environment`에 `GM_IDLE_PROCESSES` 항목을 추가했다고
기록했는데, Dokploy `compose.one` API로 받은 현재 DB `composeFile` 텍스트에는 그 줄이 아예 없었다.
반면 배포된 컨테이너의 `.env` 파일에는 실제로 `GM_IDLE_PROCESSES=1`이 들어 있어 지금 당장은 정상
동작한다 — 문제는 다음 전체 재배포(`compose.deploy`)에서 Dokploy가 `code/`를 DB의 `composeFile`로
통째로 재생성한다는 점이다. DB에 없는 줄은 다음 배포에서 조용히 사라진다.

원인으로 추정: 그 값을 넣을 때 `compose.update` API(DB 갱신)를 거치지 않고 `ssh`로 라이브
`/etc/dokploy/compose/<app>/code/docker-compose.yml`을 직접 고쳤다 — 당장은 동작하지만 DB와
어긋난 상태가 다음 배포까지 조용히 남는다. 에러도 경고도 없다.

**해결:** Dokploy raw compose(git 연동이 아니라 `composeFile` 텍스트를 DB에 직접 넣는 소스 타입)에서
설정을 바꿀 때는 **항상 `compose.one`으로 현재 `composeFile`을 받아 텍스트를 고친 뒤 `compose.update`로
다시 넣고 `compose.deploy`로 반영한다** — ssh로 라이브 파일만 고치는 지름길을 쓰지 않는다. 이미 그렇게
어긋난 값이 있는지 의심되면 `compose.one`으로 받은 DB 텍스트와 `ssh <호스트> "sudo cat
/etc/dokploy/compose/<app>/code/docker-compose.yml"`로 받은 라이브 텍스트를 diff해 본다 — 다르면
라이브 쪽이 다음 배포에서 사라질 값이다.

---

## OPS-069 — Dokploy의 `dokploy-network`는 전 프로젝트가 공유한다: 포트를 열지 않은 관리 콘솔도 그 안에서는 서비스 이름으로 열려 있다

`측정 2026-09-15 · Dokploy(misa 호스트), Nakama 3.40.0, docker overlay network`

**증상:** compose에서 관리 콘솔 포트를 `ports:`로 매핑하지 않고 Traefik 라벨도 붙이지 않았으니
"외부에 안 열었다"고 적어 뒀다. 실제로는 그 컨테이너가 Traefik 라우팅을 받으려고
`dokploy-network`(external overlay)에 붙어 있고, **그 네트워크에는 이 호스트의 다른 프로젝트
컨테이너가 전부 같이 있다**. 같은 네트워크 안에서는 서비스 별칭으로 그냥 닿는다:

```sh
docker run --rm --network dokploy-network curlimages/curl -s -X POST \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"password"}' \
  http://nakama:7351/v2/console/authenticate
# → 200, 콘솔 토큰 발급됨 (기본 자격 그대로였다)
```

Nakama 콘솔 토큰이면 계정 삭제·저장소 조회가 전부 된다(실제로 `DELETE /v2/console/account/<id>`로
계정을 지워 확인했다). 같은 호스트에 워드프레스·umami·CI 러너가 함께 떠 있었다 — 그중 하나만
뚫려도 이 콘솔이 따라 넘어간다.

**해결:** 관리 콘솔·내부 API의 **자격을 반드시 환경변수로 바꾼다**. 네트워크 분리로는 못 막는다 —
Traefik이 라우팅하려면 그 컨테이너가 공유 네트워크에 있어야 하고, 콘솔은 같은 컨테이너의 다른
포트이기 때문이다. Nakama라면 `--console.username`/`--console.password`를 entrypoint에 붙이고
값은 Dokploy 환경변수에서 받는다. 점검은 위 `docker run --network dokploy-network` 한 줄이면 된다.

**같이 나온 것 — compose entrypoint의 `-ecx`:**

```yaml
entrypoint: ["/bin/sh", "-ecx", "exec /app --database.address user:${PASSWORD}@db ..."]
```

`-ecx`의 `x`는 `set -x`다. 셸이 **치환이 끝난 명령줄**을 stderr로 뱉으므로 DB 비밀번호·서버키가
`docker logs`에 평문으로 남는다(`+ exec /nakama/nakama --database.address nakama:<암호>@...`).
호스트에서 docker를 쓸 수 있는 사람이면 누구나 읽는다. 디버깅용으로 켠 `x`를 그대로 두지 않는다 —
`-ec`로 충분하다.

## OPS-070 — 계약을 주고받는 두 서비스 중 한쪽만 배포하면 100% 실패한다. 양쪽이 같이 낡으면 격차가 안 보인다

`측정 2026-09-14 · Docker + Dokploy raw compose · trpg 리포(Nakama + Python 워커)`

**증상:** 워커를 최신 커밋으로 배포했더니 기능이 **100% 실패**했다. 워커 로그는
`400 Bad Request`, 서버 응답은 `{"code":3,"message":"invalid payload"}`. 방금 올린 커밋은 그
경로를 건드리지도 않았다.

원인은 반대편이었다. **서버가 하루 전 커밋으로 돌고 있었다.** 서버는 그날 낮에 "빈 본문 + 메타
필드만 있는 호출"을 허용하도록 고쳐졌는데 그 이미지가 배포되지 않았고, 워커 쪽에서 정확히 그
호출을 하는 코드도 같이 미배포 상태였다. **양쪽이 같이 낡아서 서로 맞아떨어져 있었다.** 한쪽만
올리는 순간 드러난다. 직접 확인한 응답으로 갈렸다:

```
본문="" + 메타 필드  → {"code":3,"message":"invalid payload"}  HTTP 400   (서버가 옛 코드)
본문="x" + 메타 필드 → {"code":13,"message":"match id invalid"} HTTP 500   (검증은 통과)
```

`docker inspect`의 이미지 생성 시각은 서버 커밋보다 **나중**이었는데도 그 커밋이 안 들어 있었다.
빌드가 어느 sha에서 나왔는지는 시각으로 추정할 수 없다.

배포 이미지에 `:latest` 태그만 걸려 있어 **무엇이 떠 있는지 알 방법도, 되돌릴 지점도 없었다.**

**해결:** ① 계약(RPC·API·스키마)을 바꾼 커밋은 **양쪽을 같은 sha로 함께 배포한다.** 한쪽만
올리는 배포는 상대의 미배포 격차를 터뜨리는 장치다. ② 장애를 만나면 **내 변경부터 의심하지 말고
반대편 버전을 먼저 확인해라** — 여기서는 서버에 최소 페이로드 두 개를 직접 쏴서 1분 만에 갈렸다.
③ **모든 배포에 sha 태그를 남긴다.** `:latest`만 쓰면 떠 있는 것이 어느 코드인지 영원히 모른다.
배포 직전 현재 이미지에 `pre-<새sha>` 태그를 걸어두면 롤백 지점이 생긴다 — 실제로 이 장애에서
워커를 그 태그로 되돌려 몇 초 만에 서비스를 복구하고, 그다음 차분히 서버를 배포했다.

## OPS-071 — Dokploy에서 비공개 GitHub 저장소를 deploy key로 자동 배포하는 API 순서와 함정 3개

`측정 2026-09-17 · Dokploy v0.30.6 (busan), GitHub deploy key(read-only), Dockerfile 빌드`

**증상:** GitHub App 연동 없이 비공개 저장소를 Dokploy에 붙이려고 API를 부르면 세 군데서 막힌다.

- `sshKey.create`는 `name`·`privateKey`·`publicKey`만으로는 400이다:
  `fieldErrors: {"organizationId": ["expected string, received undefined"]}`.
  조직 ID는 `organization.all`의 `[0].id`에서 받는다.
- git 소스 저장 프로시저 이름은 `application.saveGitProvider`다. 오타 이름
  `application.saveGitProdiver`(예전 버전에 있던 이름)는 **404 `NOT_FOUND`**만 돌려주고 원인을 말하지 않는다.
- `application.saveBuildType`은 Dockerfile 빌드에서도 `herokuVersion`과 `railpackVersion`을 요구한다:
  `"expected nonoptional, received undefined"`. 두 값을 `null`로 넣으면 통과한다.
  이 호출을 빼먹으면 `buildType`이 기본값 `nixpacks`로 남는다.

**해결:** 이 순서로 부르면 첫 시도에 통과한다.

```sh
ssh-keygen -t ed25519 -N "" -f key && gh repo deploy-key add key.pub -R <owner>/<repo>
dokploy-api post sshKey.create '{"name":..,"organizationId":"<org.id>","privateKey":..,"publicKey":..}'
dokploy-api post application.create '{"name":..,"environmentId":..}'          # appName은 무작위로 생성된다
dokploy-api post application.saveGitProvider '{"applicationId":..,"customGitUrl":"git@github.com:<owner>/<repo>.git",
  "customGitBranch":"main","customGitBuildPath":"/","customGitSSHKeyId":..,"watchPaths":[],"enableSubmodules":false}'
dokploy-api post application.saveBuildType '{"applicationId":..,"buildType":"dockerfile","dockerfile":"Dockerfile",
  "dockerContextPath":"","dockerBuildStage":"","herokuVersion":null,"railpackVersion":null}'
dokploy-api post domain.create '{..,"certificateType":"letsencrypt"}'
```

푸시 자동 배포는 GitHub 웹훅 하나면 된다. 주소는 `https://<dokploy>/api/deploy/<refreshToken>`이고
(`application.one`의 `refreshToken`), content type은 json, 이벤트는 push다. 실측 결과 웹훅 전달은 200이었고,
`main` 푸시 뒤 약 1분 만에 새 페이지가 떴다. 이렇게 하면 `localhost:5000` 레지스트리에 수동으로 push할 필요가 없다.
Dokploy가 busan 위에서 직접 clone해 빌드한다.

## OPS-072 — GitHub 사용자명은 비활성이어도 돌려받을 수 없다: `<name>.github.io`가 404여도 못 쓴다

`측정 2026-09-17 · GitHub Username Policy`

**증상:** `https://<name>.github.io`가 404이고 그 계정은 저장소 0개, 공개 활동 0건, 마지막 수정
2016년이다. 비어 보이지만 Pages 주소로 쓸 수 없다. `*.github.io`는 와일드카드 DNS라 어떤 이름이든
GitHub IP로 풀리므로 DNS 조회로는 계정 존재 여부를 알 수 없다. `gh api users/<name>`으로 확인해야 한다.
`<name>.github.com`이라는 주소는 아예 없다(DNS 레코드 없음, curl 종료 코드 6).

정책 원문: *"We do not accept requests to release, transfer, or reclaim usernames on the basis that they
appear inactive or unused."* 예외는 상표권 분쟁뿐이다.

**해결:** 다른 이름을 쓴다. 예를 들어 `<user>.github.io/<repo>`, 새 조직, 커스텀 도메인이 있다.
이름 후보는 `gh api users/<후보>`가 404인지로 거른다.

## OPS-073 — Dokploy 기본 swarm 업데이트는 새 컨테이너를 먼저 띄운다: BoltDB·SQLite 볼륨 앱은 재배포가 조용히 실패하고 옛 설정으로 계속 돈다

`측정 2026-09-17 · Dokploy v0.30.6 (busan), Remark42 v1.17.1 (BoltDB), docker swarm`

**증상:** Dokploy에서 환경변수를 바꾸고 재배포했는데 앱은 계속 옛 설정으로 돌았다. 에러 알림도 없었다.
`docker service ps <appName>`를 보면 새 task는 `Failed "task: non-zero exit (1)"`였다. 그런데도
**52분 전에 뜬 첫 task가 `Running`으로 남아** 트래픽을 계속 받고 있었다. 새 task 로그는 다음과 같았다.

```
[PANIC] failed to setup application, failed to make data store engine:
can't initialize data store: failed to make boltdb for ./var/bible.db: timeout
```

새 task가 옛 task보다 먼저 떠서(start-first) 같은 볼륨의 `bible.db`를 열려고 했다.
그런데 옛 task가 파일 잠금을 쥐고 있어서 새 task는 30초 뒤 죽었다. 결국 첫 배포 이후의 **모든 설정 변경이 한 번도 반영되지 않았다.**
설정 API(`application.one`의 `env`)는 새 값을 보여 주므로, 설정만 봐서는 반영이 안 된 걸 알 수 없다.

**해결:** 파일 잠금 DB(BoltDB, SQLite, LevelDB 등)를 볼륨에 두는 앱은 업데이트 순서를 stop-first로 바꾼다.

```sh
dokploy-api post application.update \
  '{"applicationId":"<id>","updateConfigSwarm":{"Parallelism":1,"Order":"stop-first","FailureAction":"pause"}}'
dokploy-api deploy <app>
```

재배포한 뒤에는 설정 API 말고 **앱이 실제로 내놓는 값**으로 반영을 확인한다(Remark42라면
`/api/v1/config?site=<id>`의 `auth_providers`·`admins`). `docker service ps`에서 `Running` task의
시작 시각이 방금인지도 함께 본다.

## OPS-074 — Remark42 사용자 ID는 API로 못 꺼낸다: 로그인 후 사용자 패널에서 복사한다

`측정 2026-09-17 · Remark42 v1.17.1, Google OAuth`

**증상:** 관리자 지정(`ADMIN_SHARED_ID`)에 넣을 `google_<sha1>` ID를 구하려고 로그인한 브라우저에서
`/api/v1/user?site=<id>`를 열면 `Unauthorized`가 나온다. `/auth/status`도 `{"status":"not logged in"}`이다.
둘 다 쿠키 말고 XSRF 헤더까지 요구하므로, 주소창으로 열면 로그인 상태에서도 실패한다.
댓글 위젯의 사용자 패널은 ID를 보여 주지만 `google_d4b0…c832335…`처럼 말줄임으로 자른다. 브라우저를 축소해도 잘린다.

**해결:** 위젯에서 이름을 눌러 사용자 패널을 연다. ID 줄을 세 번 클릭해 선택하고 복사하면
잘리지 않은 전체 값(`google_` + 40자 hex)이 클립보드에 들어온다. 이 값을 `ADMIN_SHARED_ID`에 넣고 재배포한다.
반영 여부는 `/api/v1/config?site=<id>`의 `admins` 배열로 확인한다.
Google 로그인 설정 조건은 두 가지다. 리디렉션 URI는 `<REMARK_URL>/auth/google/callback`이다.
`ALLOWED_HOSTS`의 self는 따옴표를 붙여 `'self',https://<site>`로 적는다. 따옴표가 없으면 CSP에 `self`라는 호스트 이름으로 들어간다.

## OPS-075 — Bible.com 본문 페이지는 curl에 봇 확인 화면을 준다: 장 단위 공식 API는 JSON으로 열린다

`측정 2026-09-19 · Bible.com / YouVersion, 현대인의 성경(version 86)`

**증상:** `curl https://www.bible.com/ko/bible/86/GEN.2.8-15.KLB`가 HTTP 200인데 본문은 3KB짜리
`<title>Client Challenge</title>` 페이지다. User-Agent·Accept-Language를 브라우저처럼 바꿔도 같고,
`www.bible.com/api/...` 경로도 같은 화면을 준다. 본문을 HTML에서 긁는 방식은 쓸 수 없다.

`https://nodejs.bible.com/api/bible/chapter/3.1?id=86&reference=GEN.2`(또는 `events.bible.com` 같은 경로)는
확인 화면 없이 JSON을 준다. 필드는 `reference.human`(`창세기 2`), `copyright.text`, `content`(장 전체 HTML)다.
절은 `span.verse[data-usfm="GEN.2.8"]` 안의 텍스트이고, `span.label`(절 번호)·`span.note`(각주)·`.heading`은 빼야 한다.
**원문이 두 절을 한 절로 묶으면 `data-usfm="GEN.2.11+GEN.2.12"`가 된다.** `GEN.2.11`로 찾으면 없다고 나온다.
한 절이 문단을 넘어 여러 `span`으로 나뉠 수도 있어 같은 `data-usfm`의 텍스트를 이어 붙여야 한다.
공식 본문의 공백은 그대로 온다(요한계시록 14:1에 `함 께`). 사람이 대조해 저장한 13절과 비교하면 12절은 글자까지 같았고, 남은 1절은 이 공백 차이였다.

**해결:** 장 단위 API로 받아 `+`로 묶인 키를 쪼개 찾고, `copyright.text`가 예상한 고지와 같은지 확인한 뒤 저장한다.
저장한 본문은 게시 전에 사람이 Bible.com 화면과 대조한다. 역본 라이선스는 이 API와 별개로 확인해야 한다.

## OPS-076 — `codex exec`로 무인 이미지 생성: 배경이 투명하게 올 수 있고, `sips` BMP는 투명을 검정으로 남긴다

`측정 2026-09-19 · codex-cli 0.154.0, macOS sips, libwebp cwebp 1.6.0`

**증상:** 흰 배경 연필 그림을 요청해 흰색을 투명으로 바꾸는 마스크를 만들었는데, 결과가 통째로 불투명한 상자였다.
Codex 내장 imagegen은 "pure white background"라고 해도 **알파 채널이 있는 PNG(배경 투명)**를 돌려줄 때가 있다.
`sips -s format bmp`는 이 PNG를 32비트 BITFIELDS BMP(헤더 124바이트, compression=3)로 저장하고,
투명 픽셀은 `(0,0,0,0)`이 된다. 알파를 무시하고 밝기만 보면 배경이 검정으로 읽힌다.

`codex exec --skip-git-repo-check -C <빈 폴더> --sandbox workspace-write -`에 "내장 imagegen으로 만들어 art.png로 저장하라"는
지시를 stdin으로 주면 ChatGPT 로그인만으로 무인 생성이 된다. LaunchAgent 환경(HOME·PATH만 전달)에서도 동작했고,
1536×1024 한 장에 73–101초 걸렸다. 유료 API 키는 필요 없다.

**해결:** BMP 헤더 54–69바이트의 R·G·B·A 채널 마스크를 읽고 흰 종이 위에 합성한 밝기(`255 − (255 − lum) × a/255`)로 계산한다.
PAM(`P7 … TUPLTYPE RGB_ALPHA`)으로 쓰면 `cwebp`가 알파를 그대로 WebP로 옮긴다(왕복 검증 완료).
불투명본이 필요하면 `cwebp -blend_alpha 0xffffff -noalpha`로 흰 바탕에 합성한다.
크롬은 `file://` 페이지의 CSS `mask-image`를 막으므로 미리보기는 로컬 HTTP로 띄운다.

## OPS-077 — `wrangler pages` 새 프로젝트는 `--force`가 필요하고, `pages deploy`는 점 폴더(`.gstack`)까지 올린다

`측정 2026-09-19 · wrangler 4.134.0, Cloudflare Pages, gstack browse`

**증상 1:** `wrangler pages project create <name> --production-branch main`이 `Delegating to the latest version of Cloudflare Pages, now part of Cloudflare Workers`를 출력한 뒤
`Missing entry-point to Worker script or to assets directory`로 실패하고 아무것도 만들지 않는다.
**해결:** 한 번만 `--force`를 붙여 만든다(`pages project create <name> --production-branch main --force`). 프로젝트가 생긴 뒤의
`pages deploy`는 위임되지 않으므로 `--force`가 다시 필요 없다.

**증상 2:** `wrangler pages deploy <dir>`이 파일 수를 예상보다 많이 올렸다. gstack `browse`를 그 폴더에서 실행하면 현재 폴더에
`.gstack/`(`browse.json`의 로컬 서버 토큰, 콘솔·네트워크 로그)을 만든다. `pages deploy`는 점으로 시작하는 폴더도 제외하지 않고 공개한다.
배포를 삭제해도 같은 경로의 응답이 한동안 엣지 캐시에 남았다(쿼리를 붙이면 새 배포가 보였다).
**해결:** 배포는 필요한 파일만 복사한 별도 폴더에서 한다. 올린 뒤 `Uploaded N files`의 N이 예상과 같은지 확인한다. 이미 올렸다면
깨끗한 폴더로 재배포하고 `pages deployment delete <id> --force`로 이전 배포를 지우고, 노출된 토큰의 프로세스를 끝내 무효로 만든다.
삭제한 파일은 `cache-control: public, s-maxage=604800`(7일)로 엣지에 남아 `cf-cache-status: HIT`가 계속됐다. **같은 경로에 빈 내용(`{}`)의 파일을 넣어 재배포하자
15초 안에 새 내용으로 바뀌었다.** 파일을 빼는 배포는 캐시를 비우지 않고, 같은 경로를 덮어쓰는 배포는 비운다.

## OPS-078 — Dokploy API의 조회 프로시저는 tRPC `input=`이 아니라 평범한 쿼리 파라미터를 받는다. raw compose는 `dockerfile_inline` 빌드가 된다

`측정 2026-09-18 · Dokploy v0.30.2 (misa), docker compose v2`

**증상:** `curl -G https://<dokploy>/api/compose.one --data-urlencode 'input={"composeId":"..."}'`가 400이다:
`fieldErrors: {"composeId": ["Invalid input: expected string, received undefined"]}`. tRPC 관례대로
`input`에 JSON을 넣으면 서버가 읽지 못한다. `project.one`도 같다.

**해결:** GET 프로시저는 필드를 쿼리 파라미터로 바로 넘긴다 — `GET /api/compose.one?composeId=<id>`,
헤더는 `x-api-key`. POST 프로시저(`project.create`·`compose.create`·`compose.update`·`domain.create`·
`compose.deploy`)는 JSON 본문 그대로다. 새 프로젝트는 이 순서로 첫 시도에 떴다:

```sh
POST project.create  {"name":..}                      # 응답에 기본 environment.environmentId가 같이 온다
POST compose.create  {"name":..,"environmentId":..,"composeType":"docker-compose","appName":"x"}  # appName 뒤에 -abc123이 붙는다
POST compose.update  {"composeId":..,"sourceType":"raw","composeFile":"<yaml>","env":"K=V\n..."}
POST domain.create   {"host":..,"port":..,"https":true,"certificateType":"letsencrypt","composeId":..,"serviceName":..,"domainType":"compose"}
POST compose.deploy  {"composeId":..}                 # 약 40초 뒤 healthy, 인증서까지 발급
```

공식 이미지가 없는 단일 바이너리(PocketBase 등)는 git 저장소 없이도 raw compose 안에서 빌드된다 —
`build: {context: ., dockerfile_inline: |  FROM alpine ... RUN wget ... && sha256sum -c -}`. 컨테이너 이름은
`<appName>-<서비스>-1`이라 `docker ps --filter name=<appName 접두>`로 찾는다.

## OPS-079 — misa 호스트에는 rsync가 없다: 파일 동기화는 tar 스트림으로, 바인드 마운트한 폴더는 교체 후 컨테이너를 재시작한다

`측정 2026-09-18 · misa(Ubuntu, Dokploy), macOS bsdtar`

**증상:** `rsync -r dir misa:path/`가 `bash: line 1: rsync: command not found` / `rsync error: unexpected
end of file`로 바로 실패한다. 원격에 rsync 바이너리가 없어서다. macOS `tar`로 대신 보내면 원격 GNU tar가
`Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.com.apple.provenance'` 경고를 파일마다 찍는다.

**해결:** `COPYFILE_DISABLE=1 tar --no-xattrs -czf - <폴더> | ssh misa 'cd <대상> && rm -rf <폴더> && tar -xzf -'`.
`--no-xattrs`가 경고를 없앤다. 그 폴더가 실행 중인 컨테이너에 바인드 마운트되어 있으면 `rm -rf` 뒤 새로 만든
디렉터리는 **다른 inode**라 컨테이너에는 **지워진 빈 디렉터리**가 보인다 — 실측: `docker run -v /tmp/bm/d:/m`
뒤 호스트에서 `rm -rf d && mkdir d && echo new > d/f`를 하자 컨테이너의 `ls /m`은 비어 있고 `cat /m/f`는
`No such file`이었다. 파일 감시로 핫 리로드하는 앱(PocketBase `--hooksWatch` 등)도 변화를 못 본다.
동기화 뒤 `docker restart <컨테이너>`로 마운트를 다시 잡는다(재시작 후 새 파일이 보이는 것 확인. misa 유저는
`docker` 그룹이라 sudo 없이 된다).

## OPS-080 — PocketBase 부트 훅에서 관리자 계정에 `setPassword`를 매번 호출하면 재시작마다 그 계정의 모든 세션 토큰이 무효가 된다

`측정 2026-09-18 · PocketBase 0.40.4 (JSVM 훅), Dokploy`

**증상:** 관리자 계정으로 받은 토큰이 멀쩡히 쓰이다가 갑자기 `401 "The request requires valid record authorization
token."`을 낸다. 앱은 시작할 때 `authRefresh`가 실패해 조용히 로그아웃되고, 목록 API는 에러 없이 `totalItems: 0`을
돌려줘서(목록 규칙이 비로그인을 걸러냄) 데이터가 사라진 것처럼 보인다. 같은 세션에서 두 번 겪었고, 두 번 다
컨테이너 재시작 직후였다(`docker ps`의 `Up N minutes`와 시각이 맞음).

`onBootstrap`에서 환경 변수의 관리자 비밀번호로 `admin.setPassword(password); e.app.save(admin)`을 매번 실행하고
있었다. 비밀번호 필드를 새로 쓰면 레코드의 `tokenKey`가 바뀌고, 기존 토큰은 서명 키가 달라 전부 무효가 된다
(값이 같은 비밀번호여도 마찬가지). 여러 세션이 훅을 자주 배포하는 개발 서버에서는 관리자가 계속 튕긴다.

**해결:** 계정을 새로 만들 때만 비밀번호를 설정하거나, `admin.validatePassword(password)`가 false일 때만
`setPassword`를 호출한다. 테스트 스크립트는 401을 받으면 다시 로그인하도록 짠다.

## OPS-081 — Flutter `setState(() => _future = load())`는 debug에서 assert로 던지고 화면을 다시 그리지 않는다. 웹 콘솔에는 에러가 안 찍힌다

`측정 2026-09-18 · Flutter 3.38.5, web debug 빌드(CanvasKit), headless Chromium`

**증상:** "다시 불러오기" 버튼이나 저장 뒤 reload를 호출하면 네트워크 탭에는 새 GET이 200으로 찍히는데 화면은 옛
데이터 그대로다. 같은 reload가 어떤 화면에서는 되고(부모가 같은 프레임에 `setState`를 따로 부르는 곳) 어떤
화면에서는 안 된다. 브라우저 콘솔에는 아무 에러도 없다.

화살표 함수 `() => _future = load()`는 대입식의 값, 즉 **Future를 반환**한다. debug 모드의 `setState`는 콜백을 먼저
실행한 뒤 반환값이 Future면 `setState() callback argument returned a Future.` assert를 던지고, `markNeedsBuild()`까지
가지 못한다. `_future`는 이미 바뀌었으니 다른 이유로 다시 빌드될 때만 새 데이터가 보인다. 호출한 쪽이 async
`onPressed`라 예외는 그 Future 안에서 끝나고, 호출 뒤의 코드(스낵바 등)도 실행되지 않는다. release 빌드는 assert가
빠져 정상 동작하므로 debug에서만 보인다.

**해결:** 블록 본문으로 쓴다: `setState(() { _future = load(); });`. 진단할 때는 reload 호출 바로 뒤에 `debugPrint`를
넣어 보면 찍히지 않는 것으로 바로 드러난다.

## OPS-082 — Flutter 웹을 gstack browse로 조작할 때: 입력은 한 칸씩 밀리고 `fill`은 먹지 않는다. 로그인은 localStorage 주입으로 건너뛴다

`측정 2026-09-18 · Flutter 3.38.5 web(release, CanvasKit), gstack browse(headless Chromium)`

**증상:** 처음 스냅샷에는 `[button] "Enable accessibility"` 하나만 보인다. Flutter 캔버스라 의미 트리가 꺼져 있어서다.
`js "document.querySelector('flt-semantics-placeholder')?.click()"`로 켜면 textbox·button ref가 나온다. 그런데
`click @텍스트칸` 뒤 곧바로 `type`을 하면 글자가 **직전에 포커스된 칸**에 들어간다. 이름·전화·이메일·주소를
차례로 넣자 전화 칸에 이메일, 이메일 칸에 주소가 들어갔다(두 번 재현, 클릭과 입력 사이 0.7초를 둬도 같음).
`fill @ref`는 "Filled"라고 답하지만 화면 값은 바뀌지 않았다.

**해결:** 폼 입력 검증은 Flutter 위젯 테스트(`tester.enterText`)에 맡기고, 브라우저로는 화면 렌더링과 실제 API
응답만 확인한다. 로그인 상태가 필요하면 API로 토큰을 받아 `shared_preferences` 저장소에 직접 넣는다. 키는
`flutter.<키>`이고 **값은 JSON 문자열을 한 번 더 JSON 인코딩한 것**이어야 한다. 객체를 그대로 넣으면
`prefs.getString`이 타입 오류를 던진다. `main()`에서 그 값을 읽는 앱은 에러 로그 없이 **스플래시 화면에서 멈춘다**(실측).
앱 쪽에서도 저장값 읽기를 try/catch로 감싸 두면 사용자가 같은 상태에 빠지지 않는다.

```sh
V=$(curl -s .../auth-with-password ... | python3 -c "import json,sys;d=json.load(sys.stdin);print(json.dumps(json.dumps(json.dumps({'token':d['token'],'model':d['record']}))))")
$B js "localStorage.setItem('flutter.pb_auth', $V)"; $B goto <앱 주소>
```

## OPS-083 — PocketBase 0.40 `onRecordAuthWithOAuth2Request`의 `e.createData`는 기본이 null이다: 키를 넣으면 신규 OAuth 가입이 전부 실패한다

`측정 2026-09-18 · PocketBase 0.40.4 JSVM, Google OAuth2`

**증상:** 신규 사용자 기본값을 넣으려고 훅에서 `e.createData["role"] = "partner"`를 썼다. 기존 사용자는 로그인되지만
**처음 가입하는 Google 계정은 모두 400**이 났다. 응답은 `"Something went wrong while processing your request."`뿐이고
`details`도 비어 있다. 원인은 `/api/logs`(level>0)의 `data.error`에만 남는다:
`TypeError: Cannot convert undefined or null to object at /pb.js:4:17(14)`.
클라이언트가 `createData`를 보내지 않으면 이 필드는 Go의 nil 맵이고, JS에서는 null이다.

**해결:** 객체를 통째로 다시 넣는다.

```js
onRecordAuthWithOAuth2Request((e) => {
  if (e.isNewRecord) {
    e.createData = Object.assign({}, e.createData || {}, { role: "partner" });
  }
  e.next();
}, "users");
```

실측으로 이 수정 뒤 실제 Google 계정의 첫 가입이 통과했다(`role`·`gift_code` 저장, `mappedFields.name`으로 이름 채움).
같이 필요했던 설정: 신규 OAuth 레코드 생성은 컬렉션 `createRule`을 탄다. 일반 가입은 막고 OAuth만 열려면
`createRule = '@request.context = "oauth2"'`로 둔다.

## OPS-084 — Google 인증 플랫폼(2026 콘솔)은 브랜딩의 홈페이지·개인정보처리방침·약관 URL과 승인 도메인이 다 차야 "앱 게시"가 켜진다

`측정 2026-09-18 · Google Cloud Console, Google 인증 플랫폼(구 OAuth 동의 화면)`

**증상:** 새 프로젝트에서 브랜딩(앱 이름·지원 이메일)·대상(외부)·연락처까지 만들고 OAuth 웹 클라이언트를 만들어도
"대상" 페이지의 **앱 게시 버튼이 비활성**이다. 안내 문구는 "앱을 게시하려면 브랜딩 페이지에서 구성을 완료해야 합니다" 한 줄뿐이다.
게시 상태가 '테스트 중'이면 테스트 사용자로 등록한 계정만 로그인된다.

**해결:** 브랜딩 페이지에서 **애플리케이션 홈페이지, 개인정보처리방침 링크, 서비스 약관 링크, 승인된 도메인** 네 칸을 채우고
저장하면 버튼이 켜진다. 로고는 넣지 않았다(로고를 넣으면 브랜드 인증 심사 대상이 된다). email·profile·openid 범위만 쓰면
게시 후 바로 "프로덕션 단계"가 되고 심사 없이 모든 Google 계정이 로그인된다.
생성 마법사 마지막의 "사용자 데이터 정책 동의" 체크박스는 접근성 트리에 나타나지 않아서, 자동화에서는
`input[type=checkbox]`를 직접 클릭해야 했다.

## OPS-085 — misa에는 crontab도 없다: 정기 작업은 compose 사이드카의 busybox `crond`로 돌린다 (rclone → Google Drive 백업 예)

`측정 2026-09-18 · misa(Ubuntu, Dokploy), rclone/rclone:1.71 이미지, Google Drive`

**증상:** `ssh misa 'which crontab rclone unzip'`가 아무것도 출력하지 않는다. 호스트에 cron 설치를 하려면 sudo와
공유 호스트 변경이 필요하다.

**해결:** 같은 compose에 사이드카를 붙인다. `rclone/rclone` 이미지는 alpine이라 busybox `crond`가 들어 있다.

```yaml
backup:
  image: rclone/rclone:1.71
  entrypoint: ["/bin/sh", "-ec"]
  command:
    - |
      echo "0 9 * * * /backup/upload.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
      exec crond -f -l 8
  environment: { RCLONE_CONFIG: /config/rclone.conf }
  volumes: [ "pb_data:/pb_data:ro", "/home/<user>/app/backup:/backup:ro", "/home/<user>/app/rclone:/config" ]
```

- `>> /proc/1/fd/1`로 보내면 작업 출력이 `docker logs`에 남는다.
- 시계는 UTC다(이미지에 tzdata가 없다).
- rclone.conf 디렉터리는 **쓰기 가능하게** 마운트한다. 갱신된 OAuth 토큰을 rclone이 그 파일에 다시 쓰기 때문이다.

Drive 인증은 맥에서 `rclone authorize drive <client_id> <secret> --auth-no-open-browser`로 받는다(데스크톱 유형 OAuth 클라이언트,
Drive API 사용 설정). 출력된 `http://127.0.0.1:53682/auth?...`를 같은 맥의 브라우저로 열어 계정을 고르면 토큰 JSON이 나온다.

- **scope:** 사용자가 **직접 만든 폴더**에 올리려면 scope가 `drive`여야 한다. `drive.file`은 앱이 만든 파일만 보여서 그 폴더를 찾지 못한다.
- **보관 기간 삭제:** 날짜 폴더(`YYYY-MM-DD`)를 문자열로 비교하고 `rclone purge`로 지운다.
- **검증:** 가짜 옛 폴더를 넣고 스크립트를 돌려 삭제되는 것까지 확인했다.

## OPS-086 — Flutter release APK에는 INTERNET 권한이 없다: 폰에서만 모든 요청이 "서버에 연결할 수 없음"(status 0)으로 실패한다

`측정 2026-09-18 · Flutter 3.38.5, Android release APK, PocketBase Dart SDK 0.25.1`

**증상:** 웹과 `flutter run`(debug)에서는 잘 되는 앱이 `flutter build apk --release`로 설치하면 첫 API 호출부터 실패한다.
PocketBase SDK는 이를 `ClientException(statusCode: 0)`으로 돌려주고 앱은 "Can't reach the server"를 띄운다.
서버 로그에는 그 폰의 요청이 **한 건도 없다** — 요청이 폰을 떠나지 않았다는 신호다.

**원인:** Flutter 템플릿은 `android.permission.INTERNET`을 `android/app/src/debug/`와 `profile/`의 매니페스트에만 넣는다.
`src/main/AndroidManifest.xml`에는 없어서 release 빌드만 권한이 빠진다.

**해결:** `src/main/AndroidManifest.xml`의 `<manifest>` 바로 아래에 `<uses-permission android:name="android.permission.INTERNET"/>`.
외부 브라우저로 URL을 여는 `url_launcher`를 쓰면 Android 11+용 `<queries>`에 `VIEW`+`https` intent도 추가한다.
원인이 모호한 status 0은 SDK의 `originalError`를 오류 문구에 붙여 두면 다음 보고에서 바로 가려진다.

## OPS-087 — 네이티브 앱의 OAuth 리디렉트 URI를 새로 등록할 수 없을 때: 이미 등록된 웹 콜백이 PocketBase `/api/oauth2-redirect`로 넘겨주게 한다

`측정 2026-09-18 · PocketBase 0.40.4 + Dart SDK 0.25.1, Google OAuth, Flutter web + Android`

**증상:** SDK의 `authWithOAuth2`는 redirect_uri로 `<pb>/api/oauth2-redirect`를 쓰므로 Google 콘솔에 그 주소가 없으면
"액세스 차단됨: 이 앱의 요청이 잘못되었습니다"(`redirect_uri_mismatch`)가 뜬다. 콘솔 자동화도 막혀 있었다:
Chrome에서 가져온 Google 쿠키로 콘솔을 한 번 쓰고 나자, 이후에는 계정이 모두 "Signed out"이 되고
"This browser or app may not be secure"로 로그인이 거부됐다(복사한 세션이 무효화됨).

**해결:** SDK 흐름을 그대로 따라 하되 redirect만 이미 등록된 웹 콜백(`https://<web>/auth/callback`)으로 바꾼다.

1. 앱: `RealtimeService(pb)`로 `@oauth2`를 구독한다. `state`를 그 `realtime.clientId`로 바꾼 authURL을 외부 브라우저로 연다.
   메시지가 오면 `authWithOAuth2Code(provider, code, verifier, '<web>/auth/callback')`를 부른다.
2. 웹의 `/auth/callback`: 그 브라우저에서 시작한 흐름이 아니면(로컬 `state` 불일치)
   `<pb>/api/oauth2-redirect?code=…&state=…`로 넘긴다. PocketBase는 state와 같은 clientId를 가진 구독자에게
   code를 보내고 자체 완료 페이지(`/_/#/auth/oauth2-redirect-success`)를 보여 준다.

실측: 구독한 clientId로 `<web>/auth/callback?code=FAKE&state=<clientId>`를 열자 구독자가
`{state, code: FAKE}`를 받았다. 토큰 교환의 redirect_uri는 authorize 때와 같은 웹 콜백이므로 Google 쪽 추가 등록이 필요 없다.

**정정 (같은 날 실측):** 위 realtime 중계는 **Android 실기기에서 실패했다**. 외부 브라우저가 앞에 오면 앱이 멈추면서
SSE 연결이 끊긴다. PocketBase의 oauth2-redirect는 state와 같은 clientId를 찾지 못하고
"Auth failed. You can close this window…"를 띄웠다. 앱으로 돌아오면 SDK가 **새 clientId**로 다시 연결하므로
그 code는 영영 전달되지 않는다. 데스크톱 Dart에서는 연결이 유지되어 성공했기 때문에 이 차이가 안 보였다.
동작하는 방식은 **서버 보관 + 폴링**이다.

1. 앱이 무작위 state(32바이트 base64url)를 만든다.
2. 웹 콜백이 `{state, code}`를 서버에 저장한다(15분 후 삭제, 한 번 읽으면 삭제).
3. 앱이 2초마다 폴링해서 code를 가져가 `authWithOAuth2Code`로 교환한다. code는 PKCE verifier가 없으면 쓸 수 없고, verifier는 앱에만 있다.
4. 웹 페이지에는 "앱으로 돌아가기" 버튼(`intent://…#Intent;scheme=<앱 스킴>;package=<패키지>;end`)을 둔다.

## OPS-088 — Hugo 다국어로 바꾸면 `/sitemap.xml`이 sitemapindex가 되고 `/ko/`에 리다이렉트 페이지가 생긴다

`측정 2026-09-19 · Hugo 0.166.0`

**증상:** `defaultContentLanguage = "ko"`, `defaultContentLanguageInSubdir = false`로 `[languages.en]`을 추가하자
`/sitemap.xml`이 `<urlset>`이 아니라 `<sitemapindex>`가 되고, 실제 목록은 `/ko/sitemap.xml`과 `/en/sitemap.xml`로 옮겨졌다.
`public/ko/index.html`에는 `/`로 가는 meta refresh 페이지가 생긴다. `</urlset>` 앞에 항목을 끼워 넣던 후처리(Worker 등)는
오류 없이 아무것도 추가하지 않게 된다. 정적 페이지 검사기는 `/ko/index.html`을 main 없는 페이지로 보고 실패한다.

**해결:** 후처리 대상을 `/ko/sitemap.xml`·`/en/sitemap.xml`로 바꾸고, 검사기에서 `http-equiv="refresh"` 페이지는 건너뛴다.
번역 연결은 파일 이름 규칙(`about.md` ↔ `about.en.md`)으로 되며, `.Translations`/`.AllTranslations`로 hreflang과 언어 전환 링크를 만든다.

## OPS-089 — YouVersion 장 API의 World English Bible은 버전 206, 저작권 문구는 "PUBLIC DOMAIN (not copyrighted)"

`측정 2026-09-19 · nodejs.bible.com/api/bible/chapter/3.1`

`https://nodejs.bible.com/api/bible/chapter/3.1?id=206&reference=MIC.6`은 `reference.version_id: 206`,
`reference.human: "Micah 6"`, `copyright.text: "PUBLIC DOMAIN (not copyrighted)"`를 돌려준다. 본문 HTML 구조는 KLB(86)와 같아
`span.verse[data-usfm]`로 절을 뽑을 수 있다. 이 역본은 하나님의 이름을 "Yahweh"로 옮긴다.
Bible.com 링크 형식은 `https://www.bible.com/bible/206/MIC.6.8.WEB`.

## OPS-090 — 기관 이름과 똑같은 도메인이 파킹 페이지일 수 있다. 200 응답만으로 공식 사이트로 확정하지 않는다

`측정 2026-09-19 · curl 8.7.1`

**증상:** `https://www.palisadesparklibrary.org/`는 `curl -sL`에 HTTP 200을 돌려주지만 본문은
`<script>window.onload=function(){window.location.href="/lander"}</script>` 한 줄뿐이다. 파킹 업자가 잡아둔 도메인이고
실제 도서관 공식 사이트는 `https://www.palparklibrary.org/`다. 상태 코드만 확인하는 링크 검사와
HTML을 안 보고 URL만 인용하는 작업은 이 차이를 놓친다.

**해결:** 기관 URL을 인용하기 전에 본문 길이와 텍스트를 함께 본다. 100~500바이트에 `lander`·`window.location` 리디렉트만
있으면 파킹이다. 도메인을 추측하지 말고 검색으로 공식 주소를 먼저 확인한다.

## OPS-091 — Imperva(Incapsula) 뒤의 사이트는 curl·WebFetch에 본문 대신 incident ID를 준다. 검색 스니펫으로 우회한다

`측정 2026-09-19 · nypl.org`

**증상:** `https://www.nypl.org/help/library-card`는 브라우저에서는 열리지만 curl(User-Agent를 Chrome으로 바꿔도)에는
`Request unsuccessful. Incapsula incident ID: 1591000770297314089-...` 959바이트만 온다. WebFetch는 같은 페이지에 대해
"웹 페이지 내용이 비어 있다"고 답한다 — 도구가 실패했다고 알려주는 게 아니라 빈 입력으로 모델을 호출하기 때문에,
모델이 "내용을 주세요"라고 되묻는 응답을 결과로 받는다. 재시도해도 같다.

**해결:** WebSearch로 그 사이트를 `allowed_domains`에 넣어 검색하면 스니펫에 본문 문장이 들어온다.
`libanswers.<기관>.org` 같은 별도 호스트의 FAQ는 보호 밖이라 WebFetch가 통하는 경우가 있다.
WebFetch 결과가 "내용이 비어 있다"는 말로 오면 그건 봇 차단 신호다.

## OPS-092 — Dokploy `application.delete` API는 서비스·파일·traefik 라우터까지 지우지만 레지스트리·SSH 키·acme.json은 남긴다

`측정 2026-09-20 · Dokploy v0.30.6 · Docker Swarm · registry:2`

**증상:** `POST /api/application.delete` + `POST /api/project.remove`(헤더 `x-api-key`)를 호출하면
Swarm 서비스·컨테이너, `/etc/dokploy/applications/<appName>/`, `/etc/dokploy/logs/<appName>/`,
`/etc/dokploy/traefik/dynamic/<appName>.yml`, DB의 `application`·`domain`·`environment`·`deployment` 행이
한 번에 사라진다. 그런데 앱을 지워도 다음 셋은 그대로 남는다.

- 사설 레지스트리(`localhost:5000`)의 이미지 리포지터리 — `_catalog`에 계속 보인다
- `ssh-key` 테이블의 배포 키 행 — 앱이 참조하던 키인데 고아로 남는다(테이블 이름이 `ssh_key`가 아니라 **`ssh-key`**)
- `/etc/dokploy/traefik/dynamic/acme.json`의 Let's Encrypt 인증서 항목

**해결:** 남은 것을 순서대로 지운다.
`POST /api/sshKey.remove {"sshKeyId":...}`로 키를 지우고,
레지스트리는 삭제 API가 꺼져 있으면(`REGISTRY_STORAGE_DELETE_ENABLED` 없음)
`rm -rf /var/lib/docker/volumes/<레지스트리볼륨>/_data/docker/registry/v2/repositories/<리포>` 후
`docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml`로 블롭을 회수한다.
GC는 매니페스트를 스캔해 참조 카운트를 세므로 다른 이미지와 공유하는 블롭은 남는다 — 실제로 다른 5개 리포의
태그·TLS 모두 무사했다.
`acme.json`은 건드리지 않는다. traefik이 실행 중에 이 파일을 다시 쓰기 때문에 손으로 고치면 **같은 파일에 든
다른 도메인 인증서까지 깨질 수 있고**, 재발급은 Let's Encrypt 속도 제한에 걸린다. 라우터가 사라진 뒤에는
갱신되지 않고 만료될 뿐이라 남겨도 서빙에 영향이 없다.

**곁가지:** `sshKey.remove` 응답은 **개인 키 원문을 그대로 돌려준다.** 터미널 로그·전사(transcript)에 남으므로
지운 뒤에도 GitHub 쪽 deploy key를 따로 제거하는 것까지 해야 실제로 폐기된 것이다.

## OPS-093 — wrangler OAuth 토큰에는 DNS 권한이 없다. 기존 DNS 레코드가 있는 호스트네임은 Custom Domain 부착이 거부된다

`측정 2026-09-20 · wrangler 4.135.0, Cloudflare Workers`

**증상:** `wrangler.jsonc`에 `"routes": [{ "pattern": "example.com", "custom_domain": true }]`를 넣고 `wrangler deploy`하면
스크립트 업로드는 성공하는데 트리거 설정에서 실패한다:

```
Trigger configuration for "<worker>" was only partially updated:
  Custom domains:
    - A request to the Cloudflare API (/accounts/<id>/workers/scripts/<worker>/domains/records) failed.
      - Hostname 'example.com' already has externally managed DNS records (A, CNAME, etc).
        Delete them first or try a different hostname. [code: 100117]
  Successful trigger changes were not rolled back.
```

**해결:** 해당 호스트네임의 기존 A/CNAME 레코드를 먼저 지운다. wrangler는 부착 시 DNS 레코드를 스스로 만들기 때문에
빈 상태여야 한다. `--force` 같은 우회 옵션은 없다. 대시보드의 Workers → Settings → Domains & Routes → Add Custom Domain
경로는 기존 레코드를 덮어쓸지 묻는 단계가 있어 삭제 없이도 붙는다.

**같이 확인한 것:** `wrangler login`이 받는 OAuth 토큰에는 DNS 스코프가 아예 없다(`wrangler login --scopes-list` 전체 목록에
`zone:read`만 있고 `dns_records`는 없다). 그래서 CLI 세션만으로는 레코드 조회도 삭제도 못 한다 —
`GET /zones/<id>/dns_records`가 `{"code":10000,"message":"Authentication error"}`로 막힌다.
DNS를 건드리려면 대시보드의 **Edit zone DNS** 템플릿으로 별도 API 토큰을 만들어야 한다.

**우회(DNS를 못 건드릴 때):** Custom Domain 대신 **Zone Route**를 쓴다. 기존 레코드가 프록시(주황 구름) 상태면
그 호스트로 오는 요청을 워커가 먼저 가로채므로, 레코드를 지우지 않고도 사이트를 갈아끼울 수 있다.
필요한 권한은 `workers_routes:write` 하나이고 wrangler OAuth에 이미 들어 있다.

```jsonc
"routes": [
  { "pattern": "example.com/*", "zone_name": "example.com" },
  { "pattern": "www.example.com/*", "zone_name": "example.com" }
]
```

`workers/domains` API에 `override_existing_dns_record: true`·`override_existing_origin: true`를 넣어도 100117은 그대로다
(대시보드의 덮어쓰기 흐름은 DNS API를 따로 호출하는 것이라 토큰 권한이 같이 필요하다). Route로 붙인 뒤 첫 응답이
옛 사이트면 엣지 캐시다 — 쿼리를 붙여 확인하고, 같은 경로를 덮어쓰는 배포가 캐시를 비운다(OPS-077).

**부수 효과:** `routes`가 설정된 배포는 `workers.dev` 서브도메인을 끈다. 위처럼 부착이 실패하면 커스텀 도메인도
workers.dev도 없는 상태가 되어 워커에 접근할 길이 사라진다(`error code: 1042`). 미리보기 주소를 되살리려면
`POST /accounts/<id>/workers/scripts/<worker>/subdomain`에 `{"enabled":true,"previews_enabled":false}`를 보낸다.

## OPS-094 — `overseas.mofa.go.kr` RSS는 세션 쿠키 없이 307 무한 루프다. Node `fetch`는 리다이렉트에 쿠키를 다시 싣지 않는다

`측정 2026-09-20 · Node 22 fetch, curl 8.7, 재외공관 포털(overseas.mofa.go.kr)`

**증상:** 재외공관 RSS(`https://overseas.mofa.go.kr/<공관경로>/brd/rss.do?brdId=<id>`)를 `curl`로 받으면
본문 0바이트에 `307`만 돌아온다. `-L`을 붙여도, User-Agent를 브라우저 문자열로 바꿔도 같다.
Node의 `fetch`는 `redirect: 'follow'`가 기본인데도 20~30초 뒤 타임아웃으로 죽는다. 같은 주소를
헤드리스 브라우저로 열면 200에 정상 XML이 나온다 — 브라우저는 먼저 받은 세션 쿠키를 리다이렉트에 다시 싣기 때문이다.

**서버는 첫 요청에 `JSESSIONID`·`TMOSHCooKie`를 `Set-Cookie`로 주고 307로 같은 주소를 가리킨다.**
그 쿠키를 다시 보내야 200이 된다. `fetch`의 자동 리다이렉트는 쿠키 저장소가 없어서 같은 307을 영원히 반복한다.

**해결:** `redirect: 'manual'`로 직접 돌면서 `response.headers.getSetCookie()`를 모아 다음 홉의 `Cookie` 헤더로 보낸다.
`curl`은 `-c/-b`로 같은 쿠키 항아리를 쓰면 한 번에 된다.

```sh
curl -s -c jar.txt -b jar.txt -L -A "Mozilla/5.0" "https://overseas.mofa.go.kr/us-losangeles-ko/brd/rss.do?brdId=12647"
```

**같이 확인한 것:** 브라우저 내장 XML 뷰어로 보면 제목이 `二쇰줈...`처럼 깨져 보이는데 **실제 바이트는 정상 UTF-8이다**.
뷰어 표시만 깨지는 것이니 EUC-KR로 재해석하지 마라 — 재해석하면 진짜로 깨진다. 본문 링크가
`http://overseas.mofa.go.kr:443/...`(http 스킴에 443 포트)로 오므로 https로 정규화해야 한다.
자동 수집기가 비표준 포트를 거르면 전부 버려진다.

## OPS-095 — AI 에이전트로 스크랩하기 전에 robots.txt의 에이전트별 차단을 확인한다. 이름을 직접 막는 사이트가 있다

`측정 2026-09-20 · robots.txt 직접 조회`

**증상:** `Allow: /`만 보고 긁으면 차단 의사를 무시하게 된다. 실제로 AI 에이전트 이름을 지목해 막거나,
허용 목록 방식으로 사실상 전부 막는 사이트가 있다. robots.txt는 **끝까지** 읽어야 한다 —
앞부분이 특정 봇 `Allow: /` 나열이어도 맨 끝에 `User-agent: *` / `Disallow: /`가 오는 구조가 흔하다.

```
radiokorea.com    User-agent: anthropic-ai → Disallow: /   (Claude-Web·GPTBot·CCBot도 차단)
heykorean.com     Googlebot 등 허용 목록 나열 후 끝에 User-agent: * → Disallow: /
koreadaily.com    User-agent: * → Allow: /
mofa.go.kr 계열   robots.txt 없음 (규칙 없음으로 처리)
```

**해결:** 수집 대상마다 robots.txt 전문을 확인하고 **확인한 날짜와 판정 근거를 설정 파일이나 문서에 남긴다.**
`Allow: /`여도 기사 전문 복제는 별개 문제다. 제목·짧은 발췌·원문 링크까지로 제한하는 편이 안전하다.

## OPS-096 — Astro 7 `dev`가 백그라운드 데몬으로 떠 있으면 Playwright `webServer`가 "exited early"로 죽는다

`측정 2026-09-20 · Astro 7.3.3, @playwright/test 1.58`

**증상:** `npx playwright test`가 테스트를 하나도 못 돌리고 `Error: Process from config.webServer exited early.`로 끝난다.
포트는 살아 있고 브라우저로 열면 페이지가 정상이다. `reuseExistingServer: true`인데도 소용없다.

**원인:** Astro 7의 `astro dev`는 이미 데몬이 떠 있으면 **새 프로세스를 즉시 종료하고 안내 메시지만 출력한다**
(`Dev server already running at ... (pid N)`). Playwright는 `webServer.command`가 살아 있어야 한다고 보므로
그 즉시 종료를 실패로 판정한다. `reuseExistingServer`는 명령을 띄우기 전 URL을 확인하는 옵션이라
데몬이 다른 호스트 표기(`localhost` vs `127.0.0.1`)로 떠 있으면 확인에 실패하고 그냥 명령을 실행한다.

**해결:** 데몬을 쓸 거면 `E2E_BASE_URL`처럼 `webServer`를 통째로 비활성화하는 환경변수로 돌린다.
데몬을 안 쓸 거면 `npx astro dev stop`으로 먼저 내린다. `lsof -ti:<port> | xargs kill -9`만으로는
데몬 상태 파일이 남아 다음 `astro dev`가 또 즉시 종료된다.

```sh
npx astro dev stop                                  # 또는
E2E_BASE_URL=http://127.0.0.1:4321 npx playwright test
```

---

## OPS-097 — Gmail로 포워딩되는 주소를 **같은 Gmail 계정에서** 보내 테스트하면 받은편지함에 절대 안 뜬다. Cloudflare 로그는 "전달됨"이다

`측정 2026-09-20 · Cloudflare Email Routing · Gmail 웹`

**증상:** `contact@<도메인>` → Gmail A로 라우팅을 걸고 **Gmail A에서** `contact@`로 테스트를 2통 보냈다.
Gmail A 받은편지함에 아무것도 안 온다. Cloudflare 활동 로그에는 2통 모두 `전달됨`, SPF pass · DKIM pass ·
ARC pass · DMARC none, 동작 `전달`. 설정(MX·규칙·대상 주소 인증)은 전부 정상이었다.

Gmail은 이미 보낸편지함에 있는 것과 같은 Message-ID의 수신본을 받은편지함에 따로 보여주지 않는다.
Cloudflare도 이 경우를 안다 — 몇 분 뒤 `noreply@email.cloudflare.net`이
"Cloudflare Email Routing: Missing email from A to contact@...?" 제목으로 "같은 계정에서 보낸 메일은
받은편지함에 안 나타날 수 있다, 다른 주소에서 테스트하라"는 안내를 **자동으로 보낸다.**
그런데 이 안내 메일 자체가 Gmail 스팸함으로 들어가서 아무도 못 봤다.

**해결:** 라우팅 테스트는 **목적지와 다른 계정**에서 보낸다. 이 dedup은 필터로 우회되지 않는다.
테스트 전에 `in:spam noreply@email.cloudflare.net`을 한 번 검색하면 Cloudflare 안내가 먼저 와 있을 수 있다.

---

## OPS-098 — Cloudflare Email Routing 활동 로그는 몇 분 늦게 뜬다. "로그에 없음"을 "도달 안 함"으로 판정하지 마라

`측정 2026-09-20 · Cloudflare 대시보드 (이메일 서비스 > 이메일 라우팅)`

**증상:** 다른 계정에서 테스트를 보냈다는 연락을 받고 바로 활동 로그를 새로고침했는데 새 항목이 없었다.
MX가 틀렸나, 발신 쪽에서 막혔나를 의심하기 시작했다. 2~3분 뒤 새로고침하니 `3분 전 · 전달됨`으로 떴다.

대시보드 개요 화면에 적힌 문구는 "메트릭 및 로그가 대시보드에 표시되기까지 **최대 2분**". 실측은 그보다
조금 길었다. 같은 순간 대시보드의 **Ask AI는 "거의 실시간이다, 안 보이면 도달하지 않은 것"이라고 답했고
그 판단은 틀렸다.** 원인 후보로 MX 캐시·Gmail 발송 차단·SMTP 거부를 줄줄이 내놓았는데 전부 무관했다.

**해결:** 로그가 비어 있으면 **3~5분 기다렸다가** 다시 본다. 그 전에 DNS·발신 측을 파지 않는다.

---

## OPS-099 — Cloudflare "전달됨"은 Gmail SMTP가 수락했다는 뜻까지다. 포워딩 메일은 스팸함으로 간다 — 도메인 단위 Gmail 필터로 막는다

`측정 2026-09-20 · Cloudflare Email Routing · Gmail 웹`

**증상:** 다른 Gmail 계정 B에서 `contact@<도메인>`으로 보낸 테스트가 Cloudflare에서 `전달됨`(SPF·DKIM·ARC
pass)인데 목적지 Gmail A 받은편지함에 없다. `in:anywhere from:B`는 0건(검색어의 점 처리 차이로 추정),
`in:anywhere <도메인>`으로 찾으니 **스팸함**에 있었다. Gmail이 붙인 사유는
"이전에 스팸으로 확인된 메일과 유사합니다". 필터도 차단 목록도 원인이 아니었다(둘 다 확인).

**해결:**
1. 스팸 해제 — Gmail이 "앞으로 이 발신자가 보내는 메일은 받은편지함으로"라고 안내하지만 **발신자 단위**다.
제3자 문의는 다시 스팸으로 갈 수 있다.
2. 도메인 단위 필터: 조건 `to:(@<도메인>)`, 작업 `라벨 적용` + `절대 스팸으로 신고하지 않음`.
`contact@`만 걸면 catch-all로 들어오는 다른 주소(OPS-100)가 빠진다.
3. Gmail 안내 그대로: **스팸함·휴지통에 이미 있는 과거 메일에는 필터가 적용되지 않는다.** 과거분은
`in:anywhere to:<도메인>`으로 찾아 손으로 옮긴다.

---

## OPS-100 — Email Routing의 catch-all 규칙은 처음에 "삭제 · 비활성화"로 만들어져 있다

`측정 2026-09-20 · Cloudflare Email Routing (도메인 2개에서 동일)`

**사실:** Email Routing을 켠 도메인 두 곳 모두 라우팅 규칙 목록에 `전체 수신` 규칙이 상단 고정으로 이미
있었고, 동작은 `삭제`, 상태는 `비활성화됨`이었다. 즉 개별 규칙(`contact@`)에 안 맞는 주소 —
`info@`·`support@`·오타 — 는 전달되지 않는다.

비활성 catch-all에서 불일치 주소가 **반송(550 5.1.1 Address does not exist)되는지 조용히 버려지는지는
직접 재지 않았다** — 커뮤니티 보고는 반송 쪽이다(확인 필요). 어느 쪽이든 수신자는 못 받는다.

**해결:** 불특정 다수가 메일을 보내는 사이트면 catch-all을 켠다 — 편집에서 동작을 `이메일로 전송` +
대상 주소로 바꾼 **뒤에** 토글을 켠다(동작이 `삭제`인 채로 켜면 전부 버린다). 스팸 유입이 늘면 토글만
끄면 되고, 그때 실제 쓰는 주소는 개별 규칙으로 남긴다. Gmail 쪽은 OPS-099의 도메인 단위 필터와 짝이다.

---

## OPS-101 — Email Routing이 "동기화 중"에서 멈춰 있으면 DNS 레코드가 안 들어간 것이다. 설정 탭의 "누락된 레코드 추가"를 누른다

`측정 2026-09-20 · Cloudflare Email Routing`

**증상:** 개요의 구성 요약이 `라우팅 상태: 동기화 중`, `DNS 레코드: 구성되지 않음`. 기다려도 안 바뀐다.
그 도메인의 DNS 레코드 목록에는 Worker 레코드 하나뿐, MX가 없었다(예전에 Email Routing을 켜다 만 흔적).

설정 탭 → DNS 레코드에 필요한 5개가 전부 `누락`으로 표시된다: MX 3개(`route1/2/3.mx.cloudflare.net`),
DKIM TXT `cf2024-1._domainkey.<도메인>`, SPF TXT `v=spf1 include:_spf.mx.cloudflare.net ~all`.

**해결:** 같은 화면의 **`누락된 레코드 추가`** 버튼 한 번. MX 3개와 DKIM은 `잠김`, SPF는 `잠금 해제` 상태로
들어간다. 켜기 전에 DNS 목록에 **다른 MX가 없는지** 먼저 본다 — 기존 메일 호스팅이 있으면 이 버튼이 수신 경로를
바꾼다. 대상 주소(목적지 Gmail)는 **계정 전체 공유**라 다른 도메인에서 이미 인증했으면 다시 인증할 필요가 없다.

---

## OPS-102 — 브라우저 자동화로 Gmail 필터를 만들 때는 UI 대신 XML "필터 가져오기"를 쓴다

`측정 2026-09-20 · Claude in Chrome · Gmail 웹(한국어) · 뷰포트 753×653`

**증상:** 검색 옵션 → `필터 만들기` 뒤 뜨는 작업 패널(체크박스·라벨 드롭다운)은 **패널 바깥을 한 번이라도
클릭하면 닫히고 입력이 전부 사라진다.** 좁은 뷰포트에서 스크린샷(941×816)과 클릭 좌표계(1176×1020)가
달라, 좌표로 누른 클릭이 패널 밖에 떨어져 4번 연속 닫혔다. 요소 ref 클릭도 라벨 드롭다운에서 같은 식으로 실패했다.
Cloudflare 대시보드의 셀렉트 박스도 같은 원인으로 대화상자가 닫혔다 — 거기서는 **ref로 콤보박스를 열고
화살표 키 + Enter**로 고르면 안정적이었다.

**해결:** 필터를 XML로 쓰고 `설정 → 필터 및 차단된 주소 → 필터 가져오기`의 파일 입력에 올린다
(`file_upload` → `파일 열기` → `필터 만들기`). 라벨이 없으면 먼저 만든다 — 사이드바 `새 라벨 만들기`는
대화상자가 뜬 **뒤에** 타이핑해야 한다(뜨는 중에 친 글자는 버려졌다).

```xml
<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom' xmlns:apps='http://schemas.google.com/apps/2006'>
  <title>Mail Filters</title>
  <entry>
    <category term='filter'></category><title>Mail Filter</title><content></content>
    <apps:property name='to' value='@example.com'/>
    <apps:property name='label' value='example'/>
    <apps:property name='shouldNeverSpam' value='true'/>
  </entry>
</feed>
```

가져오기 화면이 파싱 결과(`일치: to:(@example.com) / 작업: 'example' 라벨 적용, 절대 스팸으로 신고하지 않음`)를
먼저 보여주므로 만들기 전에 검증된다.

## OPS-103 — Node fetch fails with UNABLE_TO_VERIFY_LEAF_SIGNATURE when the server omits its intermediate cert

`측정 2026-09-20 · Node 26.8 (undici fetch) · www.missyusa.com (GoDaddy G2)`

**증상:** curl과 브라우저는 정상인데 Node `fetch()`만 `TypeError: fetch failed`,
cause `code: 'UNABLE_TO_VERIFY_LEAF_SIGNATURE'`로 실패한다. `node --use-system-ca`도 같다.

서버가 leaf 인증서만 보내고 중간 인증서를 빠뜨린 경우다. 브라우저·macOS curl은 AIA URL로 중간
인증서를 받아 오지만 Node는 받지 않는다. `openssl s_client -connect HOST:443 | openssl x509 -noout -ext authorityInfoAccess`의
`CA Issuers` URL이 빠진 인증서다.

**해결:** 스크립트 시작 시 그 URL에서 DER을 받아 PEM으로 바꾸고 기본 CA에 더한다.
`tls.setDefaultCACertificates([...tls.getCACertificates('default'), pem])` — 이후 모든 `fetch`에 적용된다.
`NODE_TLS_REJECT_UNAUTHORIZED=0`은 쓰지 않는다.

---

## OPS-104 — Resend 무료 플랜의 하루 한도는 UTC 달력일로 센다. 배치 한 번은 요청 한 번이고, 기본(strict) 배치는 주소 하나만 틀려도 전부 거절된다

`측정 2026-09-24 · Resend API (문서 확인) · 무료 플랜`

**증상:** 하루 100통 한도를 "최근 24시간"으로 세면, 한국 시간 월요일 오전 8시에 보낸 주간 메일이 다음 날 오전 8시까지
예산을 잡아먹는다. 실제 Resend 한도는 그보다 먼저 풀린다.

Resend 공식 문서(knowledge-base/account-quotas-and-limits)의 원문은 이렇다. "The daily quota is a UTC calendar day
(00:00–24:00 UTC) and resets at midnight UTC. It is not a rolling 24-hour window." 한국 시간으로는 **매일 오전 9시**에
풀린다. 무료 플랜은 하루 100통·한 달 3,000통이고, 발송 데이터는 30일 동안 보관한다(모든 플랜 공통).
배치 API(`POST /emails/batch`, 최대 100통)는 속도 제한(초당 10요청)에서 **요청 1건**으로 센다.
한도 초과는 429 `daily_quota_exceeded` / `monthly_quota_exceeded`, 속도 초과는 429 `rate_limit_exceeded`다.

기본 배치 검증은 strict다. 배열의 한 항목이라도 검증에 걸리면 **배치 전체가 거절**된다.
`x-batch-validation: permissive` 헤더를 붙이면 유효한 항목만 보내고 `errors: [{index, message}]`를 돌려준다
(2025-09 변경 로그). 이때 `data`가 거절된 항목을 빼고 돌려주는지는 공식 예시로 확인하지 못했다.

**해결:** 예산은 `sent_at >= 오늘 00:00 UTC`로 센다. 한도 초과 뒤 멈춤은 다음 00:00 UTC까지다. 배치에는 permissive
헤더를 붙이고, `errors[].index`로 실패 행을 먼저 가른다. `data`가 요청과 길이가 같으면 위치로, 다르면 실패하지 않은
행에 순서대로 id를 붙인다. `Idempotency-Key`(24시간 유효)를 배치마다 붙여, 결과를 모르는 재시도가 같은 바이트로
나가게 한다.

---

## OPS-105 — Worker의 "같은 출처 + JSON만" POST 관문이 메일의 원클릭 구독 해지(RFC 8058)를 막는다

`측정 2026-09-24 · Cloudflare Workers · RFC 8058`

**증상:** CSRF를 막으려고 모든 `/api/*` POST에 `Origin`이 사이트와 같고 `content-type: application/json`일 것을
요구하면, Gmail·Yahoo가 `List-Unsubscribe-Post: List-Unsubscribe=One-Click` 헤더를 보고 보내는 해지 요청이
403/415로 떨어진다. 메일함 제공자는 `Origin` 없이 `application/x-www-form-urlencoded` 본문
`List-Unsubscribe=One-Click`만 POST한다. Gmail·Yahoo 대량 발송 규칙은 원클릭 해지를 요구한다.

**해결:** 해지 경로만 관문 **앞에서** 처리한다. 권한은 URL의 서명 토큰(구독자 id만 담고 주소는 넣지 않는다)으로
판정한다. 같은 URL의 **GET은 아무것도 바꾸지 않고** 설정 페이지로 303 한다. 링크 검사기가 GET을 미리 열어도
구독이 해지되지 않는다. 확인(더블 옵트인) 링크도 같은 이유로 GET에서 확정하지 않고, 페이지의 버튼으로 POST한다.

---

## OPS-106 — Worker의 cron 로직을 임의 시각으로 로컬 D1에 돌려 보려면 `getPlatformProxy()`로 D1 바인딩을 Node에 가져온다

`측정 2026-09-24 · wrangler 4.134.0 · Miniflare 로컬 D1`

**증상:** `wrangler dev --test-scheduled`의 `/__scheduled`는 **지금 시각**으로만 돈다. "월요일 08:00 KST에 주간 메일"
같은 로직은 실제 D1 SQL로는 확인할 수 없다. node:sqlite 테스트는 문법은 확인하지만 D1 바인딩 동작은 확인하지 못한다.

**해결:** 같은 `worker/` 디렉터리에서 Node 스크립트로 바인딩을 가져와, 스케줄 함수에 시각을 인자로 넘긴다.
`wrangler dev`가 같은 로컬 상태를 쓰는 동안에도 함께 돌았다.

```js
const { getPlatformProxy } = await import('<npx 캐시>/node_modules/wrangler/wrangler-dist/cli.js');
const { runMail } = await import('./src/mail.js');   // (env, now)를 받게 만들어 둔다
const proxy = await getPlatformProxy({ configPath: './wrangler.jsonc', persist: true });
try { console.log(await runMail({ ...proxy.env }, Date.parse('2026-09-28T08:05:00+09:00'))); }
finally { await proxy.dispose(); }
```

`.dev.vars`의 값도 `proxy.env`에 들어온다. 로컬 D1(Miniflare)은 `UPDATE … FROM json_each(?) … RETURNING`,
`WINDOW` 절이 있는 윈도 함수, `INSERT … SELECT … WHERE … ON CONFLICT DO UPDATE … WHERE`, 부분 인덱스를 받는다.
외부 메일 API는 `env`로 주소를 바꿀 수 있게 해 두고 로컬 목 서버로 돌린다.

---

## OPS-107 — PocketBase는 무효·회수된 토큰을 401이 아니라 guest로 처리한다: 쓰기 거절이 400·404로 와서 입력 오류와 구분되지 않는다

`측정 2026-09-24 · PocketBase 0.40.4`

**증상:** 레코드의 `tokenKey`가 바뀐 뒤(비밀번호 변경·관리자 교체 등) 옛 토큰으로 레코드 API를 부르면 401이 오지 않는다.
토큰을 guest로 보고 규칙을 평가하므로 create는 `400`(규칙 불통과), delete는 `404`, list는 `200 totalItems: 0`이다.
"401이면 다시 로그인" 분기는 실행되지 않고, 사용자에게는 "입력 오류"나 "빈 목록"이 보인다.

`POST /api/collections/<auth 컬렉션>/auth-refresh`는 유효한 토큰을 요구하므로 같은 토큰에 `401`을 준다.

**해결:** 쓰기가 400·404로 거절될 때만 같은 토큰으로 `auth-refresh`를 한 번 불러 401이면 만료로 처리한다.
토큰 `exp`(초 단위)는 로컬에서 먼저 확인해 네트워크 없이 걸러낸다. 폼 중복 제출은 unique 인덱스가 걸린 nonce 필드로
막는다. 두 번째 insert는 `400`이고 본문 `data.<필드>.code`가 `validation_not_unique`이므로 성공으로 취급할 수 있다.

---

## OPS-108 — PocketBase `authRule`의 서버 헤더 조건은 토큰 발급·갱신만 막는다: 발급된 토큰은 헤더 없이도 `@request.auth`만 보는 컬렉션에서 쓰인다

`측정 2026-09-24 · PocketBase 0.40.4`

**증상:** 사이트 서버만 아는 헤더(`@request.headers.x_...`)를 auth 컬렉션의 `authRule`에 넣어 "사이트를 거쳐야만
로그인된다"고 믿었다. 새 컬렉션의 규칙을 `@request.auth.collectionName = "members" && @request.auth.id != ""`로만 두자,
헤더를 붙여 받은 토큰을 헤더 없이 PocketBase에 직접 보내도 list 200, create 200, 본인 delete 204가 나왔다.
헤더 없는 `auth-with-password`·`auth-refresh`만 403이었다. 사이트의 허용 목록(초대 이메일 등)이 서버 코드에만 있으면,
목록에서 빠진 사람도 토큰 수명 동안 DB에 직접 접근한다. 쿠키에 HMAC 서명만 하고 암호화하지 않으면 본인 쿠키에서
토큰을 그대로 꺼낼 수 있다.

**해결:** 서버 전용 헤더 경계는 발급 규칙이 아니라 **모든 컬렉션의 list·view·create·update·delete 규칙**에 AND로 넣는다.
기존 컬렉션의 규칙 문자열을 읽어 복사하고(비밀값을 소스에 두지 않음), 경계가 없으면 마이그레이션을 중단한다.
적용 후 헤더 없는 요청이 list 0건, create 400, delete 404인지 확인한다.

---

## OPS-109 — Google OAuth 리디렉트 URI 등록 여부는 콘솔 없이 curl로 확인된다. 계정 선택 화면은 서브도메인이 아니라 등록 도메인만 보여 준다

`측정 2026-09-24 · Google OAuth 2.0 (웹 클라이언트, 브랜드 미인증), curl 8.7.1`

**증상:** 서비스 도메인을 `a.example.com`에서 `b.example.com`으로 옮기면 웹 로그인의 redirect_uri도 바뀐다.
콘솔에 새 URI를 넣지 않으면 로그인 직후 `Error 400: redirect_uri_mismatch`다. 콘솔 자동화가 막혀 있으면(OPS-087)
새 URI가 등록됐는지부터 알 수 없다.

**확인:** authorize URL을 브라우저 User-Agent로 `curl -sL` 하면 등록 여부가 갈린다.
등록된 URI는 `accounts.google.com/v3/signin/identifier`(200)로 끝나고, 미등록 URI는
`accounts.google.com/signin/oauth/error?authError=...`로 끝나며 본문에 `redirect_uri_mismatch`가 있다.
로그인하지 않아도 된다. 처음 302 응답은 둘 다 같으니 `-L`을 꼭 붙인다.

```sh
curl -s -L -o /tmp/g.html -w '%{url_effective}\n' -A 'Mozilla/5.0 (Macintosh) Chrome/140' \
  "https://accounts.google.com/o/oauth2/v2/auth?client_id=<id>&response_type=code&scope=email&redirect_uri=<urlencoded>"
grep -c redirect_uri_mismatch /tmp/g.html   # 0이면 등록됨
```

같은 페이지에는 `to continue to example.com`이 나온다. 브랜드 미인증 앱은 앱 이름 대신 **redirect_uri의 등록 도메인**(eTLD+1)을
보여 주고, 서브도메인은 표시하지 않는다.

**해결(새 URI를 못 넣을 때):** redirect_uri를 옛 도메인의 콜백으로 **고정**한다. 옛 도메인은 nginx에서
`return 301 https://b.example.com$request_uri;`로 경로와 쿼리를 그대로 넘긴다. 코드 교환 때도 같은 옛 URI를 보낸다
(authorize와 일치해야 한다). 사용자 화면에는 새 도메인만 남는다. 로그인 화면 표기도 도메인 이동 전과 같다.
옛 도메인의 공유 링크·QR도 같은 301로 살아난다.

---

## OPS-110 — Resend 도메인은 이제 SPF를 TXT·MX가 아니라 `send`·`rsend` CNAME 두 개로 받는다. 인증은 레코드 공개 뒤 약 30분 걸렸고, 그 전에는 API 키를 도메인으로 제한할 수 없다

`측정 2026-09-24 · Resend 대시보드 · 리전 us-east-1 · Cloudflare DNS`

**증상:** 문서와 블로그 글은 `send` 서브도메인의 SPF TXT와 MX를 넣으라고 하지만, 새 도메인 화면이 요구한 레코드는 달랐다.
DKIM TXT `resend._domainkey`(`p=MIGf…`, 216자), CNAME `send` → `send.forge.rmta.net`, CNAME `rsend` → `rsend.forge.rmta.net`
(둘 다 DNS only), 선택 항목으로 `_dmarc` TXT `v=DMARC1; p=none;`, 수신용 루트 MX `inbound-smtp.us-east-1.amazonaws.com`이다.
CNAME 끝에서 SPF TXT와 반송 MX를 Resend가 대신 관리한다.

레코드가 1.1.1.1·8.8.8.8에서 모두 보인 뒤에도 상태가 31분 동안 `pending`이었다(14:27 도메인 생성 → 14:58 verified).
`Verify DNS Records`를 다시 눌러도 빨라지지 않는다. 이 동안 API 키 만들기의 도메인 목록에는 `All domains`만 나온다.
인증된 도메인만 제한 대상으로 고를 수 있다. 도메인 추가 화면의 추적 옵션(click/open)은 추적 서브도메인이 없으면 꺼진 채로 만들어진다
(도메인 JSON `open_track:false, click_track:false`).

**해결:** 수신용 루트 MX는 **넣지 않는다.** Cloudflare Email Routing(OPS-101)을 쓰는 도메인이면 기존 수신이 깨진다.
발신만 필요하면 DKIM·CNAME 2개·DMARC만 넣는다. 발송 코드가 도메인 인증 전에 켜지지 않게 한다. 인증 전에
`from: …@<도메인>`으로 보내면 403 `validation_error`(domain not verified)가 난다. API 키는 인증을 기다렸다가 도메인으로
제한해 만드는 편이 낫다. 계정에 도메인이 하나뿐이면 `All domains`여도 범위는 같다.

---

## OPS-111 — gstack browse의 쿠키 가져오기가 `authorization denied`로 막히면 headed 창에서 사람이 로그인하게 한다. Cloudflare 대시보드 내부 API는 GET만 되고, DNS 추가는 BIND 파일 가져오기가 확실하다

`측정 2026-09-24 · gstack browse · macOS · Brave/Chrome · Cloudflare 대시보드`

**증상:** `$B cookie-import-browser brave --domain resend.com`(Chrome도 같음)이 키체인 창 없이 곧바로 `authorization denied`를 냈다.
`$B handoff` 뒤 `$B resume`은 headless로 돌아가면서 로그인이 사라졌다(다시 `/login`으로 튕김).

Cloudflare 대시보드 세션에서 `fetch('/api/v4/zones/<id>/dns_records', {headers:{'x-atok': window.bootstrap.atok,
'x-cross-site-security':'dash'}})`는 GET이면 200과 레코드 목록을 준다. 같은 헤더로 POST하면 JSON이 아니라 HTML 차단 페이지가 온다.
wrangler OAuth 토큰에는 `zone (read)`만 있어서 DNS를 쓸 수 없다.

**해결:** `$B connect`로 headed 창(프로필 `~/.gstack/chromium-profile`)을 띄우고 사람이 그 창에서 로그인하게 한 뒤 그대로 조작한다.
headed 프로필에는 로그인이 남는다. DNS는 레코드 추가 폼 대신 **Import**를 쓴다. BIND 줄(`name. 1 IN CNAME target.`,
TXT는 따옴표)을 파일로 만들어 `$B upload 'input[type=file]' <파일>`로 올리고, `Proxy imported DNS records`는 끈 채 Upload를 누른다.
"successfully imported your records"가 뜨면 GET으로 결과를 확인한다. 비밀값(API 키, `whsec_…`)은
`$B js "<값을 찾는 식>" --raw --out <umask 077 파일>`로 대화에 보이지 않게 받는다. 받은 뒤 `tr -d '\n' < 파일 | wrangler secret put`으로
넣고 파일을 지운다. 끝나면 그 프로필의 `Default/Cookies`에서 해당 host_key 행을 지워 로그인 세션을 남기지 않는다.

---

## OPS-112 — PocketBase `listRule`을 "내 것" 필터로 쓰던 앱은 관리자 권한을 OR로 붙이는 순간 남의 행까지 받는다

`측정 2026-09-24 · PocketBase 0.40.4 + Dart SDK`

**증상:** `referrals.listRule = partner = @request.auth.id || @request.auth.role = "admin"` 상태에서 앱은
`getFullList()`를 filter 없이 불러 "내 추천 목록"을 그렸다. 규칙이 필터 역할을 대신했기 때문이다. 파트너 계정에
관리자 플래그(`|| @request.auth.admin = true`)를 붙이자 그 계정의 홈에 **전체 파트너의 추천 46건**이 떴다. 에러는 없다.
규칙이 그대로 유효한 결과를 돌려준 것이다. 반면 filter를 명시한 쿼리(`partner = "<id>"`)는 멀쩡했다.

**해결:** 한 계정이 "본인"과 "관리자"를 겸할 수 있으면, 본인용 쿼리는 전부 filter에 `partner = {:me}`를 명시한다.
규칙은 보안 경계로만 쓰고, 화면에 보일 범위는 쿼리가 정한다. 권한을 넓히기 전에 `getList`·`getFullList`·
`getFirstListItem` 중 filter 없는 호출을 grep으로 찾아 둔다. 목록 개수 배지(`getList(perPage: 1).totalItems`)도 같은 함정이다.

---

## OPS-113 — Flutter 웹 + PocketBase에서 두 서브도메인이 로그인 하나를 쓰려면: 토큰만 상위 도메인 쿠키에, OAuth 대기값도 쿠키에

`측정 2026-09-24 · Flutter 3.38.5 web, PocketBase 0.40.4 + Dart SDK 0.25.1, Chromium (gstack browse)`

**증상:** `AsyncAuthStore`를 SharedPreferences에 저장하면 웹에서는 origin별 localStorage라서 `a.example.com`에서
로그인해도 `admin.a.example.com`은 로그아웃 상태다. Google 리디렉트 URI를 한 곳(`a.example.com/auth/callback`)만
등록했다면, admin 쪽에서 시작한 로그인의 PKCE verifier와 state가 콜백 origin에 없다. 그래서 콜백은 "내 흐름이 아니다"로 판정한다.

**해결:**
1. 저장소의 `save`에서 **토큰만** `pb_token=<jwt>; Domain=a.example.com; Path=/; SameSite=Lax; Secure; Max-Age=…` 쿠키로 쓴다.
   record JSON까지 넣으면 4KB 한도에 걸릴 수 있다. 시작할 때 쿠키 토큰으로 `{"token":…, "model":null}`을 만들어
   `initial`에 넣고 `authRefresh()`로 record를 채운다(`model:null`은 빈 RecordModel로 들어간다). `clear`는 쿠키를 지운다.
   이러면 한쪽에서 로그아웃하면 다른 쪽도 다음 로드부터 로그아웃된다.
2. Google 대기값 `{state, verifier, admin}`도 같은 도메인 쿠키(`Max-Age` 15분)에 둔다. 콜백 페이지는 교환을 마친 뒤
   `admin`이면 세션 쿠키를 **직접 한 번 더 쓰고** admin 사이트로 이동한다. `AsyncAuthStore.save`는 큐에서 비동기로 돌기 때문에
   바로 `location.assign`하면 쿠키가 안 써졌을 수 있다. 실패 메시지는 5분짜리 쿠키로 넘겨 admin 쪽 로그인 화면에 띄운다.
3. 전환 전에 localStorage에만 세션이 있던 사용자는 첫 로드 때 한 번만 쿠키로 옮긴다(`pb_cookie` 표시). 표시가 없으면
   다른 쪽에서 로그아웃해도 localStorage 값이 쿠키를 되살린다.

실측: 파트너 사이트 localStorage에 넣은 세션 → 쿠키 이전 → admin 사이트가 로그인 없이 워크스페이스를 연다.
admin에서 로그아웃하면 두 사이트 모두 로그인 화면이다. admin에서 Google을 누른 뒤 파트너 사이트에서 `document.cookie`로
`pb_oauth`가 읽혔다. 가짜 code로 콜백을 열면 admin 사이트로 돌아가 "Failed to fetch OAuth2 token."이 떴다.
localhost에서는 `Domain`을 빼야 쿠키가 저장된다. `admin.localhost`와 `localhost`는 쿠키를 공유하지 않는다.

---

## OPS-114 — 옛 도메인을 거치는 OAuth 우회(OPS-109)는 일부 사용자에게 DNS 오류로 깨진다. PocketBase의 `/api/oauth2-redirect`를 `routerUse`로 가로채 앱 콜백으로 넘긴다

`측정 2026-09-24 · PocketBase 0.40.4 (JSVM), Google OAuth, Chrome`

**증상:** redirect_uri를 옛 도메인 `a.example.com/auth/callback`으로 고정하고 nginx 301로 새 도메인에 넘겼다(OPS-109).
공용 DNS(8.8.8.8, 권한 NS)에서는 옛 이름이 풀렸다. 그런데 사용자 브라우저는 Google 로그인 직후
`a.example.com의 DNS 주소를 찾을 수 없습니다 · DNS_PROBE_POSSIBLE`에서 멈췄다. 새 도메인과 API 호스트는 같은 브라우저에서
정상이었다. 우리 쪽에서 확인할 수 없는 사용자 쪽 리졸버 문제라서, 사용자가 이미 쓰는 호스트가 아닌 이름에 로그인이
기대면 안 된다.

**해결:** PocketBase 자체 엔드포인트 `<pb>/api/oauth2-redirect`가 Google 클라이언트에 등록돼 있으면(SDK 기본값이라 흔히 등록돼 있다)
그 주소를 redirect_uri로 쓴다. 앱이 authorize URL의 `state`를 자기 접두사가 붙은 값(`partners-<random>`)으로 바꾸고,
훅에서 그 state만 앱 콜백으로 넘긴다. 나머지 state는 PocketBase 기본 처리(realtime 전달)를 그대로 탄다.

```js
routerUse((e) => {
  if (e.request.method === "GET" && e.request.url.path === "/api/oauth2-redirect") {
    const state = String(e.request.url.query().get("state") || "");
    if (state.startsWith("partners-")) {
      return e.redirect(302, "https://app.example.com/auth/callback?" + e.request.url.rawQuery);
    }
  }
  return e.next();
});
```

같은 경로에 `routerAdd`를 쓰면 기본 라우트와 겹친다. 가운데에 끼우는 middleware(`routerUse`)를 써야 한다. 코드 교환 때도 같은
`<pb>/api/oauth2-redirect`를 redirect URL로 보낸다. 실측: 우리 state는 302로 넘어가고 쿼리는 그대로 유지됐다. 다른 state는
기존처럼 307로 `/_/#/auth/oauth2-redirect-failure`에 갔다. Google 계정 선택 화면은 `continue to example.com`으로 이전과 같다.
배포는 훅 파일 하나를 복사하는 것으로 끝났다(재시작 없이 hot-reload).
