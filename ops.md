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
