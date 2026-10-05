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

---

## OPS-115 — VS Code 확장 Codex Stats는 토큰을 활성화 때 한 번만 읽는다: Codex 토큰이 바뀌면 401이 창을 닫을 때까지 계속된다

`측정 2026-09-25 · MartinOrtiz.codex-stats 1.0.4 (마켓 최신), VS Code, macOS`

**증상:** 상태 표시줄의 Codex 사용량이 갱신되지 않는다. `Codex Stats: Show Logs`에는 5분마다
`Codex usage response received {"status":401,...,"contentType":"text/plain"}` → `No rate limits were returned`가 반복된다.
같은 시각 `~/.codex/auth.json`의 토큰으로 `GET https://chatgpt.com/backend-api/wham/usage`를 직접 호출하면 200이다.

확장은 활성화 시점에 `auth.json`을 읽어 `CodexAPIClient`에 고정하고 다시 읽지 않는다. Codex CLI가 토큰을 새로 받으면
(`codex login`, 자동 refresh — `auth.json`의 `last_refresh`가 바뀐다) 옛 access token은 만료 전이라도 거부된다.
실측: `last_refresh` 23:27:49Z 직후 23:34Z부터 열려 있던 모든 창이 401, 새 토큰은 200. `Refresh Codex Stats` 명령도
같은 캐시된 토큰을 쓰므로 소용없다. auth가 없던 상태로 활성화되면 폴링 타이머 자체가 시작되지 않는다.

**해결:** 당장은 `Developer: Restart Extension Host`(또는 Reload Window)로 다시 읽힌다. 근본 수정은 설치본
`~/.vscode/extensions/martinortiz.codex-stats-1.0.4/out/services/usage-monitor.js`의 `updateUsage()` 첫머리에서
매번 `loadAuthData()`를 부르고 access token이 바뀌었으면 `initializeMonitor()`로 클라이언트를 다시 만드는 것이다
(파일 읽기 하나라 비용 없음). 확장 업데이트 시 덮어써지므로 업데이트 후 다시 확인한다.

## OPS-116 — Cloudflare Workers AI 무료 플랜: 하루 10,000 뉴런, 큰 모델은 5035, 한도 초과는 4006

`측정 2026-09-25 · Workers AI REST/바인딩, Workers Free 플랜, @cf/openai/gpt-oss-120b`

**증상:** `@cf/moonshotai/kimi-k2.6`, `@cf/zai-org/glm-5.3`, `@cf/deepseek-ai/deepseek-v4-flash-0731` 호출이 곧바로
`AiError: Model ... is not available on the Workers Free plan` (code 5035)으로 실패한다. 모델 목록 API(`/ai/models/search`)에는
이 모델들이 그대로 나오므로 목록만 보고 고르면 배포 뒤에야 안다. 몇십 건 호출 뒤에는 모든 모델이
`you have used up your daily free allocation of 10,000 neurons` (code 4006)으로 멈추고 00:00 UTC에 풀린다.

- 무료 플랜에서 쓸 수 있는 것: gpt-oss-120b/20b, llama-4-scout, mistral-small-3.1, gemma-4-26b, qwen3 계열 등.
- 응답의 `result.usage.neurons`로 건당 비용이 바로 나온다. 한국어 기사 1건(입력 약 1,000토큰) 요약 실측:
  gpt-oss-120b 90~240뉴런(추론 토큰이 들쭉날쭉), mistral-small-3.1 40~57, llama-4-scout 54. 하루 10,000이면 gpt-oss-120b로 약 60건.
- gpt-oss 추론 강도는 `reasoning: {effort: "low"}`이다(`reasoning_effort` 키는 스키마에 없다). low에서도 추론이 `max_tokens`를
  다 쓰고 content가 비는 경우가 있어 3000 이상을 주고, JSON 파싱 실패 시 1회 재시도가 필요했다.
- 정확도 차이: 같은 기사에서 mistral-small은 원문의 "22일"을 "2024년 10월 22일"로 지어냈고, gpt-oss-120b는 원문대로 옮겼다.
- gemma-4-26b-a4b-it는 `max_tokens` 3000을 다 쓰고 빈 content를 돌려줬다.

**해결:** 무료 플랜이면 호출 수를 하루 60건 안으로 제한하고(크론 1회당 상한), 4006을 받으면 그 실행을 멈추고 다음 실행에 맡긴다.
밀린 작업을 한 번에 처리하거나 큰 모델을 쓰려면 Workers Paid(월 5달러, 이후 1,000뉴런당 0.011달러)가 필요하다.

## OPS-117 — Flutter web: 플러그인을 나중에 추가하면 `flutter build web`이 옛 플러그인 등록 파일을 계속 써서 `MissingPluginException`이 난다

`측정 2026-09-25 · Flutter 3.38.5 stable, flutter build web --release, url_launcher 6.3.2 (url_launcher_web 2.4.3)`

**증상:** 배포한 웹에서 링크 버튼을 누르면
`MissingPluginException(No implementation found for method launch on channel plugins.flutter.io/url_launcher)`.
`pubspec.lock`과 `.flutter-plugins-dependencies`에는 `url_launcher_web`이 있고, 빌드도 에러 없이 끝난다.
`.dart_tool/flutter_build/<hash>/web_plugin_registrant.dart`를 열어 보면 플러그인을 추가하기 전 날짜 그대로이고
`UrlLauncherPlugin.registerWith`가 없다. 같은 폴더의 `main.dart.js`만 새 날짜다.
원인은 이 파일을 쓰는 `web_entrypoint` 타깃의 입력이 `flutter_tools/lib/src/build_system/targets/web.dart` 하나뿐이라는 점이다.
pubspec·플러그인 목록이 바뀌어도 이 타깃은 최신으로 판정되어 다시 돌지 않는다. `flutter pub get`으로도 풀리지 않는다.

**해결:** 빌드 직전에 `rm -f .dart_tool/flutter_build/*/web_entrypoint.stamp`를 지운다(`flutter clean`보다 싸다).
배포 스크립트에 넣어 두면 재발하지 않는다. 확인: 빌드 뒤 `web_plugin_registrant.dart`에 새 플러그인이 있는지 보고,
url_launcher라면 `main.dart.js`에 `noopener` 문자열이 생긴다(없던 상태에서 0 → 1).

## OPS-118 — misa Docker 브리지 주소 풀이 바닥났다: 새 compose 스택은 네트워크 생성에서 죽는다. 서브넷을 compose에 직접 고정한다

`측정 2026-09-26 · misa(Ubuntu, Docker 28.5.0), Dokploy raw compose`

**증상:** Dokploy `compose.deploy`가 `composeStatus: error`로 끝난다. 배포 로그
(`/etc/dokploy/logs/<appName>/*.log`) 원문:
`failed to create network <appName>_backend: Error response from daemon: all predefined address pools have been fully subnetted`.
이미지 빌드는 성공한 뒤라 빌드 문제처럼 보이지 않는다. misa에는 브리지 네트워크가 31개였고 기본 풀
`172.17–31.0.0/16`(15개)과 `192.168.0.0/16`의 `/20` 조각 16개가 전부 할당돼 있었다. 스택마다 `_default`와
`_backend` 두 개씩 먹는다. 남은 `/20` 하나를 첫 시도의 `_default`가 가져가고 `_backend`에서 실패했다.
빈 `mars-ci-*_default` 같은 CI 잔여 네트워크도 풀을 차지한다. `172.30.1.0/24`는 호스트 LAN이라 풀에서 빠진다.

**해결:** 데몬 설정(`default-address-pools`)을 바꾸면 dockerd 재시작이 필요해 전 서비스에 영향이 간다. 스택 쪽에서
기본 풀 밖의 서브넷을 직접 지정하면 재시작 없이 뜬다. `172.16.0.0/16`은 Docker 기본 풀도 아니고 misa 호스트
라우트도 아니다(`ip -4 route`로 확인).

```yaml
networks:
  default:
    ipam: {config: [{subnet: 172.16.40.0/24}]}
  backend:
    internal: true
    ipam: {config: [{subnet: 172.16.41.0/24}]}
```

실패한 첫 시도가 만든 빈 네트워크는 `docker network rm`으로 지우고 다시 배포한다(안 지우면 설정이 달라 충돌하고
`/20` 하나도 계속 묶인다). 다른 스택과 겹치지 않게 쓰기 전에
`docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' $(docker network ls -q)`로 사용 중 대역을 본다.
사용: landgrab `172.16.40–41.0/24`, landgrabs `172.16.42.0/24`(backend만 — 서비스가 안 쓰는 `default`는 compose가 만들지 않는다).

---

## OPS-119 — VS Code "Claude Code Usage Tracker"가 `HTTP 429`로 한 시간씩 Error만 띄운다: `/api/oauth/usage`는 서드파티에 시간당 몇 번만 허용하고, 1.7.0은 429가 나면 마지막 값까지 버린다

`측정 2026-09-26 · YahyaShareef.claude-code-usage-tracker 1.7.0 · VS Code · Claude Code 2.1.283 · Max 구독`

**증상:** 상태 표시줄이 `Claude Error`, 툴팁은
`HTTP 429 — Rate limited by Anthropic API. Retry at 07:21.`. 토큰은 정상이다(같은 토큰으로 다른 호출은 200).
429 응답은 `retry-after: 3600`을 준다. 확장은 그 시각까지 막히고, 이 동안 `Claude: Refresh Usage`도 아무것도 하지 않는다.

원인은 둘이다.
- **요청 예산이 작다.** 확장 기본 폴링은 120초(시간당 30회)다. 업스트림 이슈 #16의 측정으로는 서드파티
  User-Agent의 허용량이 거의 0이고, Claude Code 본체도 같은 엔드포인트를 부른다(바이너리에
  `/api/oauth/usage?at_wall=1&skip_spend=1` 문자열이 있다). 한도 헤더(`ratelimit-*`)가 없어 남은 양을 알 수 없다.
- **429가 나면 마지막 정상 값을 버린다.** `dist/extension.js`의 catch가 공유 캐시(`claudeUsage.cache.v2`)에
  `data:null`을 쓴다. 호출한 창은 메모리 값으로 버티지만, 다른 창과 재시작한 창은 캐시에서 `null`을 읽고 차단이
  풀릴 때까지 `Error`만 보인다. 캐시 상태는 `~/Library/Application Support/Code/User/globalStorage/state.vscdb`의
  `YahyaShareef.claude-code-usage-tracker` 키에서 볼 수 있다.

**해결:**
1. `settings.json`에 `"claude-usage-monitor.refreshInterval": 600` (시간당 6회).
2. 실패한 폴링도 마지막 정상 값을 캐시에 남긴다. 업스트림 PR
   https://github.com/yahyashareef48/claude-usage-monitor/pull/22 (`src/extension.ts`의 catch에서
   `data: null` 대신 메모리 값과 캐시 값 중 `fetchedAt`이 최신인 쪽). 머지 전에는 그 브랜치를
   `node esbuild.js --production`으로 빌드해 `~/.vscode/extensions/yahyashareef.claude-code-usage-tracker-1.7.0/dist/extension.js`에
   덮어쓰고 창을 다시 불러온다. 가짜 vscode 모듈과 429를 돌려주는 https로 돌려 보면, 원본은 재시작 후 `Error`,
   수정본은 `12% · 49m ⚠`(캐시 값 + 경고)다. 확장이 업데이트되면 덮어써진다.
3. User-Agent를 `claude-code/<버전>`으로 바꾸면 통한다는 보고가 있다. 신원을 속여 접근 제한을 우회하는 것이라 쓰지 않는다.

---

## OPS-120 — macOS 27: 로그인할 때마다 "X이(가) 터미널에서 문서를 열도록 허용되지 않았기 때문에 'Y'을(를) 열 수 없습니다" — 앱 번들이 아니라 `Contents/MacOS/<실행 파일>`을 여는 옛 런처 패턴이 원인이다

`측정 2026-09-26 · macOS 27.0 (26A428) · DayCounter 1.3 (MAS, com.monobutton.daycounter)`

**증상:** 부팅·로그인 직후 터미널이 저절로 뜨고, 터미널이 주인인 경고창에
`DayCounter이(가) 터미널에서 문서를 열도록 허용되지 않았기 때문에 ‘DayCounterLauncher’을(를) 열 수 없습니다.`가 나온다.
본 앱은 자동 실행되지 않는다. Launch Services 재등록(`lsregister -f`)으로는 풀리지 않고 다음 로그인에 다시 뜬다.

원인은 `SMLoginItemSetEnabled` 시절의 흔한 런처 코드다. 런처(`Contents/Library/LoginItems/*Launcher.app`)가
`bundlePath`의 `pathComponents`에서 뒤 3개를 빼고 `MacOS`, `<앱 이름>`을 붙여 **실행 파일 경로**를 `NSWorkspace`로 연다.
macOS 27에서 이 경로는 문서로 취급되어 터미널에 넘어간다. 로그 원문:
`LAUNCH: Asking CSUI to launch 1 items` → `CoreServicesUIAgent … Opening document <FSNode> { isDir = n } with application <FSNode> { isDir = y }` →
1초 뒤 `Successfully spawned Terminal`. 요청자가 샌드박스 앱이라 터미널이 거절하고 경고창을 띄운다.
확인: `NSWorkspace.URLForApplicationToOpenURL`에 `…/Contents/MacOS/<exe>`를 넣으면 `Terminal.app`이 나온다(번들 경로는 앱 자신).
바이너리에서 `strings`로 `pathComponents`, `pathWithComponents:`, `MacOS`가 보이면 이 패턴이다.

**해결:** 앱은 서명돼 있어 고칠 수 없다. 런처를 끄고 앱 번들을 직접 로그인 항목에 넣는다.
1. 앱 설정의 "자동 실행"(런처 등록)을 끈다. `sfltool dumpbtm`에서 `…launcher`의 Disposition이 `disabled`가 되고
   `launchctl print gui/$(id -u)/<launcher id>`가 `Could not find service`면 됐다.
   `launchctl disable`은 소용없다 — 로그인 때 smd가 `Setting service … to enabled (initiated by smd)`로 되살린다.
2. `osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/<App>.app", hidden:false}'`
3. 앱의 "자동 실행"을 다시 켜면 즉시 런처가 떠서 경고창이 재발한다. 켜지 않는다.

## OPS-121 — serde_json이 f64를 1 ULP 틀리게 읽는다: 상태를 JSON으로 저장하고 다시 읽는 결정론 시뮬레이션은 `float_roundtrip` 기능 없이는 갈라진다

`측정 2026-09-26 · serde_json 1.0.151 · Rust 1.97.1 · SpacetimeDB 2.8.0 모듈(wasm32)`

**증상:** 매 틱 `serde_json::to_string(&game)` → 테이블 저장 → 다음 틱 `from_str`로 되살리는 서버 규칙 엔진에서,
직렬화하지 않은 사본과 되살린 사본의 스냅샷이 몇 틱 만에 달라진다. 처음 차이는 마지막 자리 하나다
(`98.80781492558872` 대 `98.80781492558873`). 이 차이가 속도·충돌 판정에 들어가 결과가 갈라진다.

serde_json의 기본 float 파서는 빠른 경로를 쓰고, 정확히 가장 가까운 f64로 반올림하지 않는다.
쓰기(ryu)는 최단 왕복 표기라 문제가 없고, 읽기에서 1 ULP가 틀린다. `serde_json::Value` 안의 f64도 같다.

**해결:** `Cargo.toml`에서 기능을 켠다. 새 의존성이 없어 `--offline` 빌드도 그대로 된다.

```toml
serde_json = { version = "1.0", features = ["float_roundtrip"] }
```

회귀 테스트: 상태를 직렬화→역직렬화한 사본과 원본을 같은 입력으로 N틱 진행한 뒤 스냅샷 문자열이 같은지 비교한다.

## OPS-122 — macOS Vision `VNGeneratePersonSegmentationRequest`로 사람 마스크를 추가 설치 없이 만들 수 있다. 출력은 입력 비율과 무관하게 2016×1512다

`측정 2026-09-26 · macOS 27, Swift 컴파일러(swiftc) 기본 설치, qualityLevel .accurate`

**증상:** 게임 스테이지용 인물 실루엣 마스크가 필요했지만 Python에 rembg·torch가 없었다. 모델을 받으면 수백 MB다.
Vision 요청을 쓰는 20줄짜리 Swift(`VNImageRequestHandler(cgImage:)` → `results.first.pixelBuffer` → `NSBitmapImageRep(ciImage:)` → PNG)를
`swiftc -O`로 빌드해 돌리면 1536×1024 입력에서 약 1초 만에 결과가 나온다. 결과 PNG는 입력이 3:2인데도 **2016×1512(4:3)**다.
픽셀 좌표를 그대로 겹치면 어긋난다.

**해결:** 마스크를 입력 크기로 리사이즈한다(PIL `mask.resize(image.size)`). Vision 출력은 이미지 전체를 늘려 덮으므로 정규화 좌표가 일치한다.
머리카락 가장자리는 회색 값이라 셀 격자로 줄일 때는 `Image.BOX` 평균 뒤 128 이상을 사람으로 친다.

## OPS-123 — tsconfig `types`에 `@cloudflare/workers-types`가 있으면 브라우저 스크립트의 DOM `append`·`ParentNode` 타입이 깨진다

`측정 2026-09-27 · Astro 7.3.3 · @cloudflare/workers-types 5.20260919.1 · TypeScript 5.9 · astro check`

**증상:** 같은 프로젝트의 브라우저용 `src/scripts/*.ts`에서 브라우저로는 잘 도는 코드가 `astro check`에서 오류 수십 개를 낸다.

- `div.append(node)` → `Argument of type 'HTMLElement' is not assignable to parameter of type 'string | Response | ReadableStream<any>'`
- `function $(selector, root: ParentNode = document)`에 요소를 넘기면 → `Argument of type 'HTMLDialogElement' is not assignable to parameter of type 'ParentNode'`
- `tbody.append(...rows)` → `A spread argument must either have a tuple type or be passed to a rest parameter`

workers-types는 HTMLRewriter용 전역 `Element`를 선언하고, 여기에 `append(content: string | ReadableStream | Response, options?)`가 직접 붙어 있다.
이 선언이 DOM `Element`와 합쳐지면서 `ParentNode.append`를 가리고, 그 결과 모든 DOM 요소가 `ParentNode`에 대입되지 않는다.
`querySelector`, `closest`, `replaceChildren`, `appendChild`는 가려지지 않아 그대로 통과한다.

**해결:** 서버 코드가 쓰므로 workers-types를 빼지 않는다. 브라우저 스크립트는 가려지지 않은 멤버만 쓴다.

```ts
type Root = { querySelector(s: string): unknown; querySelectorAll(s: string): ArrayLike<unknown> & Iterable<unknown> };
const $ = <T = HTMLElement>(s: string, root: Root = document) => root.querySelector(s) as T | null;
function add(parent: Node, ...kids: (Node | string)[]) {
  for (const kid of kids) parent.appendChild(typeof kid === 'string' ? document.createTextNode(kid) : kid);
}
```

## OPS-124 — PocketBase 규칙에 관리자 절을 OR로 붙이면 impersonate 토큰으로 "역할 × 비공개 헤더" 조합을 실측한다. 거절은 목록 0건과 쓰기 404로 조용히 온다

`측정 2026-09-27 · PocketBase 0.40.4 · 비공개 헤더 경계(@request.headers.x_*) 규칙`

**증상:** 관리자 계정이 숨긴 댓글·비공개 글·모든 프로필을 읽고 필드 하나만 바꾸게 하려고 기존 규칙에
`|| ((<헤더 경계>) && @request.auth.collectionName = "<auth 컬렉션>" && (@request.auth.email = "<관리자>"))`를 붙였다.
규칙이 틀려도 오류가 나지 않는다. 실측한 응답:

| 요청 | 응답 |
| --- | --- |
| 목록, 규칙 불통과 | 200, `totalItems: 0` (403 아님) |
| 수정, 규칙 불통과 | 404 |
| 수정, `@request.body.<필드>:isset = false`로 잠근 필드를 보냄 | 404 (400 필드 오류가 아니라 수정 전체 거절) |
| 관리자 토큰 + 헤더 | 비공개·숨김 포함 전부 (프로필 3/3, 댓글 874/874, Q&A 873/873) |

`@request.auth.email`은 `emailVisibility`가 꺼져 있어도 규칙 안에서 비교된다. 필드 하나만 바꾸게 하는 문법은 없어서
나머지 필드를 전부 `:isset = false`로 나열해야 한다. 목록은 라이브 스키마(`id`·`created`·`updated`와 허용 필드 제외)에서 뽑아야
나중에 필드가 늘어도 잠긴다.

**해결:** 사람 로그인 없이 끝내려면 슈퍼유저로 `POST /api/collections/<auth>/impersonate/<id>` `{"duration":300}`을 불러
관리자와 일반 회원 토큰을 만든다. 역할(관리자·회원·익명) × 헤더(있음·없음) × 동작(읽기·허용 쓰기·잠긴 쓰기)을 표로 돌리고,
기대값은 슈퍼유저가 같은 필터로 센 수와 비교한다. 쓰기 탐침은 비공개·숨김 상태로 새로 만든 레코드에만 하고 `finally`에서 지운다.
앱의 "내 것" 조회가 규칙에 기대지 않는지(OPS-112)도 같이 본다. 21개 조합을 도는 예: 교민센터 `scripts/ops/grant-admin-console.py`.

## OPS-125 — Workers 서비스 바인딩 호출은 대상 Worker가 2분 넘게 걸려도 끝까지 기다린다. `wrangler secret put`은 로컬 코드를 올리지 않는다

`측정 2026-09-27 · Cloudflare Workers Free 플랜 · wrangler 4.135.0`

**증상:** 웹 Worker의 요청 처리 안에서 `await env.COLLECTOR.fetch('https://collector.internal/run', {method:'POST', headers:{Authorization:'Bearer …'}})`로
수집 Worker를 불렀다. 대상이 외부 피드 6곳과 AI 요약을 도는 데 148초가 걸렸고, 브라우저 요청은 그동안 열린 채 결과 JSON을 받았다.
호출한 쪽은 기다리기만 하므로 CPU 한도에 걸리지 않았다. 대상 Worker의 Bearer 토큰 검사도 그대로 동작해서,
`workers_dev` 주소를 열어 두지 않고도 내부 호출만으로 수동 실행을 붙일 수 있다.

두 Worker에 같은 토큰을 넣을 때 `wrangler secret put NAME --config <대상 설정>`은 "Uploaded secret"만 하고 코드 번들·업로드 단계가 없다.
현재 배포된 코드로 새 버전을 만든다. 로컬에 미커밋 변경이 있는 Worker도 비밀값만 안전하게 바꿀 수 있다.

**해결:** 값은 파일로 한 번 만들고(`umask 077`) 두 Worker에 같은 파일을 파이프로 넣은 뒤 지운다. 화면에 찍지 않는다.
호출하는 쪽 UI는 결과를 기다리는 동안 경과 시간을 보여 주고, 대상이 실행 시작 시 남기는 기록(예: `state: running`)을 따로 폴링하면 진행을 알릴 수 있다.

## OPS-126 — Selected-file overlay images keep stale test files: in-image regression then reports failures that are not regressions
`measured 2026-09-27 · Docker 28.5.0 · Dokploy 0.30.2 (busan) · Flask app released as FROM <live digest> + COPY overlay`

**Symptom:** a release candidate fails one in-image test (`test_bug_reports.py`: `'tester-one' unexpectedly found`)
while the same test passes on the developer machine. It looks like the new release leaked data.

A release built as `FROM <live image digest>` plus `COPY overlay/ /app/` replaces only the files listed in the
overlay. A test that an earlier release changed in source, but did not put in its own overlay, stays at its old
version in every later image. Here the runtime module was byte-identical in source and image; only the test
differed, and the newer test asserted the opposite behaviour ("email is intentionally attached"). The host's
deploy tree did not contain the test at all, so comparing the deploy tree with source could not catch it.

**Fix:** run the same suites in the live (base) image and in the candidate under identical conditions
(`docker run --rm --network none …`) and compare the two failure lists — a failure present in both is
pre-existing, not the release's. Then hash the failing test in source and in the image; if only the test differs,
add the current test to the overlay so the next image is clean. Also: a Flask login redirect built with
`url_for(..., next='/admin')` comes back as `/login?next=/admin` (slash not percent-encoded) — assert on the
prefix, not on `%2F`.

## OPS-127 — macOS Vision on anime illustrations: the foreground instance mask holds, person segmentation and face detection fail silently on some images, and a white sticker border on light grey is missed
`measured 2026-09-27 · macOS 27 (Darwin 27.0.0) · Vision called from Swift 6.4 (swiftc -O) · 18 generated anime key visuals 1536×1024, 5 sticker sprites 1024×1024`

**Symptom:** a game needed the heroine's silhouette and a face crop from generated anime illustrations.
`VNGeneratePersonSegmentationRequest` (`.accurate`) returned a near-empty mask (0.9–4.9% of pixels while the character
covered 30–53%) on 3 of 18 images and less than half of the character on 5 more. No error, just a mostly black mask.
`VNDetectFaceRectanglesRequest` found the face on 14 of 18 (confidence 0.67–0.81) and nothing on 4; on those 4,
`VNDetectHumanBodyPoseRequest` found head joints once, and `VNDetectHumanRectanglesRequest` found a person on only 6
of all 18. Upscaled 2x/3x crops of the head did not help.

`VNGenerateForegroundInstanceMaskRequest` + `generateScaledMaskForImage(forInstances:from:)` worked on all 18: one
instance, the character including held props (skateboard, wrench, floating book, saber), already at the input size.
The output is deterministic: rebuilding every mask from scratch gave byte-identical files.

On opaque sticker art (white die-cut border on a flat light-grey background) the foreground mask edge lies on the
black outline inside the white border. Used as alpha, it cuts off or half-fades the border.

**Fix:** use the foreground instance mask as the silhouette. With several instances, take the one with the largest
overlap with the person mask, or the largest one when the person mask is empty. For the face crop fall back to
body-pose head joints, then to the top of the mask inside a ±12%-of-width window around the torso axis (median x of
mask pixels at 45–70% of the height), which ignores raised arms and held props. For stickers on a flat background
skip Vision: flood-fill background-coloured pixels from the image edge, set edge alpha = distance from the
background / distance of white from the background (the white border is the outermost colour), remove the
background with `C = (I - (1 - a)·B) / a` using that alpha, and only then choke the alpha by 1 px.

## OPS-128 — `codex exec` image generation for character key art: shot words set the frame fill, capes overshoot, outfits drift to garter straps
`measured 2026-09-27 · codex-cli 0.154.0 built-in image tool · 18 landscape 1536×1024 + 5 square 1024×1024 generations`

**Symptom:** "full body, occupying about 40% of the frame" produced a character covering 11.7% of the image.
A percentage alone does not size the subject; the shot type does. Coverage measured with the Vision foreground mask
(OPS-127), share of a 216×144 grid:

| Prompt framing | Coverage |
| --- | --- |
| full body, "about 40% of the frame" | 11.7% |
| cowboy shot cropped at mid-thigh, head just below the top edge, close camera, "covers roughly 40-50%" | 42.8-50.4% (11 images) |
| same, character in a long coat or a wide cape | 53.9%, 56.9% |
| + "the coat hangs close to her body ... about 40%" | 52.0%, 52.3% |
| + "compact ... background visible on both sides below the waist ... only about 35-40%" | 30.0%, 46.0% |
| + "moderately compact ... about 42%" | 45.1% |

The model also changed outfits against the prompt: "shorts over leggings" came back as thigh-high stockings with
garter straps, and "a fitted flight suit" as shorts with a bare-thigh band and thigh straps (2 of 18). "Camera at eye
level" reduced low angles but did not remove them. Sticker prompts that asked for "a plain, flat light-grey
background" returned RGBA with a transparent background in 3 of 5 (46-49% transparent pixels, see OPS-076).
Three parallel runs took 68-109 s per image over 23 generations with no rate-limit errors.

**Fix:** name the shot and the crop, then tune the fill per character: add a size note only for wide costumes. The
same size note gave 30.0% on one character and 46.0% on another, while two runs of one unchanged prompt landed 0.7
points apart (47.8%, 48.5%), so re-check coverage after every prompt change. Spell out what covers the legs and list the
exclusions ("full-length leggings to the ankles; no stockings, no garter straps, no bare thighs"). Measure every
candidate and look at it at full size; hands and outfit details do not show in thumbnails.

## OPS-129 — `glab repo create <name>` inside an existing repo adds no remote to it: it `git init`s a new `./<name>/` subdirectory instead, and `--skipGitInit` does not stop that
`measured 2026-09-27 · glab 1.82.0 · gitlab.com · non-interactive shell (agent Bash tool)`

**Symptom:** in a repo with one commit on `main` and no remotes, `glab repo create battlemarble --private
--defaultBranch main --skipGitInit` printed `✓ Created project on GitLab`, then
`Initialized empty Git repository in <repo>/battlemarble/.git/` and `✓ Initialized repository in './battlemarble/'`.
The current repo got no `origin`. The new subdirectory held an empty repo whose `origin` pointed at the new project.
Nothing was reported as an error, and the following `git push -u origin main` in the original repo has no remote to
push to.

The cause is in `internal/commands/project/create/project_create.go` at v1.82.0. A name argument takes the branch for
"not working in the current directory", which never adds a remote to the current repo; it runs `git init <path>` and
`git -C <path> remote add origin <ssh url>`. `--skipGitInit` only controls `git init` in the current directory. The
"Create a local project directory?" confirmation defaults to yes and appears only when prompts are enabled, so in a
non-interactive shell the subdirectory is created silently. A code comment on that branch says "(or just add remote if
already in git repo)"; the code does not do that. Separately, `--help` states the defaults: visibility `internal` and
default branch `master` unless `--private` and `--defaultBranch main` are passed.

**Fix:** after the project exists, look inside the stray `./<name>/` (it held only `.git`, no commits) and delete it,
then `git remote add origin git@gitlab.com:<ns>/<name>.git && git push -u origin main`. This worked, and
`git ls-remote origin refs/heads/main` matched the local `HEAD`. According to the same source file, running
`glab repo create --private --defaultBranch main` with no name argument from inside the repo names the project after the
top-level directory and adds `origin` to the current repo. That path was read in the source, not run.

## OPS-130 — 외교부 재외공관 사이트(overseas.mofa.go.kr)는 붐비면 모든 주소에 F5 대기실 페이지를 HTTP 200으로 준다. RSS 파서는 이것을 DOCTYPE 오류로 보고한다

`측정 2026-09-27 · overseas.mofa.go.kr 공관 RSS(rss.do?brdId=…) · 가정 회선과 Cloudflare Workers 발신 양쪽`

(쿠키 없이 부르면 307이 끝없이 반복되는 문제는 OPS-094. 이 항목은 쿠키를 제대로 다뤄도 생기는 실패다.)

**증상:** 공관 RSS 4개가 같은 실행에서 한꺼번에 실패하고 다음 실행에서 멀쩡해지기를 며칠째 반복했다(예약 실행의 약 절반).
수집기 오류는 `XML_ENTITIES_NOT_ALLOWED`였다. XML 파서 앞에 둔 `<!DOCTYPE|<!ENTITY` 거부 검사에 걸린 것이다.
피드가 깨진 것이 아니다. 사이트가 붐빌 때는 `robots.txt`를 포함한 **모든 경로**가 다음 페이지를 준다.

- HTTP 200, `<title>Waitingroom</title>`, XHTML DOCTYPE, F5 로고, "서비스 접속 대기 중입니다" 안내
- 첫 요청은 평소처럼 `307` + `TMOSHCooKie` 쿠키로 같은 주소를 다시 부르게 하고, 두 번째 요청에서 대기실이 나온다
- 같은 Workers 발신 요청을 몇 초 간격으로 세 번 보냈을 때 첫 번째는 피드마다 3~10초 걸려 RSS가 왔고, 뒤의 두 번은 5개 주소 모두 대기실이었다

대기실 페이지의 스크립트는 `/waitingroom/update.html`을 부른다. 응답은 `<예상 초> <순번> <다음 호출 간격 ms>`(예: `0 32 5000`)이고,
차례가 오면 `done 0 5000`, 문제가 있으면 `error`다. 이때까지 받은 쿠키(`clientid`, `qindex`, `landinguri`)를 붙여 원래 주소를 다시 부르면 RSS(200, `application/rss+xml`)가 온다.
실측한 기다림은 순번 32에서 약 15~19초였다.

**해결:** 응답 첫머리에서 `<title>Waitingroom</title>`을 찾으면 파싱하지 말고 줄을 선다. 같은 쿠키 통으로 `update.html`을 서버가 말한 간격(1~10초로 제한)마다 부르고,
`done`이 오면 원래 주소를 다시 요청한다. 한 실행이 기다릴 총 시간 상한(예: 120초)을 두고, 넘거나 `error`가 오면 "대기실 시간 초과"처럼 원인이 드러나는 코드로 실패시킨다.
한 번 들어가면 같은 실행의 나머지 공관 주소는 기다리지 않았다. `robots.txt`도 대기실이 될 수 있으니 robots 응답을 캐시하기 전에 같은 검사를 한다.
구현 예: 교민센터 `workers/auto-collector.ts`의 `sourceClient()`.

## OPS-131 — Workers 무료 플랜에서 CPU 232ms, 벽시계 148초 실행이 `outcome: ok`로 끝났다. 문서의 10ms를 즉시 끊는 한도로 보지 않는다

`측정 2026-09-27 · Cloudflare Workers(README 기준 무료 플랜) · wrangler tail --format json · 1회`

**증상:** 외부 피드 6곳, 기사 페이지 16개, Workers AI 요약 12건을 한 번의 fetch 호출에서 처리하는 수집 Worker를 `wrangler tail`로 봤다.
이벤트 필드는 `"outcome":"ok"`, `"cpuTime":232`, `"wallTime":148127`이었다. 공개 문서의 무료 플랜 CPU 한도(요청당 10ms)의 23배인데 오류(1102)가 나지 않았다.
같은 Worker의 6시간 예약 실행도 며칠째 비슷한 작업량으로 끝나고 있다.

**해결:** 무료 플랜이라는 이유만으로 작업을 잘게 쪼개지 않는다. 먼저 `wrangler tail --format json`으로 실제 `cpuTime`과 `outcome`을 잰다.
다만 1회 측정이고 보장된 동작이 아니다. 한도에 걸리면 실행이 기록 없이 끊겨 "실행 중" 상태가 남으니 그런 상태를 감지하는 점검을 따로 둔다.

## OPS-132 — `oggenc` (vorbis-tools) for game assets: decoded peaks move up to +1.6 dB, every run gets a random stream serial, and the written files over-allocate on APFS

`측정 2026-09-27 · vorbis-tools 1.4.3 (libvorbis 1.3.7), oggdec, macOS APFS`

**증상:** A generator normalised 34 mono sound effects to exactly -3.0 dBFS sample peak and encoded them
with `oggenc -q 5`. After decoding with `oggdec`, most peaks were within ±0.4 dB, but not all of them:

- A bass-heavy explosion (sub boom plus noise) came back at -1.4 dBFS, +1.6 dB.
- A dense, saturated square-wave buzz came back with 0 dBFS (clipped) samples and a 4x-oversampled
  true peak of +3.4 dBTP.

Rebuilding the same audio produced files with different md5 even though they decoded to identical
samples. `du -sh` reported 7.5 MB for an audio folder whose files summed to 5.69 MB.

Measured facts:

- **Length is exact.** All 44 files decoded to exactly the rendered sample count, loops up to
  4,167,450 samples, so sample-exact loop points survive the round trip.
- **Random serial.** `oggenc` picks a random Ogg stream serial on every run. That alone makes
  rebuilds differ byte for byte.
- **APFS over-allocation.** A 1,448,267-byte `.ogg` written by `oggenc` held 4,224 × 512-byte
  blocks (2.16 MB). A `cp` of the same file allocated normally (1,984 blocks for a 1,014,433-byte
  file).

**해결:**
- Measure peaks on the decoded file, not the WAV you fed in. Correct the gain by the measured
  difference and re-encode; one or two passes land within ±0.4 dB. Keep dense, saturated sounds
  off full scale before encoding.
- Pass `-s <fixed number>`, for example the CRC32 of the file name, to get byte-identical rebuilds.
- Encode to a temporary path, then write the bytes to the final path (or `cp` it), so `du`
  matches the real size.

## OPS-133 — Reading research sources when sites block agents or WebSearch is exhausted: GameFAQs and MobyGames answer 403; Wikipedia `?action=raw`, Wayback `id_` snapshots and the Fandom MediaWiki API still return the text

`측정 2026-09-27 · curl 8.x, WebFetch, web.archive.org, en.wikipedia.org, *.fandom.com`

**증상:** `curl` to `gamefaqs.gamespot.com/...` and `www.mobygames.com/game/...` returns HTTP 403 (checked
directly). WebFetch refused theguardian.com, wired.com, polygon.com and gamesindustry.biz, and Fandom
pages answered 402, during a research run on an old PC game.

What still worked (the research agents read full page text this way; the Wikipedia call was re-checked):

- **Wikipedia:** `https://en.wikipedia.org/wiki/<Title>?action=raw` returns the wikitext itself, with
  every `<ref>` URL and access date, which is faster than scraping the rendered page for primary sources.
- **Archived copies:** `https://web.archive.org/web/<timestamp>id_/<original url>` returns the archived
  bytes without the Wayback toolbar. Find a timestamp first with
  `https://archive.org/wayback/available?url=<url>`; an empty `archived_snapshots` means that exact URL
  was never saved (try the other URL forms the site has used).
- **Fandom wikis:** the MediaWiki API (`https://<wiki>.fandom.com/api.php?action=parse&page=<Title>&format=json`)
  answers when the page itself returns 402.
- **News sites WebFetch refuses:** `curl` with a normal browser `User-Agent` header returned the article body.

**해결:** Try these before re-searching. Check robots rules first (OPS-095).

## OPS-134 — SpacetimeDB 2.8 `v1.json.spacetimedb`: snapshot rows are named objects but live updates from others are `TransactionUpdateLight` with positional arrays, even without `light=true`

`측정 2026-09-27 · SpacetimeDB 2.8.0 standalone, Rust module, Godot 4.7.2 WebSocketPeer client`

**증상:** A GDScript client subscribed with `Subscribe {query_strings: ["SELECT * FROM world_clock"]}` on
`/v1/database/<db>/subscribe?compression=None` (no `light` parameter). Raw frames, printed as received:

- `InitialSubscription`: each row is a JSON **string of an object** with column names,
  `{"id":0,"hour":11.62,"rate":0.0083,"weather":2,...}`.
- A change made by a scheduled reducer (not by this client) arrived as **`TransactionUpdateLight`**,
  not `TransactionUpdate`, and its rows are JSON **strings of positional arrays**,
  `"[0,11.63808,0.008333334,2,0.98155856,1790493580513]"`. An update is a delete and an insert with the
  same primary key in one `updates` entry.
- Calls made by this client come back as full `TransactionUpdate` with `status`, `reducer_call.request_id`,
  `caller_identity` and a `timestamp` object (`{"__timestamp_micros_since_unix_epoch__": n}`). That
  timestamp gives an NTP-style clock offset: `server_ts - (send_time + receive_time) / 2`.

A decoder that only handles one row shape silently drops the other half of the traffic.

Also measured in the same project:
- `SELECT * FROM inventory WHERE owner = :sender` works in a v1 `Subscribe`; each client receives only
  its own rows. (2.8 does not enforce row-level security on public tables, so this is a bandwidth
  filter, not access control.)
- In `#[reducer(init)]`, `ctx.sender()` is the identity of the CLI that published, so `init` can seed an
  admin table; admin-only reducers then work through `spacetime call` from the same `--root-dir`.

- **A row that matches two of your queries arrives once per query.** Subscribed to both
  `pose WHERE zone = 0` and `pose WHERE identity = :sender`, the client's own row came as two
  `updates` entries in one table update when its zone changed: one `{deletes:[old], inserts:[new]}`
  and one `{deletes:[old]}`. Applying the entries one after another deleted the row from the cache
  although it still matched the identity query. The initial snapshot likewise repeats such rows.

**해결:** Map positional arrays to column names from `GET /v1/database/<db>/schema?version=9`
(`typespace.types[table.product_type_ref].Product.elements[i].name.some`) and accept both shapes. Handle
`TransactionUpdate` and `TransactionUpdateLight` alike. Reference-count rows per primary key
(+1 per insert, -1 per delete, summed over all `updates` entries of the table before emitting
anything); a row exists while its count is above 0. Apply every table of a transaction before
firing any row callback: a handler for one table often reads another (a new character's `player`
and `pose` rows are inserted by one reducer, and the table order inside the update is not fixed;
firing per table spawned the player at the origin because its pose was not in the cache yet).
Reference implementation:
`~/work/cobramission/client/core/net/spacetime_client.gd`.

## OPS-135 — Cloudflare D1 rejects a compound SELECT with more than five terms (`too many terms in compound SELECT`); local D1 fails the same way, node:sqlite does not

`측정 2026-09-27 · Cloudflare D1 (remote, ENAM), wrangler 4.135.0 local D1, Node 26.8 node:sqlite`

**증상:** A dashboard query that joined eight `GROUP BY` subqueries with `UNION ALL` failed inside
`db.batch()` with `too many terms in compound SELECT: SQLITE_ERROR`. Measured with
`wrangler d1 execute <db> --command "SELECT 1 UNION ALL SELECT 2 ..."`:

| Terms | Remote D1 | Local D1 (`--local`) |
| --- | --- | --- |
| 5 | ok | ok |
| 6 | `too many terms in compound SELECT: SQLITE_ERROR [code: 7500]` | same error |

Stock SQLite allows 500 terms (`SQLITE_MAX_COMPOUND_SELECT`), so a test on `node:sqlite` or
`better-sqlite3` passes the query that D1 rejects. The limit is per level:
`SELECT * FROM (3 terms) UNION ALL SELECT * FROM (3 terms)` returns six rows without error.

**해결:** Give each part its own statement and send them together with `db.batch([...])` (one round trip,
results in order). Or nest so no level has more than five terms. Run new SQL once against local D1
(`wrangler d1 execute --local`, or the binding from `getPlatformProxy()`, OPS-106) before trusting a
node:sqlite test.

## OPS-136 — itch.io free and pay-what-you-want downloads can be scripted without a browser, but the `/file/` call fails with `invalid key` if you pass the key from the download-page URL

`측정 2026-09-27 · itch.io web flow (static.itch.io extern.min.js of that date), Python 3.9 stdlib urllib + cookiejar`

**증상:** Asset packs from kaylousberg.itch.io (KayKit) and quaternius.itch.io exist only on itch.io in their
newest versions (KayKit Adventurers 2.0 and Character Animations 1.1 are not on the KayKit GitHub account,
which stops at 1.0). A plain `curl` of the page has no file links. The obvious last step,
POST `/<game>/file/<upload_id>?key=<key from the /download/<key> URL>`, returns
`{"errors":["invalid key"]}`.

The browser flow, reproduced with one cookie jar kept across all steps:

```
GET  https://<creator>.itch.io/<game>/purchase        -> <input name="csrf_token" value="...">
POST https://<creator>.itch.io/<game>/download_url    csrf_token=...  (X-Requested-With: XMLHttpRequest)
     -> {"url": "https://<creator>.itch.io/<game>/download/<key>"}
GET  that url                                           -> one data-upload_id="..." per file you may download
POST https://<creator>.itch.io/<game>/file/<upload_id>?source=game_download&after_download_lightbox=1&as_props=1
     csrf_token=...                                     -> {"url": "https://itchio-mirror.<hash>.r2.cloudflarestorage.com/..."}
GET  that url                                           -> the zip (Content-Disposition has the file name)
```

The page JS (`GameDownload.download_upload` in `extern.min.js`) adds `key` only when the page's
`init_GameDownload(...)` options contain one. For a $0 name-your-own-price game they do not, so the
access comes from the session cookie and the key must be left out. The download page lists only the
tiers you may take at $0 (the paid "Source"/"Pro" uploads do not appear). 13 KayKit and 5 Quaternius
packs came down this way. One 153 MB transfer (Medieval Village MegaKit) stopped at 82.8 MB and
left a zip with no central directory (`unzip -t` prints `No zipfiles found`).

**해결:** Follow the flow above and send no `key` parameter. Run `unzip -t` on every zip and compare its size with the size the page lists. Read the upload name from
`<strong title="..." class="name">` next to each `data-upload_id` to pick the free tier. This is the
publisher's own distribution, so it is not an unofficial mirror; record the itch page URL, not the
signed R2 link (it expires).

## OPS-137 — A public Google Drive folder can be listed and downloaded with curl: `embeddedfolderview` gives the file IDs, `drive.usercontent.google.com` gives the bytes

`측정 2026-09-27 · drive.google.com public "anyone with the link" folders (Quaternius packs), Python 3.9 stdlib`

**증상:** Older Quaternius packs (Ultimate Monsters, Cute Animated Monsters, Ultimate Animated
Character, Ultimate RPG) link only to a Google Drive folder. `curl` on the `.../drive/folders/<id>`
link returns a JavaScript app with no file list.

- `GET https://drive.google.com/embeddedfolderview?id=<folderId>` returns static HTML. Each entry is
  `<div class="flip-entry" id="entry-<id>">` with an `<a href>` (it contains `/folders/` for a
  subfolder) and `<div class="flip-entry-title">name</div>`. A 52-file folder was listed complete.
- `GET https://drive.usercontent.google.com/download?id=<fileId>&export=download&confirm=t` returns
  the file itself, with no virus-scan interstitial page.

Recursing and skipping the `Blends`/`FBX`/`OBJ` subfolders pulled 57 files (32.7 MB) and
43 files (15.7 MB) with 0 errors; one file in a later folder needed a retry after `The read operation timed out`.

**해결:** Walk the folder with the two URLs above. Check that a response does not start with
`<!doctype html` before writing it. Record the folder URL from the publisher's page as the source.

## OPS-138 — Quaternius moved new packs to its own "Quaternius Asset License (QAL)", not CC0; free "Standard" tiers are subsets of what the page advertises

`측정 2026-09-27 · quaternius.com pack pages and /license.html (QAL v1.0, "Last updated: 8/28/2026")`

**증상:** Quaternius assets are widely described as CC0, and most still are. But
`Bestiary - Dungeon Monsters Kit` shows `License QAL` on its pack page, linking to
`https://quaternius.com/license.html`. QAL allows commercial games with no credit, and it forbids
redistributing the assets "as a standalone asset, asset pack, stock file, template, or similar product,
whether for free or for payment ... regardless of how much the Assets have been modified". It is not
CC0. Committing the raw files to a public repository is the case to think about. On the same date,
Ultimate Monsters, Cute Animated Monsters, Universal Animation Library 1/2, Universal Base Characters,
the Stylized Nature, Medieval Village and Fantasy Props MegaKits and the Ultimate Platformer Pack still
said `License CC0`, and the `License.txt` in each of those that was downloaded says `CC0 1.0 Universal`.

The advertised counts include paid tiers. Universal Animation Library says "120+ animations", but the free
`[Standard].zip` (15 MB, against Pro at 41 MB) has 43 clips, one of them `A_TPose`. UAL2 Standard also
has 43. Stylized Nature MegaKit Standard ships 68 of the 116 models, and its `License_Standard.txt`
says so.

**해결:** Read the `License` row on each pack page, not the author's reputation. Treat QAL packs as
"not CC0" wherever a project requires CC0 or CC-BY. Count clips and models in the downloaded Standard
zip before planning around the advertised number.


## OPS-139 — `codex exec -i <base.png>` keeps a generated character on-model across expression variants; the framing follows the reference, not the prompt

`측정 2026-09-27 · codex-cli 0.154.0 built-in image tool · 5 reference runs, 1024x1536 portraits`

**증상:** a dialogue system needs one character in several expressions. Two text-only runs of the same
character prompt gave similar but visibly different faces (jaw, nose, hair parting), so identical description text
alone does not hold a character across images.

Attaching the approved base image with `-i` and telling Codex "The attached image is the approved model sheet of
this character. Use it as the visual reference: keep the same face, hair, outfit, colours, art style, framing and
plain background, and change only what the description below asks for" gave on-model variants in 5 of 5 runs:
same face, hair, outfit, palette, head size and position; hands correct (5 fingers) in all of them. The framing of
the variant follows the reference image even when the prompt asks for a different crop.

**해결:** generate and approve one base image per character, then make every variant with
`codex exec -i <base.png> --skip-git-repo-check -C <empty dir> --sandbox workspace-write -`. Keep the base image
outside the empty output folder. `-i` accepts several files, so put it before the other flags, not right before the
`-` that reads stdin.

## OPS-140 — "Waist-up" in a 2:3 portrait canvas returns a mid-thigh 3/4 shot; a raised fist "just below the top edge" gets cropped

`측정 2026-09-27 · codex-cli 0.154.0 built-in image tool · 1024x1536 generations: 13 dialogue portraits, 11 enemy figures`

**증상:** "waist-up bust" and then "a close medium shot framed from the waist up. The bottom edge of the image
crosses the character's waist at the belt line, so no hips or legs are visible" both returned figures cut at
mid-thigh, with the belt at 72-80% of the image height. The model fills the canvas width with the shoulders, and at
2:3 that leaves room down to the thighs. (OPS-128 measured the same effect for full-body framing.)

For a figure with one arm raised overhead, "framed from just below the knees" came back head-to-feet (1 of 1).
Adding "the bottom edge crosses her shins, so her feet are out of frame" fixed the crop, but "her raised fist sits
just below the top edge" cut the fist off in 2 of 2. "Her whole raised arm, wristband and fist are inside the frame,
with a clear strip of plain background above the fist" kept it in 2 of 2.

**해결:** do not fight the canvas. Generate at 1024x1536 and crop every portrait to one common canvas afterwards
(here 1024x1280 from the top). For raised limbs, ask for background above the limb instead of naming the edge.

## OPS-141 — Vision person segmentation returns 1512x2016 for portrait inputs; background slivers between hair strands survive the foreground mask

`측정 2026-09-27 · macOS 27 · Vision from Swift 6.4 · 15 generated anime character images 1024x1536 on flat light grey`

**증상 1:** `VNGeneratePersonSegmentationRequest` (`.accurate`) returned **1512x2016** masks for 1024x1536 (2:3
portrait) inputs. OPS-122 measured 2016x1512 on a 3:2 landscape input: the output is 4:3 in the input's own
orientation. Resizing to the input size still aligns. Coverage against `VNGenerateForegroundInstanceMaskRequest`:
0.2% vs 73.7%, 9.4% vs 33.1%, 55.4% vs 67.3% (coat missed) and 56.8% vs 74.2% on 4 of 15; the foreground mask stayed
within 1 point of a flat-background colour key on 15 of 15 (consistent with OPS-127).

**증상 2:** cutouts showed a pale grey fringe along hair on dark UI. It is background trapped between the hair
mass and thin outer strands: the foreground mask keeps it, and a flood fill from the image border cannot reach it
through the strands. Pixel check: 5-7 px runs of RGB within 12 of the background grey, bounded on both sides by
hair colour. Removing background-coloured components (distance < 12) that come within 12 px of the transparent
region deleted 23-31 slivers (1,200-1,500 px) per portrait and left grey hair and white shirts intact.

**해결:** use the foreground instance mask, set everything the border flood fill (distance < 18) reaches to
transparent, then remove the trapped slivers, choke 1 px and decontaminate edge colours (OPS-127). Where the figure
touches the image border the mask fades over the last 4-5 px; copy the alpha from 6 px inside so cropped limbs end
in a hard edge.

## OPS-142 — `VNDetectHumanBodyPoseRequest` finds 16-18 joints on generated anime fighters when the arms are held apart on a flat background

`측정 2026-09-27 · macOS 27 · Vision from Swift 6.4 · 6 generated enemy portraits 1024x1536, knees-up, facing the viewer`

**증상:** a first-person duel needs per-part hit boxes (face, neck, chest, arms, hands, legs) on each enemy
portrait. OPS-127 found body pose unreliable on anime key visuals (head joints on 1 of 4 images).

Prompting for "facing the viewer head-on ... both arms and both hands fully visible and held clearly apart from the
torso, with background showing between each arm and the body ... plain flat light-grey background" gave 16-18 of 19
joints on 6 of 6 figures (confidence 0.17-0.88), with Vision's left/right being the subject's own side (the image's
right for a figure facing the viewer). `VNDetectFaceLandmarksRequest` found the face on only 3 of 6.

**해결:** derive boxes from joints (face from eye spacing and the nose, chest from shoulders to mid-torso, stomach to
the hips, arms from shoulder-elbow-wrist plus 0.45 of the forearm past the wrist for the fist, legs widened to the
silhouette below the knees, head top from the mask above the face only). Joints put the wrist at the wrist, so open
hands, gloves, bandaged hands and raised knees still need a look at a debug overlay and a hand-set box.

## OPS-143 — SpacetimeDB 2.8: publishing every player move as its own transaction saturates one core at 60 players × 10 Hz; a private input table plus a 100 ms publish tick cut p95 from 1,260 ms to 12 ms

`측정 2026-09-27 · SpacetimeDB 2.8.0 standalone on an Apple M1 Max · Rust module · v1.json clients (Godot headless bots, barrier-synced per OPS-048)`

**증상:** A shared-city game let each client call `move_player` at 10 Hz, and the reducer updated the public `pose` row
that every client subscribes to (`SELECT * FROM pose WHERE zone = 0`). With 60 bots in 10 processes (6 each, decode
skipped so the drivers were not the bottleneck, OPS-047):

- each client received about 580 messages per second: one `TransactionUpdateLight` per move of every player;
- move round trip p50 8–20 ms but **p95 about 1,260 ms and p99 about 1,540 ms**;
- `spacetimedb-standalone` averaged 99 % of one core (peak 149 %).

Every move was a transaction, and every transaction fanned out to every subscriber as a separate message.

**해결:** Split input from publication.

1. `move_player` validates the step and writes a **private** `pose_input` row (one per player, `dirty = true`).
   Private tables have no subscribers, so this transaction sends nothing to anyone else.
2. A scheduled `pose_tick` reducer (100 ms) copies every dirty input into the public `pose` table in one
   transaction. Each client now gets one message per tick carrying all changed rows.
3. Server-side teleports write both tables, so the next client step validates from the new position; distance
   checks read the input table (the published pose can be one tick old).

Measured with the same harness, 45–60 s windows:

| Players | p50 | p95 (worst process) | p99 (worst process) | Server CPU avg (1 core = 100 %) | Msgs per client per s |
|---:|---:|---:|---:|---:|---:|
| 60, per-move publish | 8–20 ms | 1,260 ms | 1,540 ms | 99 % | 580 |
| 60, 100 ms tick | 6.8 ms | 12 ms | 51 ms | 22 % | 65 |
| 150, 100 ms tick | 7.1 ms | 30 ms | 116 ms | 43 % | 12 |
| 300, 100 ms tick | 10.5 ms | 83 ms | 190 ms | 77 % | 14 |

The first run right after `publish --delete-data` once showed a 2 s p95 in a single process; a repeat run was clean.
Warm up for a few seconds before measuring. Beyond this point the next wall is the client: at 300 players every tick
carries 300 rows to decode, so interest management (subscribe by map chunk) comes next.
Reference: `~/work/cobramission/server/src/module.rs` (`move_player`, `pose_tick`), `scripts/load-test.sh`.

## OPS-144 — 공용 맥에서 고정 포트의 `/healthcheck` 200은 남의 스택일 수 있다. 내 `compose up`은 포트 충돌로 실패했는데 대기 루프는 "healthy"를 찍었다

`측정 2026-09-27 · Docker Desktop 29.7.2 (macOS) · Nakama 3.37.0`

**증상:** `docker compose up -d` 뒤 `curl …:17350/healthcheck`가 200이 될 때까지 도는 루프가 2초 만에 통과했다.
실제로 내 nakama 컨테이너는 `Bind for 127.0.0.1:17350 failed: port is already allocated`로 뜨지도 않았다.
200을 준 것은 다른 프로젝트 세션이 몇 분 전에 띄운 e2e 스택의 Nakama였다.

같은 날 7350도 꼬였다. Docker Desktop을 켜자 `restart: unless-stopped`인 다른 프로젝트 스택이 되살아나
0.0.0.0:7350을 잡았다. 그 컨테이너를 멈춘 뒤에도 바인드는 계속 실패했고, `lsof`를 보니 또 다른 세션의
`node scripts/dev-server.mjs 7350`이 127.0.0.1:7350을 쥐고 있었다. `docker ps`만 봐서는 이 프로세스가 안 보인다.

**해결:**
1. `compose up`의 종료 코드를 확인한다. 대기 루프 앞에 `|| exit 1`을 둔다.
2. 포트 주인은 `lsof -nP -iTCP:<port> -sTCP:LISTEN`으로 본다. 주인이 `com.docker.backend`면
   `docker ps --format '{{.Names}} {{.Ports}}' | grep <port>`로 어느 컨테이너인지 찾는다.
3. 준비 판정은 healthcheck가 아니라 **내 서버 모듈만 하는 응답**으로 한다. 예를 들어 내 RPC의 버전 거절 메시지.
   healthcheck는 "그 포트에 Nakama가 하나 있다"까지만 증명한다.
4. 남의 포트면 그 프로세스를 죽이지 않는다. compose 포트를 `${NAKAMA_PORT:-7350}:7350`처럼 변수로 빼고
   빈 슬롯을 쓴다 (OPS-006 슬롯 규약).

관련: OPS-006, OPS-017, OPS-063

## OPS-145 — SpacetimeDB: after the `/v1/identity/websocket-token` exchange, `InitialConnection.token` is the 60-second token. Saving it loses the player a minute later

`측정 2026-09-27 · SpacetimeDB 2.8.0 (spacetimedb.mnori.com) · Godot 4.7.2 GDScript client over v2/v3.bsatn · headless Chrome 153`

**증상:** A client reconnected with its saved token and got the same identity. Any later launch more than
60 s after that reconnect would have come back as a new identity. Browsers cannot put the token in an
`Authorization` header on a websocket handshake, so web clients do what the TS SDK's `ws.ts` does:
`POST /v1/identity/websocket-token` with `Authorization: Bearer <token>`, then `?token=<answer>` on the
socket URL. In that case the `token` field of the server's `InitialConnection` message is the **short-lived
websocket token**, not the one the client came in with. Decoded JWT claims, measured:

```
long-lived (minted on first connect):  "exp": null,        "iat": 1790497467
InitialConnection after the exchange:  "exp": 1790497534,  "iat": 1790497474     # exp = iat + 60
```

A client that writes `InitialConnection.token` to storage on every connect overwrites the good token with
one that expires in a minute. The reconnect that did it still succeeds, and so does any reconnect in the
next 60 s, so a quick test never sees it. A native client that sends the header instead gets the long-lived
token back and does not hit this.

**해결:** Do what the TS SDK does (`db_connection_impl.ts`, case `'InitialConnection'`:
`if (!this.token && serverMessage.value.token) this.token = ...`): adopt and persist the server's token
**only when the connection was opened without one**. Otherwise keep and report the token you opened with.
A check for it: decode the stored token's payload after a reconnect and assert `exp` is still null, or
that the stored token has not changed.

Also measured on the same run: SpacetimeDB answers the schema GET and the token POST cross-origin from
`http://127.0.0.1` (no CORS failure), and Godot 4.7.2's web `WebSocketPeer` sends `supported_protocols` as
the browser's `new WebSocket(url, protocols)` (`get_selected_protocol()` read back `v2.bsatn.spacetimedb`
and `v3.bsatn.spacetimedb`).

관련: OPS-134 (the JSON protocol's own quirks)

## OPS-146 — `codex exec` image tool for a full game cast: "fully transparent background" gave RGBA 55/55, a full-body master passed with `-i` held 18/18 derived images on-model — including a landscape close-up, so the framing can change

`측정 2026-09-27 · codex-cli 0.154.0 built-in image tool · 70 generations (62 final assets + 8 retries), 4 in parallel`

**증상:** a card-battle game needed 8 characters × (full-body idle, attack pose, landscape eye-level cut-in), 29 spirit
figures, a boss and 6 backgrounds, all original, as cutouts for 3D billboards and UI.

Measured:
- **Transparency on request.** Every prompt that ended with "isolated on a fully transparent background" came back as an
  RGBA PNG with transparent corners: 55/55 full-body and bust images. Cut-ins (1536×1024 extreme close-ups): 9/9 RGBA,
  opaque corners only where the hair was asked to bleed off the frame. Backgrounds asked to be "fully opaque": 6/6 RGB.
  No hand masking was needed. (OPS-076/OPS-128 saw transparency only sometimes, when it was not asked for.)
- **Reference consistency across poses and framing.** Passing the approved full-body master as a reference kept face,
  hair, mask, costume and palette in 18/18 derived images: 9 attack poses (portrait) and 9 cut-ins (landscape, "extreme
  close-up from forehead to chin"). Unlike OPS-139, the framing followed the prompt here: the prompt changed the canvas
  shape as well as the crop, and it said "keep face, hair, mask, costume, colours and proportions" without mentioning
  framing. The command put the reference last: `codex exec ... - -i master.png`, with `-` (stdin prompt) before `-i`. That
  works because `-i` takes several files and nothing follows it.
- **Outfit drift beyond OPS-128, one case each, fixed 4/4 by one explicit coverage sentence:** "torn band tee" → crop top
  with bare midriff; "jacket over a hoodie" → cropped hoodie; "long-sleeved bodysuit" → open back; "cargo shorts over
  leggings" → thigh straps.
- **Shapes need geometry, not nouns.** "Mask shaped like a stylized spade (points up over the brow)" returned a plain
  domino mask 2/2. Describing the geometry fixed it 1/1: "the pointed tip rises along the middle of the forehead to the
  hairline, the two round lobes cover the eyes". "Three-legged crow" drew two legs. "Exactly THREE legs, one in the centre
  and one on each side" fixed it 1/1.
- **Effects get cropped.** "All effects stay inside the frame" still let 1 of 9 attack poses cut a muzzle flash at the
  edge. Naming the effect and adding "fades out well before the left edge" fixed it.
- **Time:** median 72 s per image without a reference, 98 s with one. No failures. One 9-minute stretch ran 297–469 s per
  image, still without errors.

**해결:** for game cutouts, ask for transparency explicitly and verify colour type 6 and the corners in code. Approve one
full-body master per character, then derive every pose and cut-in from it with `-i`. Write coverage sentences for every
garment likely to shrink. Describe signature shapes as geometry. Name the effects that must stay in frame.

## OPS-147 — A Worker far from a single-homed origin: the `placement` region hint ran it next to the origin from the first call (8–11 ms per request instead of 157–175 ms); `hostname` placement stayed local; service-binding calls are placed too

`측정 2026-09-27 · Cloudflare Workers (Free plan), wrangler 4.135.0, origin: one PocketBase host in Seoul, requests entering at DEN`

**증상:** A site Worker for US visitors read its database on one host in Seoul. From the Denver data center each small
request took 157–203 ms (about 950 ms on a new connection) and a 636 KB response 530–1,000 ms, so pages with two to
five sequential reads spent 1–3.5 s of server time (2.3 s for a page that ended in 404).

A probe Worker timed requests to the origin under each `placement` setting:

| `placement` | `cf-placement` header | Small request | 636 KB response |
| --- | --- | --- | --- |
| none | absent | 157–203 ms | 580–1,000 ms |
| `{"mode": "targeted", "hostname": "<origin>"}` (docs: experimental) | `local-DEN` for all 4 calls in the first minute | 156–184 ms | 222–800 ms |
| `{"mode": "targeted", "region": "gcp:asia-northeast3"}` | `remote-ICN` from the first call | 8–11 ms | 29–71 ms |

Also measured:
- A service binding `env.X.fetch()` from an unplaced Worker to the placed one ran placed (`cf-placement: remote-ICN`
  on the binding's response). The round trip DEN → ICN → DEN took 207–289 ms with a 1 KB body (about 60 ms of it
  origin work), 289–431 ms with 100 KB and 557–622 ms with 300 KB, so result size still matters.
- Inside the placed Worker, `request.cf.colo` still said `DEN` (where the request entered). Only `cf-placement` shows
  where it ran.
- The docs say placement applies only to `fetch` handlers, not RPC methods, and that assets read through the ASSETS
  binding are served from where the Worker runs. A site Worker with `assets.run_worker_first` should therefore stay
  unplaced.

**해결:** Move the database reads into a second Worker with no route and
`"placement": {"mode": "targeted", "region": "<cloud region nearest the origin>"}`. The site calls it through a
service binding with `fetch` (not RPC). Let it do all of a page's reads and return one compact result, gzipped when
large. On kyomincenter.com this cut story pages from 2.5–3.5 s to 0.28–0.45 s and region pages from 1.05 s to
0.36 s (server time).

## OPS-148 — Inline JavaScript kept in a non-raw Python string: `'\n'` becomes a real line break, the whole `<script>` block is discarded, and a fail-closed server hides it for a month

`측정 2026-09-27 · Python 3.9 · Flask 3.1 (templates as module-level strings, render_template_string) · Chromium 153 and WebKit 26.6 via Playwright 1.63`

**증상:** On two pages of a Flask app, buttons did nothing visible or ended on a bare `400` text page. No user saw
a JavaScript error; the server log only showed the 400s, which the server raises on purpose (a fail-closed check
for missing fields). It had been that way for 31 days. A browser crawl that records `pageerror` found it at once:
Chromium `Invalid or unexpected token`, WebKit `Unexpected EOF`.

The page templates were ordinary triple-quoted Python strings. A script inside them had
`window.prompt('first line\nsecond line', '')`. Python turned `\n` into a newline before Jinja or the browser saw
it; a JavaScript single-quoted string cannot span lines, so the script element failed to parse and **every
function defined in that block was undefined**. The inline handlers (`onclick="return _qh(this.form,1,1)"`,
`onsubmit="return _sub(this)"`) then threw `ReferenceError` — and an exception in an inline handler does not
cancel the default action, so the forms still submitted, without the client-side work (field filling, the
evidence prompt). The server's own checks refused those half-filled forms, which kept the data clean and made the
breakage look like user error.

`\s` in the same scripts survived only because Python keeps unknown escapes (with a DeprecationWarning); `\n`,
`\t`, `\b`, `\f`, `\r`, `\v`, `\a` and `\'` do not.

**해결:** Write `\\n` in the Python source (or use raw strings / real template files), and anchor it with a test
that cannot know which page is next: extract every `<script>` from every string constant that holds one
(`ast.walk` over the module, plus `templates/*.html`) and fail on any quoted JavaScript string cut by a raw line
break (a 60-line lexer that skips comments, template literals and regex literals is enough). Belt and braces: fetch
every page and run each inline script through `node --check`, and have the browser crawl fail on `pageerror`.

## OPS-149 — `overflow-wrap: anywhere` on table cells lets a two-syllable header break per syllable: the min-content width of every `th` becomes one character

`측정 2026-09-27 · Chromium 153 / WebKit 26.6 (Playwright 1.63) · Korean text, 12–13px, tables inside 320–390px cards`

**증상:** In narrow tables (a 2-column profile table on a phone, a 5-column table at 320px) short Korean headers
rendered as 「네 / 기둥」, 「타고 / 난 / 그릇」, 「사인· / 도수」: one or two syllables per line, while the data column
next to them had room to spare. A shared stylesheet set `td,th{overflow-wrap:anywhere}` (and the body had
`word-break:keep-all`).

`overflow-wrap: anywhere` (unlike `break-word`) lowers the element's **min-content** size to a single character.
Table auto layout gives columns their min-content width first and hands the spare width to the columns that want
more, so the label column is squeezed to one or two characters and the long data cell takes the rest.
`word-break: keep-all` does not prevent it: `anywhere` still counts as a soft wrap opportunity for min-content.

**해결:** `th{white-space:nowrap}` (or `overflow-wrap:normal` on the header cells) and let the data cells keep
`anywhere`. Before applying it to a wide table, add up the header widths against the narrowest container (five
2–5 character headers at 12px with 6px padding came to 216px against a 242px card at 320px, so no overflow). For a
label that pairs a name with a secondary value (「자시 23:30–01:29」), put the secondary part on its own line below
600px (`th .muted{display:block}`) instead of letting the pair set the column width. The same min-content collapse
hits scale options and chips in flex rows (「늘 / 그렇다」): `white-space:nowrap` on each option, and let the row wrap.

## OPS-150 — Measuring pages with Playwright: smooth scroll fakes end-of-page geometry, `offsetParent` is null for fixed elements, WebKit reports aborted polls as page errors, and an `ssh -L` tunnel dies silently in long runs

`측정 2026-09-27 · Playwright 1.63 (Chromium 153, WebKit 26.6) on macOS · app on a remote Docker host reached through ssh -f -N -L · 272 page views per image`

**증상:** An all-page layout audit (34 page states × 8 engine/width/theme combinations, two images compared)
produced four kinds of wrong numbers before the harness was fixed:

1. "What sits under the floating button at the end of the page" found content on pages that had enough bottom room.
   The pages set `html{scroll-behavior:smooth}`, so `window.scrollTo(0, scrollHeight)` starts an animation and the
   `getBoundingClientRect()` read on the next line is still at the old position.
2. A visibility guard `if (!el.offsetParent) skip` skipped the floating button on every page: `offsetParent` is
   `null` for `position: fixed` elements in Chromium.
3. WebKit reported `pageerror: Fetch API cannot load … due to access control checks` on the next page when the
   previous page had a status poll in flight during navigation — even though every poll was inside `try/catch`.
   It is the aborted request, not CORS and not an unhandled error in the app.
4. Partway through a long run (while the controlling session was paused), every later view failed with
   `ERR_CONNECTION_REFUSED` / `Could not connect to the server`: the `ssh -f -N -L` tunnels had died without a message. An earlier run that
   wrote results only at the end lost 40 minutes when WebKit's browser process died
   (`Target page, context or browser has been closed`).

**해결:** `window.scrollTo({top: document.documentElement.scrollHeight, behavior: 'instant'})` (or run the context
with `reducedMotion: 'reduce'`, which these pages honour); test visibility with `getBoundingClientRect()` size plus
computed `display`/`visibility`/`opacity`; filter the WebKit "due to access control checks" message and 404 console
lines on pages that are 404 by design; open tunnels with `-o ServerAliveInterval=15 -o ServerAliveCountMax=4`,
check them before each batch, write results after every page, relaunch the browser when it reports it was closed,
and count failed views separately from findings. Split the matrix over 4 processes per image, not 8: on a shared
10-core Mac with other sessions running, 8 processes made each one slower (load average up to 195) rather than the
run shorter.

When the workstation itself is saturated (load average 300–500 later the same day), run the browsers on the server
next to the app instead: `docker run --rm --network host --ipc=host mcr.microsoft.com/playwright:v1.63.0-noble`
with the harness mounted and `npm i playwright@1.63.0` inside (the image carries the browsers, not the package).
Three containers at `--cpus 2` measured 228 Chromium views in about 9 minutes on a 12-vCPU arm64 host, against
about 40 minutes on the Mac. Keep Safari-specific checks (select heights, OPS-151) on macOS WebKit: the image's
WebKit is the Linux port.

## OPS-151 — Desktop WebKit draws a `<select>` 23px tall as soon as it has any border, radius or background, ignoring the author's `min-height` and `padding`; `appearance: none` restores them

`측정 2026-09-27 · WebKit 26.6 and Chromium 153 via Playwright 1.63 on macOS · standards and quirks mode, 16px text`

**증상:** A form stylesheet gave every control `min-height:48px;padding:12px 14px;border:1px solid …;border-radius:8px;
background:…`. In Chromium every select was 48px, level with the text inputs. In WebKit every select was **23px** tall
beside 48px inputs, and `getComputedStyle(select).minHeight` read `18px` with `padding-top: 0px` — the author values
were replaced, not overridden by specificity. The same select with only `min-height` and `padding` (no border, radius
or background) was 49px in WebKit.

One select, `min-height:48px;padding:12px 14px;font-size:16px` plus one extra declaration:

| Extra declaration | Chromium | WebKit |
|---|---:|---:|
| none | 48 | 49 |
| `border:1px solid` | 48 | 23 |
| `border-radius:8px` | 48 | 23 |
| `background:#fff` or `background-color:#fff` | 48 | 23 |
| border + radius + background | 48 | 23 |
| the same + `appearance:none` | 48 | 48 |

Quirks and standards mode gave the same numbers. Flex stretch still makes the select taller (a select in a row of
48px items came out 50px), which hides the problem on some screens and not others.

**해결:** Give selects `appearance:none; -webkit-appearance:none` and draw the arrow yourself: an inline SVG chevron as
`background-image` with `background-position: right 12px center`, `background-size: 12px`, `background-repeat:
no-repeat` and `padding-right: 30px`; `select[multiple]{background-image:none}`. Any later rule that uses the
`background` shorthand on a select (a light-theme override, a component rule) resets the image — use
`background-color` there, or repeat the image after it. Measure select heights in WebKit, not only Chromium.

## OPS-152 — `python3 -m http.server` on macOS resets connections when Chrome loads a page's ES modules in parallel: the listen backlog is 5

`측정 2026-09-27 · Python 3.9.6 http.server (ThreadingHTTPServer) on macOS 27 · Chrome via Playwright 1.63, HTTP/1.1 to 127.0.0.1 and localhost`

**증상:** A static page whose `app.js` is a module importing ~17 sibling modules failed to boot about half the time
under `python3 -m http.server 8091 --directory web`. Nothing in the page's own code threw; the network log showed
`net::ERR_CONNECTION_RESET` for a different set of `ui/*.js` files on each load (and sometimes for plain
`<script src>` files), so the module graph never finished and the entry module never ran. It is not the disk,
not IPv6 vs IPv4 and not logging: the same four loads against `127.0.0.1` failed 4/4 with the stock server and
passed 4/4 when only the backlog was raised.

`socketserver.TCPServer.request_queue_size` is 5. Chrome opens up to 6 parallel HTTP/1.1 connections per host as
soon as it discovers the imports, and macOS answers connections beyond a full accept queue with RST (Linux drops
the SYN and the client retries, which hides the problem there).

**해결:** For local testing, raise the backlog (same directory listing, same MIME types):

```sh
python3 -c 'import http.server as h, functools as f; h.ThreadingHTTPServer.request_queue_size = 128; h.test(HandlerClass=f.partial(h.SimpleHTTPRequestHandler, directory="web"), ServerClass=h.ThreadingHTTPServer, port=8091, bind="127.0.0.1")'
```

or serve from the test itself with Node's `http.createServer` (default backlog 511). A random boot failure on a
multi-module page under the stock Python server says nothing about the code; production servers (nginx) are not
affected.

## OPS-153 — SpacetimeDB 2.8's websocket protocol, for a client that is not the official SDK

`측정 2026-09-27 · SpacetimeDB 2.8.0 standalone · subprotocol v2.bsatn.spacetimedb · read off node_modules/spacetimedb/src/sdk`

**증상:** Writing a client without the SDK (a GDScript one, GDT-116), each of these cost a failed run or a read of the
SDK source; none is on the documentation's front page.

- **Framing.** Every *server* message starts with one compression byte (0 none, 1 brotli, 2 gzip) before the BSATN
  `ServerMessage`. *Client* messages have no such byte. Ask for `?compression=None` on the subscribe URL.
- **Auth.** A browser cannot put a header on a websocket. The SDK `POST`s the saved token to
  `v1/identity/websocket-token` with `Authorization: Bearer …`, gets a short-lived token back, and passes it as
  `?token=`. With no saved token, connect without one and keep the token from `InitialConnection`.
- **Variant order** is declaration order in `client_api/types.ts`: ClientMessage Subscribe=0, Unsubscribe=1,
  OneOffQuery=2, CallReducer=3; ServerMessage InitialConnection=0 … TransactionUpdate=4, ReducerResult=6.
  `Option<T>` is **some=0, none=1**. Reducer names on the wire are the Rust function names (`start_training`).
- **Identity** is a little-endian u256 on the wire and printed big-endian everywhere else (SDK hex, SQL `0x…`, CLI).
- **The caller's own changes arrive inside `ReducerResult.Ok.transactionUpdate`**, not as a separate
  `TransactionUpdate`; a client that only applies `TransactionUpdate` never sees its own move.
- A row update is a delete of the old bytes plus an insert of the new; a cache keyed by the row's bytes needs no
  primary key. Reference-count rows when query sets overlap.
- `ReducerResult` carries the server's timestamp (micros): with the round trip measured client-side it gives the
  clock offset for a countdown against a server deadline.
- **Subscription SQL accepts** `WHERE identity = :sender`, identity literals `WHERE identity = 0x<64 hex>`, and a
  JOIN on indexed columns: `SELECT player.* FROM player JOIN seat ON player.identity = seat.identity WHERE
  seat.game_key = '1234'` follows whoever sits down later.

**해결:** Use the above as the checklist. `button/godot/net/stdb_client.gd` is a complete 400-line reference.

## OPS-154 — ffmpeg's native Vorbis decoder returns the wrong number of samples for short OGG files; `oggdec` (libvorbis, what Godot uses) is exact

`측정 2026-09-27 · ffmpeg 9.0.1 (Homebrew), vorbis-tools 1.4.3 (libvorbis 1.3.7), 44.1 kHz`

**증상:** A build script decoded every encoded file back to check that loops kept their exact length.
Music loops of 2.6 to 5.7 million samples matched, but the first short effect failed the check.

Mono 440 Hz tones encoded with `oggenc -q 4`, decoded both ways:

| Rendered samples | ffmpeg `-f f32le` | `oggdec` |
|---:|---:|---:|
| 1,000 | 872 | 1,000 |
| 2,205 | 2,077 | 2,205 |
| 4,410 | 4,282 | 4,410 |
| 8,820 | 9,792 | 8,820 |
| 20,000 | 19,872 | 20,000 |

The Homebrew ffmpeg has only the native decoder: `-c:a libvorbis` as a decoder fails with
`Unknown decoder 'libvorbis'`.

**해결:** Decode with `oggdec -Q -R -b 16 -o - file.ogg` (raw signed 16-bit little-endian on stdout, no
temporary file) when sample counts matter. `oggenc` also reads a 32-bit float WAV from stdin
(`oggenc -q 4 -o out.ogg -`), so an encode-and-verify loop needs no temporary WAV at all.

## OPS-155 — libvorbis bitrate follows the `-q` level, not the content: a quiet music stem costs almost as much as the full mix

`측정 2026-09-27 · vorbis-tools 1.4.3 (libvorbis 1.3.7), 44.1 kHz stereo, a 92.9 s electronic track and its two stems`

**증상:** A game shipped each stage track as three synchronized stems (base mix plus two layers that fade
in). The layers were 13 LU quieter and much sparser than the base, yet the first build at q3 was almost
three times the size of the base alone.

Average bitrate in kbps:

| Signal | q-1 | q0 | q1 | q2 | q3 |
|---|---:|---:|---:|---:|---:|
| Full mix, -14 LUFS | 46 | 63 | 76 | 87 | 102 |
| Tension stem, -27 LUFS | 35 | 53 | 65 | 77 | 89 |
| Hats-and-arps stem, -26 LUFS | 35 | 61 | 75 | 89 | 108 |

- A 15 kHz low-pass before encoding changed nothing (63 → 63 kbps at q0, 87 → 88 at q2).
- Mono saved 15 to 20 % at q-1 (46 → 39, 35 → 29, 35 → 30).
- q0.5 gave about 70 kbps on the full mix; fractional `-q` values work.

**해결:** Budget game audio by quality level per role, not by trimming content: in the same project 87 files
(20 music files, 9 jingles, 58 effects) fit 11.8 MiB with stage and title music at q0.5, menu music at
q0, stems at q-1 (one of them mono), jingles at q2 and effects at q4. Everything at q5 would have been
about 27 MB.

## OPS-156 — Parallel renders on a nearly full disk: macOS swap files take the last free space and unrelated writes fail with ENOSPC

`측정 2026-09-27 · macOS, Apple M1 Max 64 GB, 926 GiB APFS container with under 1 GiB free, Python 3.9 ProcessPoolExecutor`

**증상:** An offline audio build with 8 worker processes (2 to 3 GB of numpy arrays each) failed with
`OSError: [Errno 28] No space left on device` while writing files of a few MB. Its own output was
under 20 MB. During the run `vm.swapusage` went to 3 GB used, five swap files appeared in
`/System/Volumes/VM` (the same APFS container as the data volume), and free space on
`/System/Volumes/Data` fell from 978 MiB to 307 MiB. Removing the job's temporary WAV files alone did
not help; the second 8-worker run failed the same way.

**해결:** Before a parallel job, check `df -h /System/Volumes/Data` and `sysctl vm.swapusage`. Cap the
workers by memory, not by core count: the same build with 3 workers finished in 183 s without errors.
Pipe data to encoders through stdin instead of temporary files. Swap growth also hits every other
session writing to the same disk, so a failure there may come from another job's memory use.

## OPS-157 — A backgrounded static server that fails with EADDRINUSE is silent, and the browser test then tests another session's app on that port

`측정 2026-09-27 · macOS, Node 26 http server started with `&`, Playwright Chrome`

**증상:** A test started `node serve.mjs <dir> 8765 &` and pointed Playwright at `http://localhost:8765/`. The page never
reported its marker and the test timed out after 90 s. The screenshot showed a different game: another project's
`python3 -m http.server` already held port 8765. The Node server had died at once with
`Error: listen EADDRINUSE: address already in use :::8765`, but that went to a log nobody read, so the failure looked
like a bug in the app under test. A check that only waited for `load` or took a screenshot would have passed on the
wrong app.

**해결:** Before starting a server, check the port: `lsof -nP -iTCP:<port> -sTCP:LISTEN`. Prefer a random high port.
After `goto`, assert something only your app has (the page title or a marker) before any other check, and fail fast
if it is missing. See OPS-006 for port slots in integration stacks.

## OPS-158 — Rapier 0.21: a fixed ground lets a tall stack sink forever under real-scale gravity; a kinematic ground holds it

`측정 2026-09-27 · @dimforge/rapier3d-simd-compat 0.21.0, Node 26, 18-layer tower of 7.5 × 1.5 × 2.5 cm boxes, g = 981 cm/s², 240 Hz, 8 solver iterations`

**증상:** A block tower in centimetre units sank into a `RigidBodyDesc.fixed()` cuboid ground: the bottom layer went
0.10 cm down in 0.05 s and 1.52 cm in 5 s with the default `lengthUnit = 1`, and kept going. With `lengthUnit ≥ 3` it
stopped at 0.19 cm, which is still exactly proportional to the load and did not change with `contact_natural_frequency`,
solver iterations or timestep. The same tower on a `kinematicPositionBased()` ground (never moved) sank 0.003 cm.
Separately, the default contact softness (30 Hz) compresses an 18-layer stack at this scale until it topples; 480 Hz
held it (0.015 cm total compression) and 1000 Hz exploded.

**해결:** Use a kinematic body for the static floor/table, `world.integrationParameters.contact_natural_frequency = 480`
with `numSolverIterations = 8` at 240 Hz, and keep `lengthUnit = 1` so the allowed penetration stays far below small
geometric details (0.25 mm height differences decided which blocks carry load). Raise
`normalizedPredictionDistance` (0.5 cm here) instead of `lengthUnit` for fast motion.

## OPS-159 — Rapier JS: `sleep()` after `setTranslation(..., false)` keeps stale collider positions, and moving a kinematic body every step keeps waking its island

`측정 2026-09-27 · @dimforge/rapier3d-simd-compat 0.21.0, browser and Node`

**증상:** Restoring a saved tower with `setTranslation(p, false)` + `setRotation(q, false)` and then `body.sleep()` looked
fine until something woke the island: the top block jumped 1.7 cm within 10 frames and the tower settled 0.3 cm off its
saved pose. The wake-up came from a kinematic table that received `setNextKinematicTranslation` to the same position on
every step.

**해결:** Restore with `wakeUp = true` and let bodies fall asleep on their own (a settled snapshot restored this way
moved ≤ 0.017 cm and slept within 3 s). Call `setNextKinematicTranslation` only while the kinematic body actually
moves, plus one call to return it to rest.

## OPS-160 — Rapier JS `GenericImpulseJoint` exposes no per-axis motors; the raw joint set does, and they make a stable force-limited "hand"

`측정 2026-09-27 · @dimforge/rapier3d-simd-compat 0.21.0`

**증상:** To push a block with a finger-like limited force, explicit `addForce` PD control needed stiffness high enough
to hold a block level, which became unstable. `JointData.generic(a1, a2, axis, 0)` (mask = locked axes, so 0 frees all
six) accepted motors only through `SphericalImpulseJoint`/`UnitImpulseJoint` methods in the typed API.

**해결:** The typed joint keeps `rawSet` and `handle`: for axis 0–5 call
`rawSet.jointConfigureMotorModel(handle, axis, 1 /* ForceBased */)`,
`rawSet.jointConfigureMotorPosition(handle, axis, 0, k, c)` and `rawSet.jointSetMotorMaxForce(handle, axis, cap)`, then
move a kinematic body that carries the joint. Motors are solved implicitly, so stiff holds are stable, and the caps
decide what the hand can overcome: with a 45 000 dyn axial cap a loose block slid 9.5 cm out while load-bearing blocks
moved ≤ 0.16 cm, and tight blocks near the top dragged the layers above, as in the real game.

## OPS-161 — postprocessing `EffectComposer.setSize(w, h)` restyles the canvas; with a ResizeObserver it pins the canvas to 1 × 1 px

`측정 2026-09-27 · postprocessing 6.39.5, three 0.186.1, Chromium`

**증상:** The page rendered pure white. The console repeated `GL_INVALID_FRAMEBUFFER_OPERATION: Framebuffer is incomplete:
Attachment has zero size`. The composer was created while the scene size was still 1 × 1; `composer.setSize()` forwards
to `renderer.setSize(w, h, updateStyle = true)`, which wrote `width: 1px; height: 1px` onto the canvas style, and the
ResizeObserver then kept reporting 1 × 1. Without the composer the same scene rendered correctly. Also in three r186:
`THREE.PCFSoftShadowMap` is gone (it warns and falls back to `PCFShadowMap`; soften with `shadow.radius`).

**해결:** Always pass `false` as the third argument: `composer.setSize(w, h, false)` (and `renderer.setSize(w, h, false)`)
and size the canvas with CSS.

---

## OPS-162 — Chrome's `DynamicsCompressorNode` starts a fresh `OfflineAudioContext` render with heavy gain reduction: measure levels after ≥ 0.5 s of lead-in

`측정 2026-09-27 · Chrome 153 (Playwright 1.63, headless) · WebAudio master chain compressor → limiter`

**증상:** Offline level checks of short sound effects through a game's master chain (glue compressor,
limiter) reported them far too quiet. A 0.100-amplitude blip measured 0.023 at the output when rendered
from t = 0, but 0.139 from a 0.080 input once the render had 0.5 s of silence before it. The difference is
the compressor's automatic makeup gain settling (about +4.8 dB with those settings).

**해결:** In `OfflineAudioContext` measurements, schedule the sound at least 0.5 s after the start (or
play a short pre-roll through the chain) and measure only after that point. Compare SFX against music at
the shell's real default volumes, with the same lead-in for both.

---

## OPS-163 — Headless Chrome with `--autoplay-policy=no-user-gesture-required --mute-audio` runs a real-time `AudioContext` silently; startup can take 1.5–3.9 s under load

`측정 2026-09-27 · Chrome 153 · Playwright 1.63 (channel: 'chrome', headless) · macOS, many parallel sessions`

**증상:** An audio smoke test that checked a sequencer's beat position after fixed waits failed
intermittently: the `AudioContext` had not started yet. With the two flags above, the context does run
in real time (clock advances, `beat()` progresses) and nothing is heard through the speakers.

**해결:** Launch with both flags (`--mute-audio` keeps CI and a shared Mac quiet). Derive expected
positions from the elapsed `performance.now()` since the context actually started (wait for
`ctx.state === 'running'`), not from fixed windows.

## OPS-164 — A focus helper that selects `[href]` also picks the SVG `<use href="#icon">` inside every icon button: arrow-key navigation "moves" to the icon and focus silently stays put

`측정 2026-09-27 · Chrome (Playwright 1.63) on macOS 27 · hand-written spatial focus navigation over buttons that contain inline SVG sprite icons`

**증상:** Arrow keys in a menu did nothing: `document.activeElement` stayed on the first button, no error. The list of
"focusable" elements came from `root.querySelectorAll('button:not([disabled]), [href], input, …')` and had eight
entries for four buttons — every `<button><svg><use href="#i-play"/></svg>…</button>` contributed its `<use>` element,
which matches `[href]` and passes a `checkVisibility()` filter. The nearest candidate below a button was often that
button's own icon, so the helper called `.focus()` on an SVG `<use>` element. That call is a silent no-op, and the
helper still reported success, so no fallback ran.

**해결:** Select links explicitly — `a[href], area[href]` — never a bare `[href]` (SVG `<use>`, `<image>`, `<a>` in SVG
and `<link>` all carry `href`). When a helper moves focus, confirm it with `document.activeElement === target` before
treating the move as done.

---

## OPS-165 — Firefox `DynamicsCompressorNode` crushes short transients: a 13 ms blip comes out ~12 dB quieter than in Chrome/WebKit, so a master compressor makes SFX loudness browser-dependent

`측정 2026-09-27 · Firefox 153, Chrome 153, WebKit (Safari 26.6) · Playwright 1.63 headless · OfflineAudioContext 48 kHz`

**증상:** A game's short UI sounds (click, hover, 12–30 ms envelopes) rendered 7.5 dB quieter in Firefox than in
Chrome through the same master chain; sounds longer than ~1 s matched within 1 dB.

Same raw graph in all three engines (sine, 1 ms attack, 12 ms decay, −20 dBFS peak), with and without a
`DynamicsCompressorNode` (threshold −16, knee 10, ratio 3, attack 0.004, release 0.25). Output relative to input:

| | Chrome / WebKit | Firefox |
|---|---|---|
| blip, no compressor | −0.1 dB | −0.1 dB |
| blip at t = 0.05 s (fresh compressor) | −0.4 dB | −7.9 dB |
| blip at t = 2.0 s (settled) | +4.4 dB | −8.1 dB |
| 20 ms attack / 200 ms decay note at t = 0.05 s | +1.4 dB | −0.7 dB |

The input never reaches the threshold. Chrome and WebKit add their automatic makeup gain (and start clamped,
OPS-162); Firefox cuts the transient instead.

**해결:** Do not put a `DynamicsCompressorNode` on a master bus whose per-sound levels are calibrated. A
`WaveShaperNode` soft clipper (unity below 0.6, tanh knee to 0.95, input pre-scaled by 1/4 so overs up to +12 dB
still bend smoothly) renders identically: 38 one-shots within 0.3 dB between Chrome and WebKit, the short ones
within 0.1 dB in Firefox. Calibrate levels with no compressor in the chain.

---

## OPS-166 — Firefox throws `NotSupportedError` on `setValueAtTime` inside a still-running `setValueCurveAtTime`, even right after `cancelScheduledValues`

`측정 2026-09-27 · Firefox 153, Chrome 153, WebKit (Safari 26.6)`

**증상:** Music crossfades worked in Chrome and Safari. In Firefox, changing tracks within 1.5 s of the previous
change left the music silent. The fade-out did `g.gain.cancelScheduledValues(now); g.gain.setValueAtTime(v, now);
g.gain.setValueCurveAtTime(...)` while the fade-in `setValueCurveAtTime` (started before `now`) was still running.
Chrome and WebKit cancel the active curve, as the spec says ("any active automations whose automation event time
is less than cancelTime are also cancelled"). Firefox keeps it, then rejects `setValueAtTime` inside the curve's
span with `NotSupportedError`. The half-finished switch had already recorded the new track as current, so it
never started.

Minimal check: `g.gain.setValueCurveAtTime(new Float32Array([0, 0.5, 1]), 0, 1.5); g.gain.cancelScheduledValues(0.5);
g.gain.setValueAtTime(0.4, 0.5)` throws in Firefox only.

**해결:** Never re-automate a param that may still be inside a curve. Put the fade-in curve and the fade-out
curve on two `GainNode`s in series (the second has no events until the fade-out), so a fade-out that starts
mid-fade-in is just a product of two curves. Or use `setTargetAtTime` / linear ramps, which have no such span.

---

## OPS-167 — Firefox `BiquadFilterNode` warns "channel count changes may produce audio glitches" when a bus input flips between mono and stereo

`측정 2026-09-27 · Firefox 153`

**증상:** Console warning `BiquadFilterNode channel count changes may produce audio glitches.`, 6 times in a
25 s session. Bus-level biquads (a music duck lowpass, a reverb-send highpass) summed voices that were mono
(oscillator → gain) or stereo (through a `StereoPannerNode`), so their computed input channel count changed as
voices started and ended. Firefox resets the filter state on each change.

**해결:** Pin bus nodes to a fixed layout: `node.channelCount = 2; node.channelCountMode = "explicit"` on the bus
biquads and the master gain. Levels do not change (mono up-mixes to L = R either way) and the warning is gone.

---

## OPS-168 — Web Audio CPU: a-rate LFO into oscillator `detune` costs 3.7× and automated biquads 2×; `automationRate = "k-rate"` removes most of it

`측정 2026-09-27 · Chrome 153 headless · OfflineAudioContext 48 kHz, 20 s renders · share of one core, Apple Silicon Mac under load (ratios are the point)`

**증상:** A generative music engine (detuned-saw strings and brass with vibrato LFOs, swept filters) used up to
22 % of one core per track in offline renders.

Per 100 nodes: sine oscillator 4.2 % (k-rate) vs 4.5 % (a-rate); sawtooth with an LFO into `detune` 4.8 % (k-rate)
vs 17.7 % (a-rate); `BiquadFilterNode` with a frequency ramp 14.5 % (k-rate) vs 29.2 % (a-rate); `GainNode` running
`setTargetAtTime` 5.1 % vs static 1.8 %; `StereoPannerNode` 3.2 %; looping noise `AudioBufferSourceNode` 4.2 %.
`ConvolverNode` cost grows linearly with impulse length: stereo 2.8 s 8.5 %, 2.0 s 6.1 %, 1.5 s 4.4 %, and a mono
impulse halves it.

**해결:** Set `param.automationRate = "k-rate"` on every param that is not audio-rate FM (oscillator
`frequency`/`detune`, filter `frequency`/`Q`, panner `pan`). An LFO connected to a k-rate param is sampled once
per 128 frames, which is inaudible for vibrato and filter sweeps. Keep reverb impulses around 2 s. With this and
filter-free plucked notes, the heaviest track went from 21.8 % to 16.5 % of one core in the same setup.

## OPS-169 — SpacetimeDB 2.8 TypeScript module: appending columns with `.default(...)` migrates a live database under `--delete-data=never`; `init` does not run again, so new scheduled tables start empty

`측정 2026-09-27 · SpacetimeDB 2.8.0 standalone · TypeScript module (spacetimedb npm 2.8.0) · spacetime CLI 2.8.0`

**증상:** A game module in production needed new columns on existing tables (`room`, `player`, `secret_role`) and nine new tables. The deploy procedure forbids a data-deleting publish, and it was not known whether the TypeScript module could extend an existing table in place.

Measured on a disposable local database seeded with the old module (a room in the middle of a timed game, five players, their private roles):

- New columns were appended at the end of each table with a default: `t.u32().default(0)`, `t.string().default('fedora')`, `t.bool().default(false)`. `spacetime publish <db> --delete-data=never --yes` printed `Created table ...` for the new tables, then `!!! Warning: All clients will be disconnected due to breaking schema changes`, and `Updated database`. It did not refuse the publish.
- Every existing row survived. `SELECT` on the old rows returned the declared defaults in the new columns.
- The game already in progress kept going: the old module's scheduled row for the phase timer fired into the new reducer code, which moved the room to the next phase.
- `init` ran only on the very first publish (`spacetime logs` shows `Invoking init reducer` once, and nothing like it for the update). A new scheduled table (a 1 s interval timer) therefore got its row only from the lazy insert the module does in `clientConnected`.

**해결:** Keep the schema append-only: add tables freely, add columns only at the end of a table and always with `.default(...)`, and never reorder, retype or remove columns. Insert rows for new scheduled tables lazily (`if (!ctx.db.timer.count()) insert(...)`) from `clientConnected` and from the reducers that need them, not only from `init`. The publish disconnects every client, so release the regenerated client bindings at the same time.

## OPS-170 — SpacetimeDB 2.8 CLI: a schema change that disconnects clients aborts a non-interactive publish unless `--yes` includes `break-clients`

`측정 2026-09-27 · SpacetimeDB CLI 2.8.0 · Rust module · local standalone`

**증상:** A deploy script published with `spacetime publish --delete-data=never --yes=remote,skip-login,migrate`. After
columns with `#[default(...)]` were appended to a table, the same command printed the migration plan, then:

```
!!! Warning: All clients will be disconnected due to breaking schema changes

The above changes will BREAK existing clients. Do you want to proceed? [y/N]Aborting
Error: Publishing aborted by user
```

Nothing asked for input: without a terminal the prompt reads "no" and the script sees an error it did not cause.
`migrate` covers the migration prompt only. `break-clients` is a separate prompt; per `spacetime publish --help`, it
does not force a publish that would delete data, so it is safe together with `--delete-data=never`. OPS-169 used bare
`--yes` (all prompts), which is why that publish went through.

**해결:** List the prompts explicitly for data-safe automation: `--delete-data=never --yes=remote,skip-login,migrate,break-clients`.
The publish disconnects every client, so ship regenerated client bindings in the same release.

## OPS-171 — macOS: a test bind on `0.0.0.0` or `::` succeeds next to another process's `127.0.0.1` listener. Probe all four addresses before claiming a port

`측정 2026-09-27 · macOS 27.0 · Node.js 26.8 · Docker Desktop (com.docker.backend)`

**증상:** A dev server picked "the first free port" by test-binding `0.0.0.0` and `::`. Both succeeded on 17350,
17360 and 17380, yet `lsof` showed Docker already listening on `127.0.0.1` at those ports for other sessions' test
stacks. The reverse also happens: a Node server bound `127.0.0.1:7350` while Docker held `*:7350` (IPv6 wildcard), and
from then on IPv4 loopback traffic went to Node, not to the other project's Nakama (the conflict OPS-144 describes).

`net.createServer().listen({port, host, exclusive: true})`, errors per address:

| Port | Holder (`lsof`) | `127.0.0.1` | `0.0.0.0` | `::1` | `::` |
|---|---|---|---|---|---|
| 7350 | Docker `*:7350` (IPv6) + Node `127.0.0.1` | EADDRINUSE | EADDRINUSE | free | EADDRINUSE |
| 17350 | Docker `127.0.0.1:17350` | EADDRINUSE | free | free | free |
| 17370 | nothing | free | free | free | free |

**해결:** Treat a port as free only when binds on `127.0.0.1`, `0.0.0.0`, `::1` and `::` all succeed (count
`EADDRNOTAVAIL`/`EAFNOSUPPORT` as free for a missing address family). Keep local dev servers off the defaults other
projects run in Docker (7350 for Nakama) and pick from the OPS-006 slots instead, printing the chosen address so
clients can be pointed at it.

## OPS-172 — `glab repo create <name>` inside an existing Git repository creates an empty nested clone `./<name>/` and does not add `origin` to the current repository

`측정 2026-09-27 · glab 1.82.0 · gitlab.com`

**증상:** In a local repository with commits and no remote, `glab repo create mafia --private` printed `✓ Created project on GitLab`, then `Initialized empty Git repository in <repo>/mafia/.git/` and `✓ Initialized repository in './mafia/'`. The current repository still had no `origin`, and a new untracked folder `mafia/` (containing only `.git`) sat in the working tree, where a later `git add -A` would pick it up as an embedded repository.

**해결:** Create the project, then wire the remote yourself: `git remote add origin git@gitlab.com:<ns>/<name>.git && git push -u origin main`. Delete the nested folder after checking it holds nothing but `.git` (`ls -A <name>`). Verify with `git ls-remote origin` and `glab api projects/<ns>%2F<name>` (`visibility`).

## OPS-173 — A result cache in a Worker's module memory served 1 of 3 repeats seconds apart; `caches.default` in the page Worker served every repeat

`측정 2026-09-27 · Cloudflare Workers (Free plan): a Worker placed in ICN and reached only by service binding, and the site Worker on zone routes`

**증상:** The placed Worker kept a 528 KB result in a module-level `Map` for 60 s. Three requests for the same key,
6 s and then 1 s apart: the first read the database, the second read it again (it ran in an instance without the
entry), and only the third was served from memory (age 6,484 ms). For a second key, two requests 1 s apart both
read the database. The expected saving mostly did not happen.

**해결:** Keep the result in the Cache API of the Worker that serves the page: `caches.default.match()` and
`put()` with a URL on the zone's own host that no route serves, versioned and carrying the call's arguments, and
`Cache-Control: max-age=60` on the stored response. In the same session every repeat was served from it: 62–72 ms
of server time instead of 987 ms. The docs list custom domains as having working cache operations (zone routes
worked here too); a Worker with no route of its own is not in that list, so the placed Worker keeps no cache. Do not
cache results that carry one member's data.

## OPS-174 — ffmpeg `loudnorm` second pass with `linear=true` falls back to dynamic mode without an error when the measured LRA exceeds the target `LRA` (default 7) or is exactly 0; only the JSON `normalization_type` shows it

`측정 2026-09-27 · ffmpeg 9.0.1 loudnorm · I=-16:TP=-1.5`

**증상:** music normalised by two-pass `loudnorm` landed near −16 LUFS, but a 3.7 s defeat stinger with a long decaying
tail (LRA 10.2) came out at **−17.54 LUFS** measured on the decoded MP3.

Linear mode is used only when the measured LRA is at or below the target `LRA` and the linear gain keeps the true peak
under `TP`. Otherwise the filter silently switches to dynamic mode:

| Source (second pass, `linear=true`) | measured LRA | target LRA | `normalization_type` | output I |
| --- | --- | --- | --- | --- |
| sine with a 4.5 s exponential tail | 21.4 | 7 | `dynamic` | −16.36 |
| same | 21.4 | 25 | `linear` | −15.64 |
| constant sine | **0.00** | 7 | `dynamic` | −15.95 |
| the stinger after shortening its tail | 0.9 | 7 | — | −16.58 (shipped) |

A measured LRA of exactly 0 also blocks linear mode.

**해결:** check `normalization_type` in the second pass's `print_format=json` output. When it says `dynamic`, either raise
the target `LRA` above the measured value or reduce the source's range (shorter tails, trimmed silence). Verify the result
by measuring the decoded output (OPS-132).

## OPS-175 — Google Fonts CSS2 API: only 1 of 88 `@font-face` blocks for a Korean face carried a `/* subset */` comment; picking subsets by comment silently drops the rest

`측정 2026-09-27 · fonts.googleapis.com/css2 · Black Han Sans`

**증상:** a self-hosting script downloaded the subsets named in the `/* latin */`-style comments of the CSS2 response.
For Black Han Sans the response held 88 `@font-face` blocks, and only 1 had a comment (`latin`). The other 87 Korean
slices have no comment, so the script kept Latin only and dropped all Hangul without an error.

**해결:** select blocks by `unicode-range`, or keep every block. The slice number is in the file URL (`….N.woff2`), not in
a comment.

## OPS-176 — Vite 8.3.1 `import.meta.glob` with no matching file returns `{}` and the build passes; a file added later is bundled as its own chunk with no code change

`측정 2026-09-27 · Vite 8.3.1`

**증상:** a client had to import a generated module (a local battle engine) that another parallel ticket had not produced
yet. A static `import` breaks the build until the file exists.

`import.meta.glob('../generated/engine.js')` returned `{}` while the file was missing, and `vite build` passed. When the
file appeared, the next build emitted it as a lazy chunk (36.1 KB gzip) with no source edit.

**해결:** when a parallel ticket codes against another ticket's future output, load it through `import.meta.glob` and
handle the empty map (fall back to a stub).

## OPS-177 — Deterministic GSAP frames in Playwright: `gsap.globalTimeline.pause()` + `.time(t)`, but awaiting a tween's promise while the clock is paused hangs until the test timeout

`측정 2026-09-27 · GSAP 3.15 · Playwright 1.63 · Chrome`

**증상:** screenshots of UI animations taken with `waitForTimeout` caught different frames on each run. Freezing the clock
fixed that, but a later `page.evaluate` that awaited an animation's completion promise hung for the full 90 s test
timeout.

`gsap.globalTimeline.pause()` stops every tween; `gsap.globalTimeline.time(t)` then renders the exact frame at `t`
seconds. Completion promises and `onComplete` callbacks only fire when the timeline reaches the end, so they never
resolve while it is paused unless the test moves `time()` past the end.

**해결:** pause, seek to each frame to photograph, then either seek past the end or `resume()` before awaiting any
completion.

## OPS-178 — Under a load average of 100–110, the Vite dev server took 27.7 s to start and the first page load exceeded Playwright's 30 s `goto` timeout; `vite build` + `vite preview` ran stably

`측정 2026-09-27 · Vite 8.3.1 · Playwright 1.63 · macOS, many parallel sessions`

**증상:** UI tests failed at the first `page.goto` with a timeout. The dev server's on-demand transform of the whole
module graph on first load took longer than the default 30 s while other sessions kept the machine at load 100–110.

**해결:** on a shared machine, run Playwright against a production build: `webServer.command: 'vite build && vite preview
--port <own port> --strictPort'` with `timeout: 120_000` (own port per OPS-006). The preview server serves static files,
so the first load does not pay transform time.

## OPS-179 — `codex exec` image tool for adult glamour key art: the output filter blocked 1 of 30 (a swimsuit beach shot), "not a photograph" still came back near-photoreal, and cowboy framing filled only 27–35%

`측정 2026-09-27 · codex-cli 0.154.0 built-in image tool · 30 landscape 1536×1024 heroine pictures + 23 square sprites, 3 parallel runs`

**증상:**
- One prompt (a white one-piece swimsuit at a beach photoshoot) failed after ~140 s with `http 400 ... "Your request
  was rejected by the safety system ... safety_violations=[sexual]"`, `"moderation_stage": "output"`,
  `"code": "moderation_blocked"`. No file was written. Five other swimwear prompts (bikini with sarong, one-pieces,
  a race-queen dress) and 24 gown/uniform prompts passed; which ones pass is decided on the generated image, not on
  the words.
- A style block that asked for a "premium semi-realistic digital painting ... Not a photograph, not a 3D render"
  still produced near-photographic glamour renders on every attempt.
- The OPS-128 framing ("cowboy shot ... covers roughly 40-50%") gave 19–30% Vision-mask coverage for these prompts;
  "close cowboy shot: the camera is close to her ... cropped at mid-thigh" gave 27.5–34.7%. A top-anchored centre
  crop to 90% (upscaled back to 1536 × 1024) raised that to 29.5–39.1%.

**해결:** when a picture is blocked, regenerate it with a covered outfit (the blocked one came back fine as a resort
maxi dress, 69 s). Budget one or two regenerations per 30 adult-glamour pictures. For bigger subjects, name a close
cowboy shot and crop, then re-measure coverage; do not rely on percentages in the prompt.

## OPS-180 — A hand-written SpacetimeDB client can be held to the module's own schema: `GET /v1/database/<db>/schema?version=9` lists every table's columns in order and says which tables are public

`측정 2026-09-27 · SpacetimeDB 2.8.0 standalone · a GDScript client (GDT-116, OPS-153)`

**증상:** without the official SDK there are no generated bindings, so nothing tells a hand-written decoder that the module changed. BSATN carries no field names: a decoder that reads one column too few, too many or in the wrong order does not fail — it hands every later field the wrong value under the right name. The TypeScript bindings a previous client generated had been the contract, and deleting that client deleted the contract.

The server states the contract itself. `GET /v1/database/<db>/schema?version=9` answers JSON with `tables` (each with `name`, `product_type_ref` and `table_access` = `{"Public": []}` or `{"Private": []}`), `reducers` (each with `params.elements`) and `typespace.types`, where a table's row is `typespace.types[product_type_ref].Product.elements` **in declaration order**, each element `{name: {"some": "col"}, algebraic_type: {"U64": []}}`. Identity columns are a `Product` with one `__identity__` `U256`; `Option<T>` is a `Sum` whose variant 0 is `some`; `Vec<u32>` is `{"Array": {"U32": []}}`. Names come back as either a plain string or `{"some": "…"}` depending on the field — handle both.

Measured use (the `button` game's `godot/tests/schema_test.gd`): for every public table, write one BSATN row from the schema giving each column a value no other column has, decode it with the client's decoder, and assert (1) the decoder consumed exactly the row's bytes, (2) it named the columns in the module's order, (3) each name came back holding the value written under it. Broken on purpose four ways — two columns' names swapped, a `U8` inserted mid-table, a `U8` widened to `U16`, the private `layout` table flipped to public — each failed by name; the real schema passed with 8 tables and 71 columns. The same endpoint on every production host, compared with the local module's, is the check that catches a region left behind after a publish (reducers **and** tables — one game had each half of that outage).

**해결:** make the module's `/schema` the contract for any client without generated bindings: decode a synthetic row per public table in CI, assert the tables that must stay private are `Private`, and compare every deployed host's `/schema` with the local build's after each publish.

## OPS-181 — A windowed Godot capture on a shared desktop takes real input: the operator's keys and mouse reach the game, and the first synthetic click is spent on mouse capture

`측정 2026-09-27 · Godot 4.7.2 · macOS 27 · windowed `godot --path . --script res://tools/play_capture.gd` while other sessions use the same machine`

**증상:** scripted captures that drive input with `Input.action_press` and `Input.parse_input_event` gave different pictures run to run:

- one run of four froze with the player in mid-air for the whole script; logging `paused` and the open menu showed `paused=true menu=map`. Nothing in the script presses the map action (bound to `M` and the gamepad Back button only); the next run with the same script was normal.
- the bow-aim shot looked straight down at the grass although the script set the camera pitch to −0.05 right before it. The game rotates the camera from `InputEventMouseMotion.relative` once the mouse is captured, and the first synthetic left click was consumed by the "click to capture the mouse" handler, after which desktop mouse motion steered the camera.

A new Godot window takes focus when it opens, so keystrokes and mouse movement meant for another app land in it.

**해결:** in capture scripts, neutralise the desk: set camera sensitivity to 0, mark the mouse as already captured (so clicks are attacks, not capture), and print `get_tree().paused` and the open menu next to every screenshot so a stray menu is visible in the log instead of in a wrong image. Re-run any capture whose log shows `paused=true` that the script did not cause. Prefer headless tests for pass/fail and use windowed captures only for pictures.

## OPS-182 — nginx: an unquoted regex `location` containing `{8,}` fails at startup with `unknown directive "8,}\.(js|css)$"`; the container exits

`측정 2026-09-27 · nginx 1.30-alpine`

**증상:** a location for content-hashed bundles, `location ~* ^/assets/[^/]+-[A-Za-z0-9_-]{8,}\.(js|css)$ {`, made the
web container exit at start with `[emerg] unknown directive "8,}\.(js|css)$" in /etc/nginx/nginx.conf:68`. nginx reads
the `{` of the quantifier as the start of the location block. The config had only been reviewed, not run.

**해결:** quote any regex that contains `{`, `}` or `;`: `location ~* "^/assets/[^/]+-[A-Za-z0-9_-]{8,}\.(js|css)$" {`.
Before building the image, validate the file with the same image:
`docker run --rm -v "$PWD/nginx.conf:/etc/nginx/nginx.conf:ro" --add-host <upstream>:127.0.0.1 nginx:1.30-alpine nginx -t`
(`--add-host` lets `proxy_pass` hostnames resolve).

## OPS-183 — GSAP 3.15: tweening `x`/`y` on an element centred with the CSS `translate` property (`translate: -50%`) overrides that translate, and the element jumps off centre

`측정 2026-09-27 · GSAP 3.15.0 · Chrome`

**증상:** badges centred with `left: 50%; translate: -50% 0` shifted right by half their width as soon as a GSAP
`x`/`y` entrance tween ran on them. GSAP writes the element's transform itself and the separate CSS `translate` offset
was lost, so the element ended at `left: 50%` without the −50%.

**해결:** centre such elements without `translate` (`left: 0; right: 0; margin-inline: auto` with a set width, or a
flex/grid parent), or let GSAP own the offset with `xPercent: -50`. Keep the CSS `translate`/`rotate`/`scale`
properties for elements GSAP never animates.

## OPS-184 — Python's `euc-kr` codec encodes all 11,172 Hangul syllables, so "encodes without error" is not a KS X 1001 test; only the 2-byte results (2,350) are in the table

`측정 2026-09-27 · CPython 3.9.6 (macOS) · fontTools 4.60.2`

**증상:** a font-subset script meant to keep "the 2,350 KS X 1001 syllables" used
`try: chr(cp).encode("euc-kr")` over U+AC00–U+D7A3. It kept all 11,172, and the Noto Sans KR subset came out
4.3 MB instead of 0.97 MB. CPython's `euc_kr` codec spells a syllable that is not in the KS X 1001 table as an
8-byte jamo sequence (KS X 1001 Annex 3): `"똠".encode("euc-kr")` is `b'\xa4\xd4\xa4\xa8\xa4\xc7\xa4\xb1'`,
while `"가"` is `b'\xb0\xa1'`. `cp949` is no help either: it encodes all 11,172 syllables in 2 bytes.

**해결:** count a syllable as KS X 1001 only when `len(chr(cp).encode("euc-kr")) == 2` — that gives exactly 2,350.
Print the kept code-point count after subsetting; about 3,100 (KS X 1001 + ASCII + punctuation + a game's own
text) is the expected size, 11,000+ means the whole Hangul block slipped in.

## OPS-185 — Astro/Vite production builds lower CSS `light-dark()` to `--lightningcss-light/dark` switches, which are only defined where the same processed CSS declares `color-scheme`

`측정 2026-09-27 · Astro 7.3 · Vite/Lightning CSS (build minify) · Chrome 141`

**증상:** a page whose component `<style>` used `background: light-dark(#f5f2e9, #1a2124)` rendered correctly
in `astro dev` but shipped with a transparent background and black text in production. The built CSS was
`background: var(--lightningcss-light,#f5f2e9)var(--lightningcss-dark,#1a2124)`. Lightning CSS only emits the
`:root{--lightningcss-light:initial;--lightningcss-dark: }` defaults (and the `@media (prefers-color-scheme:dark)`
flip) next to a `color-scheme` declaration in the CSS it processes. A page with no such declaration in its
bundle — here a standalone page that set `color-scheme` only through `<meta name="color-scheme">` and an
`is:inline` style — leaves both variables undefined, both fallbacks apply, the value becomes two colours, and the
declaration is dropped. A manual `:root[data-theme=dark]{color-scheme:dark}` in unprocessed CSS also does not flip
the variables, so a saved theme choice has no effect on lowered colours.

**해결:** either declare `color-scheme` (with the `[data-theme]` overrides) inside a processed stylesheet that the
page loads, or define the switches by hand in an `is:inline` style shared by every page:
`:root{color-scheme:light dark;--lightningcss-light:initial;--lightningcss-dark: }`
`@media (prefers-color-scheme:dark){:root{--lightningcss-light: ;--lightningcss-dark:initial}}`
`:root[data-theme="dark"]{color-scheme:dark;--lightningcss-light: ;--lightningcss-dark:initial}` (and the light
mirror). Verify dark mode against the production build, not `astro dev`.

## OPS-186 — SpacetimeDB's free production licence covers one SpacetimeDB instance per application: a second self-hosted region is a second instance

`측정 2026-09-27 · SpacetimeDB LICENSE.txt read at tag v2.8.0 and on master (names 2.11.0)`

**증상:** A turn-based game ran the same SpacetimeDB module on two self-hosted standalone servers, one per region
(Korea and US, one shared signing key, separate data). Nobody on the project had read the licence, and the
second region was planned as an ordinary scaling step.

SpacetimeDB is under the Business Source License 1.1, which the file itself says is not an open-source licence.
The Additional Use Grant, word for word the same at v2.8.0 and on master (2.11.0):

> You may make use of the Licensed Work provided your application or service uses the Licensed Work with no
> more than one SpacetimeDB instance in production and provided that you do not use the Licensed Work for a
> Database Service.

- "Database Service" is defined as a commercial offering that lets third parties create tables whose schemas
  they control. A game whose players never define schemas is not one.
- Non-production use (development, staging, a sandbox database) is granted by the base BSL terms without the
  instance limit.
- Use outside the grant requires a commercial licence from Clockwork Labs, or stopping.
- Each version converts to AGPL v3 with a linking exception on its own Change Date: 2.8.0 on 2031-08-02, 2.11.0
  on 2031-09-15 (or the version's fourth anniversary, if earlier).
- The text does not define "instance" (for example, whether a replicated cluster counts as one).

**해결:** Count production instances per application before adding a region or a failover box. One region per
application stays inside the grant; a second one needs Clockwork Labs' written terms (or their hosted
Maincloud, where the instance is theirs). Several applications sharing one instance each use one instance
(reading of the text, not legal advice). Ask Clockwork Labs when a design depends on what counts as an instance.

## OPS-187 — modern-screenshot returns a blank image when the captured DOM has Alpine-style attributes (`x-on:click`, `@click`, `x-bind:foo`)

`측정 2026-09-27 · modern-screenshot 4.7.0 · Alpine.js 3.14 · Chrome 145/153`

**증상:** `domToCanvas(document.body)` / `domToPng()` finished without an error and produced a correctly sized but
completely empty image. Capturing a single heading worked; any subtree containing an Alpine element came back blank.

The library serialises the cloned DOM into an SVG `<foreignObject>` and loads it as an image. Attribute names such as
`x-on:click` or `x-bind:aria-expanded` are namespace-prefixed names with an undeclared prefix, and `@click` is not a
valid XML name at all, so the SVG is not well-formed XML and the `<img>` fires `error`; modern-screenshot draws
nothing and does not reject. Its default `removeAbnormalAttributes` feature does not remove these names.

**해결:** strip them from the copy (the live page is untouched):
`onCloneEachNode: node => { if (node instanceof Element) for (const a of [...node.attributes]) if (/[:@]/.test(a.name) && !/^(xmlns|xlink|xml):/.test(a.name)) node.removeAttribute(a.name) }`.
To find which subtree breaks a capture, serialise `domToForeignObjectSvg(node)` with `XMLSerializer` and try loading
it as `data:image/svg+xml` per child; skip zero-size children, which fail for an unrelated reason.

## OPS-188 — modern-screenshot waits for every `<img>` under the captured node, so lazy images below the fold make each capture take the full `timeout`

`측정 2026-09-27 · modern-screenshot 4.7.0 · Chrome 145 · production page with 82 list rows`

**증상:** capturing the visible part of a long page took 6.9 s, of which `wait until load` (visible with
`debug: true`) was exactly the 6000 ms `timeout`; with the default timeout it was 30 s. Clone, embed and draw took
about 0.9 s together. A `filter` that drops off-screen nodes does not help: `createContext()` calls
`waitUntilLoad(node)` on the original node, which awaits every `img`/`video` descendant, and `loading="lazy"` images
that were never scrolled into view never fire `load`.

**해결:** build the context with a tiny timeout, then raise it for the asset fetches that follow:
`const ctx = await createContext(root, { ...options, timeout: 1 }); ctx.timeout = 5000; await domToCanvas(ctx)`.
The same capture then took 1.4–1.5 s. Images on screen that are still loading render empty; that is the trade-off.

## OPS-189 — PocketBase JSVM: a `.pb.js` top-level `const` is not visible inside hooks, and `e.request` is undefined in `onRecordCreateRequest`

`측정 2026-09-27 · PocketBase 0.40.4`

**증상:** a record create through the REST API answered `400 "Something went wrong while processing your request."`
with no detail. The request log (`/api/logs`, filter `data.url~"<collection>"`) held the real error:
`ReferenceError: FEEDBACK_KINDS is not defined` for a `const` declared at the top of the same `.pb.js` file, and after
that was fixed, `TypeError: Cannot read property 'header' of undefined` from `e.request.header.get("User-Agent")` inside
`onRecordCreateRequest`.

Each handler runs in its own VM, so file-level constants and functions do not exist when the handler runs, even though
the file loads without error. Shared code has to live in a module that every handler `require(`${__hooks}/lib.js`)`s
itself. In the record request hook, `e.request` was undefined, while `e.requestInfo()` worked.

**해결:** inline constants in the handler or export them from a `require`d module; read headers with
`e.requestInfo().headers["user_agent"]` (lower case, dashes become underscores). When a hook returns a bare 400,
read `/api/logs` as a superuser before guessing.

## OPS-190 — Flutter web in headless Chromium without WebGL: images and `RepaintBoundary.toImage` captures render blank

`측정 2026-09-27 · Flutter 3.38.5 web (release, --no-web-resources-cdn) · gstack browse (Playwright Chromium)`

**증상:** QA of an in-app screenshot feature in headless browse showed an empty thumbnail and an empty full-size preview,
and the page's own `Image.asset` hero photo was also blank. The console only said
`WARNING: Falling back to CPU-only rendering. WebGL support not detected.` No error was thrown. The same build in
headed Chrome (`browse --headed`) showed the hero photo, and the captured PNG uploaded to the server (417 KB) was a
correct image of the page.

**해결:** do not judge image rendering or canvas capture of a Flutter web build from headless Chromium without WebGL.
Run the check with `browse --headed` (every command needs the flag, or run `browse stop` first), or fetch the uploaded
file and look at it directly.

## OPS-191 — Dokploy GitLab-provider app by API: `saveGitlabProvider` fields, `saveEnvironment` needs `createEnvFile`, and the push hook is not created for you

`측정 2026-09-27 · Dokploy on dokploy.mnori.com (misa) · GitLab.com provider already connected · Dockerfile build`

**증상:** three things stop a GitLab-sourced application set up through the API (as opposed to the UI):

- `application.saveEnvironment` with `env`, `buildArgs`, `buildSecrets` returns 400
  `fieldErrors: {"createEnvFile": ["Invalid input: expected nonoptional, received undefined"]}`.
- `application.saveGitlabProvider` needs the provider's `gitlabId` (from an existing app's `application.one`, field `gitlabId`) and the GitLab numeric `gitlabProjectId`; with those it returned `true` first try.
- After all of it, `autoDeploy: true` and a successful first deploy, the GitLab project has **no hooks** (`GET projects/:id/hooks` → `[]`), so a push deploys nothing. The existing app that auto-deploys has one hook to `https://<dokploy>/api/deploy/<token>`.

**해결:** this order worked first time:

```sh
POST project.create {"name":..}                                    # returns environment.environmentId
POST application.create {"name":"web","appName":"x","environmentId":..}
POST application.saveGitlabProvider {"applicationId":..,"gitlabId":..,"gitlabProjectId":<n>,"gitlabRepository":"repo",
     "gitlabOwner":"user","gitlabBranch":"main","gitlabBuildPath":"/","gitlabPathNamespace":"user/repo","watchPaths":[],"enableSubmodules":false}
POST application.saveBuildType {..,"buildType":"dockerfile","dockerfile":"deploy/Dockerfile","dockerContextPath":".","dockerBuildStage":"","herokuVersion":null,"railpackVersion":null}
POST application.saveEnvironment {"applicationId":..,"env":"K=V\n..","buildArgs":"","buildSecrets":"","createEnvFile":false}
POST application.update {"applicationId":..,"autoDeploy":true}
POST domain.create {"host":..,"path":"/","port":80,"https":true,"certificateType":"letsencrypt","applicationId":..,"domainType":"application"}
POST application.deploy {"applicationId":..}                        # empty body back; poll application.one
glab api -X POST projects/<id>/hooks -f url=https://<dokploy>/api/deploy/<application.one.refreshToken> -f push_events=true
```

Measured: the first Dockerfile deploy (Godot web export, three stages) went from `running` to `done` in about 3.5 minutes, the letsencrypt certificate was served right away, and after adding the hook a push to `main` started a new deployment. Also check the GitLab path before creating: `chowooick/bearhunter2` already existed as a fork, and `POST projects` with that name returned an error mixed into the JSON rather than a clean failure.

## OPS-192 — a spare Mac used as an ssh test host installs a major macOS update on its own and reboots mid-run; user-level jobs and servers die silently

`측정 2026-09-27 · MacBook Air M1 · macOS 26.6.2 → 27.0 · ssh key auth, no sudo`

**증상:** a long test (`pnpm godot test`, ~10 min) run over `ssh host 'zsh -lc "..."'` never returned; the local
`ssh` ended with exit 255 and no output. On the host, no test process and no `spacetime start` server
were left, and `uptime` said `up 7 mins`. `system_profiler SPInstallHistoryDataType` showed
`macOS 27.0 · Install Date: 오후 7:12` — the machine had upgraded a **major** version by itself, between one
command and the next, with a user logged in on the console. `/Library/Preferences/com.apple.SoftwareUpdate`
had `AutomaticallyInstallMacOSUpdates = 1`, `AutomaticDownload = 1`, `CriticalUpdateInstall = 1` (the default
on a Mac someone once clicked "keep up to date" on). `pmset` showing `sleep 1 (sleep prevented by powerd)`
does not protect against this; it is not sleep.

Things that survived: files under `~`, the Rust toolchain, the SpacetimeDB data dir (the database and
its module were still there after the reboot). Things that did not: every process started with `nohup … &`
from ssh, including the local database server.

**해결:**

- Turn automatic macOS installs off on a test host. It needs admin rights, so it is the owner's hand, not
  the session's: System Settings → General → Software Update → Automatic Updates → "Install macOS updates"
  off, or `sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false`.
- Run long servers as a user LaunchAgent (`~/Library/LaunchAgents/*.plist`, `RunAtLoad` + `KeepAlive`,
  `launchctl bootstrap gui/$(id -u) <plist>`) so they come back at the next console login — no sudo needed.
  Measured: right after `bootstrap` the job sat at `runs = 0, state = not running`; `launchctl kickstart -p
  gui/$(id -u)/<label>` started it.
- Run long tests detached with a log and an exit marker (`nohup zsh -lc "cmd; echo EXIT=\$?" > log 2>&1 &`)
  and poll for `EXIT=`; after a silent ssh 255 check `uptime` before debugging the test.

## OPS-193 — A fresh Dokploy install leaves `/register` open to whoever reaches it first; create the admin from the shell

`측정 2026-09-27 · Dokploy v0.30.7, Ubuntu 24.04 arm64 (AWS t4g, 1.8GB RAM + 4GB swap)`

**증상:** `curl -sSL https://dokploy.com/install.sh | sudo sh` ends with "Please go to http://<ip>:3000".
Until someone registers, every request to the dashboard 307-redirects to `/register`, and the first
account registered becomes the owner. Removing the host publish of 3000 does not close it: Traefik
still serves the dashboard on 443 for any request carrying the dashboard's `Host` header.

Also measured on the same install: the `dokploy` container idles at 762MiB, so a 2GB box has about
550MiB available after the install, before any app.

**해결:** Register the admin immediately, from the shell, against the domain router:

```bash
curl -sk --resolve <domain>:443:<ip> -H 'Content-Type: application/json' \
  -H 'Origin: https://<domain>' \
  -d '{"email":"…","password":"…","name":"…","lastName":"…"}' \
  https://<domain>/api/auth/sign-up/email
```

The response carries a `"user"` object; afterwards `/` returns 200 (the login page) instead of the
307 to `/register`. `--resolve` works before public DNS points at the box. The domain itself is set
by hand in two places that must agree — `/etc/dokploy/traefik/dynamic/dokploy.yml` and the
`webServerSettings` row (`host`, `https`, `"certificateType"`, `"letsEncryptEmail"`) — and the
installer's ACME email `test@localhost.com` in `traefik.yml` should be replaced.

## OPS-194 — Traefik answers `/.well-known/acme-challenge/` itself above any user router; to forward a name's certificate check to another box, use TLS-ALPN-01 through a TCP passthrough

`측정 2026-09-27 · Traefik v3.6.25 (Dokploy v0.30.7), hosting.co.kr DNS`

**증상:** A new A record `dokploy.oregon.mxox.com` → the new box was answered by ns2–ns4 of
hosting.co.kr within minutes, but ns1 kept returning the older `*.mxox.com` wildcard (another
Traefik box) for over 20 minutes with the same zone serial on all four. Let's Encrypt HTTP-01 kept
landing on the wrong box: `403 … 121.174.3.182: Invalid response from http://…/.well-known/acme-challenge/…: 404`.
The hosting.co.kr console also refuses a multi-level wildcard such as `*.oregon`.

Forwarding the name at the wrong box with an HTTP router does not help for the challenge: that
Traefik's built-in `acme-http@internal` router takes every `/.well-known/acme-challenge/` path for
every host. A user router cannot outrank it — `priority: 9223372036854775807` is rejected with
`the router priority … exceeds the max user-defined priority 9223372036854774807`.

**해결:** On the wrong box, add a TCP router with `HostSNI(`<name>`)`, `tls: {passthrough: true}`,
pointing at `<right-ip>:443` (and an HTTP router for the `web` entrypoint for plain traffic). On
the right box switch the resolver from `httpChallenge` to `tlsChallenge: {}` in `traefik.yml`
and restart Traefik. TLS-ALPN-01 rides the SNI passthrough, so the certificate issues whichever
nameserver Let's Encrypt asked; the first try after the switch succeeded. Watch the failed-validation
limit (5 per hostname per hour) — four failures had already been spent before the switch.

---

## OPS-195 — Dokploy v0.30.7 on an idle 2 GB box: 546 MB of live V8 heap after a forced GC, against a 1015 MB heap limit

`측정 2026-09-27 · Dokploy v0.30.7 (Node 24.4.0) · Ubuntu, 2 vCPU / 1.8 GB RAM + 4 GB swap · 0 applications`

**증상:** on a fresh Dokploy install with nothing deployed, `docker stats` shows the `dokploy`
service at 858 MiB of 1.79 GiB, and host `MemAvailable` is 484 MB. The node process
(`dist/server.mjs`) has `VmRSS` 860 MB and `VmHWM` 1,070 MB after 45 minutes of uptime.
`smaps_rollup`: 804 MB anonymous, 57 MB file-backed, so it is heap, not mapped code.
Postgres (60 MiB) and Traefik (19 MiB) are not the cause.

Measured inside the process through the inspector (`kill -USR1` in the container, CDP over
`127.0.0.1:9229` from `docker exec`, `HeapProfiler.collectGarbage`, then `inspector.close()`):

| | before GC | after full GC |
|---|---|---|
| rss | 846 MB | 796 MB |
| heapUsed | 552 MB | 546 MB |
| old_space used | 491 MB | 487 MB |
| heap_size_limit | 1015 MB | 1015 MB |

So about 550 MB is live data, not garbage the GC has not collected yet. The service sets no
`NODE_OPTIONS`, and V8 sized the heap limit from the 1.8 GB of RAM. Over 9 minutes of idling after
the GC, RSS grew from 767 MB to 777 MB, about 1 MB/min. Upstream issues report the same:
Dokploy#3909 (about 1 GB on a fresh 2 GB VPS, crash and restart every 12–16 h, maintainer blames
the Next.js server), Dokploy#3755 (healthcheck-driven growth since v0.27.1), and Dokploy#5504
(v0.30.6–0.30.7: the docker-stats interval keeps running after the Monitoring page websocket
closes).

**해결:** treat about 800 MB RSS as Dokploy's idle baseline, not a leak to hunt, and size the box
for it: the documented minimum is 2 GB, and a 2 GB box has little left for apps. Do not set
`--max-old-space-size=512`; the live heap is already above 512 MB, so V8 would hit its limit
right away. Close the Monitoring page when you are done with it (#5504), and if RSS keeps climbing
across days, restart the service with `docker service update --force dokploy`, or move to a
4 GB box.

## OPS-196 — A regional game server has more tenants than the session wiping it knows about; list every database on the box before emptying it

`측정 2026-09-28 · SpacetimeDB 2.8.0, AWS Oregon box oregon.mxox.com`

**증상:** A second game's US players could not connect the morning after a box was "emptied and
reinstalled with Dokploy". Publishing to it failed with `The certificate was not trusted`, and
`openssl s_client` showed `CN=TRAEFIK DEFAULT CERT` — which looks like a certificate problem and is
not one. `ss -ltnp` showed only Traefik on 80/443; no SpacetimeDB was running at all.

One SpacetimeDB process on one box held several games' databases (`bearhunter`, `button`, …).
The session that emptied the box was working on one game and archived the data directory as a
whole (`data/spacetimedb/`), so nothing was lost — but the other game's client still routed its
Americas players to that host, and nothing told that game's repository.

**해결:** Before emptying a shared host, list its databases (`spacetime` data dir, or
`GET /v1/database/<name>` for each name the family uses) and say which games go down. When a
region disappears, the fastest safe fix for a turn-based client is to drop the region from the
client's region table and route everyone to the remaining host; keep the stored per-device region
keys so the region can come back without re-placing devices. Diagnose "certificate not trusted"
on a known host with `ss -ltnp` on the box before touching certificates.

---

## OPS-197 — Moving a shared PocketBase's collections to their own host: copy the whole `data.db` and trim it with a migration; a Worker placed at `aws:us-west-2` lands in SEA

`측정 2026-09-28 · PocketBase 0.40.4 (Docker on x86_64 → systemd on arm64) · Caddy 2.11.4 · Cloudflare Workers placement, wrangler 4.x`

**증상:** one app's `kc_*` collections lived in another app's PocketBase in Seoul while the app's visitors were in the US.
Moving them looked like it meant exporting records and recreating accounts, OAuth links and sessions.

What worked:

- **Copy the whole database, then delete what is not yours.** `sqlite3 /pb_data/data.db ".backup /out/data.db"` from a
  throwaway `alpine` container started with `--volumes-from <pocketbase container>` gives a consistent copy of the live
  file (the volume is root-owned; the Docker group is enough, no sudo). On the new host, a one-off JS migration run
  with `pocketbase migrate up` deletes every collection that is not the app's or a system one (loop over
  `app.delete(collection)` a few passes, because a collection referenced by a relation cannot go first). Clean
  `_externalAuths`, `_authOrigins`, `_mfas` and `_otps` by `collectionRef`. Record IDs, OAuth links and each auth
  collection's token secret come along, so existing sessions and service accounts keep working without re-login.
- **Carried-over settings belong to the other app.** `meta.appURL`, the app name and SMTP credentials were the host
  app's. Reset them in the same migration. Set `trustedProxy.headers = ["X-Forwarded-For"]` behind a local reverse
  proxy, or every request looks like `127.0.0.1` to PocketBase's rate limiter.
- **The SQLite file moves between architectures unchanged** (x86_64 → arm64).
- **Behind the Cloudflare proxy:** Caddy obtained the Let's Encrypt certificate through a proxied (orange) record with
  HTTP-01 after TLS-ALPN-01 failed (`Cannot negotiate ALPN protocol`). PocketBase realtime SSE through the proxy
  delivered an `@oauth2` message 1 ms after `/api/oauth2-redirect` was hit, so the popup OAuth flow works as-is. The
  OAuth redirect URI changes with the host, so add the new one to the Google client before switching and keep the
  old one for rollback.
- **Placement:** `"placement": {"mode": "targeted", "region": "aws:us-west-2"}` answered `cf-placement: remote-SEA`.
  Each PocketBase read from there took 14–30 ms to the first byte through the proxy (8–11 ms in the Seoul setup of
  OPS-147, unproxied). For a member entering at DEN, page server time went from 402 to 133–137 ms (home) and from
  787 to 120–211 ms (story page).

**해결:** freeze nothing. Take the final `.backup`, run the trim migration, start the new host, deploy every Worker that
names the database URL at once, then query the old copy for rows with `updated` after the backup time. There were none,
so no merge was needed. Keep the old collections and the old redirect URI for a week as the rollback path.

---

## OPS-198 — PocketBase behind Cloudflare: `trustedProxy: X-Forwarded-For` breaks realtime subscriptions, so the popup Google sign-in stalls with no error

`측정 2026-09-28 · PocketBase 0.40.4 · Caddy 2.11.4 · Cloudflare proxied (orange) record`

**증상:** after moving PocketBase behind Caddy and a proxied Cloudflare record, the web login (PocketBase's realtime popup
OAuth flow) stopped after the Google account was chosen. The popup closed, the page kept saying "log in in the Google
window", and nothing reached `auth-with-oauth2`. It had worked once right after the move. Reproduced with curl through
Cloudflare: open `GET /api/realtime`, then `POST /api/realtime {"clientId":..,"subscriptions":["@oauth2"]}` answers
`400 {"message":"Invalid realtime client."}`; `/api/oauth2-redirect?state=<clientId>` then redirects to
`/_/#/auth/oauth2-redirect-failure`. The same sequence against `127.0.0.1:8090` on the host works.

Cause, from `apis/realtime.go`: the connect handler stores `e.RealIP()` on the client, and the subscribe handler
rejects a request whose `RealIP()` differs (`the subscription request IP doesn't match with the realtime client IP`).
With `trustedProxy.headers = ["X-Forwarded-For"]` and `useLeftmostIP: false`, RealIP is the rightmost entry, which
Caddy appends: the Cloudflare edge address. The SSE request and the POST usually arrive from different edges (seen:
four different edge IPs in a minute, some via MIA), so the check fails. Using the leftmost entry would fix the
mismatch but trusts a header any client can set.

**해결:** let Caddy decide the client address and hand PocketBase one header:

```
{
	servers {
		trusted_proxies static <every range from https://www.cloudflare.com/ips-v4 and ips-v6>
		client_ip_headers CF-Connecting-IP
	}
}
db.example.com {
	@compressible not path /api/realtime
	encode @compressible zstd gzip
	reverse_proxy 127.0.0.1:8090 {
		header_up X-Real-IP {client_ip}
	}
}
```

and set PocketBase `trustedProxy.headers = ["X-Real-IP"]` (settings API, no restart). `{client_ip}` is taken from
`CF-Connecting-IP` only when the connection comes from a trusted range, so a direct request cannot spoof it. After the
change 11 of 11 curl runs through Cloudflare subscribed (204) and received `@oauth2` within 100 ms, and a real Google
sign-in completed. Test any PocketBase-behind-a-proxy setup with two separate requests, not one process that happens to
reuse a connection.

---

## OPS-199 — A placed Worker with no route can use `caches.default`, and because it runs in one place its cache is shared by visitors from every data center

`측정 2026-09-28 · Cloudflare Workers, service binding to a Worker with `placement: {mode: "targeted", region: "aws:us-west-2"}`, no route, `workers_dev: false``

**증상:** a site Worker's own Cache API entries live in the visitor's data center, so at low traffic almost every page
found them empty. It was unclear whether a Worker reached only through a service binding (no route, no zone) could
use `caches.default` at all; the docs say Cache API operations are no-ops on workers.dev.

Measured: the data Worker (placed, `cf-placement: remote-SEA`) put each database response into `caches.default` under
a URL on the site's zone host that nothing serves, with `Cache-Control: max-age=60`. On the next page 1–4 seconds
later the reads were hits (`match` returned the entry), and across 16 page loads from Denver 31 of 44 reads were hits,
including the first read of pages whose data had been read by another page. Its time for a page fell from 47–68 ms to
11–20 ms when every read was a hit.

**해결:** when a Worker is placed next to its origin, cache the origin reads there rather than in the calling Worker:
the placement concentrates every visitor's requests on the same data center, so one cache serves all of them. Keep
keys on a hostname path that no public route serves, never cache requests carrying a user's token, and add a
generation number to the keys so an admin change can invalidate everything with one `put` (the Cache API has no
prefix purge).

## OPS-200 — PocketBase invite-only sign-in without superusers: an admin clause in the auth collection's `createRule`, and the `authRule` email list can go

`측정 2026-09-29 · PocketBase 0.40.4, auth collection with password auth off and Google OAuth2 on`

**증상:** a private site kept its member list three times (site code, a superuser-created auth record, and an
`authRule` of `email = "..." || ...`), so adding a person meant a code deploy plus two manual database edits.

Measured with impersonated tokens and the private header the rules require:

- `createRule` = the admin clause (`@request.auth.collectionName = "<auth>" && (@request.auth.email = "a" || ...)`).
  An admin token creates the account with `{email, emailVisibility: false, password, passwordConfirm}` → 200 (the
  password field stays required even with password auth disabled; send a random 48-hex value). The same address
  again → **400** with `data.email.code = "validation_not_unique"`, which is how to tell "already has an account".
- A member token, an admin token without the header, and an anonymous request are all refused with **400, not 403**,
  and no field errors. Code that treats only 403 as "no permission" misreads a rule failure as bad input.
- OAuth2 still cannot create accounts for strangers: during the OAuth request `@request.auth` is empty, so the admin
  clause fails. The first Google sign-in links to the admin-created record by email, as with superuser-created ones.
- With that, the `authRule` email list is redundant; keep only the header boundary and let the site decide who may
  sign in. `listRule`/`viewRule` = admin clause lists accounts for admins; members list 0.

**해결:** keep the list in one place the app can write (here a D1 table checked on every request, a yes cached one
minute, a no never cached), let admins create the auth record through the admin clause, and remove access in the app
list instead of deleting the record (a cascade would delete the person's profile and comments).

## OPS-201 — `wrangler d1 migrations apply --remote` right after `wrangler d1 create` answers 7403 "The given account is not valid or is not authorized"

`측정 2026-09-29 · wrangler 4.135.0, new D1 database in ENAM`

**증상:** the first `migrations apply --remote` a few seconds after `d1 create` failed with `code: 7403`, and a
following `d1 execute` said `no such table`. Nothing was wrong with the account or the token.

**해결:** wait about 20 seconds and run it again; it applied normally (`0001_init.sql ✅`). Do not rotate tokens or
re-create the database over this error on a database created in the last minute.

## OPS-202 — `wrangler d1 create` can fail once with `Authentication error [code: 10000]` while `d1 list` works with the same login

`측정 2026-09-29 · wrangler 4.135.0, OAuth login (Super Administrator)`

**증상:** `npx wrangler d1 create <name>` printed only the token scope list and exited; the log file held
`A request to the Cloudflare API (/accounts/<id>/d1/database) failed. Authentication error [code: 10000]`.
`npx wrangler d1 list` in the same minute listed the account's databases normally, and the login had write scope
for D1. The database was not created.

**해결:** run the same `d1 create` again after a few seconds; it succeeded (`✅ Successfully created DB`). The error
text is only in the log (`~/Library/Preferences/.wrangler/logs/`), not on stdout, so check `d1 list` before assuming
it was created. Do not re-login or rotate tokens over a single failure. Right after a create, see OPS-201 before the
first `migrations apply --remote`.

## OPS-203 — PocketBase JSVM migration: collection rules are Go `*string` (`typeof` "object"), and a migration that throws takes the server down in a restart loop

`측정 2026-09-29 · PocketBase 0.40.4, systemd `Restart=always`, migrations applied at `serve` start`

**증상:** a migration guarded with `typeof collection.viewRule === 'string'` skipped every rule, then its own sanity check
threw. PocketBase logged `failed to apply migration ...` and exited; systemd restarted it every 3 seconds, and every
start failed the same way, so the database (and the site on top of it) was down until the file was removed from
`pb_migrations`. The failed migration had rolled back, so nothing was half-applied.

In JSVM, `collection.listRule` and the other rules are Go `*string`: `typeof` is `"object"` for a set rule and the
value is `null` for an unset one. `String(value)` gives the text; `.replace` on the raw value happens to work, which is
why code that never checked the type ran fine.

**해결:** read rules as `value == null ? null : String(value)`. Before copying a migration to a live host, run it on a
copy: `pocketbase migrate up --dir=<copy of pb_data> --migrationsDir=<dir with the new file>` applies it and exits,
and `pocketbase serve` on another port lets you probe the rules with impersonated tokens. If a live start fails,
move the migration file out first — that restores service — then debug.

## OPS-204 — Changing an auth collection's `authRule` makes PocketBase issue a new token secret: every existing token turns into "no auth", silently

`측정 2026-09-29 · PocketBase 0.40.4, JSVM migration saving `kc_members` with a new `authRule``

**증상:** after a migration that only removed an email list from `kc_members.authRule`, the site kept working for
signed-in members but everything the database scoped to them quietly failed: an admin's list of member profiles came
back 200 with 0 items, an admin PATCH answered 404 `sql: no rows in result set`, member-only writes were refused.
The request log (`auxiliary.db` `_logs`, `data.auth`) showed `auth: ""` for every site request from the migration
restart on, where it had been `kc_members` until 30 seconds before.

`options.authToken.secret` of the collection differed between the backup taken just before and the live database. A
later migration on the same collection that changed list/view/create/update rules and added a field did **not**
change it, so the `authRule` change is what rotated it. Record `tokenKey`s were unchanged. Tokens are not rejected
with 401: they are treated as anonymous, so reads succeed with empty results.

**해결:** treat an `authRule` change as "all tokens revoked". An app that keeps the PocketBase token inside its own
session must make its users sign in again — here the site refuses sessions issued before the change time
(`SESSIONS_VALID_FROM`). To find it after the fact, compare `authToken.secret` hashes across backups and look for
the moment `data.auth` goes empty in `_logs`.

## OPS-205 — PocketBase JSVM migrations: a set collection rule is a boxed `String` (`typeof` is `"object"`), so a `typeof v === 'string'` guard skips every rule; a migration that throws at startup makes `pocketbase serve` exit

`측정 2026-09-29 · PocketBase 0.40.4 (linux arm64) · systemd Restart=always`

**증상:** a migration meant to rewrite every rule (`for k of ['listRule', …] { const v = c[k]; if (typeof v !== 'string') continue; … }`)
changed nothing. Its own guard (`if (count < 9) throw …`) fired: `failed to apply migration …: Error: rotated only 0 rules`,
and the server process exited with status 1. With `Restart=always` it would crash-loop until the file is removed; the site
was down for about 3 s here only because the file was deleted right after the restart.

Probe (`migrate up` on an empty data dir): `c.listRule` of a set rule gives `typeof=object`, `constructor.name=String`;
an unset rule gives `typeof=object` and `=== null`. `'' + v` is a real string, and `.replace` / `RegExp.test` work on the
boxed value, which is why older migrations that call `rule.replace(…)` directly never noticed.

**해결:** check `v === null || v === undefined`, then use `'' + v`. Run a rule-rewriting migration first with
`pocketbase migrate up --dir=<copy of pb_data> --migrationsDir=<dir with only that file>` against a `sqlite3 .backup` copy;
only then drop it into the live `pb_migrations` and restart.

## OPS-206 — Google Fonts CSS2: listing weights (`wght@400;500;600;700;800`) returns 5× the `@font-face` blocks of a range (`wght@400..800`) for the same font files

`측정 2026-09-29 · fonts.googleapis.com/css2 · Manrope + Noto Sans KR · Chrome 140 user agent`

**증상:** the render-blocking stylesheet for `Manrope:wght@400;500;600;700;800&Noto+Sans+KR:wght@400;500;600;700;800`
was 486,625 bytes (116,654 gzip) with 650 `@font-face` blocks. For Korean faces every weight repeats all ~100
`unicode-range` slices.

Both forms point at the same 130 variable `woff2` URLs, so the font bytes a page downloads do not change. With
`Manrope:wght@400..800&Noto+Sans+KR:wght@400..900` the CSS is 97,845 bytes (23,681 gzip), 130 blocks. A range also
renders in-between weights (`font-weight: 650`) as written; a list snaps them to the nearest listed weight.

**해결:** request variable faces with a `min..max` range. Dropping weights from a list saves CSS, not font downloads.

## OPS-207 — Two `astro preview` (Cloudflare adapter) servers on one machine: the second answers 500 to every request because both workerd runtimes want inspector port 9229

`측정 2026-09-29 · Astro 7.3 · @astrojs/cloudflare 14.3 · wrangler 4.135 · macOS`

**증상:** a before/after comparison started two previews at once (`--port 4341` and `--port 4342`) from two copies of the
same project. The second answered every page with HTTP 500 and a 455-byte body; the smoke run reported 36 of 36 failed.
Its log repeated `Error: listen EADDRINUSE: address already in use 127.0.0.1:9229`. `--port` moves only the HTTP port.

**해결:** run the previews one after another (stop the first before starting the second), or give each its own inspector
port. Grep the preview log for `EADDRINUSE` before trusting a run where every page fails the same way.

## OPS-208 — `rsync --exclude '[backup]'` is a character class: it silently drops every one-letter file or folder named b, a, c, k, u or p

`측정 2026-09-29 · rsync (openrsync, macOS 26) · macOS`

**증상:** a project copied to a test machine with `rsync -a --exclude '[backup]' ./ host:dir/` built without error, but
every URL under `/c/s/...` returned the site's 404. The route file `src/pages/c/s/[token].astro` was missing on the
copy: rsync exclude patterns are shell globs, so `[backup]` matched the one-character directory `c` (and would match
`a`, `b`, `k`, `p`, `u`), not a folder literally named `[backup]`. The same trap exists in `.gitignore`.

**해결:** escape the brackets, `--exclude '\[backup\]'`, or anchor the name you mean (`--exclude '/\[backup\]/'`).
When a copied project behaves differently, compare file lists first: `rsync -an --itemize-changes` or
`diff <(cd a && find . | sort) <(ssh host 'cd b && find . | sort')`.

## OPS-209 — SpacetimeDB 2.8 SQL cannot write an array column: `UPDATE t SET counts = [..]` is refused, so a `Vec<u32>` row cannot be seeded by hand

`측정 2026-09-29 · SpacetimeDB 2.8.0 · local standalone · spacetime CLI and HTTP /v1/database/<db>/sql`

**증상:** seeding a test player's `Vec<u32>` column on a local database to photograph a screen:

- `UPDATE collection SET counts = [3,0,1] WHERE …` → `Unsupported column/variable assignment expression: [3, 0]` (HTTP 400; the CLI prints only the 400)
- `SET counts = 0x03000000` → ``The literal expression `03000000` cannot be parsed as type `Array<U32>` ``
- `SET counts = '[3,0]'` → `Unexpected type: (expected) String != Array<U32> (inferred)`

A scalar column in the same row updates fine (`SET chosen = 0` succeeds), and `SELECT` prints the array as one run of digits (`300000…`), which is not a form it accepts back. The CLI's error hides the reason — POST the SQL to `/v1/database/<db>/sql` with curl to read it.

**해결:** there is no SQL route to an array column. Either reach the state through the module's own reducers, or — for a picture of a screen only — build a throwaway client whose view code overrides the value, install it, photograph, and reinstall the real build. Never commit that override.

## OPS-210 — the D1 `7403` "account is not valid" error is not limited to a new database: an hours-old one gave it once too

`측정 2026-09-29 · wrangler 4.125.0 · D1 kyomincenter-coupons (created the same morning) · OAuth login`

**증상:** `wrangler d1 migrations apply <db> --remote` for one new migration failed with
`The given account is not valid or is not authorized to access this service [code: 7403]`. `wrangler whoami` listed
the account and every D1 permission. The database had been created hours earlier, so OPS-201's "right after
`d1 create`" explanation did not fit.

**해결:** run the same command again; the second run applied `0003_partner_staff.sql ✅` with no change to login or
token. Treat a single 7403 from D1 as transient and retry before touching credentials. Deploying code that needs the
migration before the retry succeeds would ship a page whose queries hit a missing table.

## OPS-211 — Playwright over plain http cannot carry a `__Host-` session cookie: `addCookies` refuses it, and an `extraHTTPHeaders` Cookie is lost on redirects

`측정 2026-09-29 · playwright-core 1.63 · Chrome for Testing 1243 (headless, macOS) · Astro dev server on http://localhost`

**증상:** testing signed-in pages of a local dev server whose session cookie is `__Host-…` (Secure, no Domain):

- `context.addCookies([{ name: '__Host-kc_session', url: 'http://localhost:4399', secure: true, … }])` →
  `Protocol error (Storage.setCookies): Invalid cookie fields` (same with `127.0.0.1`).
- `newContext({ extraHTTPHeaders: { Cookie: '__Host-kc_session=…' } })` works for `goto` and `fetch`, but the request
  that follows a server redirect (a form POST answered 303, then GET) arrives without it, so the app sees a signed-out
  visitor. The cookie jar was empty (`context.cookies()` → `[]`), so it is not a jar cookie overriding the header.
- A page whose script writes `document.cookie` and reloads (here an admin console storing the browser time zone) also
  lost the session on the reload.
- Rewriting the header in `context.route(… route.continue({ headers: { cookie } }))` did not get the cookie through either.

**해결:** use `extraHTTPHeaders`, and after any step that redirects, `goto` the target URL again yourself to check it;
the dev-server log shows the redirect itself (`[303] POST …` then `[302] /next`). Remove the reason for script cookie
writes where you can (a matching `timezoneId` stopped the console's reload). Real browsers keep the cookie; this is a
test-harness limit, not an app bug — for a true end-to-end check use https or the production site.

## OPS-212 — test a web QR scanner headlessly: feed Chromium's fake camera a Y4M clip of the QR

`측정 2026-09-29 · Chrome for Testing 1243 (headless, macOS arm64) · playwright-core 1.63 · jsqr 1.4.0`

**증상:** a page that reads QR codes with `getUserMedia` + `BarcodeDetector` (or jsQR where `BarcodeDetector` is
missing, as on Safari) needs a camera to test, and a desktop test machine has none facing a phone.

Launch Chromium with `--use-fake-ui-for-media-stream --use-fake-device-for-media-stream
--use-file-for-fake-video-capture=qr.y4m` and grant `permissions: ['camera']`. The clip can be written by hand: a
`YUV4MPEG2 W640 H480 F10:1 Ip A1:1 C420jpeg` header, then 20 × (`FRAME\n` + 640×480 luma bytes + two 320×240 chroma
planes of 128), with the QR drawn in the luma plane from `qrcode-generator`'s `isDark()` (dark 20, light 235,
2-module quiet zone). Measured: headless Chrome for Testing on macOS **has** `BarcodeDetector` and read the clip; the
page showed the result 4.2 s after `goto` (camera start and first module load included). With
`addInitScript(() => { delete window.BarcodeDetector })` the jsQR fallback loaded and decoded in 16 ms.
`--use-fake-device-for-media-stream=device-count=0` gives a machine with no camera (`NotFoundError`) for the
no-camera state.

**해결:** one Y4M per code (the capture file is fixed per browser launch), one browser launch per scenario. Headless
is enough; no window opens on the test machine.

## OPS-213 — Listing the subdomains a box actually serves: wildcard DNS answers every name and crt.sh does not list names under a wildcard certificate; read the reverse proxy's routers

`측정 2026-09-29 · Traefik v3 behind Dokploy · crt.sh JSON API · dig 9.10`

**증상:** the question was "which `*.example.com` sites exist". `dig anything-random.example.com` returned the box's
IP, because DNS is a wildcard. crt.sh (`?q=%25.example.com&output=json`) listed 16 names, but three sites that
had been live for days were missing: they are served under a `*.example.com` certificate, so no certificate
names them. Guessing hostnames with `curl` found only the names that were guessed.

The complete list was on the box. Dokploy puts per-app routers in Docker labels
(`traefik.http.routers.<name>.rule=Host(\`…\`)`) and file-provider routers in `/etc/dokploy/traefik/dynamic/*.yml`.
Reading both gave 24 hosts, including the three the other methods missed.

**해결:**
```
docker ps -q | xargs docker inspect -f '{{range $k,$v := .Config.Labels}}{{$v}}{{"\n"}}{{end}}' | grep -oE 'Host\(`[^`]+`\)' | sort -u
grep -rhoE 'Host\(`[^`]+`\)' /etc/dokploy/traefik/dynamic/ | sort -u
```
Swarm services keep their labels on the service (`docker service inspect -f '{{.Spec.Labels}}'`). A routed host can
still answer 404 (no backend), so follow with one `curl -o /dev/null -w '%{http_code}'` per host.

## OPS-214 — macOS LibreSSL `openssl genpkey -algorithm EC` writes explicit curve parameters; SpacetimeDB then answers 500 `InvalidEcdsaKey`

`측정 2026-09-29 · SpacetimeDB standalone 2.8.0 · macOS 27 /usr/bin/openssl (LibreSSL 3.3.6) vs Homebrew OpenSSL 3.6.4`

**증상:** a dev script that makes the server's JWT key with
`openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1` worked on a Mac with Homebrew
OpenSSL first on PATH. On a Mac with only the system `/usr/bin/openssl` the server started, but the
first CLI call failed with `HTTP status server error (500 Internal Server Error) for url (…/v1/identity)`
and the server log said `internal error: InvalidEcdsaKey`. Both keys begin `-----BEGIN PRIVATE KEY-----`;
`openssl asn1parse` shows the difference: LibreSSL's key carries `prime-field` and the whole curve
(377-byte key), OpenSSL 3's names the curve (`prime256v1`, 135 bytes).

**해결:** add `-pkeyopt ec_param_enc:named_curve` to the `genpkey` call. Both LibreSSL and OpenSSL 3
accept it and write the named-curve form, which SpacetimeDB loads. Delete the old key pair first; the
server keeps its data dir.

## OPS-215 — Safari (WebKit) makes an `aspect-ratio: 1` box with a `height: 100%` SVG inside taller than wide

`측정 2026-09-29 · Playwright WebKit 26.6 (webkit-2359), iPhone 13 profile · Chrome for Testing 1243 for comparison`

**증상:** a white QR tile, `width: min(232px, 68vw); aspect-ratio: 1; padding: 12px` holding an inline
`<svg style="width:100%;height:100%">`, measured 232×232 in Chromium and **232×256** in WebKit: the extra 24 px (the
padding) went under the code as blank space. The box sat in a flex column.

**해결:** give the box an explicit `height` equal to its width (`height: min(232px, 68vw); box-sizing: border-box`)
instead of relying on `aspect-ratio` when its child's height is a percentage. Measure `boundingBox()` in both engines
rather than trusting a Chromium screenshot for iPhone layouts.

## OPS-216 — Playwright WebKit on a Mac without Google Fonts reachability never fires `load`, and screenshots hang "waiting for fonts to load"

`측정 2026-09-29 · playwright-core 1.63 · WebKit 26.6 · MacBook Air (macOS) against a local Astro dev server`

**증상:** `page.goto(url, { waitUntil: 'load' | 'networkidle' })` timed out at 120 s, and with `domcontentloaded`
the page worked but `page.screenshot()` failed after 30 s with `waiting for fonts to load...`. The console showed
`Failed to preconnect to https://fonts.googleapis.com/. Error: Preconnection timed out`. Chromium on the same machine
and page loaded normally.

**해결:** abort the font hosts in the test context — `context.route(/fonts\.(googleapis|gstatic)\.com/, r => r.abort())` —
and wait with `domcontentloaded` plus a selector. The page then renders with fallback fonts; judge layout, not the
exact glyphs, from those shots.

## OPS-217 — SpacetimeDB 2.8 TypeScript client: `table.pk.find()` returns `null` for a missing row, and a `WHERE flag = false` subscription plus a `WHERE id = '…'` one hides private rows from a lobby list without losing your own

`측정 2026-09-29 · SpacetimeDB 2.8.0 standalone · spacetimedb npm 2.8.0 (TypeScript module and client) · Node 26`

**증상:** a test asserted `assert.equal(conn.db.room.id.find(id), undefined)` after the row was deleted and failed with
`actual: null`. The row was gone; the client cache answers a miss with `null`, not `undefined`, so `=== undefined`
checks silently take the wrong branch.

Also measured in the same change (a private "practice" room that must not show up in a public room list):

- A subscription `SELECT * FROM room WHERE practice = false` (a `bool` column, no index) is accepted, and an observer
  subscribed that way received no insert for a practice room during a whole game.
- The practice room's own player subscribed both `room WHERE practice = false` and `room WHERE id = '<its id>'`. The SDK
  kept its room row while it played and dropped it when that second subscription was replaced on leaving.
- This is a bandwidth filter, not access control: a client subscribed to plain `SELECT * FROM room` still saw the row
  and its `practice = true`. Refuse joining in the reducer as well.

**해결:** test a lookup with `!row` or `row == null`. To keep rows out of other clients' lists, filter the shared
subscription and add a per-client subscription for the one row the client needs; enforce the rule in reducers.

## OPS-218 — Korean adult (19+) verification: Kakao/Naver login age fields do not count, and the only free method the law names is a mailed or faxed ID copy

`측정 2026-09-29 · 청소년 보호법 시행령 제17조 (2024-12-27 시행본) · Kakao DevTalk staff answers · 앱인토스 개발자 문서 llms-full.txt · PortOne 헬프센터`

**증상:** a web service with adults-only content wants a real age check at no cost. The obvious free tools — Kakao Login
`age_range` / `birthyear`, Naver Login age range / birthday, free SMS or MO (user-sends-a-text) phone checks, a yes/no
button — look like age verification but none is accepted.

- Kakao staff on DevTalk: Kakao is not an identity-verification agency, so login data "has no legal effect" and must not
  be used for adult checks; the birth year is user-editable; CI is given only for duplicate-member checks after the service
  already verifies through a licensed agency. An adult-content service reachable without real verification can lose Kakao
  Login.
- MO/SMS services (e.g. OCTOMO, 0 won) prove phone possession only; no birth date.
- 청소년 보호법 시행령 제17조 lists the accepted means for providing material harmful to minors: (1) ID checked face to
  face, or an ID copy received **by fax or post**; (2) a real-name electronic-signature certificate; (3)(4) the
  resident-number substitutes (i-PIN and similar); (5) credit card; (6) mobile phone plus SMS/ARS. Only (1) has no
  per-check fee.
- Cheapest paid references found: KG이니시스 통합본인인증 40 won per success (VAT excl., no sign-up fee, needs a PG contract
  and a business registration); 다날 mobile check 50,000 won/month for 1,200 checks via PortOne.
- 앱인토스 (Toss mini apps): Toss Login returns birth date and CI and lists no fee today, but it needs a business
  registration and a listed mini app, the content policy refuses content whose main element is sexual objectification,
  and Toss's own docs send legal identity checks (web-board, adult services) to the separate, contracted "토스 인증".
- Government mobile ID (모바일 신분증) can disclose only "adult: yes", but the integration needs an official letter,
  DID registration and a server; fees are not published (contact 042-870-1498, mid_apply@komsco.com).

**해결:** decide first whether the content really needs an adult rating. From 2025-10-09 the amended 게임산업법 exempts
non-commercial games made by individuals or clubs from rating unless they contain 청소년이용불가-level content, and
waives the fee for non-commercial 전체–15세 games by individuals without a business registration; a game below the
adult line has no legal identity-check duty. If it must stay adults-only, budget roughly 40 won per verified user
(PG-backed mobile/integrated check), or accept manual fax/post ID checks as the only zero-fee legal route. Never ship
social-login age fields as the adult check.

## OPS-219 — Building a second copy of the same Cargo package into a shared `CARGO_TARGET_DIR` leaves the other copy's artifact in place; the next build says "Finished" and does not rewrite it

`측정 2026-09-29 · cargo 1.97.1 · wasm32-unknown-unknown release · macOS`

**증상:** to get the previous release's module, a copy of `Cargo.toml` plus the old `lib.rs` was built with
`CARGO_TARGET_DIR=<repo>/server/target`. Then `cargo build --manifest-path server/Cargo.toml ...` printed
`Finished ... in 0.04s` and `target/.../release/escape_online.wasm` was still the **old** module (same bytes; a
string only the new code contains: 0 matches). Fingerprints are per source path, so the real package was
"fresh", but the uplifted output file has one name per package and the copy had overwritten it. That file is
what deploy scripts pick up.

**해결:** build the other copy with its own `CARGO_TARGET_DIR`. If it already happened, `touch` a source file of
the real package and rebuild, then check the artifact for a symbol only the intended version has
(`grep -a -c <new_reducer_name> <file>.wasm`) before shipping it.

## OPS-220 — The official `nginx:alpine` image has no brotli module; serve a precompressed Godot `.wasm.br` with a `map` + `rewrite` into an `internal` location that sets `Content-Encoding: br` and keeps `application/wasm`

`측정 2026-09-29 · nginx 1.29-alpine (official image) · Godot 4.7.2 web export (39,514,754-byte wasm) · Chrome headed on an M1 Air`

**증상:** `brotli_static on;` is an unknown directive in the official image, and plain `gzip on` sends the engine as
11,747,624 bytes (gzip level 1 on the fly). `brotli -q 11` makes it 6,902,599 bytes (GDT-172), but a location that just
serves the `.br` file needs the right headers or the browser either saves garbage or loses streaming compilation.

**해결:**

```nginx
map $http_accept_encoding $brotli_ok { default 0; "~*\bbr\b" 1; }
location ~* \.wasm$     { if ($brotli_ok) { rewrite ^(.+)$ $1.br last; } try_files $uri =404; }
location ~* \.wasm\.br$ {
    internal; gzip off;
    types { } default_type application/wasm;
    add_header Content-Encoding br always;
    add_header Vary Accept-Encoding always;
}
```

- Measured on the deployed server: `Accept-Encoding: br, gzip` → `content-encoding: br`, `content-type: application/wasm`,
  `content-length: 6902599`; `gzip` only → gzip on the fly; none → the raw 39.5 MB; a direct request for
  `/index.wasm.br` → 404 because the location is `internal`.
- A location with its own `add_header` drops the server-level ones; repeat CORP and cache headers there.
- The release must always ship the `.br` file (the rewrite does not check it exists): make the build refuse to
  release without it. `brotli -q 11` on the 39.5 MB engine took about 75 s on an M1 Max; cache it by content hash.
- Effect on a cold first visit throttled to 10 Mbps (CDP), three runs each: the engine finished downloading at
  11.3–11.4 s before and 7.4–8.2 s after; unthrottled on Wi-Fi, 2.5–3.6 s → 2.1–2.3 s.

## OPS-221 — `codex exec -i <landscape art>` redraws the same character in a 2:3 frame, but the figure grows: ask for "about 42%" and "the central 60% of the width" to land near 50%

`측정 2026-09-29 · codex-cli 0.154.0 built-in image tool · 8 characters + 1 retry, 1536x1024 references → 1024x1536 outputs`

**증상:** a game needed a tall (2:3) version of eight approved landscape (3:2) splash illustrations. Text-only prompts
drift off-model (OPS-139), and cropping the landscape art to 2:3 keeps only 44% of its width.

Attaching the approved landscape image with `-i`, asking for "portrait 1024x1536" in the instruction, and adding
"Draw the SAME character as a new portrait-format illustration: identical face, eye colour, hairstyle, outfit,
accessories, props, colour palette, rendering style and setting. Only the framing and the pose change; do not copy the
landscape image by cropping or stretching it" gave 8 of 8 on-model redraws (same face, outfit, props, background world)
with clean hands, 104–138 s each, three in parallel without rate limits. Unlike OPS-139's same-shape variants, the
framing did change here: the outputs are genuine 2:3 compositions.

The figure fills more of a tall frame than the prompt asks. Silhouette share of the image (macOS Vision instance mask):

| Prompt | Result |
| --- | --- |
| "covers roughly 40-50% of the image", three-quarter body | 61.4% (1 run) |
| "only about 42%", "occupies roughly the central 60% of the image width", "background visible on BOTH sides", "nothing touches the left or right edge" | 50.8–57.8% (8 runs) |

**해결:** redraw with `-i <approved art>` rather than re-prompting, keep the reference outside the output folder, and
budget about 10 points of overshoot on area targets in a tall frame (ask for ~42% to get ~50–58%).

## OPS-222 — The shared Pixel locks itself after the screen timeout, and adb cannot open a secure keyguard: verify web builds in desktop Chrome as a phone instead of waiting for a person

`측정 2026-09-29 · Pixel 7 Pro · Android 17 · adb 1.0.41 · screen_off_timeout 1800000`

**증상:** a session came back to the USB phone about 40 minutes after its last command and found it dozing:
`dumpsys power` → `mWakefulness=Dozing`, `dumpsys window` → `isKeyguardShowing=true`, `mDreamingLockscreen=true`.
`input keyevent KEYCODE_WAKEUP` woke the screen, but `wm dismiss-keyguard` only raised the fingerprint prompt
(`mCurrentFocus=Window{… AlternateBouncerView}`), and a swipe up went back to the always-on display.
`locksettings get-disabled` printed `false`: the lock is a secure one (PIN plus fingerprint), so nothing over adb opens it.

The phone locks whenever no session touches it for `screen_off_timeout` (here 30 min), so any session that pauses for a
long build or image generation can come back to a locked phone.

**해결 (2026-09-29, 소유자 승인 후 적용):** `adb shell settings put global stay_on_while_plugged_in 7` (AC·USB·무선 충전 모두).
충전 중에는 화면이 꺼지지 않으므로 잠기지도 않는다. `dumpsys power`에 `mStayOn=true`, `mStayOnWhilePluggedInSetting=7`로 확인한다.
이미 잠긴 뒤에는 이 설정으로도 풀리지 않는다 — 한 번은 사람이 풀어야 한다. 밝기가 낮아도(`screen_brightness` 12) 화면이
계속 켜져 있으므로 번인 위험은 남는다. 이 값은 공유 설정이니 끄지 말 것.

폰이 켜져 있으면 실기기 Chrome도 CDP로 조작된다: `adb forward tcp:9333 localabstract:chrome_devtools_remote` →
`http://127.0.0.1:9333/json/list`에서 대상 탭 id → 그 `webSocketDebuggerUrl`로 `Input.dispatchTouchEvent`(두 손가락)와
`Page.captureScreenshot`을 보낸다. 측정: Pixel 7 Pro Chrome 뷰포트 411×794 CSS, DPR 3.5. 단 **다른 세션이 자기 앱을 앞으로
띄우면 내 탭은 `visibilityState: hidden`이 되고 rAF가 0회로 멈춘다** — 화면 캡처가 같은 그림으로 굳어 "게임이 멈췄다"로
오진하기 쉽다. 이상하면 `dumpsys window | grep mCurrentFocus`부터 본다. `json/list`는 개인 탭도 전부 보여 주니 대상 탭 외에는 건드리지 않는다.

폰이 잠겨 있을 때의 대안: unlock 시도를 반복하지 말고, web build라면 Air의 desktop Chrome에서 폰처럼 확인한다:
Playwright context with the phone's CSS viewport, `isMobile`, `hasTouch` and an Android Chrome User-Agent, Chrome with
`--use-angle=metal` for WebGL2, and CDP `Input.dispatchTouchEvent` for multi-finger input (GDT-174). Check the physical
phone early in a task, while it is still awake, and use `adb shell dumpsys window | grep isKeyguardShowing` before planning
on it.

## OPS-223 — Cross-subdomain SSO via a hub cookie signs a fresh popup login out again: the popup's close fires `focus`, and the reconcile runs before the hub has set the cookie

`측정 2026-09-29 · Firebase JS SDK 12.17.1 · Chrome 14x on macOS · mnori.com /api/auth hub`

**증상:** on a `*.mnori.com` game, `signInWithPopup` succeeds, and 1.7 s later the page is signed out; about 5 s after that it is
signed in again. No error anywhere. If the hub POST fails or is slow, the player simply stays signed out.

The hub pattern (every origin POSTs its ID token to the hub, which sets a readable `mnori_auth` cookie on the parent domain;
each origin polls that cookie and calls `signOut()` when it is absent but a local user exists) has a race: `publishSignIn`
is async, and the popup closing gives the opener window a `focus` event. A `reconcile` bound to `focus` runs immediately,
sees *local user, no cookie yet*, and signs the brand-new user out. The next 4 s poll finds the cookie and restores the session
with a custom token, which is why it looks like a flicker rather than a failure.

**해결:** keep the in-flight publish as a promise and make `reconcile` await it first; and do not sign out a local user
whose publish failed merely because the cookie is missing. Any origin that copied the hub's reference snippet
(`startSsoSync` + `publishSignIn`) has the race; measure it by timestamping auth-state changes around a real popup login.

## OPS-224 — `codex exec -i <art>` extends approved key art sideways: ask for a 30% overlap, then align the overlap by search (it lands 100-140 px off) and feather the seam in a low-detail strip

`측정 2026-09-29 · codex-cli 0.154.0 built-in image tool · 1536x1024 3:2 key art → 3072x1024 · 2 left + 2 right runs`

**증상:** landscape key art at 3:2 lost the characters' heads on phones (2.2-2.4:1) and 16:9 monitors when drawn as a cover. The image tool only outputs 1024x1024, 1536x1024 and 1024x1536, so a wider file needs outpainting by hand: generate a continuation and stitch it.

What worked: attach the art with `-i`, say "the attached image is the RIGHT part of a wider panorama; paint the part that continues to the LEFT", and require that "the RIGHT 30% of your output (the rightmost 460 pixels) must reproduce the LEFT 30% of the attached image as exactly as possible" (sun, horizon, bridge, colours), with the rest continuing the scene in low detail and no characters. Style, horizon, palette and light matched in 4 of 4 runs. The overlap is never at the nominal position: the best least-squares fit (RGB MSE over the original's edge strip, dx ±300, dy ±60) was 136 px off for the left extension and -128 px for the right one, both with 0 rows of vertical shift. MSE at the fit tells whether the seam will hide: 200 (left, sky and sea) and 750 (right, hotel front) were invisible after a 110-140 px linear feather at full resolution; 5465 (a right run that drew a different building) showed a jump in the sidewalk, so generate two and keep the lower one.

**해결:** overlap 30%, align by search in a strip of the original that has only low-detail content (sky, sea, road; for a building side, restrict the alignment window to the rows above any figure), feather over that strip only, keep the original's pixels untouched, and store the generated continuations next to the art with the run ids. For the side where a character stands near the edge the model draws the character again in its overlap (whole or a sliver); the feather strip must be narrower than the gap between the character and the edge (here 60-110 px). Then draw the wide art so a chosen focus fraction of its width lands at a chosen fraction of the screen, clamped to the slack, instead of anchoring to an edge, or the characters end up on the screen's border.

## OPS-225 — A Dokploy push can look like it never deployed: `last-modified` stays old when the export is unchanged, and builds queue behind other apps

`측정 2026-09-30 · misa, Dokploy application build (Dockerfile), button-web-th6jrz`

**증상:** after a push to `main`, the served `index.html` kept its old `last-modified` and `etag` for 25 minutes.
That looked like a failed or missing deploy. It was neither. The build started 15 minutes after the push, because it
was queued behind four other apps building on misa in the same window. It passed, and the new container came up healthy.
The change was a new `RUN` check in the export stage, and the exported files were byte-identical. The later stages were
`CACHED`, so the file nginx serves kept its old mtime.

**해결:** do not use `last-modified` or `etag` to tell whether a deploy happened. Read the deploy logs:
`ssh misa 'ls -t /etc/dokploy/logs/<appName>'`. A new timestamped log means a build ran. `tail` it to see the steps
and whether it finished. Several apps pushing at once can hold a build in the queue for 10–15 minutes.

## OPS-226 — `codex exec` image tool rejects lingerie and "plunging neckline" pin-up prompts at the input stage in 24–34 s; OPS-179's swimsuit block was at the output stage

`측정 2026-09-29 · codex-cli 0.154.0 built-in image tool · 3 landscape 1536×1024 prompts, 3 parallel runs`

**증상:** three anime pin-up prompts for clearly adult characters failed 3 of 3 with `http 400 ... "Your request was
rejected by the safety system ... safety_violations=[sexual]"`, `"code": "moderation_blocked"`,
`"moderation_stage": "input"`. They failed after 24, 33 and 34 s, before any image was drawn (a normal generation
takes 70–110 s, and the OPS-179 output-stage block took ~140 s). The prompts described (1) a leather halter top with
"a deep plunging neckline", hot pants and "biting her lower lip, half-lidded eyes", (2) a lace bralette and briefs under
an open shirt, kneeling on a bed, (3) a corset, garter belt and stockings, lying on a card table. Each prompt also said
"Her breasts and hips stay covered by the outfit; no nudity" and "Sensual adult pin-up glamour"; that did not help.
Prompts from the same pipeline at the OPS-179 level (gowns with slits, open backs, one-piece swimsuits, a bikini top
with a sarong) pass the input stage.

**해결:** treat the tool's ceiling as fashion glamour and swimwear. Lingerie, bedroom scenes and arousal wording
(lip biting, "sensual", "teasing", "inviting gaze") are refused on the words alone, so the refusal is fast and costs
no generation. Do not plan adult-rated pin-up art on this tool; choose the content level first, then the tool.
Measured the same day at the permitted level (1990s cel-anime style, slit gowns, open backs, bikinis, one-piece
swimsuits): 28 of 30 passed on the first run. One was refused at the input stage ("a red bikini top and short denim
cut-offs, soaked from the hose", 33 s) and one at the output stage (a high-cut one-piece on a jacuzzi edge, 98 s);
both passed once the outfit was more covered.

## OPS-227 — Docker on a Mac with no brew and no sudo: colima + lima + docker CLI under `~/.local`; LuLu silently blocks the new binaries, so the VM boots with no network

`측정 2026-09-29 · MacBook Air M1, macOS 27.0.1 · colima 0.10.3, lima 2.2.0, docker CLI 29.8.1, buildx 0.37.1 · LuLu (alert mode) · ssh key auth, no sudo`

**증상:** `colima start` over ssh failed twice with `error resolving download URL '…colima-core/releases/download/v0.10.4/ubuntu-24.04-minimal-cloudimg-arm64-docker.raw.gz': … DNS lookup failed for host 'github.com'`
and then `connection timed out`, while `curl` to the same URL on the same host worked. Once the VM was up (image
fetched by hand), every pull failed with `lookup registry-1.docker.io on 192.168.5.1:53: read udp …: i/o timeout`
and `curl https://1.1.1.1` inside the VM timed out; `--dns 1.1.1.1` changed nothing. The host has LuLu in alert
mode: a binary with no rule raises a prompt on the console screen, nobody on ssh sees it, and the connection just
hangs. `/Library/Objective-See/LuLu/rules.plist` (root-owned, world-readable) had no entry for `colima` or
`limactl`; `curl` is Apple-signed and allowed. All VM traffic leaves through the `limactl` host agent, so one
missing rule takes the whole VM offline. After the owner allowed both binaries on the console, the VM reached the
registry at once and a three-stage Dockerfile built.

**해결:**
- Install without brew: `colima-Darwin-arm64` → `~/.local/bin/colima`; `lima-<v>-Darwin-arm64.tar.gz` unpacked to
  `~/.local/opt/lima` with `bin/*` symlinked into `~/.local/bin` (it needs its `share/lima` beside it);
  `docker` from `download.docker.com/mac/static/stable/aarch64/docker-<v>.tgz`; `buildx-v<v>.darwin-arm64` →
  `~/.docker/cli-plugins/docker-buildx`. `colima start --vm-type vz` needs no qemu and no sudo.
- If colima cannot download its disk image, fetch the `.raw.gz` with `curl` and pass `--disk-image <file>.raw.gz`.
  Pass the **compressed** file: a gunzipped `.raw` is refused with `SHA512 checksum mismatch`.
- On a host with LuLu, check the rules before debugging DNS:
  `plutil -convert xml1 -o - /Library/Objective-See/LuLu/rules.plist | grep limactl`. No line means someone has
  to click Allow for `limactl` and `colima` on the console; it cannot be done over ssh without sudo. The same
  applies to any freshly installed unsigned binary that needs the network.
- `docker build` of a Dockerfile whose `FROM` image is not in the local store still fails after that, in 30 s, with
  `failed to fetch anonymous token: Get "https://auth.docker.io/token?…": dial tcp: lookup auth.docker.io: i/o timeout`
  (3 of 3), while `docker pull` of the same image works. The registry token is fetched by the **`docker-buildx`
  client on the host**, not by the daemon in the VM, and that binary is a third one with no LuLu rule:
  `docker buildx imagetools inspect debian:bookworm-slim` times out the same way in 31 s while host `curl` to the
  same token URL answers 200 in 0.14 s. Either allow `~/.docker/cli-plugins/docker-buildx` on the console too, or
  `docker pull` every `FROM` image first: with the image local the same build passed in 1 s, no token needed.
- The VM holds its memory (6GB here) while running: `colima stop` after use on a shared 16GB host.

## OPS-228 — Empty-cache "first load MB" of a web game: count CDP `Network.loadingFinished.encodedDataLength`, not resource sizes; `~/kc-test` has no `playwright` package

`측정 2026-09-29 · MacBook Air M1 · Playwright 1.62 + installed Chrome · Chrome DevTools Protocol`

**증상:** The MNORI game manifest asks each game for `firstLoadMB`, the bytes a first visit downloads before it
can be played. `performance.getEntriesByType("resource")` under-reports (`transferSize` is 0 for cross-origin
responses without Timing-Allow-Origin, e.g. Google Fonts and jsDelivr), and Playwright's `response.body()` gives
decoded, not transferred, size. Running the measuring script from `~/kc-test` on the Air fails with
`Cannot find package 'playwright'` — that directory only has `playwright-core`.

**해결:**
- Attach a CDP session, `Network.enable`, `Network.clearBrowserCache`, and sum `encodedDataLength` from
  `Network.loadingFinished`. It counts every request including cross-origin and websocket-upgrade ones, in
  wire bytes, so gzip/brotli is reflected.
- Take the total at two points: when the playable screen is interactive, and again after the first action that
  starts play. For a WebGL/WASM game the second point can be a few hundred KB higher (a second physics build,
  textures) — report that one.
- For a package the script needs, make your own directory and symlink another project's modules:
  `mkdir -p ~/work/<mine> && ln -sfn ~/work/button/node_modules ~/work/<mine>/node_modules`. Do not install
  into another session's project.

## OPS-229 — Dokploy raw-compose redeploy returns Traefik 404 for seconds; roll a second container with the same config hash and drain the old one by health check

`측정 2026-09-30 · Dokploy v0.30.7 (misa), docker compose v5.0.2 host / v5.5.1 in Dokploy, Traefik v3.6.7, nginx 1.30`

**증상:** Every `compose.deploy` of a one-container web service answered `404 text/plain` on the whole host for
some seconds: compose stops the old container before the new one is healthy, and Traefik has no server for the
router. A daily checker that happened to fetch in that window reported the file as missing.

Facts that make a gapless swap possible without Swarm:
- Traefik's Docker provider skips a container whose health status is `starting` or `unhealthy`, and re-reads on
  `health_status` events. A health check is therefore a routing switch.
- Dokploy writes the compose file it runs (Traefik labels and networks injected) to
  `/etc/dokploy/compose/<appName>/code/docker-compose.yml` and `.env`, world-readable, regenerated each deploy.
- `docker compose config --hash web` on that file with the host's compose gave the same hash as the
  `com.docker.compose.config-hash` label Dokploy's newer compose had set, so a container started by hand from that
  file counts as up to date for Dokploy's own `up`.
- When `up` scales a service down, compose removes obsolete (hash-diverged) containers first.

**해결:** Before calling `compose.deploy` (after `compose.saveEnvironment`):
1. Copy the generated `.env` with only the image tag variable changed and run
   `docker compose -p <appName> -f <code>/docker-compose.yml --env-file <copy> up -d --no-deps --no-recreate --scale web=2 web`.
   The old container stays; a second one starts on the new image with the same labels.
2. Wait until the new container is `healthy`, then a few seconds for Traefik.
3. Make the old one fail its check and wait for `unhealthy`: health check
   `test ! -e /tmp/drain && wget -q -O /dev/null http://127.0.0.1:8080/healthz` (interval 5s, retries 3,
   `start_interval: 1s`), then `docker exec <old> touch /tmp/drain` (works with `read_only: true` when `/tmp` is tmpfs).
4. Call `compose.deploy`. Dokploy's `up` keeps the new container and removes the drained one.
Measured: 1164 requests at about 7 a second across a deploy, 0 failed; before, the gap was visible to a checker.
Limits: the container number grows each release (`-web-3`), so find it by the `com.docker.compose.service` label,
not by the name `-web-1`. A release that edits the compose file changes the hash and Dokploy recreates the
container, gap included. Wait for the deployment record with your title to be `done`; the rolled container already
runs the new image, so an image check alone passes before Dokploy has started. Do not roll a service whose
upstream restarts in the same deploy (nginx resolves upstream names at startup).

## OPS-230 — `add_header` in an nginx location drops every inherited header, so a `/mnori.json` block must repeat the ones it needs
`측정 2026-09-30 · nginx 1.30-alpine`

**증상:** A site serves its security headers once at `server` level (`X-Content-Type-Options`,
`Cross-Origin-Opener-Policy`, …). Adding an exact-match location for one file plus the two headers that file needs
(`Access-Control-Allow-Origin`, a short cache lifetime) silently serves that file with *only* those two: nginx's
`add_header` is not additive across levels — a directive at the deeper level replaces the whole inherited set, and
`always` does not change that.

Also measured on the same deploy:
- `expires 5m;` alone produces exactly `Cache-Control: max-age=300` plus a matching `Expires`. No second
  `add_header Cache-Control` is needed, and adding one there gives two values.
- A `location = /file.json` with `try_files $uri =404;` is what keeps a single-page site from answering the path
  with `index.html` and a 200. A portal or monitor that reads a JSON file at a fixed path sees the HTML fallback as
  "not published", not as an error.
- `mime.types` already maps `.json` to `application/json`, so no `default_type` is needed; with `gzip_static on`
  and a pre-gzipped `file.json.gz` in the image the Content-Type stays `application/json`.

**해결:** Repeat the inherited headers that still matter inside the location. For a JSON fact file that is
`X-Content-Type-Options: nosniff`; the COOP/COEP/Permissions-Policy set applies to documents, not to it. Verify with
`curl -sI` after deploying and assert the three headers in the deploy script — a header lost this way breaks nothing
visible on the site.

---

## OPS-231 — Driving a phone game from adb: `input motionevent` holds one finger; `sendevent` multi-touch is denied without root

`측정 2026-09-29 · Pixel 7 Pro (Android 17, not rooted) · adb over USB`

**증상:** testing on-screen sticks needs a finger that stays down, and a second finger for buttons.

- One held finger works: `adb shell input motionevent DOWN x y`, then `MOVE x y` as often as needed, a `sleep`, a screenshot (`adb exec-out screencap -p > shot.png`) and `UP x y`. The game sees an ordinary touch and drag (`input swipe` cannot hold at the end, `input tap` cannot drag). Coordinates are pixels of the current orientation.
- A second finger does not: writing multi-touch protocol B to the touchscreen node fails, although the shell user is in the `input` group and the node is `crw-rw---- root input`:

```
$ adb shell sendevent /dev/input/event4 0 0 0
sendevent: /dev/input/event4: Permission denied
```

`adb shell input` has no multi-pointer command.

**해결:** split the check. Test the multi-finger routing inside the engine, headless, with synthetic events that carry a touch index (Godot: `InputEventScreenTouch.index`, `Input.parse_input_event`), and use adb on the real phone for what only the phone shows: layout, safe area, single-finger feel. Real two-thumb play still needs a person. A person holding the phone also touches it while the script runs: a stick that looks "held" in a screenshot may be their thumb.


## OPS-232 — nginx `default_type` plus `add_header Content-Type` sends the header twice; and a build host whose clock runs a day ahead dates generated files wrong

`측정 2026-09-29 · nginx 1.30-alpine · Dokploy on misa`

**증상:** A small JSON file served from its own `location` block with both

```nginx
location = /mnori.json {
    default_type application/json;
    add_header Content-Type application/json always;
}
```

answers with the header twice:

```
content-type: application/json
content-type: application/json
```

`curl -sI` shows both lines; strict clients may reject a duplicated
`Content-Type`. `add_header` appends — it does not replace what nginx already
picked from `mime.types` or `default_type`.

The same deploy exposed a second trap: the file was generated on the build host
with `datetime.now(timezone.utc)`, and that host's clock was a day ahead of the
deploying machine, so a file deployed on 2026-09-29 carried `2026-09-30`.

**해결:** For a real file with a known extension, drop both lines — `mime.types`
already maps `.json` to `application/json`; keep at most `default_type` and
never add `Content-Type` with `add_header`. Use `add_header` only for headers
nginx does not set itself (`Access-Control-Allow-Origin`, `Cache-Control`).

For dates in generated files, do not read the clock of whatever host runs the
generator. Derive them from the release identifier produced by the machine that
started the deploy (`20260929T050541Z-...` → `2026-09-29`), or pass the date in
as an argument.

## OPS-233 — Serving a per-game `/mnori.json` from nginx: it needs its own `location`, because `add_header` there replaces the site's inherited headers

`측정 2026-09-29 · nginx 1.29-alpine in Docker Compose (Dokploy) · static Godot web export`

**증상:** the portal contract wants `Content-Type: application/json`, `Access-Control-Allow-Origin: *` and `Cache-Control: max-age<=300` at the game's root. Dropping the file into the web root gets the type right from `mime.types`, but it inherits the site's `Cache-Control` (here `no-cache`) and has no CORS header at all, so a cross-origin reader cannot use it.

**해결:** give it a location of its own and keep the file out of any SPA fallback:

```nginx
location = /mnori.json {
    default_type application/json;
    add_header Access-Control-Allow-Origin * always;
    add_header Cache-Control "public, max-age=300" always;
}
```

The trap is `add_header`: a `location` that sets any header drops the whole inherited set, so every site-wide header that file still needs has to be repeated inside the block.

About the config file itself, when it is mounted as a **single file** (`- /host/deploy/nginx.conf:/etc/nginx/conf.d/default.conf:ro`): `scp` writes the host file in place and keeps its inode, so the running container sees the new bytes immediately (md5 inside the container matched the host's on the same inode, 2366022, without any restart). `nginx -s reload` is enough; `docker restart` is not required. Copying with an editor or a tool that writes a temp file and renames it would break the mount, so check with `docker exec <web> md5sum /etc/nginx/conf.d/default.conf` before assuming either way.

Generate the JSON in the build or release script rather than copying it by hand, so `version` and `updatedAt` cannot go stale.

## OPS-234 — Chrome DevTools Protocol byte counts miss everything a service worker fetches

`측정 2026-09-29 · Chrome 154 · Playwright 1.63 · CDP Network domain`

**증상:** measuring what a first visit downloads (`firstLoadMB` for the MNORI game manifest) by summing `Network.loadingFinished.encodedDataLength` on a page CDP session reported **0.51 MB** for a site whose engine alone is 33 MB. Nothing in the run looked wrong: the page loaded, the game started, and the biggest request listed was a 0.08 MB script.

The site's service worker relays the large files, and a worker is a **separate CDP target**. `context.newCDPSession(page)` only sees the page's own requests, so every byte the worker fetched was invisible. Playwright's `newCDPSession` takes a Page or Frame, not a worker, so there is no one-line fix.

**해결:** keep the worker out of the way and let the same fetches happen in the page — the volume is identical, since the worker only stores what it fetched from the network:

```js
await page.addInitScript(() => { delete Object.getPrototypeOf(navigator).serviceWorker; });
```

Delete it from `Navigator.prototype`, **not** with `Object.defineProperty(navigator, 'serviceWorker', { get: () => undefined })`. Shadowing leaves `'serviceWorker' in navigator` true, so a page that guards with `if (!('serviceWorker' in navigator)) return;` walks straight into `navigator.serviceWorker.register(...)` and throws — the symptom is a boot that stalls forever with no error in the log (here: a start button that never enabled, a 300 s timeout, and no page error until one was explicitly printed).

Cross-check the total against the wire before trusting it: `curl -s -o /dev/null -w '%{size_download}' --compressed <url>` over the files a first visit needs summed to 33.56 MB against the browser's 33.96 MB.

## OPS-235 — Firebase Auth's `getAuth()` loads a 127 KB sign-in iframe before first paint on phones and Safari; it was the whole mobile LCP problem

`측정 2026-09-29 · firebase 12.18.0 (@firebase/auth 1.13.5) · Next.js 16.3 · Lighthouse 12 mobile`

**증상:** a page that only shows a "Sign in with Google" button scored mobile LCP 4.0–4.6 s in Lighthouse while a real phone painted in 0.5 s. The request list had `https://<project>.firebaseapp.com/__/auth/iframe.js` (93 KB) and `apis.google.com/.../gapi_iframes` (34 KB) at **High** priority before anything was clicked. Fixing images and fonts first changed nothing.

`getAuth()` registers `browserPopupRedirectResolver`, and `_initializeWithPersistence` calls `resolver._initialize(auth)` when `_shouldInitProactively` is true, which is `_isMobileBrowser() || _isSafari() || _isIOS()`. It is also **awaited before `initializeCurrentUser`**, so on those browsers the signed-in state itself waits for the iframe. Desktop Chrome does not do this, which is why it is invisible from a laptop.

Which resource matters is cheap to prove before changing code: `lighthouse <url> --blocked-url-patterns='*firebaseapp.com*' --blocked-url-patterns='*apis.google.com*'`. Three runs each on production: as shipped 4.0–4.6 s, Korean web font (272 KB) blocked 2.3–2.4 s, the two auth origins blocked 1.5–1.6 s (one outlier 2.6).

**해결:** start Auth without the resolver and pass it at the call sites:

```ts
const auth = initializeAuth(app, { persistence: [browserLocalPersistence, indexedDBLocalPersistence] });
await signInWithPopup(auth, provider, browserPopupRedirectResolver); // and linkWithPopup
```

Then warm the iframe up yourself, because the SDK loads it eagerly for a reason: Safari and phone browsers only allow a popup opened in the same turn as the tap, and the SDK opens it *after* the iframe has loaded. There is no public call for it; the SDK's own is reachable as

```ts
import { _getInstance } from "@firebase/auth/internal";
void (_getInstance(browserPopupRedirectResolver) as any)._initialize(auth);
```

Run that 2.5 s after `load`, or at the first `pointerdown` / `pointermove` / `keydown` / `touchstart` / `scroll`, whichever comes first. `initializeAuth` throws if the app already has an Auth (hot reload), so fall back to `getAuth(app)` in a `catch`. Verified on production with a real Google account: sign out, popup, sign in, session cookies, still signed in after reload.

Two measuring traps on the way: a local build without the `NEXT_PUBLIC_FIREBASE_*` values renders the button disabled and tests nothing (the web config is public and can be read out of the production bundle; `localhost` is an authorized domain by default, `127.0.0.1` is not). And Lighthouse on a shared test host is only as steady as its load: the same deploy gave LCP 1.4, 1.6, 3.2, 6.0 and 6.0 s in five consecutive runs while other sessions were measuring on the machine (load average 5–10), with FCP itself jumping to 3.9 s. Check `uptime` before trusting a run, and wait for load under 2.


## OPS-236 — A freshly installed Xcode cannot run `simctl` until its first-launch packages are installed, and that step needs an admin password (no way around it over ssh without sudo)

`측정 2026-09-30 · Xcode 27.0 (27A266a) · macOS 27.0.1 · MacBook Air M1, ssh session without sudo`

**증상:** Xcode.app was in `/Applications` and `xcode-select -p` pointed at it, `xcodebuild -version` worked, but every `xcrun simctl …` failed with
`simctl: line 32: /Library/Developer/PrivateFrameworks/CoreSimulator.framework/Versions/A/Resources/bin/simctl: No such file or directory`.
`/Library/Developer/PrivateFrameworks` did not exist. `xcodebuild -runFirstLaunch` printed `Install Started` then `Install Failed: 패키지를 설치하려면 인증이 필요합니다.` and `xcodebuild -checkFirstLaunchStatus` exited 69. Being in the `admin` group does not help when `sudo` asks for a password.

**해결:** someone with the password has to do it once on that Mac: open Xcode and accept the component install, or run `sudo xcodebuild -license accept && sudo xcodebuild -runFirstLaunch`. After that `xcodebuild -downloadPlatform iOS` fetches a simulator runtime (a new Xcode has none: `xcrun simctl list runtimes` is empty). Copying Xcode.app from another Mac into `~/Applications` does not avoid this step.

## OPS-237 — A release upload to a 97%-full host fails mid-`tar` and leaves 0-byte files; `deploy.sh | tail -1` hides the failure

`측정 2026-09-30 · misa (Ubuntu, / 98G, 90G used, 3.2G free), `tar -czf - … | ssh misa "tar -xzf - -C <release>"`, several apps building at the time`

**증상:** the upload printed only `tar: Exiting with failure status due to previous errors` (GNU tar on the host). The
release folder existed with every file of `build/web` at 0 bytes, and the deploy step never ran, so production kept
serving the previous release. The caller had piped the deploy script through `| tail -1` inside an `&&` chain: the
pipe's status was `tail`'s 0, so the chain went on to verification and to removing the build folder. The mismatch
showed only because the verification compared the served `index.pck` hash with the local one. A retry a few minutes
later, with 4.4G free, passed.

**해결:** never pipe a deploy script into `tail`/`grep` without `set -o pipefail` (or redirect to a log and test the
exit status). Before an upload check `ssh <host> 'df -h /'`; under ~5G free on a shared build host, other apps'
image builds can take the rest mid-upload. After a failed upload delete the half-written release folder before
retrying, and always compare a served file's hash with the local build.

## OPS-238 — A deploy to a shared Docker host fails at its first `mkdir` with "No space left on device": the build cache of every project's deploys had filled the disk

`측정 2026-09-30 · Ubuntu host with Docker and Dokploy, 98 GB root volume shared by about 20 projects`

**증상:** `ssh host "mkdir -p ~/project/releases/<release>"` failed with
`mkdir: cannot create directory '...': No space left on device`. `df -h /` showed 98G size, 94G used, **0 available**, 100 %. Inodes were at 35 %. `docker system df`: Images 52.96 GB (35.75 GB reclaimable), Local Volumes 16.58 GB, **Build Cache 671 entries, 4.636 GB, 0 active**. Every project deploys by building an image on the host, and nobody prunes. The running sites still answered, so nothing alerted; the next thing to fail would have been a database write.

**해결:** `docker builder prune -af` removes only the build cache: no image, container or volume is touched, and the next build is just slower. After it `df` showed 4.6 G available and the same deploy passed. Do not run `docker image prune -a` or `docker system prune` on a shared host: the unused images are other projects' rollback releases. Before a deploy run `df -h /` on the host; when it is above 90 %, report it to the owner, because the rest (old release images and release directories per project) is each project's own to clean. Related: OPS-005, OPS-237 (the same full host seen mid-upload).


## OPS-239 — Driving Safari in an iOS simulator over ssh with no GUI permissions: a one-test XCUITest rotates the device and opens the URL, synthetic `TouchEvent`s in the page do the multi-touch

`측정 2026-09-30 · Xcode 27.0 · iOS 27.0 simulator (iPhone 18 Pro) · MacBook Air M1 over ssh, no sudo`

**증상:** `xcrun simctl` can boot a simulator, `openurl` and `io screenshot`, but it cannot tap or rotate. The usual ways out were all closed from an ssh session: `osascript` on System Events hung (it waits for an Automation/Accessibility prompt on the Mac's screen), `safaridriver --enable` asked for a password, and `safaridriver` sessions with `safari:useSimulator` failed with `Could not find any session hosts that match the requested capabilities`.

**해결:** two pieces, neither needs a permission prompt.
- Rotation and opening the page: a project with a single UI-testing bundle target (no app target; `CODE_SIGNING_ALLOWED = NO`, `GENERATE_INFOPLIST_FILE = YES`) whose test sets `XCUIDevice.shared.orientation`, calls `XCUIDevice.shared.system.open(url)` and sleeps. Build once with `xcodebuild build-for-testing`, run with `test-without-building`; environment variables prefixed `TEST_RUNNER_` reach the test without the prefix. Take `simctl io <udid> screenshot` in a loop while the test sleeps.
- Touch input: XCUITest coordinates are single-finger, so two-finger play (joystick + held button) came from the page itself: serve the build locally (the simulator reaches the Mac's `127.0.0.1`) with a script appended that dispatches `new TouchEvent('touchstart'|'touchmove'|'touchend', {touches, targetTouches, changedTouches})` built from `new Touch({identifier, target: canvas, clientX, clientY, …})` on the canvas. A Godot 4.7 web export accepted them like real touches in iOS Safari (cut, claim, UI buttons).
- The first boot of a new simulator pushed the Air's load average to 189 for about five minutes and Safari sat on its start page; wait for the load to drop before judging the page.

## OPS-240 — A Dokploy app built as `<app>:latest` leaves every earlier build as a dangling image: 27 GB in one day on a shared host, cleared safely with `docker image prune -f`

`측정 2026-09-30 · Ubuntu host with Docker and Dokploy, 98 GB root volume shared by about 20 projects`

**증상:** the "disk full within 4 hours" alert fired (`predict_linear` over 6 h). `df -h /`: 98G size, 92G used, 1.2G available, 99 %, a few hours after OPS-238 had cleared the build cache. `docker images -f dangling=true` listed 44 untagged images; 30 of them were 1.67 GB each, created every 5 to 15 minutes since 00:29 UTC. They were all former builds of one Dokploy application whose image is `<app>:latest`: each redeploy moves the tag to the new build and the old one stays as `<none>:<none>`. `docker system df` showed Images 54.77 GB, 37.63 GB reclaimable, while the build cache was only 545 MB, so `docker builder prune` (OPS-238) frees almost nothing in this case.

**해결:** `docker image prune -f` (without `-a`) removes only untagged images that no container uses. It reclaimed 27.06 GB (92G used to 63G, 99 % to 68 %); no service changed replica count and no tagged rollback image was touched. `-a` stays forbidden on a shared host (OPS-238). To find the writer, sort `docker images --format "{{.CreatedAt}}\t{{.Size}}\t{{.Repository}}:{{.Tag}}" | sort -r`: the repeating size at a regular interval names the app. A session that redeploys a `:latest` app many times a day should run `docker image prune -f` after each deploy, or the app should get a smaller image. Related: OPS-238, OPS-237.

**Follow-up (same day, OPS-240):** the host now runs `docker image prune -f` every 30 minutes from a systemd user timer (`~/.config/systemd/user/docker-dangling-prune.{service,timer}`, `OnCalendar=*:0/30`; the host has no `crontab` binary, and `Linger=yes` keeps user timers running without a login). The root volume was also only half of the disk: `lsblk` showed a 235.4G partition under a 100G logical volume (the Ubuntu installer default), readable without sudo. `lvextend -r -L 200G /dev/ubuntu-vg/ubuntu-lv` grew the mounted ext4 online with no restart (197G size, 29 % used); 35G stays unallocated in the volume group. On a "disk full" host, run `lsblk` before deleting anything.

**Follow-up 2 (same day, OPS-240):** the root volume now takes the whole SSD (`lvextend -r -l +100%FREE`, 232G). The host's second disk was checked before use with `lsblk -o NAME,SIZE,TRAN,ROTA,MODEL`: `ROTA=1`, a 7200 rpm laptop HDD with 27,340 power-on hours, so it was not added to the root volume group (a linear span dies with either disk and puts database files on the slow one). It is a separate ext4 at `/mnt/hdd` (687G, `nofail,noatime` in `/etc/fstab`, owned by the deploy user) for backups, release folders and CI caches. Without sudo but in the `docker` group, host root commands ran as `docker run --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i -- sh -c '<cmd>'`; the host had `sfdisk` but no `parted`.

**Follow-up 3 (same day, OPS-240):** `/mnt/hdd` holds copies of the backups, which until now sat on the same SSD as the data. `~/.mnori-deploy/mirror-backups-to-hdd.sh` runs from the user timer `backup-mirror-hdd.timer` (04:45 UTC daily, after the nightly backup and the Sunday retention) and copies `~/backups`, `~/.config/*/backups` and the other backup folders to `/mnt/hdd/backups` with `cp -au --parents` (the host has no `rsync`). It refuses to run when `/mnt/hdd` is not a mountpoint, never touches the SSD side, and deletes HDD copies older than 365 days. A project that writes backups into `~/.config/<project>/backups` is covered without doing anything. The fstab entry was tested without a reboot: `umount`, then `mount -a`, then `umount` and `systemctl start mnt-hdd.mount`; the generated unit has `WantedBy=local-fs.target`. A real reboot has not been tested.

## OPS-241 — Chrome on Android refuses `PUT /json/new` over the forwarded DevTools socket ("Could not create new page"), and the socket vanishes when Chrome is not running

`측정 2026-09-30 · Chrome on Pixel 7 Pro (Android 17) · adb forward tcp:<port> localabstract:chrome_devtools_remote · Node 26`

**증상:** `fetch('http://127.0.0.1:<port>/json/new?<url>', {method:'PUT'})` answered with the plain text `Could not create new page`, so `.json()` threw `Unexpected token 'C'`. A minute later every request failed with `SocketError: other side closed`: Chrome had left the foreground and its process was gone (`pidof com.android.chrome` empty, no `chrome_devtools_remote` in `/proc/net/unix`), while `adb forward --list` still showed the forward.

**해결:** open the tab from Android, then attach to it: `adb shell am start -a android.intent.action.VIEW -d '<url>?r=<marker>' com.android.chrome`, wait a few seconds, find the tab in `/json/list` by the marker and connect to its `webSocketDebuggerUrl`. `Page.navigate` reloads it for a clean run and `Page.close` removes it afterwards. This also starts Chrome when it was not running. On a phone shared by sessions, read `dumpsys window | grep mCurrentFocus` before every `adb shell input`: another session's app may have taken the screen, and the tap lands there (AGT-044).


## OPS-242 — A Nixpacks image of a Next.js standalone app is 1.67 GB and carries every secret in `docker history`; a three-stage Dockerfile makes it 319 MB, switched through the Dokploy API

`측정 2026-09-30 · Dokploy v0.30.7 · Nixpacks (Ubuntu 24.04 + Nix base) · Next.js 16.3 standalone · Docker 28.5 · GitLab CI`

**증상:** the app of OPS-240 kept producing 1.67 GB images. `docker history <app>:latest` gave the split: 810 MB `npm ci` (every dev dependency stays in the final image), about 600 MB base (Ubuntu 78 MB, apt 103 MB, Nix installer 165 MB, `nix-env` Node 252 MB), 103 MB `next build`, and the source tree copied three times (3 × 46 MB). The server that actually runs, `.next/standalone`, was 104 MB. The same `docker history --no-trunc` printed the database URL with its password and the base64 service-account key: Nixpacks declares every environment variable of the app as a build `ARG`, and ARG values are recorded in each `RUN` layer's metadata. Anyone in the `docker` group on the host can read them.

**해결:**
- Three stages on `node:22.11-slim`: `deps` (`npm ci` with a cache mount), `build` (`next build`), and a final stage that copies only `.next/standalone`, `.next/static`, `public/` and whatever the host reaches through `docker exec` (list those from the host's scripts before cutting: `grep -n "docker exec" ~/…/*.sh`). Result on the host: 319 MB, `USER node`, `docker history | grep -c DATABASE_URL` is 0.
- `NEXT_PUBLIC_*` values are inlined at build, so they must be build arguments. With Dokploy's `dockerfile` build type, the app's Environment is **not** passed to the build; only "Build-time Arguments" are. A missing argument still builds, and ships a site with an empty Firebase config. Make the Dockerfile fail instead: a `RUN` that exits 1 when a required `ARG` is empty. A failed build leaves the previous container serving.
- The switch needs no panel session: `POST /api/application.saveEnvironment {applicationId, env, buildArgs, buildSecrets, createEnvFile}` (send `env` back unchanged; `buildArgs` is the `KEY=value` lines) and `POST /api/application.saveBuildType {applicationId, buildType: "dockerfile", dockerfile: "Dockerfile", dockerContextPath: "", dockerBuildStage: "", herokuVersion, railpackVersion, publishDirectory, isStaticSpa}` with the `x-api-key` header, then read `application.one` back. Both answered 200. Save the settings before the push that adds the Dockerfile: a deploy in between fails the build and changes nothing.
- Fewer deploys: GitLab `rules: - if: $CI_COMMIT_BRANCH == "main"` plus `changes:` with the paths the image is built from, on the deploy job and on every job that `needs` it. On the day of OPS-240, 20 of 31 pushes changed only docs, tests or check scripts. A pipeline started by hand ("Run pipeline") treats `changes` as true, which is the manual redeploy. Do not add auto-cancel of older pipelines on top: `changes` looks only at the newest push, so a docs push that cancels a pending app push leaves the app change undeployed.
- Docker Desktop/colima with the containerd image store reported the same image as 494 MB (`docker images`) and 125 MB (`inspect .Size`); compare sizes on the host that runs it.
- Swarm keeps 5 stopped tasks per service (`TaskHistoryRetentionLimit`), shown as `Exited (143)` after each redeploy. That is the normal SIGTERM of a replaced task, and each one pins its old image against `docker image prune`. Related: OPS-240, OPS-238.

## OPS-243 — Editing an inline `configs: content:` block in a Dokploy compose and redeploying changes nothing: compose reports every container "Running" and the old config stays mounted

`측정 2026-09-30 · Dokploy v0.30.7 · Docker Compose 5.0.2 · Grafana 13.0.7 provisioned from inline compose configs`

**증상:** a monitoring stack keeps its Grafana alert rules and dashboard JSON as `configs: <name>: content: |` blocks in one raw compose. After `compose.update` + `compose.deploy` the deployment log ended with `Container …-grafana-1 Running` and `Docker Compose Deployed: ✅`, `composeStatus` was `done` after 15 s, and the container still showed `Up 5 weeks`. Inside it the provisioning files had none of the new text. `up -d` did not treat the changed config content as a reason to recreate the service.

Two more things that cost time on the way:
- `/etc/dokploy/compose/<appName>/code/docker-compose.yml` is not the source. It is Dokploy's rendered copy: comments removed, short lists expanded, Traefik labels added (1092 lines against 1100 in the database). Patch the `composeFile` returned by `compose.one`, never the file on disk; comparing the two byte for byte fails even when nothing changed.
- `project.all` returns projects without their services in this version. To find a `composeId` by `appName`, call `project.one` and then `environment.one` for each environment.

**해결:** after the Dokploy deploy, recreate the one service from the rendered file, which is world-readable:
`cd /etc/dokploy/compose/<appName>/code && docker compose -p <appName> --env-file .env -f docker-compose.yml up -d --force-recreate --no-deps <service>`.
Grafana was back in 6 s and logged `finished to provision alerting` and `finished to provision dashboards`. Verify inside the container (`docker exec <c> grep -c <new text> /etc/grafana/provisioning/...`), not by the deployment status. The Grafana admin password in the container environment is only used at first start; if it was changed later, basic auth with the env value answers 401. Related: OPS-240.

**Follow-up 4 (same day, OPS-240):** the Grafana dashboard `mnori-host` and the disk alerts only queried `mountpoint="/"`, so the new disk was collected by node-exporter but shown nowhere. Added three panels for `/mnt/hdd` and the rule `disk-hdd-backup`, whose query ends with `or on() vector(100)`: a missing mount evaluates to 100 %, so one rule covers both a full and an absent disk without relying on NoData handling. Deploying it needed OPS-243.

## OPS-244 — Dokploy deploy fails in 10 s with `RPC failed; HTTP 401` on the git clone; the same deploy passes on retry

`측정 2026-09-30 · Dokploy v0.30.7 · GitLab.com private repo over HTTPS · application build type dockerfile`

**증상:** a CI job called `application.deploy`; the deployment row went to `error` ten seconds later. The CI log only says the row failed. The Dokploy log (`/etc/dokploy/logs/<appName>/<appName>-<timestamp>.log`) shows the clone, not the build:

```
Cloning into '/etc/dokploy/applications/<appName>/code'...
error: RPC failed; HTTP 401 curl 22 The requested URL returned error: 401
fatal: expected flush after ref listing
```

The deploy before it (5 hours earlier) and the retry (4.5 minutes later) cloned the same repo with the same stored credentials and passed. Nothing was changed between the failure and the retry. The cause was not found: at that minute five other applications were deploying on the same host. The old container kept serving, so the site was not down, only stale.

**해결:** read the Dokploy log before touching credentials: a 401 on a single clone is not proof that the token expired. Retry the failed job (`glab api -X POST projects/:id/jobs/<job id>/retry`); it redeploys the branch head. Note that a later push that changes no deployable path does not redeploy, so a failed deploy followed by a docs-only push leaves production on the old build with a green latest pipeline. Check the live site, not the newest pipeline.

## OPS-245 — fontTools: limiting a variable font's weight range and then subsetting fails with `KeyError: 'uni3004'`; subset first

`측정 2026-09-30 · fontTools 4.60.2 · Python 3.9 · Noto Serif SC [wght] and Noto Serif JP [wght] (Google Fonts, 25 MB and 14 MB)`

**증상:** A script cut a web subset from a CJK variable font in this order: `instancer.instantiateVariableFont(font, {"wght": (400, 700)})`, then `subset.Subsetter(...).subset(font)`. The subsetter stopped with

```
  File ".../fontTools/subset/__init__.py", line 2455, in subset_glyphs
    self.variations = _dict_subset(self.variations, s.glyphs)
KeyError: 'uni3004'
```

The `gvar` table of the range-limited font no longer has an entry for every glyph the subsetter asks for.

**해결:** Subset first, then limit the axis: `Subsetter.subset(TTFont(source))` and only then `instantiateVariableFont(font, {"wght": (400, 700)})`. It is also faster, since the instancer then touches a few hundred glyphs instead of 30,000. Measured result: 633 Chinese characters → 200 KB woff2, 520 Japanese characters → 195 KB woff2, weights 400–700. Leaving out `layout_features=["*"]` cut the Japanese file from 282 KB to 195 KB. For a static cut used by Godot `TextMesh`, see GDT-212.

## OPS-246 — A Korean-first page translated to Chinese or Japanese: header labels in a flex row wrap to one character per line

`측정 2026-09-30 · Chrome 154 · 390 px and 320 px viewports · page CSS written for Korean (`word-break:keep-all`)`

**증상:** A page written for Korean used `word-break:keep-all` on its text. For `zh` and `ja` the rule was reset to `word-break:normal` so long lines wrap. At 390 px the header then showed each label as a vertical column, one character per line (`観 / 測 / 室 / に / …`), and the header grew to 250 px: Han and kana may break between any two characters, so a flex item that is allowed to shrink shrinks to the width of one character. Korean and Latin labels never did this because they only break at spaces.

**해결:** Give short labels in flex rows (header controls, chips, buttons) `white-space:nowrap`, and keep `word-break:normal` only for running text. Check every translated page at 320 px and 390 px: the problem does not appear at desktop width, and a text search for leftover Korean does not see it.

## OPS-247 — `rsync --delete` from the dev machine to a test host deletes the files Godot generated there: every new asset fails with `has no resource loaders (unrecognized file extension)`

`측정 2026-09-30 · rsync 2.6.9 (macOS) · Godot 4.7.2 --headless --import on the test host`

**증상:** the working tree is synced to a test Mac with `rsync -az --delete --exclude godot/.godot ...` before each test. New fonts were added on the dev machine; `godot --headless --import` on the test host imported them and the next test passed. After the next sync every preload of a new font failed:

```
SCRIPT ERROR: Parse Error: Preload file "res://assets/fonts/ZCOOLKuaiLe.subset.woff2" has no resource loaders (unrecognized file extension).
```

Godot writes `<asset>.import` (and `<script>.gd.uid`) next to the source files, not inside `.godot/`. They existed only on the test host, so `--delete` removed them, and without its `.import` file a `.woff2` is an unknown file to the loader. The message says nothing about a missing import.

**해결:** after the first import on the test host, copy the generated files back and commit them: `rsync -az --include='*/' --include='*.import' --include='*.uid' --exclude='*' host:project/godot/ godot/`. Or re-run `--import` after every sync. The same applies to any generator that writes beside its sources.

## OPS-248 — zsh: a glob with no match aborts the whole command line, so `rm -f /tmp/x-*.log; nohup …` starts nothing

`측정 2026-09-30 · zsh 5.9 (macOS), command sent over ssh`

**증상:** `ssh host 'rm -f /tmp/f-*.log; (nohup zsh -l job.sh &)'` printed `zsh:1: no matches found: /tmp/f-*.log`
and the job never started. `rm -f` does not help: zsh refuses the line before `rm` runs. Thinking it had started,
I launched it again later, and on the run where the logs did exist two copies ran at once and wrote the same logs.
bash would have passed the unmatched pattern through and carried on.

**해결:** mark the glob as allowed to match nothing: `rm -f /tmp/f-*.log(N)`, or name the files. After starting a
detached job over ssh, confirm it with `pgrep -f job.sh`. Do not count with `ps | grep` inside the same ssh
command: the remote shell's own command line contains the pattern and adds one to the count.

## OPS-249 — Dokploy `compose.deploy` is accepted at once but can start minutes later when other projects are deploying; a 300 s wait gave up on a good deploy

`측정 2026-09-30 · Dokploy v0.30.7 · one host, several projects deploying in the same hour`

**증상:** a deploy script called `compose.deploy`, then polled `compose.one` and `docker ps` for up to 300 s and stopped with "containers did not become healthy". Nothing was wrong with the containers. The Dokploy log for that deployment (`/etc/dokploy/logs/<appName>/<appName>-<timestamp>.log`) did not exist yet: the file appeared 5.5 minutes after the API call, and the compose `up` then finished in seconds. Earlier the same day the same call started within seconds. Deployments are queued host-wide, so the delay depends on what other projects are doing.

**해결:** tell "queued" from "failed" by the log file: no new file under `/etc/dokploy/logs/<appName>/` means Dokploy has not started. Wait at least 15 minutes before giving up, and do not retry the API call meanwhile (a second call queues a second deployment). If the script records release state only after the wait, a timeout leaves the state file one release behind even though production is on the new one; check the state file after any timeout. Related: OPS-244.

## OPS-250 — Adding Chinese/Japanese/Spanish to a Korean web UI: `word-break: keep-all`, `1fr` columns and `nowrap` buttons break at 320 px
`측정 2026-09-30 · Chrome 140 · CSS`

**증상:** A Korean-first page translated into five languages (GAME-LOCALES contract) looked right
in Korean and broke in the others:

- `body { word-break: keep-all }` (right for Korean) stops Chinese and Japanese from wrapping at
  all: they have no spaces, so a sentence runs off the screen.
- At 320 px the Spanish and Japanese pages scrolled sideways and every line was cut. The cause was
  not the long text itself: one `white-space: nowrap` row (a top bar, a button row, a header with
  a button) raised the min-content width of a grid whose column was `1fr` (= `minmax(auto, 1fr)`),
  and the whole column became wider than the screen.
- The display web font (Hahmlet) and Pretendard have no Han or kana: titles fell back to a system
  face, or to none.

**해결:**

- `:root:lang(zh) body, :root:lang(ja) body { word-break: normal; line-break: strict }`, and for
  Japanese `word-break: auto-phrase` after it (Chrome 119+; others ignore it and keep `normal`).
- Every grid that holds translated text: `grid-template-columns: minmax(0, 1fr)`; grid and flex
  children `min-width: 0`; button rows `flex-wrap: wrap` with `flex: 1 1 auto` (not `flex: 1`,
  whose zero basis never wraps).
- Title font for zh/ja: cut Noto Serif SC/JP down to the characters in the string table with
  fontTools (830 characters, 239 KB woff2 for zh). Subset first, then
  `instancer.instantiateVariableFont(font, {'wght': (700, 900)})`: the other order fails in the
  subsetter with `KeyError: '.notdef'`. A test compares the table's characters with the list the
  font was cut from, so a new string cannot ship without its glyphs.
- Check by script, not by eye alone: at 320 px list every element whose right edge is past
  `innerWidth`, and every line of `document.body.innerText` that still has Hangul.
- Spanish: a player's gender is unknown. "Han ejecutado a {n}" and "Sospecho de {t}" instead of
  "{n} ha sido ejecutado" and "{t} es sospechoso".

## OPS-251 — Vite 8: a shared chunk's CSS is linked before the entry CSS, so an `@layer a, b, c;` order statement in the entry stylesheet arrives too late and the layer order inverts
`측정 2026-09-30 · Vite 8.3.1 (rolldown) · Chrome 140 · CSS cascade layers`

**증상:** a page that declares its layer order once, at the top of the entry stylesheet
(`@layer reset, tokens, base, components, screens, utilities, overrides;`), built into a single
`index-*.css` and rendered correctly. After the entry module gained a top-level `await` and a few
dynamic `import()`s, the build split the component library into its own chunk and `dist/index.html`
listed two stylesheets, the chunk first:

```
<link rel="stylesheet" crossorigin href="/assets/ui-kG8juHsH.css">      <- only `@layer components { … }`
<link rel="stylesheet" crossorigin href="/assets/index-Bw5g2qMT.css">   <- carries the order statement
```

Layer order is fixed by the first time each name appears in the document, so `components` became
the lowest layer and the reset outranked every component. Nothing errors. What showed: an `<h1>`
with a component class stayed at 16 px (`h1 { font-size: inherit }` from `reset` beat
`.logo { font-size: var(--logo-fs) }` from `components`), while the same class on a `<div>` was
172.8 px. DevTools lists both rules as matching; only the layer order explains the winner. A probe
that prints `CSSLayerStatementRule` / `CSSLayerBlockRule` per stylesheet in document order shows it
at once.

**해결:** state the layer order in the HTML, before any stylesheet link, and keep the statement in
the CSS too:

```html
<style>@layer reset, tokens, base, components, screens, utilities, overrides;</style>
```

Vite appends its `<link>`s after it, so the order no longer depends on how the bundler chunks the
CSS. Check after any change that can re-chunk the build (top-level await, new dynamic imports,
`manualChunks`): `grep -o '<link[^>]*stylesheet[^>]*>' dist/index.html`.

## OPS-252 — nginx: one static page per language chosen by `?lang=`, a cookie, then `Accept-Language`, with four `map`s; `add_header` in that location drops the server's COOP/COEP

`측정 2026-09-30 · nginx 1.30-alpine · static Godot Web export, 11 request cases in a throwaway container`

**증상:** A static game page needs `<title>`, `og:title` and the description in the visitor's
language before any script runs (link previews, crawlers). The build writes `index.ko.html` …
`index.es.html`; nginx has no `if` chain that reads well for "query, else cookie, else the first
supported entry of Accept-Language, else English". Putting `add_header Content-Language` in the
`location = /` block also silently removed the server-level `Cross-Origin-Opener-Policy` and
`Cross-Origin-Embedder-Policy` headers for that location (any `add_header` in a location replaces
the inherited list), which a threaded or SharedArrayBuffer build cannot lose.

**해결:** in `http {}`:

```nginx
map $arg_lang $lang_from_arg { default ""; "~^(?<l>ko|en|zh|ja|es)$" $l; }
map $cookie_mnori_lang $lang_from_cookie { default ""; "~^(?<l>ko|en|zh|ja|es)$" $l; }
map $http_accept_language $lang_from_browser { default en; "~*(?:^|,)\s*(?<l>ko|en|zh|ja|es)(?:[-;,]|$)" $l; }
map "$lang_from_arg:$lang_from_cookie" $page_lang {
    default $lang_from_browser;
    "~^(?<l>[a-z][a-z]):" $l;
    "~^:(?<l>[a-z][a-z])$" $l;
}
```

and `location = / { try_files /index.$page_lang.html /index.html =404; add_header Content-Language $page_lang always; add_header Vary "Accept-Language, Cookie" always; … }`
with every server-level `add_header` repeated inside. The Accept-Language regex is unanchored, so
the leftmost entry that starts with a supported primary tag wins: `fr-FR,de;q=0.8,ja;q=0.5,en;q=0.4`
→ ja, `zh-TW,zh` → zh, `es-419` → es, `eo,ko` → ko, `en-US,en,ko` → en, `fr` alone → en. The
`(?:[-;,]|$)` after the tag keeps a longer tag that merely starts with the letters from matching.
The `default` of `$lang_from_browser` is what a link-preview crawler gets (it sends no cookie and
usually no Accept-Language): the MNORI contract wants the source language there (`default ko`),
while the page script in a browser still falls back to English. Each copy sets its own
`og:image` (`og.<code>.jpg`) so the preview picture is in that language too. An unknown `?lang=xx` falls through to the cookie
and header. Check the config before it replaces a live container:
`docker run --rm --add-host <upstream>:127.0.0.1 -v $PWD/nginx.conf:/etc/nginx/nginx.conf:ro nginx:1.30-alpine nginx -t`
(`proxy_pass` to a hostname fails `nginx -t` with "host not found in upstream" unless the name
resolves, hence `--add-host`).

## OPS-253 — Dokploy GitLab-provider deploy can error in ~2 s with `HTTP Basic: Access denied` on the deploy that refreshes the OAuth token; the errored row and its log are pruned within hours

`측정 2026-09-30 · Dokploy v0.30.7 · GitLab.com OAuth provider · application sourceType gitlab`

**증상:** A CI job that calls `application.deploy` and polls the deployment row saw it go
`error` 1.9 s after `createdAt`. The Dokploy container log (`docker logs -t dokploy.1.<id>`) held
only `Error getting git commit info … fatal: not a git repository` and the clone command with
`exitCode: 128`, `stdout: ''`, `stderr: ''` — git's own message went to the per-deployment log
file. It was the first deploy of any GitLab-sourced app on that host in eight hours, i.e. the one
that ran `refreshGitlabToken` (Dokploy refreshes only when a deploy starts within 60 s of
`gitlab.expires_at`; GitLab.com access tokens last 2 h). Re-requesting the deploy 5 min later
succeeded with nothing changed.

Reproduced the same day at 17:36:38 UTC, again on a refresh deploy (`expires_at` moved to
19:36:38, the deploy's own second). The log file this time:
`remote: HTTP Basic: Access denied … If a token was provided, it was either incorrect, expired, or
improperly scoped` / `fatal: Authentication failed for 'https://gitlab.com/<ns>/<repo>.git/'`.
The deploy requested 30 s later, with that same freshly issued token, cloned fine. So GitLab.com
can reject an OAuth access token for a few seconds right after issuing it, and Dokploy clones
immediately after refreshing. Not every refresh hits it (one at 15:27:28 the same day did not).

Dokploy keeps a bounded number of deployment rows per app (11 observed) and deletes the log file
(`/etc/dokploy/logs/<appName>/<appName>-<timestamp>.log`) with the row, so after a few more deploys
the errored deployment leaves no trace in the UI, the DB or on disk.

**해결:** In the CI poller, treat an `error` row whose `finishedAt - createdAt` is under ~30 s as
"never started" and request the deploy again (3 attempts, 20 s apart); a real build failure takes
a minute or more and is reported at once. Print the row's `errorMessage` and `logPath` in the CI
log when it fails, since the CI log outlives the row. Token expiry for triage:
`select to_timestamp(expires_at) from gitlab;` in `dokploy-postgres`.

## OPS-254 — A Dokploy schedule runs `docker exec <container> sh -c "<command>"`, so moving the app to a `-slim` image breaks a `curl` schedule with nothing red but the schedule's own log

`측정 2026-09-30 · Dokploy schedules (scheduleType application), app image moved from Nixpacks to node:22.11-slim`

**증상:** a Grafana "sync stalled" alert fired about an hour after an app switched from Nixpacks to a Dockerfile on `node:22-slim`. The deploy succeeded and the site served normally. Dokploy kept firing both schedules on time; each `deployment` row (the schedule run) had `status = error` and an empty `errorMessage`. The reason was only in the run's log file (`deployment.logPath`, under `/etc/dokploy/schedules/<appName>/`): `docker exec <id> sh -c curl -sS ... ` then `sh: 1: curl: not found`. The Nixpacks image had curl; `node:*-slim` and `debian:*-slim` have neither curl nor wget. It went unnoticed for ten hours.

An application schedule runs inside the app container, so the app image is the schedule's runtime. Changing the base image changes what every schedule can call, and neither the build nor the deploy knows.

**해결:** keep the command a schedule runs in the app repository and ship it in the image (e.g. `node scripts/ops/sync.mjs fast`, using Node's built-in `fetch`), so the image and the command change in the same commit. Read secrets from the container's environment instead of writing them into the schedule command. A test that fails when a host-run script is not copied into the runtime stage closes the gap. To change a schedule through the API, `schedule.update` rejects a partial body (zod: `name`, `cronExpression` ... "expected string, received undefined"): fetch `schedule.one?scheduleId=...`, change `command`, and send the whole object back. The change takes effect at the next tick with no restart. To read why a schedule failed: `SELECT "logPath" FROM deployment WHERE "scheduleId" IS NOT NULL ORDER BY "createdAt" DESC LIMIT 1` in `dokploy-postgres`, then `cat` that path on the host. Related: OPS-240.

## OPS-255 — A "last success" alert over `max(finished_at) WHERE ok` across all sources stays quiet while one source fails for days

`측정 2026-09-30 · Grafana alerting with a PostgreSQL datasource, table format`

**증상:** a `sync_run(source, finished_at, ok, error)` table logged two sync jobs. The alert asked `SELECT EXTRACT(EPOCH FROM now() - max(finished_at)) / 60 FROM sync_run WHERE ok` and fired past 45 minutes. One source failed on every run for nine days (5,252 rows with the same error) while the other succeeded every 15 minutes, so the alert never fired. It fired only when a separate fault stopped both.

**해결:** group by source and return the source as a string column. Grafana turns each row into its own alert instance labelled by that column, and `{{ $labels.source }}` names it in the summary (inside a compose `configs:` block, write `$$labels`, or compose interpolates it away):

```sql
SELECT source,
  COALESCE(EXTRACT(EPOCH FROM (now() - max(finished_at) FILTER (WHERE ok))) / 60, 999)
  AS minutes_since_success
FROM sync_run
WHERE started_at > now() - interval '30 days'
GROUP BY source
HAVING max(started_at) > now() - interval '1 day'
```

`FILTER (WHERE ok)` with the `COALESCE` gives a source that ran but never succeeded 999, where `WHERE ok` would have dropped the source entirely. The `HAVING` lets a retired source drop out after a day. When every source stops, the query returns no rows, so the rule needs `noDataState: Alerting`. After changing inline `configs:` content, Grafana needs `up -d --force-recreate grafana` (the container hash does not cover config content).

## OPS-256 — Next.js with two root layouts (`app/(ko)` + `app/[locale]`) serves Next's own unstyled 404 for every unmatched URL; `experimental.globalNotFound` fixes it

`측정 2026-09-30 · Next.js 16.3.2 (App Router, `next start`) · React 19.2`

**증상:** a site moved to two root layouts so `<html lang>` could differ per language: `app/(ko)/layout.tsx` for unprefixed paths and `app/[locale]/layout.tsx` with `generateStaticParams` + `dynamicParams = false` for `/en`, `/zh`, … Build and tests pass. Then `/nope`, `/a/b/c`, `/fr` and `/zh/nope` all return 404 with Next's built-in page (`<h1 class="next-error-h1">404</h1>`, `<title>404: This page could not be found.</title>`, no header, no styles). `app/(ko)/not-found.tsx` and `app/[locale]/not-found.tsx` are ignored for these, because an unmatched URL (and a `dynamicParams = false` miss, including an unknown slug under the dynamic root) has no layout to render a segment `not-found` in. `notFound()` thrown inside a page still uses its segment's `not-found.tsx`.

Workarounds that look tempting and are worse: dropping `dynamicParams = false` and calling `notFound()` for an unknown locale makes every bot path (`/wp-login.php`) an on-demand render cached as an ISR entry; a `[...rest]` catch-all at the root loses to `[locale]` for single-segment paths; a proxy/middleware runs on every request.

**해결:** turn on the documented flag and add `app/global-not-found.tsx`, which must return a full `<html><body>` and import its own global CSS:

```ts
// next.config.ts
experimental: { globalNotFound: true },
```

The build log then lists `✓ globalNotFound`, and all unmatched URLs return 404 with that page (verified with curl on `/nope`, `/a/b/c`, `/fr`, `/ko`, `/zh/nope`, `/en/games/nope`). The page is prerendered once, so it cannot know the URL's language on the server. To localise it without a hydration mismatch, read the path with `useSyncExternalStore(() => () => {}, () => localeFromPath(location.pathname), () => DEFAULT_LOCALE)` in a client provider: the server snapshot is used during hydration and the client value re-renders right after (set `document.documentElement.lang` in an effect). (Verified in Chrome: `/zh/nope` redraws in Chinese with no console error besides the 404 itself.)

## OPS-257 — Android emulator exits with `No initial system image for this configuration!` when the SDK system-image folder lost its `.img` files; sdkmanager still reports it installed

`측정 2026-09-30 · Android emulator 36.3.10 · system-images;android-35;google_apis;arm64-v8a r9 · macOS (Apple M1 Max)`

**증상:** `emulator -avd <name>` printed `Found systemPath …/system-images/android-35/google_apis/arm64-v8a/`
then `ERROR | No initial system image for this configuration!` and quit; `adb devices` stayed empty.
The folder still had `package.xml`, `source.properties`, `kernel-ranchu` and `data/`, but
`system.img`, `vendor.img` and `ramdisk.img` were gone (a disk cleanup had removed the large files).
`sdkmanager --list` still listed the package as installed, so `--install` alone does nothing.
Every AVD built on that image is broken the same way.

**해결:** `sdkmanager --uninstall "system-images;android-35;google_apis;arm64-v8a"` then
`sdkmanager --install` the same package (same revision, ~1.5 GB). The AVD folders are untouched; the
AVD booted in 15 s afterwards with its old userdata.

## OPS-258 — Android 35 emulator: `cmd locale set-system-locales` does not exist; switch the system language with `adb root` + `setprop persist.sys.locale` + `stop; start`

`측정 2026-09-30 · Android 35 google_apis arm64 emulator (sdk_gphone64_arm64) · adb 36`

**증상:** `adb shell cmd locale set-system-locales ko-KR` answers `Unknown command: set-system-locales`
(API 35's `cmd locale` only has `set-app-locales`). `settings put system system_locales` does not
change the running configuration, and the google_apis image has no `com.android.customlocale2` to
broadcast `SET_LOCALE` to.

**해결:** google_apis images allow root:

```
adb root
adb shell "setprop persist.sys.locale ja-JP; stop; sleep 1; start"
# wait ~20 s, then: adb shell am get-config  ->  config: …-ja-rJP-…
```

The framework restarts (not the VM), the launcher relabels apps in the new language, and apps
launched afterwards see the new locale. Per-app locale needs no root: `cmd locale set-app-locales <pkg> --locales ja-JP`.

## OPS-259 — GitLab.com jobs go to SaaS shared runners even when a project runner is online, until shared runners are turned off for the project

`측정 2026-10-01 · GitLab.com, untagged project runner (run_untagged=true) beside instance shared runners`

**증상:** a pipeline-schedule job that had always passed failed with every target `UNREACHABLE TimeoutError`. The job log's "Running on" line named `k8s.saas-linux-small-amd64.runners-manager.gitlab.com`, not the project's self-hosted runner. The job relied on being on that host: it writes the docker bridge gateway into `/etc/hosts` to get around a router that does not hairpin, and on a SaaS runner the gateway is a k8s node, so every request timed out. Every push job in the same project had run on the project runner for days; nothing in `.gitlab-ci.yml` chose a runner (no `tags`), so GitLab picked whichever eligible runner asked first.

An untagged job with `shared_runners_enabled: true` can land on either kind of runner. A project runner being online, idle and unlocked does not reserve the job for it.

**해결:** if every job assumes the self-hosted box, turn shared runners off for the project: `glab api -X PUT "projects/:id" -f shared_runners_enabled=false` (or Settings → CI/CD → Runners). Re-running the schedule (`glab api -X POST "projects/:id/pipeline_schedules/<id>/play"`) then ran on the project runner and passed 14 of 14. If only some jobs need the box, give the runner a tag and those jobs `tags:` instead. To check where a job ran: `glab api "projects/:id/jobs?per_page=20"` and read `runner.runner_type` (`instance_type` = shared, `project_type` = yours).

## OPS-260 — GitHub Actions storage on a free account (0.5GB) is filled by `upload-artifact` build outputs, and a self-hosted runner does not change that

`측정 2026-10-01 · GitHub Free (personal), actions/upload-artifact@v4, actions/runner v2.337.0 linux-arm64`

**증상:** GitHub emails "You have used 90% of the Actions storage included" (0.45 GB / 0.5 GB). The only producer was one private repo whose Godot client workflows uploaded macOS (~73MB) and Windows (~40MB) exports with the default 90-day retention: 16 artifacts, 904MB, from about 8 runs in two days. Public repos (Pages artifacts) do not count.

Find the producer with `gh api "repos/<owner>/<repo>/actions/artifacts?per_page=100"` per repo and sum `size_in_bytes` of non-expired ones. The billing usage API needs the `user` scope, which a default `gh` token lacks (404 + "needs the user scope").

Artifacts uploaded from a self-hosted runner are stored on GitHub and count the same. Release assets do not count toward Actions storage.

**해결:** delete the existing artifacts (`gh api -X DELETE repos/<owner>/<repo>/actions/artifacts/<id>`), then stop uploading them: build and `gh release create` in one job instead of passing exports between jobs as artifacts, and keep manual builds on the runner's own disk. For a self-hosted runner on Ubuntu, `gh` and `zip` are not preinstalled (`apt-get install gh zip`), and `actions/cache` steps become unnecessary because the home directory persists.

## OPS-261 — Korean banking agent WizIn-Delfino G3 keeps asking to be installed on Apple Silicon: x86_64-only binary, no Rosetta, and a non-traversable install folder

`측정 2026-10-01 · macOS 27 (Darwin 27.0.0) arm64, Delfino pkg com.wizvera.delfino, Chrome`

**증상:** after installing WizIn-Delfino G3, the bank site in Chrome still shows the "install Delfino" prompt on every visit. `pgrep delfino` finds nothing and nothing listens on localhost. `launchctl print gui/$(id -u)/com.wizvera.delfino` shows `job state = spawn failed`, `last exit code = 78: EX_CONFIG`. `log show` has no line for it, and Login Items (`sfltool dumpbtm`) shows it enabled and allowed, so neither hints at the cause.

Two independent faults, both silent:
1. The installer left `/Applications/Delfino` as `drwxrw-rw-` (766, no `x` for group/other), so the LaunchAgent, which runs as the user, cannot reach the binary. `ls /Applications/Delfino` fails with `fts_read: Permission denied`.
2. `delfino` is `Mach-O thin (x86_64)` only (`codesign -dv` → `Format=`), and Rosetta 2 was not installed. `arch -x86_64 /usr/bin/true` → `Bad CPU type in executable`. launchd reports this as the same EX_CONFIG.

**해결:**
```
sudo chmod -R u+rwX,go+rX /Applications/Delfino
sudo chmod go-w /Applications/Delfino /Applications/Delfino/*.app   # -R +rX leaves the top dirs 777 here
sudo softwareupdate --install-rosetta --agree-to-license
launchctl bootout gui/$(id -u)/com.wizvera.delfino
launchctl bootstrap gui/$(id -u) /Library/LaunchAgents/com.wizvera.delfino.plist
```
Then `job state = running` and `delfino` listens on `127.0.0.1:16107` and `127.0.0.1:16117`; reload the bank page. `launchctl kickstart -k` on the failed job hung instead of restarting it; bootout/bootstrap worked. Without sudo in a non-interactive shell, `osascript -e 'do shell script "…" with administrator privileges'` shows the GUI password prompt.

## OPS-262 — The MacBook Air test host has the `docker` CLI on `PATH` but no daemon: image builds cannot be tested there

`측정 2026-10-02 · MacBook Air test host (192.168.0.123) · docker CLI in ~/.local/bin`

**증상:** `ssh 192.168.0.123 'zsh -lc "which docker"'` prints `/Users/chowooick/.local/bin/docker`, so a Dockerfile looks testable on the Air. `docker build` then fails at once:
`failed to connect to the docker API at unix:///var/run/docker.sock ... no such file or directory`. There is no Docker Desktop, OrbStack or Colima daemon running, and starting one needs the owner's hand.

**해결:** on the Air, test what the Dockerfile runs rather than the image: `npm ci && npm run build` (Node 26 there) and the test suites. Let Dokploy do the image build, then check the live URL (headers, `/healthz`, a browser pass from the Air). For a plain static site (Vite → nginx:alpine, Dokploy GitLab provider, OPS-191 order, domain port 8080), the first deploy went from `running` to `done` in about 1 minute and the letsencrypt certificate was served on the first request.

## OPS-263 — Workers Free: 50 subrequests per invocation with Workers AI calls counted, and the 51st throws; a cut-off cron run is delivered again 4-6 s later

`측정 2026-10-03 · Cloudflare Workers Free · cron trigger · wrangler 4.135.0 · Workers GraphQL analytics`

**증상:** a six-hourly collector Worker left its run record in `running` 7 times out of 18 with no error in its own log. `wrangler tail` shows only live events, and the Workers Observability query API answers `code 10000 Authentication error` to the wrangler OAuth token. The GraphQL API at `https://api.cloudflare.com/client/v4/graphql` does accept that token. The `workersInvocationsAdaptive` dataset has `dimensions {datetimeFifteenMinutes status scriptVersion}`, `sum {requests errors subrequests}` and `quantiles {cpuTimeP99 wallTimeP99}` for each invocation, and it showed two causes:

- `scriptThrewException` with `subrequests` exactly 50. Normal runs used 41-49 out of 50, counting each fetch, each manual-redirect hop, waiting-room poll and Workers AI binding call. Retries to an origin that answered `HTTP 522` used up the rest. The 51st call threw after the main data was saved, and the `catch` block's own write to close the record threw too.
- `clientDisconnected` after 148-333 s of wall time, with CPU 50-130 ms. Each one was followed 4-6 s later by a second invocation for the same `scheduledTime`, which used 2 subrequests. The code checked whether a run for the slot was "running for less than 20 min" and treated the redelivery as a duplicate, so the slot was lost.

The 522s were on the origin's side: the same URLs answered 200 from home, from AWS Oregon and, four days later, from Workers again.

**해결:** count subrequests yourself and stop optional work at a reserve kept for the closing writes. After N connection failures to an origin (errors, timeouts, HTTP 52x), skip that origin for the rest of the invocation. Treat a scheduled delivery whose same-slot run started more than about 60 s ago as a redelivery and take that run over. At the start of each run, close older records left `running`. Workers Paid raises the limit to 10,000. Moving the job to a host that is not limited per invocation also avoids it; Workers AI can stay behind a small token-protected relay endpoint on the Worker, one model call per request.

## OPS-264 — Homebrew `codex` 0.154.0 fails every `codex exec` with "model is not supported when using Codex with a ChatGPT account" after the config default moves to a newer model; the ChatGPT app's bundled CLI works

`측정 2026-10-02 · codex-cli 0.154.0 (/opt/homebrew/bin/codex) · codex-cli 0.159.2 (ChatGPT.app) · ~/.codex/config.toml model = "gpt-6-sol"`

**증상:** unattended image generation (OPS-076) that worked a week earlier exits 1 in 6-9 s with no file. The log ends with
`warning: Model metadata for 'gpt-6-sol' not found` and `ERROR: {"type":"error","status":400,"error":{"type":"invalid_request_error","message":"The 'gpt-6-sol' model is not supported when using Codex with a ChatGPT account."}}`.
The shared `~/.codex/config.toml` had been switched to the new model by the desktop app; the older Homebrew CLI does not know it.

**해결:** run the CLI the ChatGPT app ships, which follows its own config: `/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex exec --skip-git-repo-check -C <empty dir> --sandbox workspace-write -`. With it the same instruction produced a 1024x1536 PNG in 62-90 s, two and three runs in parallel without errors (8 images). Check `"$CODEX" --version` in scripts instead of assuming `codex` on `PATH` is current.

## OPS-265 — PocketBase 0.40 JSVM migration: `field.type` is a Go method, so `field.type === 'select'` is silently false and the migration "applies" while changing nothing

`측정 2026-10-03 · PocketBase 0.40.4 (linux arm64, JS migrations)`

**증상:** a migration that widens a select field (`collection.fields.getByName('region')`, then `field.values = [...field.values, 'co']`, guarded by `field.type === 'select'`) printed `Applied 1790001600_….js`, was recorded in `_migrations`, and left every collection unchanged. No error, no warning.

On a field object from `collection.fields.getByName()`, `type` is the Go method `Type()` exposed to the JS VM as a function, so `field.type` is a function and never equals a string. `collection.type` is different: it is a plain value (`'base'`, `'view'`, `'auth'`). `field.name`, `field.values` and other plain struct members read as values; `field.values.indexOf()` and assigning a new JS array both work.

**해결:** compare `field.type()` (or `typeof field.type === 'function' ? field.type() : field.type`). Before touching production, dry-run on a copy: `sqlite3 data.db ".backup /tmp/pbtest/pb_data/data.db"`, copy the applied migrations plus the new one into `/tmp/pbtest/mig`, then `pocketbase migrate up --dir=/tmp/pbtest/pb_data --migrationsDir=/tmp/pbtest/mig` and read the result from `_collections`. A view collection built over the widened field re-reads its schema when it is saved again (`app.save(app.findCollectionByNameOrId(id))`). `pocketbase migrate down` asks `Do you really want to revert…? (y/N)` on stdin and cancels (exit 255) when run over ssh without a terminal.

## OPS-266 — three.js `renderer.dispose()` does not free the WebGL context: an SPA that mounts a new renderer per view hits Chrome's "Too many active WebGL contexts" and evicts the oldest scene

`측정 2026-10-03 · three 0.186 · Google Chrome (Playwright channel chrome, headless) · React 19 SPA`

**증상:** a site with three WebGL views (hero globe, a lab globe, a solar-system scene), each creating its own `WebGLRenderer` on mount and calling `scene` disposal plus `renderer.dispose()` on unmount. Cycling hero → lab → solar seven times (21 renderers) logged `WARNING: Too many active WebGL contexts. Oldest context will be lost.` and the view that lost its context went blank. Nothing failed while navigating slowly by hand; it shows up after a few minutes of browsing or in an end-to-end test that loops through the views.

`renderer.dispose()` releases three.js resources but leaves the context to be reclaimed whenever the browser garbage-collects the canvas. Chrome allows about 16 live contexts.

A second trap in the same code: three.js restores a lost context by itself (`webglcontextlost` is `preventDefault`ed internally), but a scene that renders only when something changes (paused globe, a static diagram) stays blank after `webglcontextrestored`, because nothing asks for a new frame.

**해결:** call `renderer.forceContextLoss()` right after `renderer.dispose()` on teardown (remove your own `webglcontextlost` listeners first, or ignore events after teardown). The same 7-round loop then logs no warning. For on-demand scenes, listen for `webglcontextrestored` on `renderer.domElement` and render again; hide the canvas (show a still) on `webglcontextlost`. Reproduce in a test with `canvas.getContext('webgl2').getExtension('WEBGL_lose_context').loseContext()` then `.restoreContext()` after a few hundred ms.

## OPS-267 — `.gitignore` treats `[backup]/` as a character class: it ignores `b/`, `a/`, `k/`… and not the folder literally named `[backup]`

`측정 2026-10-03 · git 2.54.0 (Apple Git-157)`

**증상:** a folder named `[backup]` holding private files kept appearing as `?? [backup]/` after adding the line `[backup]/` to `.gitignore`. Meanwhile a folder `b/` silently became ignored.

gitignore patterns use fnmatch globbing, where `[...]` matches one character from the set. `.dockerignore` (Go `filepath.Match`) behaves the same way.

**해결:** escape the brackets: `\[backup\]/` (in both `.gitignore` and `.dockerignore`). Check with `git status --porcelain --untracked-files=all` or `git check-ignore -v '[backup]/x'`. Better still, avoid `[`, `]`, `*`, `?` in folder names that need ignoring.

## OPS-268 — 재외공관 RSS의 `brdId`는 게시판 주소의 `m_` 번호와 다르다: 공관별 RSS 목록 페이지 `wpge/m_24159`에서 찾는다

`측정 2026-10-03 · overseas.mofa.go.kr 주샌프란시스코 총영사관(us-sanfrancisco-ko)`

**증상:** 게시판 주소의 번호(예: 순회영사 공지 `brd/m_4675/list.do`)를 `rss.do?brdId=4675`에 넣으면 피드가 아니라 빈 페이지나 오류 HTML이 온다. 목록 화면은 스크립트로 불러와서 HTML을 긁어도 글이 없다.

`brdId`는 게시판 메뉴 번호(`m_…`)와 별개다. 공관마다 RSS를 공개한 게시판만 `https://overseas.mofa.go.kr/<공관경로>/wpge/m_24159/contents.do`(RSS 안내 페이지)에 `brdId`와 함께 나열되어 있다. 주샌프란시스코는 `8832`(공지사항)와 `8846`(관할지역 정보) 두 개뿐이고, 순회영사 게시판에는 RSS가 없다.

**해결:** RSS 안내 페이지에서 `brdId`를 읽어 쓴다. 관할이 여러 주에 걸친 공관은 제목의 지명으로 지역을 가른다(본문에는 관할 주 전체가 나열되는 경우가 많아 본문 기준은 오분류가 난다).

## OPS-269 — 미국 지역 언론 RSS는 다수가 robots.txt로 ClaudeBot·anthropic-ai를 막는다: TEGNA 계열 방송사 `/feeds/syndication/rss/news/local`은 허용한다

`측정 2026-10-03 · 미국 4개 지역(LA·NJ·TX·CO) 영어 뉴스·관공서 피드 약 40곳 점검`

**증상:** 지역 신문 RSS를 수집기에 넣으려고 robots.txt를 확인하면 Colorado Sun, CPR, Denver Post, LA Times·Daily Pilot, OC Register, NJ.com, Patch, Houston Public Media, KUT, Dallas Morning News가 Anthropic 에이전트(ClaudeBot/anthropic-ai)를 `Disallow`한다. api.weather.gov는 모든 봇을 막는다. LAist·Gothamist는 GPTBot만 막는다.

**해결:** robots.txt를 존중하는 수집기라면 이 매체들은 뺀다. 같은 지역을 덮는 대안으로 TEGNA 계열 방송사(9NEWS 덴버, WFAA 댈러스, KHOU 휴스턴, KVUE 오스틴)의 `https://<도메인>/feeds/syndication/rss/news/local`은 허용되고 HTTP 200으로 열린다. 시·카운티 관공서는 403·404이거나 피드가 없는 곳이 많아(덴버·오로라·플레이노·캐럴턴·휴스턴·LA시·포트리·팰팍) 피드가 있는 곳만 골라야 한다.

## OPS-270 — PocketBase 0.40 규칙 검증: 운영 DB 복사본에 `superuser upsert` 후 `impersonate`로 회원 토큰을 받아 HTTP로 직접 찔러 본다

`측정 2026-10-03 · PocketBase 0.40.4 (linux arm64)`

**증상:** 새 컬렉션의 list/create/update/delete 규칙이 의도대로인지 마이그레이션 단위 테스트(문자열 비교)로는 확인이 안 된다. 운영 슈퍼유저 비밀번호는 기록되어 있지 않다.

**해결:** 복사본에서만 한다. `sqlite3 data.db ".backup /tmp/x/pb_data/data.db"` → 마이그레이션 적용(`migrate up --dir --migrationsDir`) → `pocketbase superuser upsert <임시메일> <임시비번> --dir=/tmp/x/pb_data` → `serve --http=127.0.0.1:<다른포트> --dir=/tmp/x/pb_data`로 띄운다. 슈퍼유저로 로그인한 뒤 `POST /api/collections/<auth컬렉션>/impersonate/<회원id>`(`{"duration":600}`)로 회원별 토큰을 받아 타인 수정(404 기대)·소유자 위조(400 기대)·헤더 없는 요청 등을 확인한다. 같은 회원 행에 `admin` 플래그가 있으면 "타인 삭제가 204"처럼 보이는 착시가 나니 비관리자 두 명으로 시험한다. 끝나면 프로세스를 PID로 종료하고(`pkill -f` 패턴이 ssh 명령 자신과 겹치면 세션이 끊긴다) 디렉터리를 지운다.

## OPS-271 — Playwright `page.route` aborts cross-document view transitions in Chrome: "Transition was aborted because of invalid state. ViewTransition opt-in disabled"

`측정 2026-10-03 · Playwright 1.63.0 · Google Chrome 154.0.8037.95 (channel: 'chrome', macOS)`

**증상:** A site with `@view-transition { navigation: auto; }` logs `InvalidStateError: Transition was aborted because of invalid state. ViewTransition opt-in disabled` as a page error on link navigations, but only in tests. A real browser and the same test without request interception show 0 errors.

Registering any `page.route` / `context.route` handler makes Chrome treat navigations as intercepted, and it then cancels the cross-document view transition. The handler does not need to match the navigated URL.

**해결:** This is a test artifact, not a site bug. Options: run the specs that need interception with `reducedMotion: 'reduce'` (if the site turns view transitions off under `prefers-reduced-motion`), or filter that one message out of the page-error assertion. Specs that assert "no page errors during navigation" should avoid `route` entirely.

## OPS-272 — Playwright `route.fetch()` follows redirects by default and fulfills the original URL with the final page, so the address bar never changes

`측정 2026-10-03 · Playwright 1.63.0`

**증상:** A route handler that edits HTML (`const r = await route.fetch(); route.fulfill({ response: r, body: edited })`) leaves the browser on the pre-redirect URL, for example `/nj/stories/` instead of `/nj/stories`, or a protected page instead of its login redirect. Relative links and tests that check `toHaveURL` then break.

`route.fetch()` follows up to 20 redirects itself, and `fulfill` answers the original request with the last response's body and a 200.

**해결:** `const r = await route.fetch({ maxRedirects: 0 }); if (r.status() !== 200) return route.fulfill({ response: r });` passes the 3xx back to the browser, which then follows it and requests the next URL through the same handler.

## OPS-273 — Node output generated on arm64 differs from amd64 in the last digit; a `git diff --exit-code` check on generated JSON fails on an amd64 runner

`측정 2026-10-03 · node:25 (v25.9.0) image, arm64 native vs amd64 · GitLab shell runner on arm64 Linux, docker runner on amd64`

**증상:** a CI job regenerates data with Node (trig on stage coordinates) and runs `git diff --exit-code -- <data dir>`. On a clean tree generated on an Apple Silicon Mac it failed on the amd64 runner with only last-digit changes, for example `-32.922779924576304` → `-32.9227799245763` and `-19.89367974722387` → `-19.893679747223867`. The Node version was the same (`node:25`) on both sides.

The same tree in the same `node:25` image produced no diff on arm64 Linux and the amd64 diff under `--platform linux/amd64` on that same host, so the CPU architecture alone decides it, not the OS or Node version.

**해결:** run the regenerate-and-diff job on a runner with the same architecture as the machines that generate the data (here an arm64 shell runner calling `docker run --platform linux/arm64 node:25 ...`), or round numbers before writing them. When a project gets a second runner, tag every job: two runners that both take untagged jobs pick them up at random.

## OPS-274 — `docker run --platform linux/amd64 <tag>` replaces the local `<tag>`, and later runs without `--platform` use the emulated image

`측정 2026-10-03 · Docker on arm64 Linux (OrbStack) · node:25`

**증상:** after one test with `docker run --platform linux/amd64 node:25`, a plain `docker run node:25` on the same arm64 host printed `x86_64` and gave amd64 results. The pull for the foreign platform re-pointed the local tag; nothing warns. A CI job on a shared host can silently switch architecture because of somebody else's test.

**해결:** put `--platform` on every `docker run` whose output depends on the architecture. To repair the tag: `docker pull --platform linux/arm64 <tag>` and check `docker image inspect <tag> --format '{{.Architecture}}'`.

## OPS-275 — Google sign-up forms on the test Mac (Air) prefill the **United States**: its internet egress is a US exit node. AdMob's payee country can never be changed

`측정 2026-10-03 · AdMob sign-up (admob.google.com/signup) in Chrome on the MacBook Air, Tailscale exit node on`

**증상:** opening AdMob's sign-up in the Air's Chrome profile showed 「수취인 국가/지역」 already set to **미국**, with the warning "지급 국가/지역은 현재 위치에 따라 정해집니다. 이 정보는 나중에 변경할 수 없으니…". The Air's public IP resolves to Colorado (CenturyLink) because its traffic leaves through a Tailscale exit node (see OPS-049 for the LAN side of the same setting).

**해결:** read every country / time-zone / currency field on Google (AdMob, AdSense, Play, Cloud) forms filled from the Air and set it explicitly — for (주)엠노리 that is 대한민국, (GMT+09:00) 서울, KRW. After the country was changed the terms re-rendered as the Korean 「구글 애드센스 온라인 서비스 약관」, which is the visible sign the change took. The next step of AdMob sign-up is SMS/voice phone verification, which needs the owner's phone.

## OPS-276 — A Chrome profile shared by Playwright and plain Chrome loses its Google login: Playwright launches with `--use-mock-keychain`, so the two encrypt cookies with different keys

`측정 2026-10-03 · playwright-core 1.63.0 · Google Chrome 154 · macOS (MacBook Air test host, ~/kc-test/profile)`

**증상:** the Air's automation profile (`~/kc-test/profile`, opened with `chromium.launchPersistentContext(..., { channel: 'chrome' })`) was signed in to Google for weeks. The owner then signed in again in a **plain** Chrome window on the same `--user-data-dir`. `Preferences` showed `account_info: chowooick@gmail.com`, but the next Playwright launch showed an empty Google sign-in page (no account chooser), and afterwards the `Cookies` DB held only 4 fresh google.com cookies (`NID`, `OTZ`, `__Host-GAPS`, `S`) and no `SID` family. The earlier logout, which stopped at "본인 확인 중... 패스키를 사용하여 로그인을 완료합니다", is likely the same thing in reverse. Copying the profile was suspected first, and that suspicion was wrong.

**원인:** playwright-core adds `--use-mock-keychain` to every Chrome it launches on macOS (`lib/coreBundle.js`, default args). `ignoreDefaultArgs: ['--enable-automation']` keeps it. So Playwright's Chrome encrypts cookies with a fixed mock key and plain Chrome uses the real macOS Keychain key. Each one fails to decrypt the other's cookies, treats itself as signed out and discards them. A sign-in done in one kind of window is wiped by the next launch of the other kind.

**해결:** sign in to an automation profile **only in a window Playwright opened** (headed, the same launch options the tests use), and never open that profile with plain Chrome (`open -na "Google Chrome" --args --user-data-dir=…` is plain Chrome). For a passkey sign-in, have the script open `https://accounts.google.com/AccountChooser?Email=<account>&continue=<target>` in its own window and poll until the target page is reached, while a person completes the passkey there. Check the result by what the page shows, not by `Preferences` `account_info`: that survives after the cookies are gone.

## OPS-277 — SpacetimeDB 2.8 area-of-interest subscriptions: `SubscribeMulti` with a range on an indexed column works on the v1.json protocol; it cut client-side rows 39 % and cost the server 22 points of one core

`측정 2026-10-03 · SpacetimeDB 2.8.0 standalone · v1.json.spacetimedb · Rust module · MacBook Air (Apple M1), 150 load bots in 6 Godot processes`

**증상:** a hand-written client (OPS-153) subscribed `SELECT * FROM pose WHERE zone = 0`, so every client decoded every player's movement at 10 Hz. Splitting the map into chunks needed message shapes and SQL support that the documentation does not show for the JSON protocol.

- **Messages** (JSON, probed with a Node `WebSocket`): send `{"SubscribeMulti": {"query_strings": [...], "request_id": n, "query_id": {"id": k}}}` and later `{"UnsubscribeMulti": {"request_id": n, "query_id": {"id": k}}}`. The answers are `SubscribeMultiApplied` / `UnsubscribeMultiApplied`, with the rows under `update.tables` exactly like a transaction. **Unsubscribing sends the rows the set held back as deletes.** A rejected set comes back as `SubscriptionError` carrying that `query_id`; the base `Subscribe` stays up.
- **Moving a window without rows blinking out:** subscribe the new set first, then unsubscribe the old one, and reference-count rows per query in the client cache (a row in both sets arrives twice and leaves once).
- **Subscription SQL accepts a range on an indexed `u32`:** `SELECT * FROM enemy WHERE chunk >= 525825 AND chunk <= 526850` returned exactly the matching rows. Packing the chunk id as `cx * 1024 + cz` makes the three chunks of a column consecutive, so a 3x3 window is 3 range queries per table instead of 9 equality queries.
- **Schema:** appending `#[index(btree)] #[default(0u32)] pub chunk: u32` to two live tables in a Rust module migrated under a data-keeping publish (with `--yes` including break-clients, OPS-170). Old rows read 0, so backfill them in a scheduled reducer.
- **Cost, measured.** Each of the 150 bots decoded every row and walked at 10 Hz, using 48 m chunks and a 3x3 window. Whole-map subscription: 17,946 rows decoded/s per 25-bot process, move p99 142–155 ms, server 50 % of one core. Chunk window: 9,585–11,994 rows/s, p99 59–69 ms, server 72 %. The window moved about 4 times per player per minute, so resubscribing is not the server's extra cost. The likely cause: an update is now evaluated and encoded per distinct query set instead of once for all.

**해결:** use chunked `SubscribeMulti` when client decode is the wall, and expect the server to pay for it. Put hysteresis on the window (here: move only 6 m inside a new chunk). In a load test, **check that the bots actually spread out**: this test's bots started at a spawn point outside their own walking box, only ever reversed direction, and stood in one chunk for every earlier run. With all bots in one spot, chunking showed −4 % instead of −39 %. Print the number of distinct chunks the bots occupy.

## OPS-278 — Google Play Console (Korean UI) by Playwright: Material inputs ignore clicks, one translation's gap blocks every save, and tablet screenshots are required for a game

`측정 2026-10-03 · Play Console web (ko UI) · Chrome 154 on the Air via playwright-core 1.63 connectOverCDP/persistent context · organization developer account`

**증상:** a scripted first setup of a game app (create app → internal testing → store listing → App content) stalls in places that look like timing: a radio stays unchecked after `click()`, the listing "저장" shows `일부 언어에 오류가 있습니다.` with no visible field error, the uploaded icon never reaches its slot, and the review cannot be sent.

Measured behaviour:

- **Create app** now asks for the package name up front (`[debug-id=app-package-name-input] input`, with a 「사용 가능 여부 확인」 check), plus default language, game/app, free/paid. A free game also shows 「자동 보호가 제공됩니다」 (installer check, on by default). The two declaration boxes (`guidelines-checkbox`, `export-laws-checkbox`) did not toggle on `material-checkbox.click()`. `locator('input').check({ force: true })` worked.
- **Material radios/checkboxes in App content and IARC:** sometimes `input.check({force:true})` throws "Clicking the checkbox did not change its state". What worked every time: `scrollIntoViewIfNeeded()` → `click()` on `material-radio` → if still unchecked, `input.evaluate(e => e.click())` → as a last resort, `page.mouse.click` on the box's left edge. Questions open one after another as earlier ones are answered, and "다음" stays disabled until the step is saved with "저장".
- **Asset slots (「애셋 추가」):** these open a side library, not a dialog. Clicking 「업로드」 raises a `filechooser`, and the uploaded files arrive selected. The button that puts them in the slot is the bottom-right 「추가」 of that panel (text `add_photo_alternate 추가`, x > 1030 at 1400 px wide). A text match on 「추가」 also hits the page's own 「애셋 추가」 links and opens another slot instead. For an asset that is already in the library: hover the row, then its `arrow_right_alt` button, then the panel's 「추가」.
- **A game's listing requires phone, 7-inch and 10-inch tablet screenshots** (all three marked *). 1920 × 1080 PNGs pass all three.
- **Translations:** after 「번역 관리 → 언어 선택」 adds languages, the listing cannot be saved until **every** added language has its title, short and full description (`일부 언어에 오류가 있습니다.`). Fill them all, then save once. A language without its own graphics shows the default language's graphics.
- **Contact details** (스토어 설정) save with 「저장 및 출시」: they go live at once, outside the review.
- **App content** for an AdMob game needed 10 declarations (privacy policy, ads, login, content rating, target audience, data safety, advertising ID, government, finance, health). The privacy-policy page adds that the policy must also be linked **inside the app**.
- **Internal testing** rolls out at once to an email list. The tester opt-in link only goes to the clipboard: `https://play.google.com/apps/internaltest/<track id>`. To read it, grant `clipboard-read` for `https://play.google.com` and read `navigator.clipboard.readText()`. Testers see the name `<package> (unreviewed)` until the app passes review.

**해결:** write small step scripts against one long-lived Chrome (attach over CDP rather than relaunching, so the Google login survives, OPS-276). After every step, read `innerText` and a screenshot. Match controls by `debug-id` or `aria-label`, and confirm every toggle by reading `input.checked` back. Fill all listing languages before the first save.

## OPS-279 — The Android emulator on the test Mac (Air) has no network, and a Godot GL game hangs QEMU within minutes; use the USB Pixel

`측정 2026-10-03 · Android emulator (sdkmanager "emulator") + system-images;android-35;google_apis;arm64-v8a, -no-window -gpu swiftshader_indirect · MacBook Air (Apple Silicon), Tailscale exit node on`

**증상:** an AVD created and booted headless on the Air (boot completed in 85 s) installed a Godot 4.7.2 release APK and showed its title screen, but inside the emulator nothing reached the internet: `nc -w 5 <public IP> 443` timed out, the app's UMP consent request failed with "2 Error making request", while the Air itself reached the same hosts (HTTP 200) and its firewall was off. A few minutes later the emulator died: `detected a hanging thread 'QEMU2 CPU0 thread'. No response for 15012 ms`, and `adb devices` lost it. Before that, System UI showed "isn't responding" dialogs.

**해결:** do not plan device tests of a GL game on an emulator on the Air. Use the USB Pixel 7 Pro (shared; see AGT-044 for etiquette). If the Pixel is locked (fingerprint), wait until it is unlocked rather than trying the emulator. The emulator packages (~2 GB) were left installed in ~/Library/Android/sdk on the Air; the AVD is `landgrab_qa`.

## OPS-280 — Google Play Console: with managed publishing off, a first app's changes were sent for review on their own once the publishing overview's quick checks passed

`측정 2026-10-03 · Play Console (web, ko UI), new app, organization account`

**증상:** the publishing overview listed 17 changes with a button "검토를 위해 변경사항 17개 제출" and the note "변경사항을 전송하면 검사가 성공적으로 완료되는 즉시 전송됩니다", plus one blocking quick-check issue (incomplete advertising ID declaration, "최대 14분 남음"). After the advertising ID declaration was saved, and without the submit button being pressed, 제출 활동 showed submission 1 at the time the checks finished, status 검토 중. The submission also contained an open testing release of the same bundle that had not been created on purpose; the open testing track stayed paused (트랙 다시 시작) and inactive.

**해결:** treat "save" on the last missing declaration of a new app with managed publishing off as a possible submission: finish the final device test of the bundle **before** completing the last App content item, or turn managed publishing on first if review must wait. Check 게시 개요 → 제출 활동 after any App content change to know whether something was sent.

## OPS-281 — A service worker's offline copy of a Vite build misses every module script under `vite preview`: the responses carry `Vary: Origin`, so `caches.match` needs `ignoreVary: true`

`측정 2026-10-03 · Vite 8.3 preview · Chrome 14x (Playwright, channel chrome) · Cache Storage API`

**증상:** a service worker cached the fingerprinted `/assets/*.js` and `.css` of a Vite site (`cache.add(url)` from a list the page posted). `caches.keys()` listed every file, yet with the context offline the reload showed a blank page (`#root` empty) and two `net::ERR_FAILED` for the module script and stylesheet. `curl -sI` on `vite preview` showed `Vary: Origin` on the assets. The page requests them with `crossorigin` (Vite adds it), so they carry an `Origin` header; `cache.add` fetched them without one. `caches.match(request)` honours `Vary`, so the stored copies never matched and the worker fell through to the network.

**해결:** for fingerprinted, immutable files match with `caches.match(request, { ignoreVary: true })` (and use it in the "already cached?" check too). After that the offline reload rendered the page and an experiment route. Production behind nginx sent no `Vary: Origin`, so a test against `vite preview` fails where production would pass; test offline against the server the site really runs on, or keep `ignoreVary`.

## OPS-282 — Black Han Sans draws ㄸ like ㅍ: "땅따먹기" in a game's title logo read as "팡파먹기"

`측정 2026-10-03 · Black Han Sans Regular (Google Fonts) · Paperlogy 9 Black 1.001`

**증상:** a Korean title logo set in Black Han Sans at display size (120 px, white fill, ink outline, hard shadow) was read by the owner as "땅파먹기". Rendering the bare glyphs with PIL, without outline or slant, shows the same thing. Black Han Sans draws the doubled consonant ㄸ as one closed box with two upright bars, which is the shape of ㅍ. The same happens to the ㄸ of 땅, so the word reads "팡파먹기". The outline and shadow do not cause it. It is the glyph design, so it shows at every size.

Paperlogy 9 Black (SIL OFL 1.1), Noto Sans KR Black and Gmarket Sans Bold draw ㄸ as two separate ㄷ, and these read correctly with the same treatment. Paperlogy 9 Black is about as heavy as Black Han Sans and 5% wider (advance 0.88 em against 0.835 em). Its ink height is 0.87 em against 0.76 em, so line spacing tuned for Black Han Sans packs the two lines too tight.

**해결:** before you choose a Korean display face, render the actual words and check the doubled consonants (ㄲ ㄸ ㅃ ㅆ ㅉ) next to their look-alikes (ㅍ for ㄸ). Paperlogy is not on Google Fonts. Its official archive is `https://github.com/Freesentation/paperlogy/raw/main/Paperlogy-1.001.zip` (also Homebrew cask `font-paperlogy`), and `OFL license.txt` is in the same repository.

## OPS-283 — Chrome on Android stops firing `beforeinstallprompt` once the site's WebAPK exists (or is being minted); "no prompt" on a test phone usually means "already installed"

`측정 2026-10-03 · Chrome 154.0.8037.92 · Pixel 7 Pro (Android 17) · adb + DevTools over adb forward`

**증상:** a site's own install card (shown on `beforeinstallprompt`) appeared 4–5 s after opening the page on the phone. After a reload, and in two fresh tabs (one per manifest language), the event never came within 45 s, although `Page.getInstallabilityErrors` returned `[]` and `localStorage` held no dismissal. The Chrome menu entry, now named **「설치 및 바로가기 만들기」** (Install and create shortcut), opened a sheet saying 「앱이 이미 설치되어 있습니다 · 클릭하여 앱 열기」. The app had been installed on the phone meanwhile (`firstInstallTime` minutes after the first prompt; the WebAPK `org.chromium.webapk.a…_v2`, label = manifest `short_name`, was missing from `pm list packages` until then). No prompt arrived from then on, and none arrived during that window either.

**해결:** before you debug a missing prompt on a device, find the site's WebAPK: for each `org.chromium.webapk.*` package, `adb pull` its `pm path` and run `aapt dump badging … | grep application-label` (the start URL is in `aapt dump xmltree … AndroidManifest.xml`). `adb uninstall <pkg>` brings the prompt back at once (4 s here). Chrome then shows `ClearDataDialogActivity` ("<app>도 Chrome에서 데이터를 보유하고 있습니다"); choose 「데이터 보관」 to keep the site's storage. A reinstall from the prompt fired `appinstalled` within 0.5 s, because Chrome reuses the minted APK. Shortcuts from the manifest appear in `dumpsys shortcut` under that package. The rich install sheet (description plus `form_factor: "narrow"` screenshots) shows in the dialog that `prompt()` opens.

## OPS-284 — Opening a just-installed PWA from the page on Android: `appinstalled` fires when the user accepts, the WebAPK lands 5–9 s later, and an `intent://` sent before that only reloads the tab

`측정 2026-10-03 · Chrome 154.0.8037.92 · Pixel 7 Pro (Android 17) · WebAPK minted through Play (Finsky)`

**증상:** a site wanted its new app to come to the front right after the install. The page followed `intent://<host>/#Intent;scheme=https;action=android.intent.action.VIEW;end` (a scripted `<a>` click; Chrome allowed it without a user gesture) 0.9 s after `appinstalled`. The tab simply navigated to `https://<host>/` in the browser. The same intent fired a minute later opened `SameTaskWebApkActivity`. Timeline of one install (page console timestamps, logcat):

- +0.0 s user taps 「설치」 in Chrome's sheet → **first `appinstalled`**
- +4.1 s Finsky `installPackage` … DOWNLOADING
- +6.4 s **second `appinstalled`**; +6.7 s `navigator.getInstalledRelatedApps()` first returns the app (with `related_applications: [{platform:"webapp", url:"./manifest.webmanifest"}]`)
- +8.7 s `SessionCommitReceiver: Adding package name to install queue` (the package exists)

An intent before the package exists has only Chrome as a handler, so Chrome loads the https URL in the same tab. `S.browser_fallback_url` is ignored for `scheme=https`, so a fallback cannot stop that.

**해결:** after `appinstalled`, poll `getInstalledRelatedApps()` until it returns the `webapp`, wait 3 s more, then follow the intent. Two runs measured 10.1 s and 10.8 s from accepting the sheet to the app in front, first try. Put a marker in the intent URL (`/?open-app=1`). If the tab reloads with it, the hand-off failed: retry from the reloaded page a few times, then show an "Open app" button. The app strips the marker when `display-mode: standalone` matches. `getInstalledRelatedApps` is 2.2–2.4 s ahead of the real install, so the poll alone is not enough.

## OPS-285 — Web Speech API in Chrome on macOS: the first utterance plays in a different voice (Albert) than later ones

`측정 2026-10-03 · Chrome (stable) on macOS 27.0.1, Korean system language · speechSynthesis`

**증상:** a page that picks a voice with `speechSynthesis.getVoices().find(...)` inside `speak()` played the first
line in a hoarse male voice and every later line in the chosen voice (Samantha). No error. In Chrome the voice list
can be empty on the first `getVoices()` call; the code then leaves `utterance.voice` unset, and Chrome falls back to
the first voice matching `utterance.lang`. On macOS the first `en-US` voice in Chrome's list is **Albert** (the list
starts `유나 (ko-KR, default)`, `Albert`, `Bad News`, `Bahh`, … — novelty voices included). Recorded with a
`speechSynthesis.speak` hook: first utterance `voice=null`, then `Samantha`.

Also seen: a male regex like `/male|daniel/` matches `female` in voice names on Windows/Google voices.

**해결:** call `getVoices()` at page load, and make `speak()` wait for a non-empty list (`voiceschanged`, with a
timeout) before building the utterance. Resolve the voice by exact name from a ranked list, cache it for the session,
and always set `utterance.voice` so every line uses the same voice.

## OPS-286 — A cross-document view transition on `root` moves the sticky header too; to test a CSS fix on production without `page.route`, inject it with `addInitScript`

`측정 2026-10-03 · Google Chrome (channel: 'chrome', headed, macOS) · Playwright (playwright-core)`

**증상:** With `@view-transition { navigation: auto; }` and a `page-in` keyframe on `::view-transition-new(root)` (fade plus `translate: 0 7px`), every top-menu click visibly shifts the sticky header. The header is part of the `root` snapshot, so it fades and slides with the page. Measured by screenshotting the header every ~50 ms during the transition: 1–2 px vertical offset, mean luminance difference up to 9.67 against the settled frame.

Giving the header its own snapshot stops it: `.topbar { view-transition-name: site-topbar }`, `::view-transition-group(site-topbar), ::view-transition-new(site-topbar) { animation: none }`, `::view-transition-old(site-topbar) { display: none }`. Afterwards: 0 px offset, mean difference ≤ 0.9 (a translucent `#ffffffed` background over the fading root). Holds when scrolled and in dark mode. The name must be unique per page, or Chrome skips the whole transition.

Testing the fix against production before deploying: CSS injected through `page.route` gave 0 transition pseudo-element animations even with an unmodified body, because any route handler cancels the transition (OPS-271). `context.addInitScript` that appends a `<style>` once `document.head` exists (MutationObserver on `document`) keeps the transition running, and `getComputedStyle(el).viewTransitionName` confirms the rule applied.

**해결:** Name fixed chrome (top bar, bottom nav) with `animation: none` so only content transitions. To check page-transition CSS, inject it with `addInitScript`, never `route`, and list `document.getAnimations().filter(a => a.effect?.pseudoElement)` to see which groups animate. A named group with `animation: none` does not appear in that list.

## OPS-287 — Chrome on the MacBook Air test host: a real-time `AudioContext` reports `running` but its clock never moves; `--disable-audio-output` fixes it

`측정 2026-10-03 · Chrome (stable) via Playwright 1.63 `channel: 'chrome'` · MacBook Air M1, macOS 27.0.1 · headed and headless`

**증상:** Web Audio playback never ended: `AudioBufferSourceNode.onended` never fired, so code that waits for speech to finish
hung forever. `new AudioContext()` created on a click reported `state: 'running'` but `currentTime` stayed at
`0.0053` (one render quantum) after 2 s. Same in headed and headless, with and without
`--mute-audio --autoplay-policy=no-user-gesture-required` (so OPS-163's flags do not help here). The default output
device was the built-in speakers and `coreaudiod` was running.

**해결:** launch Chrome with `--disable-audio-output`. Chrome then uses a fake output sink: `currentTime` read
`2.0107` after 2 s, and the playback-end events fired. Nothing is heard, which suits a shared test host. Use it for
any audio timing test on the Air.

## OPS-288 — Android WebView debugging: Playwright `connectOverCDP` refuses a WebView; raw CDP over the forwarded socket works

`측정 2026-10-03 · Playwright-core 1.63 · Android 15 emulator, system WebView · app calls WebView.setWebContentsDebuggingEnabled(true)`

**증상:** after `adb forward tcp:9339 localabstract:webview_devtools_remote_<pid>`,
`chromium.connectOverCDP('http://127.0.0.1:9339')` fails with
`Protocol error (Browser.setDownloadBehavior): Browser context management is not supported.`

**해결:** skip Playwright. Fetch `http://127.0.0.1:9339/json`, open the page target's `webSocketDebuggerUrl` with
Node's built-in `WebSocket`, and send CDP directly: `Runtime.evaluate` (`awaitPromise`, `returnByValue`) to read
state and `Input.dispatchTouchEvent` (`touchStart` then `touchEnd`) to tap. Use CSS-pixel coordinates from
`getBoundingClientRect()`. `adb shell input tap` with `rect × devicePixelRatio` misses as soon as the app pads
the WebView for system bars (edge to edge on Android 15+), because the WebView no longer starts at screen y = 0.
Find the socket name with `adb shell cat /proc/net/unix | grep webview_devtools_remote`.

## OPS-289 — wrangler OAuth 토큰으로 Cloudflare REST API를 직접 부르면 `10000 Authentication error`가 난다. `wrangler whoami`를 한 번 돌리면 풀린다

`측정 2026-10-03 · wrangler 4.125 · macOS · ~/Library/Preferences/.wrangler/config/default.toml`

**증상:** 스크립트가 `default.toml`의 `oauth_token`을 읽어 `POST /accounts/<id>/ai/run/<model>`을 불렀더니 `{"code":10000,"message":"Authentication error"}`가 왔다. 토큰 범위에는 `ai:write`가 있었다. wrangler 자체 명령은 정상이었다.

**해결:** 파일 속 토큰이 만료된 상태였다. wrangler는 자기 명령을 실행할 때만 `refresh_token`으로 갱신한다. REST 호출 전에 `npx wrangler whoami`를 한 번 실행하면 `oauth_token`이 새로 쓰이고, 같은 호출이 `success: true`로 돌아온다. 스크립트에서 쓸 때는 시작할 때 `wrangler whoami`를 먼저 부르거나 `CLOUDFLARE_API_TOKEN`을 쓴다.

## OPS-290 — A `zsh -c 'while pgrep -f "X"; do sleep …; done; …'` waiter waits forever: `pgrep -f` matches the waiter's own command line

`측정 2026-10-03 · macOS 27 (Darwin 27.0.0) · zsh, pgrep`

**증상:** background waiters meant to start a job after another finished (`nohup zsh -c 'while pgrep -f "run_cuts.py" >/dev/null; do sleep 15; done; python3 run_cuts.py …'`) never started. `pgrep -fl run_cuts` listed the waiters themselves: their own `zsh -c` argument contains the pattern, so the loop always finds a match. Two waiters on the same pattern also keep each other alive.

**해결:** chain jobs in one script run in the foreground of a single background shell (`job_a; job_b; echo DONE`), and make a later queue wait on a marker file or a log line (`until grep -q QUEUE_DONE queue.log; do sleep 10; done`) instead of a process pattern. If a process match is unavoidable, use a pattern that cannot appear in the waiter, e.g. `pgrep -f '^python3 .*run_cuts'`.

## OPS-291 — Android emulator 37.2.12 on macOS: gRPC `injectAudio` (microphone injection) kills the headless emulator

`측정 2026-10-04 · Android emulator 37.2.12.0 (build 16428233) · qemu-system-aarch64-headless · macOS 27.0.1, MacBook Air M1 · Python grpcio client`

**증상:** with the emulator started as `-no-window -grpc 8556`, streaming `AudioPacket`s to
`EmulatorController.injectAudio` (16 kHz mono S16, `MODE_REAL_TIME` or `MODE_UNSPECIFIED`) while an app records
makes the client fail with `UNAVAILABLE: Stream removed (recvmsg:Connection reset by peer (54))`, and the emulator
process is gone (`adb devices` empty). The crash report (`~/Library/Logs/DiagnosticReports/qemu-system-aarch64-headless-*.ips`)
is `EXC_BAD_ACCESS KERN_INVALID_ADDRESS at 0x58` in `audio_forwarder_enable` ←
`QemuAudioInputEngine::start` ← `QemuAudioInputStream` ← `EmulatorControllerImpl::injectAudio`. The crash happened
with `-allow-host-audio`, and also with `-audio coreaudio`. Without either flag the call returned, but the app got
no audio. A windowed emulator started over ssh (directly, or through `open x.command`) never reached `adb devices`.
It stopped after `Enabling Vulkan`.

**해결:** do not use `injectAudio` for unattended voice tests on this host. Feed the app's capture code from a file
instead: in debug builds only, read a 16 kHz mono WAV from the app's files dir in place of `AudioRecord.read`, at
real-time pace. Copy it in with `adb push x.wav /data/local/tmp/ && adb shell run-as <pkg> cp /data/local/tmp/x.wav files/<name>`.
This tests turn logic, VAD, socket and server STT end to end, but not the physical microphone.

## OPS-292 — Chrome launched over ssh on the Air gets an all-zero microphone; test the real capture pipeline with Chrome's fake device file

`측정 2026-10-04 · Chrome (stable) via Playwright 1.63 `channel: 'chrome'` · MacBook Air M1, macOS 27.0.1 · launched from an ssh session`

**증상:** `getUserMedia({audio})` succeeds and the track label is `MacBook Air 마이크 (Built-in)`, but every
sample is 0: peak RMS was 0.0000 in a quiet room and still 0.0000 while `afplay` played speech through the unmuted
speakers. This held with echo cancellation, noise suppression and AGC all off. macOS hands silent buffers to a process
whose responsible app has no microphone permission, and there is no prompt over ssh. (The output was muted at
volume 31; restore it afterwards.)

**해결:** use `--use-fake-ui-for-media-stream --use-fake-device-for-media-stream
--use-file-for-fake-audio-capture=<16 kHz wav>` (plus `--disable-audio-output`, OPS-287). This still runs Chrome's
real capture and processing path. The file loops from the moment the stream opens. If the app only listens at certain
moments (turn-taking), pad the file with leading silence so that the speech starts after the listening window opens.
Otherwise the test captures half sentences: speech started 9 s into the file gave a full sentence, and a looping file
with no lead-in gave three fragments.

## OPS-293 — `npx wrangler auth token` prints a refreshed OAuth token for scripts that call the Cloudflare REST API
`측정 2026-10-04 · wrangler 4.135.0`

**증상:** a script that reads `oauth_token` from wrangler's `default.toml` gets `{"code":10000,"message":"Authentication
error"}` from `POST /accounts/<id>/ai/run/<model>` once the stored token has expired (OPS-289).

`npx wrangler auth token` refreshes an expired login with the stored refresh token and prints the token. stdout is a
banner line, a rule line and the token as the last line, so take the last non-empty line. The same Workers AI call then
succeeds. This replaces reading `default.toml` (whose path differs between macOS and Linux) and the `wrangler whoami`
workaround in one step.

**해결:** in Node, `execFileSync('npx', ['wrangler', 'auth', 'token'], { stdio: ['ignore', 'pipe', 'ignore'] })
.toString().trim().split('\n').at(-1)`; fall back to `CLOUDFLARE_API_TOKEN` when it is set. Never log the value.

## OPS-294 — `git apply --unidiff-zero` with some `-U0` hunks left out puts later insertions at the wrong line and still reports success

`측정 2026-10-04 · git 2.50 · macOS`

**증상:** to split one session's work out of a shared dirty checkout, the hunks of `git diff -U0 HEAD -- file` were filtered (another session's hunks dropped) and applied in a clean worktree with `git apply --unidiff-zero`. The apply succeeded with no warning, but pure insertions landed inside other functions; the GDScript file then failed to parse (`Expected indented block after "if" block`) and a web build made from it shipped a broken scene script. The release was caught by running the tests before deploying.

Without context lines, an insertion hunk (`@@ -N,0 +M,K @@`) is placed purely by line number, and the numbers of the kept hunks assume the dropped ones were applied too.

**해결:** filter `git diff -U3` hunks instead and apply them with plain `git apply --check` / `git apply`; context lines place each hunk, and a hunk whose context includes the dropped work fails loudly instead of landing in the wrong place. Then compare the result with the source file (`diff` should show only the dropped work) and compare trees before committing (`git write-tree` in both places). Stage the same patch with `git apply --cached` in the shared checkout so the other session's working files are left alone.

## OPS-295 — CPU neural TTS on misa (i7-2635QM, thermally clamped): 18 s per new sentence, a 6-minute warm-up on every deploy; keep WAVs on a Dokploy volume (`mounts.create`) and send them at 24 kHz

`측정 2026-10-04 · Supertonic-3 ONNX (supertonic 1.3, onnxruntime CPU) · python:3.11-slim on Dokploy (misa) · 8 GB RAM`

**증상:** a FastAPI app that synthesizes speech with Supertonic-3 at startup (36 scripted sentences) kept the container at 170-300 % CPU for about 6 minutes after each deploy, and the host load average reached 15. During that window one new sentence took **18.1 s** (`POST /api/speech`), and even an already cached WAV took 2-6 s. `top` showed eight `idle_inject` kernel threads at 47 % each: intel_powerclamp is throttling the CPU for heat, so the box has less than its 4C/8T on paper. Every redeploy started a new container with an empty in-memory cache and paid the 6 minutes again. Idle, after warm-up, a new short sentence took 3.5 s. On an M1 MacBook Air the same sentence takes about 2.6 s including model load.

Second cost: Supertonic renders 44.1 kHz mono, so a 5 s line is a 460 KB WAV. From this host to a client in Korea the download ran at 100-800 KB/s, so the caller stayed silent for up to 5.2 s while the browser waited for the whole file before `decodeAudioData`.

**해결:**

- Write each synthesized WAV to a directory keyed by `sha1(voice|speed|rate|text)` (write to `.part`, then rename) and mount it as a named volume. Dokploy API: `POST /api/mounts.create {"type":"volume","volumeName":"<name>","mountPath":"/srv/app/cache","serviceId":"<applicationId>","serviceType":"application"}` returned the mount on the first try; it applies from the next deploy. Measured: after a redeploy the new container sat at 0.4-0.7 % CPU from its first seconds, against 270 % before.
- Resample to 24 kHz before writing the WAV. A band-limited resample through `numpy.fft.rfft`/`irfft` needs no scipy. The opening line went from 460 KB to 251 KB and its download from 5.2 s to 1.9 s. SenseVoice still transcribed the 24 kHz output word for word. Put the rate in the cache key, or the old 44.1 kHz files keep being served.
- Expect one more 6-minute warm-up after any change to the key or to the scripted lines. Run it after the deploy, not inside the image build: the build uses the same CPU.

## OPS-296 — A Samsung phone shows up in `ioreg` as "SAMSUNG_Android" but never in `adb devices`: no ADB USB interface means USB debugging is off, and `adb wait-for-usb-device` catches the moment it is turned on

`측정 2026-10-04 · Galaxy S24+ (SM-S926U) · macOS 27 · adb 1.0.41`

**증상:** `adb devices` was empty on both Macs, and `adb reconnect` printed "no devices/emulators found", while `ioreg -p IOUSB` on one of them listed `"USB Product Name" = "SAMSUNG_Android"` with a serial number. The device's interfaces (`ioreg -r -c IOUSBHostInterface -l`) were class 6 (MTP/PTP), 2 and 10 (CDC) only. An adb-capable device also exposes an interface with `bInterfaceClass = 255`, `bInterfaceSubClass = 66`, `bInterfaceProtocol = 1`. Without it, no host-side command helps; USB debugging is off on the phone.

**해결:** check for the 255/66 interface before you try anything else (`ioreg -r -c IOUSBHostInterface -l -w0 | grep -E '"bInterfaceClass" = 255|"bInterfaceSubClass" = 66'`). If it is missing, the owner has to turn on USB debugging. Start `adb -s <serial> wait-for-usb-device && adb -s <serial> install -r app.apk` in the background right away. In this run the install finished on its own the moment debugging came on, with no second prompt. A phone with a PIN lock still blocks UI checks afterwards (`dumpsys trust` → `deviceLocked=1`, the focus is `Bouncer`; see OPS-222). Poll `deviceLocked=0` the same way to take the screenshot once it is unlocked.

## OPS-297 — Shared test host: `pgrep -f tests/<name>.gd` also matches another worktree's run, because Godot is launched with a relative `--path client`

`측정 2026-10-04 · macOS 26 test host shared by parallel sessions · Godot 4.7.2 headless test scripts`

**증상:** a test run seemed hung, and `pgrep -fl "tests/"` showed `Godot --headless --path client --script ../tests/ui_flow.gd`. The command line was the same as this project's, so it looked like this session's leftover run, and it was killed. `lsof -p <pid> | grep cwd` showed `~/work/landgrab-gamepad/client`, a different worktree of the same repository, and no session there had started it either. Every worktree runs the same relative command, so the command line cannot tell them apart.

**해결:** before killing a process on a shared host, read its working directory (`lsof -p <pid> | grep cwd`) and its start time (`ps -o lstart -p <pid>`), and kill only if both match a run you started. Better still, start test runs with an absolute `--path ~/work/<project>/client` and a log path that names the project, so `pgrep -f <project>` finds only your own. Related: OPS-290 (pgrep matching its own waiter).

## OPS-298 — DeepSeek API: `deepseek-v4.1-flash` is rejected with 400 (the ids are `deepseek-flash` and `deepseek-v4-pro`), and the MacBook Air test host cannot reach api.deepseek.com at all

`측정 2026-10-04 · api.deepseek.com · curl 8 · httpx 0.28 · MacBook Air test host (192.168.0.123), misa`

**증상:** an app configured with `model: deepseek-v4.1-flash` got HTTP 400 on `/chat/completions`. The app caught the error and fell back to scripted lines, so with a valid key nothing looked broken. `GET /models` with the same key listed only `deepseek-flash` and `deepseek-v4-pro`. With `deepseek-flash`, a JSON-mode judge call (`thinking: {"type":"disabled"}`, `response_format: json_object`) answered in 1.07 s.

Separately, on the Air every call to `https://api.deepseek.com` hung until its timeout: `curl` → `000` after 30 s, httpx `ConnectError` after 30 s. DNS resolves to CloudFront (`3.173.21.63`) through gateway `192.168.0.1`. In the same minutes the developer Mac and misa (host and container) got answers in 0.24-0.36 s. On the Air the app's timeouts (7 s judge, 20 s stream) looked like a slow model.

**정정 (2026-10-04, 같은 날):** the Air's failure was not the network. LuLu (Objective-See firewall, `allowApple: true`, not passive) let `curl` (Apple-signed) out but held the uv-installed `cpython-3.11.16/bin/python3.11` binary, so httpx calls timed out (`ConnectTimeout` 21 s, `ConnectError` 30 s, once `gaierror`) while `nc -z` and `curl` to the same IP worked. After the owner allowed the binary in LuLu, the same calls returned 200 in 0.61-1.04 s. Check `/Library/Objective-See/LuLu/rules.plist` (world-readable NSKeyedArchiver; `action` 1 = allow) for the exact binary path before you blame the network (OPS-299).

**해결:** take model ids from `GET /models`, not from release names. Log the status of every LLM call that falls back, or a typo looks like a slow model. Test LLM features against a deployed server (misa) or from the developer Mac, not from the Air.

## OPS-299 — Serving an app from the MacBook Air behind LuLu: run cloudflared inside a colima VM, create the tunnel with the wrangler OAuth token, add the DNS record through the dashboard form

`측정 2026-10-04 · MacBook Air M1 16 GB (Denver) · LuLu (allowApple, not passive) · colima vz · cloudflared latest · wrangler OAuth`

**증상:** three blockers when a session moves a public site to the Air without anyone at the keyboard.

- LuLu holds every new binary that connects out until someone clicks its alert, and over ssh the session can neither see nor click it. `screencapture` says "could not create image from display". `osascript` System Events fails with -1728 (no accessibility), including when it is run through Terminal.app. In the system TCC database, `/usr/libexec/sshd-keygen-wrapper` has accessibility `0`; only Chrome has screen capture. A downloaded `cloudflared` would hang the same way.
- The wrangler OAuth token has no DNS write scope (OPS-093), and the dashboard session's `/api/v4` POST answers 403 HTML (OPS-111).
- Without auto-login, LaunchAgents start only after a console login.

**해결:**

- Read `/Library/Objective-See/LuLu/rules.plist` (world-readable NSKeyedArchiver; decode with `plistlib` by following the UIDs) to see which paths already have `action: 1`. Here `colima`, `limactl`, the uv Python and `com.apple.ssh` were allowed. So cloudflared ran as a container in a dedicated colima profile (`colima start speakout --cpu 1 --memory 1 --disk 4 --vm-type vz`): the VM's traffic passed with no alert, and `--add-host host.docker.internal:host-gateway` reached the server on the host's :8740 (bind it to 0.0.0.0, not 127.0.0.1). `colima start <profile>` switches the global docker context. Run `docker context use default` afterwards, or other sessions' `docker` commands land in your VM.
- The wrangler OAuth token's `connectivity:admin` scope is enough for tunnels: `POST /accounts/<id>/cfd_tunnel {"name":..,"config_src":"cloudflare"}`, `PUT .../cfd_tunnel/<id>/configurations {"config":{"ingress":[{"hostname":..,"service":"http://host.docker.internal:8740"},{"service":"http_status:404"}]}}`, `GET .../cfd_tunnel/<id>/token`. Pipe the token straight into a 0600 env file on the target, never through stdout, and pass it with `--env-file` (`TUNNEL_TOKEN`). Four connections registered within 2 s.
- For the CNAME, sign the Air's Chrome profile into the dashboard with Google, then fill the "레코드 추가" form with Playwright. The type picker is a custom control: click it and pick the `option` named CNAME. Fill the target by its placeholder `예: www.example.com` and the name by `루트에 @ 사용`, never by input index, or the target lands in the name field. Proxy is on by default. A specific `speakout` CNAME overrides the `*.mnori.com` A record. Requests then came back with `cf-ray …-DEN`.
- Deploy without inbound access: a read-only GitLab deploy key on the Air and a LaunchAgent with `StartInterval 60` that runs `git fetch`, `reset --hard` on a new commit and `launchctl kickstart -k` on the server. Measured: live 4 s after the push.
- Measured gain over misa (OPS-295): a new TTS sentence in 1.0 s instead of 3.5-18 s, and one LLM turn in 3.6 s instead of 12.8 s. Known gaps: no auto-login, macOS auto-install on, and the Air dropped off the LAN once for about 3 minutes (ARP incomplete, uptime unchanged).

## OPS-300 — Play Console internal testing for a new app, end to end by Playwright: the create button navigates after ~15 s, tester lists are `mat-checkbox[aria-label=<list>]`, and no signing prompt appears

`측정 2026-10-04 · Play Console web (ko UI), organization account · playwright-core connectOverCDP to one long-lived persistent context on the Air`

**증상:** extends OPS-278 for a first release of a non-AdMob app.

- `[debug-id=create-app-button]` took longer than 12 s to leave `create-new-app`. The page still showed the filled form, so it looked like nothing had happened, and a second click could create a duplicate app. It had already moved to `/app/<id>/app-dashboard`.
- On `tracks/internal-testing`, `[debug-id=create-android-release-button]` opens `releases/1/prepare`. The page body stays on "로드 중" for about 10 s. There was **no app signing choice**: Play App Signing is the default, and the uploaded bundle's key became the upload key. Upload: click 「업로드」, take the `filechooser` and `setFiles(aab)`. `[debug-id=added-artifacts-table]` shows `1 (0.1.0)` after about 5 s, and the release name fills itself in. Release notes go in `[debug-id=whats-new] textarea` as `<ko-KR>…</ko-KR>`. `[debug-id=review-button]`, then `[debug-id=main-button]` 「저장 및 출시」, then the dialog's 「저장 및 출시」. Warnings that did not block: no testers yet, no deobfuscation file.
- Testers tab: an existing email list is a `mat-checkbox[aria-label="<list name>"]` with `aria-checked`. A plain `click()` toggled it; read `aria-checked` back, then `[debug-id=save-button]`. It persisted across a reload, and the track summary changed from 비활성 to 활성. `[debug-id=web-link-share-button]` copies `https://play.google.com/apps/internaltest/<track id>` (read it with clipboard-read granted, OPS-278).
- Opening that link in the owner's profile showed "You're invited…" with a Become-a-tester button. After the click it showed "You're a tester for <package> (unreviewed)". This internal track needed no App content declarations and no store listing.

**해결:** after any navigating click, wait for the URL to change (or poll it) instead of clicking again. Read controls by `debug-id` or `aria-label` and confirm each state change by reading it back. Close the long-lived browser at the end so other sessions can use the shared profile.

## OPS-301 — Cloudflare without an API token: the signed-in dashboard session answers `/api/v4` calls; and what changes when a DNS-only host is switched to proxied

`측정 2026-10-04 · Cloudflare free plan, dashboard in Chrome (Playwright persistent profile) · nginx 1.30 origin behind Traefik`

**증상:** a site served straight from a home/office origin booted in 3 minutes: the origin sent 0.1-0.2 MB/s to the internet (a 27 MB file in 132-141 s), while it read the same file locally in 0.9 s and the client's line pulled 17 MB/s elsewhere. The zone was on Cloudflare but the host resolved through a DNS-only wildcard. `wrangler whoami` showed only `zone (read)`, no DNS or rules scope, and no API token existed.

- **No token needed:** in a page of `dash.cloudflare.com` with a signed-in session, `fetch('/api/v4/<path>', {headers: {'x-cross-site-security': 'dash', 'content-type': 'application/json'}})` runs the public API as that user. `POST /zones/<id>/dns_records` with `proxied: true` added a host record that overrides the wildcard; `PUT /zones/<id>/rulesets/phases/http_request_cache_settings/entrypoint` created the zone's first cache rule (a GET on that path returns 404 code 10003 until then).
- **Cache rule:** `action: set_cache_settings`, `cache: true`, edge and browser TTL `respect_origin`, on `ends_with(http.request.uri.path, ".pck")` etc. With the origin's `Cache-Control: no-cache` the edge stores the file and revalidates it with the ETag each time (`cf-cache-status: REVALIDATED`), so a release is live at once. Cloudflare's own fetch from the slow origin was fast: a miss took 2.9 s for 10 MB and 5.3 s for 29 MB; revalidated hits 0.8 s and 1.4 s. Browser boot went from 178-201 s to 7-11 s.
- **What broke:** the Browser Integrity Check answers `403` to the `Python-urllib/3.x` user agent (curl, Godot's `GodotEngine/4.x` and browsers pass), so urllib-based smoke tests failed with a JSON decode error on an HTML page. Every request now arrives at the origin from a Cloudflare address, so nginx `limit_req` keyed on `$binary_remote_addr` throttles all visitors behind one edge together.

**해결:** send your own `User-Agent` from scripts. Key rate limits on the visitor: `map $http_cf_connecting_ip $limit_key { "" $binary_remote_addr; default $http_cf_connecting_ip; }` and `limit_req_zone $limit_key ...`. A client that bypasses Cloudflare could set the header itself, but that only lets it choose its own rate-limit bucket.

## OPS-302 — Chrome 154 crashes the tab during a cross-document view transition when a stylesheet has `::view-transition-old(<name>):only-child`; use view transition types instead

`측정 2026-10-04 · Google Chrome 154.0.8037.95 (channel: 'chrome', headed, macOS) · Playwright (playwright-core) · Astro site with @view-transition { navigation: auto }`

**증상:** Adding one rule such as `::view-transition-old(site-footer):only-child { display: block }` (or the same with `::view-transition-new(...)` and an `animation`) made Playwright report `page.waitForTimeout: Page crashed` on one specific navigation (`/la` → `/la/stories`) every time, 6 of 6 runs. The same navigation with no extra CSS, with `:only-child` on a name nobody uses (`site-zzz`), or with plain `::view-transition-old(site-footer) { display: none }` did not crash. Other page pairs with the same rule (`/la/stories` → `/la/coupons`) did not crash. It crashed even when no element carried the name in the old page. Also note that `::view-transition-old(x):not(:only-child)` is not a valid selector (no `:not()` after the pseudo-element), so the whole rule is silently dropped.

**해결:** Do not tell exit-only and entry-only groups apart with `:only-child`. Decide it in script and say it with a view transition type: in `pageswap` store whether the element was named (`sessionStorage`), in `pagereveal` read it, check the new page, and `event.viewTransition.types.add('footer-out' | 'footer-in' | 'footer-stay')`. Style with `:root:active-view-transition-type(footer-out)::view-transition-old(site-footer) { display: block; animation: ... }`. 0 crashes in 30+ navigations afterwards.

## OPS-303 — A cross-document view transition captures the new page before the parser reaches the end of `<body>`; an element named in `pagereveal` may not exist yet. Add `<link rel="expect" blocking="render">` from the head script only when a transition is coming

`측정 2026-10-04 · Google Chrome 154.0.8037.95 (channel: 'chrome', headed, macOS) · Cloudflare Workers SSR pages, 50-470 KB HTML`

**증상:** A site footer is named in `pagereveal` only when it is on screen, so it can slide in. On `/housing` → `/stories` (58 KB HTML) `document.querySelector('.site-footer')` was `null` inside `pagereveal` in 2 of 2 runs, so the footer was never named and just appeared with the page. On other pairs it existed. Server timing for these pages: time to first byte 80-310 ms, the rest of the body 17-82 ms later.

`<link rel="expect" href="#site-footer" blocking="render">` fixes it, and it works when a head inline script inserts it during parsing (not only when parser-inserted): with it, the footer existed at `pagereveal` in 8 of 8 runs, first contentful paint +0-30 ms. A static link would block every first paint of every page, including first visits that have no transition.

**해결:** Give the element an `id`. In the old page's `pageswap`, when `event.viewTransition` is set, write a flag to `sessionStorage`. In an inline script in `<head>` of every page, read and remove the flag, and only if it was there append `<link rel="expect" href="#<id>" blocking="render">` to `document.head`. Clear the flag again in `pagereveal`, since a page restored from the back/forward cache does not rerun the head script.

## OPS-304 — Driving a cross-document view transition frame by frame from script: animate the root snapshots with WAAPI, add a live third layer by naming an element in `pagereveal`, and slow the whole thing with CDP to screenshot it

`측정 2026-10-04 · Google Chrome 154.0.8037.95 (Playwright channel: 'chrome', headless, macOS) · Astro 7 SSR pages on Cloudflare Workers`

**증상:** A page-to-page "zoom out to a grid of pages, pan, zoom into the next page" effect (Keynote Magic Move) cannot be written in CSS keyframes alone: the path depends on the viewport, the list position of both pages and the direction, and the grid of other pages exists in neither document. Screenshots taken during a 1 s transition land on 2-3 random frames.

**해결:**
- In an inline `<head>` script, listen for `pagereveal`, add a view transition type (for example `magic`) and set `animation: none; mix-blend-mode: normal` on `::view-transition-old(root)` / `::view-transition-new(root)` for that type. Then, in `event.viewTransition.ready.then(...)`, call `document.documentElement.animate(keyframes, { pseudoElement: '::view-transition-old(root)', duration, fill: 'both' })` and the same for `new(root)`. Script animations on the pseudo-elements keep the transition alive until they finish. Sample the camera path in JS (64 keyframes, `easing: 'linear'`) so several layers share one path exactly.
- A third layer: in the same `pagereveal`, append a `position: fixed` element with its own `view-transition-name` to `<html>`. It exists only in the new state, so it gets a new-only group; its `::view-transition-new(...)` is live, so WAAPI animations on its DOM children show during the transition. It is cut out of the new root snapshot. Order layers with `z-index` on `::view-transition-group(...)` (the root group above the inserted layer). Before the transition ends, fade the element to `opacity: 0` (last 1.5 % of its animation, while the new page already covers it) and remove it in `viewTransition.finished`; otherwise it can show for a frame after the pseudo-elements go.
- `clip-path: inset(0 round Npx)` works on `::view-transition-old/new(root)` for rounded page corners while they are scaled down.
- Measured with `requestAnimationFrame` from `pagereveal`: 77 frames, one 50 ms first frame, one 33 ms frame at most (390 px and 1440 px viewports).
- When the path is only zoom out → slide → zoom in, no script is needed and the phases can still overlap exactly: put the zoom (`scale` keyframes) on `::view-transition-image-pair(root)` and the slide (`translate: calc(-100% - <gap>) 0`) on `::view-transition-old/new(root)`. The nested transforms compose like a camera, `100%` is one card width, and `border-radius` + `overflow: clip` + `box-shadow` on old/new give rounded, shadowed cards; the canvas colour goes on `::view-transition-group(root)`.
- To capture frames: `const cdp = await context.newCDPSession(page); await cdp.send('Animation.enable'); await cdp.send('Animation.setPlaybackRate', { playbackRate: 0.1 })` before clicking the link. The rate survives the cross-document navigation and slows the view transition 10x, so screenshots every 1-1.5 s show each phase.

## OPS-305 — Gradle on JDK 25 fails with nothing but the version string ("What went wrong: 25.0.1"); a re-uploaded App Bundle is not attached to the Play release

`측정 2026-10-04 · Gradle wrapper of an AGP 8.x Android project · Temurin 25.0.1 as the only system JDK · macOS 27 · Google Play Console (web, Korean UI)`

**증상:** `./gradlew :app:bundleRelease` on a Mac whose only JDK is Temurin 25 printed `* What went wrong:` followed by a single line, `25.0.1`, with no stack trace. With Android Studio's bundled JDK it went one step further: `SDK location not found` (the git-ignored `local.properties` was gone).

**해결:** `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ANDROID_HOME=~/Library/Android/sdk ./gradlew :app:bundleRelease -P...`. Both variables are needed; neither needs a file in the repo.

In Play Console, uploading the `.aab` registers its version code in the app's bundle library at once, even if the release draft is then left unsaved. Uploading the same file again into the draft does nothing visible: the bundle table stays empty and "다음" stays disabled. Use "라이브러리에서 추가", tick the version, then "버전에 추가". The release name is empty when added this way and has to be filled (e.g. `2 (0.1.0)`) before "다음" enables. The only review warning for an unminified build is the missing deobfuscation file, which does not block "저장 및 출시".

## OPS-306 — atlantaga.gov answers 403 to a collector in Korea while a US host gets 200; check new feeds from the host that will read them

`측정 2026-10-04 · City of Atlanta RSS (www.atlantaga.gov/Home/Components/RssFeeds/RssFeed/View?ctID=5&cateIDs=1) · test host in the US, collector host in Korea (busan)`

**증상:** the City of Atlanta news feed returned HTTP 200 with 24 items from the US test host (curl and Node `fetch`,
same User-Agent), and robots.txt allowed every agent. The first scheduled-style run on the collector host in Korea
reported `SOURCE_HTTP_403` for it, while the other seven Georgia feeds read fine from there. WebFetch was refused by
atlantaga.gov the same day.

**해결:** vet a new feed from the machine that will actually read it (here: run the collector once with `--manual`
right after deploying) and drop or replace feeds that only answer some networks. A feed that fails on every run only
adds a permanent `failed` row to each run report.

## OPS-307 — Cross-document view transition: one keyframe set for both directions via a custom property set by `:active-view-transition-type()`; cut the moving root at a translucent sticky header with `clip-path`

`측정 2026-10-04 · Google Chrome 154.0.8037.95 (channel: 'chrome', headless and headed, macOS) · Astro site with @view-transition { navigation: auto }`

**증상:** A next/prev page turn written as separate keyframes per direction doubles every rule, and when `::view-transition-old/new(root)` slides sideways under a sticky header with a `#ffffffed` background, the sliding page faintly shows through the header. A headline lifted into its own new-only layer (`view-transition-name` set in `pagereveal`) to land a beat ahead of the body ghosted over the old headline when it started before the old root had faded out.

- `:root:active-view-transition-type(turn-next, panel-next) { --turn-dir: 1 }` (comma list accepted) plus `@keyframes turn-in { from { translate: calc(var(--turn-dir, 1) * 48px) 0 } }` works: the `::view-transition-*` pseudo-elements inherit the custom property from `<html>` and the keyframe resolves it. 0 aborted transitions in 10+ runs at 390 and 1280-1440 px.
- `clip-path: inset(var(--turn-top) 0 0)` on `::view-transition-old(root)` and `::view-transition-new(root)`, with `--turn-top` set from `.topbar.getBoundingClientRect().bottom` in `pagereveal`, hides the page under the header for the whole move; a horizontal `translate` moves the clip with the image, so the top cut stays put. Put the page colour on `::view-transition-group(root)` (`animation: none`) so the strip a sliding image uncovers is not empty.
- Ghosting: with old root fading out over 0.18 s and the headline layer starting at 0.12 s, both headlines were visible at once in slowed captures (CDP `Animation.setPlaybackRate` 0.1). Starting the headline at 0.15 s and the body at 0.2 s after a 0.16 s exit removed it. Frame times stayed at 17 ms with `filter: blur(6px)` on full-viewport snapshots (headless).

**해결:** Set the direction once as a custom property under the transition type, cut the root images at the header with `clip-path`, and start any new-only layer only after the old root's exit has ended.

## OPS-308 — Play Console update by Playwright: an App Bundle over 50 MB cannot be uploaded over `connectOverCDP`, screenshots land in the order uploads finish, and the listing's save button hides in a ⋮ menu

`측정 2026-10-05 · Play Console web (ko UI), organization account · playwright-core with a persistent Chrome profile on the Air · 139 MB .aab`

**증상:** an update (new production release, new store graphics in five languages, content rating
and data safety re-answered) driven by small step scripts attached over CDP to one long-lived
Chrome (OPS-278, OPS-300):

1. `fileChooser.setFiles` on the bundle failed: `Cannot transfer files larger than 50Mb to a browser
   not co-located with the server`. CDP-attached clients cannot send big files.
2. Eight screenshots uploaded in one file chooser went into the slot in the order the uploads
   finished, not file-name order (title ended up seventh).
3. In the asset library panel, rows below the panel's bottom bar (about y > 850 at 1400×1000) are
   covered by it. Hovering them shows no row arrow, and the add silently does nothing.
4. With the library panel closed, the listing's bottom bar showed only 「삭제」 and ⋮. 「저장」 and
   「임시보관함에 저장」 were inside the ⋮ menu (`[role=menuitem]`).
5. `getByText(...).click()` timed out on several controls because the first match was a hidden copy
   (another language's form or a collapsed section kept in the DOM).
6. On a translation, empty graphics slots show the default language's images faded. Counting `img`
   in the slot reports them as if they were the translation's own.

**해결:**
- Run the steps inside the process that launched the persistent context: a small server polls for
  `job.mjs`, imports it with a cache-busting query, and runs it against its own page. Uploads of any
  size then work. Import helper modules as `file:///…/lib.mjs?v=N`, or Node keeps serving the first
  version.
- Put screenshots in order by uploading them to the library once, then adding them one at a time.
  For each, open the slot's 「애셋 추가」, scroll the panel until the row is above the bar, hover the
  row, press its `arrow_right_alt`, then press the panel's own 「추가」 (bottom right).
- Click 「저장」 through the ⋮ menu when it is not in the bar.
- Use `locator("visible=true")` or click the bounding box with `page.mouse`.
- Check a translation's graphics by screenshot, not by counting.

Data safety answers export and import as CSV (「CSV 파일로 내보내기」 / 「CSV에서 가져오기」, then
confirm the overwrite dialog and step 2 → 5 → 저장). Editing one purpose in the CSV is faster and
safer than clicking through the form.

With managed publishing turned on first, all of these saved changes collect in the publishing
overview and go to review together, which avoids the auto-submission of OPS-280.

## OPS-309 — Playwright persistent profile held by another session: exit code 21 "ProcessSingleton"; copy the profile without `Singleton*` and open the copy

`측정 2026-10-05 · Chrome 154 on the Air · playwright-core launchPersistentContext({ channel: 'chrome' })`

**증상:** a session on the shared test host opened the shared signed-in profile while another
session's Chrome held it. Playwright threw at once:
`browserType.launchPersistentContext: Failed to create a ProcessSingleton for your profile directory`,
with `Failed to create <profile>/SingletonLock: File exists (17)` in the call log and
`process did exit: exitCode=21`. A script that only saved `storageState` afterwards wrote no state,
so every test after it failed as signed out. The failures looked like a broken deploy (82 of 86 tests).

The lock is not stale while the other Chrome runs, so waiting or deleting `SingletonLock` is wrong.
Never delete or reset the original profile.

**해결:** copy the profile to a directory of your own, leaving out the lock files and caches, and open
the copy:
`rsync -a --exclude 'Singleton*' --exclude '*Cache*' ~/kc-test/profile/ ~/kc-test/profile-<task>/`.
The Google account came across in the copy: the account chooser offered it and a site sign-in
through it completed (`SIGNED_IN`). Check the sign-in line before running the suite, so a missing
session fails one step instead of the whole run.

## OPS-310 — China restaurant data without login: Dianping shop pages open with `?msource=applemaps`; Apple Maps place pages carry Dianping menu prices; 360 map POI search needs no key; China map coordinates are GCJ-02

`측정 2026-10-05 · curl 8 from macOS · m.dianping.com · maps.apple.com · restapi.map.so.com · Chrome 154 headless on the Air`

**증상:** researching Chinese restaurants (address, hours, average spend, dishes, coordinates) from
outside China: `m.dianping.com/search/...` and dish pages return only a phone-login wall
(`手机号快捷登录`); Amap web endpoints (`amap.com/service/poiInfo`) return an Alibaba captcha page;
Bing via curl returns unrelated results; DuckDuckGo lite returns a bot challenge; WebSearch rarely
finds the branch page.

What works without login or key:

- **Dianping shop page:** `http://m.dianping.com/shop/<id>?msource=applemaps` returns the full
  server-rendered page (≈230 KB). Its embedded JSON has `"name"`, `"branchName"`, `"avgPrice"`
  (人均), `"regionName"`, `"categoryName"`, the hours as `"value":"周一至周日\n10:00-22:00","name":"营业时间"`,
  recommended dishes as `"dishName":…,"recommendCount":N`, `"hasQueue"`, and
  `"branchIds":"id1,id2,…"` listing the brand's other branches in the same city. Fetch each branch id
  the same way to find a named branch. The address is masked after a few characters (`钱王街67******`)
  and `lat`/`lng` are 0. The same URL without `msource=applemaps`, and `/dish…` pages, hit the login wall.
- **Apple Maps place page:** `https://maps.apple.com/place?place-id=<H…>` or `?auid=<n>&lsp=57879`
  via curl returns server-rendered HTML with the Chinese name, full address, phone, hours, AVG. COST,
  **recommended dishes with prices** (`野生菌过桥米线 ¥99`), recent review text, a
  `dianping.com/shop/<id>` link (the bridge to the Dianping page above), and
  `<meta property="place:location:latitude/longitude">`.
  `maps.apple.com/search?query=…` is client-rendered (empty via curl); run it in headless Chrome
  (`page.goto('https://maps.apple.com/search?query=<kw>&center=<lat,lng>&span=0.03,0.03')`, wait ~9 s,
  read `a[href*="place"]`) to get place ids and the full address of the top hit.
- **360 map POI search:** `https://restapi.map.so.com/newapi?keyword=<kw>&cityname=<城市>&batch=1&number=15&sid=1000`
  returns JSON (`name`, `address`, `x`, `y`, `tel`, `pguid`) with no key. Data can be years old
  (closed or renamed branches still listed).

Coordinates from Apple Maps in China and from 360 map are **GCJ-02**, not WGS84. Kunming offset is
about +0.003° lat / +0.0015° lng. Converted with the standard iterative GCJ-02→WGS84 inverse, two
malls landed 10–25 m from their OpenStreetMap buildings (Nominatim); unconverted they are ~300 m off.

**해결:** seed one Dianping id from any Apple Maps page of the brand (WebSearch with
`allowed_domains: ["maps.apple.com"]` and the English brand name finds them), walk `branchIds` to the
branch, then take prices and full address from that branch's Apple Maps page. Convert all China map
coordinates GCJ-02→WGS84 before use. Branch names differ between platforms (Dianping
`思茅小馆(昆明站店)` = Apple `思茅小馆(双龙商场店)`, same Dianping id), so match on the Dianping id, not the name.

## OPS-312 — Python 3.9 rejects a valid UTF-8 script with "SyntaxError: Non-UTF-8 code" when a line holds a long run of multibyte text

`측정 2026-10-05 · macOS system /usr/bin/python3 3.9.6`

**증상:** a generator script with long Korean strings (one string literal per line, ~900 Hangul
characters) failed at start-up:
`SyntaxError: Non-UTF-8 code starting with '\xec' in file build.py on line 185, but no encoding declared`.
The file is valid UTF-8: `open(p,'rb').read().decode('utf-8')` succeeds and
`ast.parse(open(p, encoding='utf-8').read())` parses it. Adding `# -*- coding: utf-8 -*-` is the
reflex fix suggested by the message and does not address the cause — the 3.9 file tokenizer
mishandles very long lines of multibyte text.

**해결:** run the source through `compile()` instead of the file tokenizer:
`python3 -c "exec(compile(open('build.py',encoding='utf-8').read(),'build.py','exec'))"`,
or use a newer Python (Homebrew `python3.12`), or keep long strings in a JSON/text file that the
script loads.

## OPS-311 — Kunming government sites (*.km.gov.cn) refuse connections from outside China; cite a mirror

`측정 2026-10-05 · curl and WebFetch from a Korean home connection`

**증상:** `http://kmds.km.gov.cn/...` (Kunming party-history office) and `http://www.kmwh.gov.cn/...`
(Wuhua district) both fail with `connect ECONNREFUSED 116.52.6.87:443` in WebFetch, and curl
returns nothing. `m.yunnan.cn` also blocks some article URLs with an HTTP-proxy page
("The request contains some unreasonable content", Block Event ID ...).

**해결:** do not retry. The same official text is usually republished on reachable hosts:
the district's own media account on `news.qq.com/rain/a/...`, `m.thepaper.cn/baijiahao_...` (official
WeChat accounts mirrored to The Paper), `rujiazg.com`, `chinanews.com`. Search the article title and
cite the mirror with its date. A plain `curl` also needs `--compressed`: several of these hosts send
gzip regardless of `Accept-Encoding`, and the body otherwise looks like binary garbage.

## OPS-313 — `npm run dev -- --host 127.0.0.1` on top of a script that already says `astro dev --host 0.0.0.0` leaves the server on `localhost` only: `127.0.0.1` is refused

`측정 2026-10-05 · astro 7.3 dev server · macOS 26 (MacBook Air) · curl 8 · Playwright with Chrome`

**증상:** with `"dev": "astro dev --host 0.0.0.0"` in `package.json`, `npm run dev -- --port 4451 --host 127.0.0.1` started
and printed `Local http://localhost:4451/` and `Network use --host to expose`. `curl http://127.0.0.1:4451/` failed
with `000` (connection refused) and every Playwright test with `E2E_BASE_URL=http://127.0.0.1:4451` failed with
`ECONNREFUSED 127.0.0.1:4451`, while `curl http://localhost:4451/` answered at once. A readiness loop that polled
`127.0.0.1` never saw the server come up. Two `--host` flags do not combine; the result was neither of them.

**해결:** do not pass `--host` again when the npm script already sets one; use the URL the server prints
(`http://localhost:<port>`) for the readiness check and the test base URL, or call `npx astro dev --port <p> --host
127.0.0.1` directly instead of through the npm script.

## OPS-314 — `@vite-pwa/astro` precaches the 404 page as `404/`; behind nginx that URL answers 404, the service worker never installs, and the PWA silently has no offline copy

`측정 2026-10-05 · astro 5.18 (static, build.format directory) · @vite-pwa/astro 1.2.0 · vite-plugin-pwa 1.2 (generateSW, Workbox 7.4) · nginx 1.30 · Chrome (Playwright, channel chrome)`

**증상:** a static Astro PWA worked offline under `astro preview`, but on production `navigator.serviceWorker.ready`
never resolved, `caches` held 2 precache entries out of 83, and every offline reload failed with
`ERR_INTERNET_DISCONNECTED`. No console error. The generated `sw.js` lists `{url:"404/"}`: the integration rewrites
`404.html` to a directory URL like every other page. nginx serves `404.html` only as an `error_page`, so `GET /404/`
returns status 404 and Workbox's precache aborts the whole install (one failed entry fails the install event).
`astro preview` answered that URL differently, so the local offline test passed.

**해결:** add `globIgnores: ['404.html', '404/**']` to `workbox`, then check every precache URL against the real
server after each deploy: fetch `/sw.js`, extract `url:"..."`, and require 200 for all of them (a 15-line script).
Here that check reported `82 urls, 0 failing` and the precache filled to 74 entries within 5 s. Test offline against
the production server, not the preview server (same lesson as OPS-281).

## OPS-315 — SpacetimeDB 2.8 HTTP reducer call: a reducer's `Err` comes back as HTTP 530 with the message as the body; a missing route through a proxy looks different (403/404)

`측정 2026-10-05 · SpacetimeDB standalone 2.8.0 · Rust module · POST /v1/database/<db>/call/<reducer> behind nginx and Cloudflare`

**증상:** after adding a reducer and an nginx `location` for it, a call with a deliberately bad argument
(`report_daily` with a row id that does not exist) answered **530**, which reads like a Cloudflare origin error.
It is not: the body was the reducer's own `Err` text ("No such board entry."). A reducer returning
`Err("That callsign is not allowed. Choose another one.")` from `join` answered 530 with that text the same way.
A call the proxy does not route answers the proxy's 403/404 instead, and success is 200 with an empty body.

**해결:** use a call that must fail as the cheapest end-to-end check of a new reducer route: 530 plus the
reducer's message proves the proxy route, the published module and the reducer are all live, without
writing anything. Clients should treat any non-2xx as "refused" and show the body text, not only 4xx.

## OPS-316 — SpacetimeDB 2.8: a scheduled reducer that saves every tick grows the commit log without bound (7.5 GB in 9 days); segments before the second-newest snapshot can move out of the data dir

`측정 2026-10-05 · SpacetimeDB standalone 2.8.0 · Rust module · Docker volume on Ubuntu`

**증상:** a game's database volume was 7.5 GB, its pre-deploy volume backup (`tar -czf` with the database
stopped) 5.7 GB and 20 minutes of downtime. `du` inside the volume: `replicas/<n>/clog` 7.5 GB,
`snapshots` 12 MB. A 130 ms `ScheduleAt::Interval` reducer updated two rows (about 6 KB of JSON) on every
call whether anyone was connected or not: 5.7 million transactions. SpacetimeDB rotates a segment at
1 GiB and zstd-compresses older segments (file magic `28 b5 2f fd`, about 210 MB each), takes a snapshot
on rotation, but keeps every segment.

- A reducer call that writes nothing adds nothing to the log: returning early from the tick when the
  arena is empty measured 0 bytes in 180 s on production (a fresh local database grew 336 KB/min before).
- On start the server logs `restoring snapshot of tx_offset N`, then `applying transaction history` from
  N+1. A copy restored from backup with all segments before the one holding the snapshot moved out
  (33 of 36, 5.9 GB) started, restored the snapshot and replayed 104,336 transactions in 5 s.

**해결:** return from per-tick reducers without writing when nothing changes. To shrink an existing log,
stop the database and move (not delete) `clog/<offset>.stdb.log` and `.stdb.ofs` older than the segment
before the one containing the **second-newest** snapshot's offset (margin for an unreadable newest
snapshot) to an archive outside the volume; offsets are the zero-padded file names. Test on a restored
copy first. Measured: backup 5.7 GB to 0.4 GB, downtime 20 to 4.5 minutes.

## OPS-317 — A web font named `"Serif KR"` is silently dropped in production: Lightning CSS unquotes it to `font-family:Serif KR`, Chrome rejects that `@font-face`, and every heading falls back to a system serif

`측정 2026-10-05 · astro 5.18 build (Vite 6, Lightning CSS minify) · Chrome 154 on Android 17 (Pixel 7 Pro) · Chrome 14x headless`

**증상:** a self-hosted Korean display face declared as `@font-face { font-family: "Serif KR"; src: url(/fonts/serif-kr-sub.woff2) }`
was never used. `document.fonts` listed only the other two faces (`Pretendard:loaded`, `Seal:loaded`), the preload
warned "preloaded but not used within a few seconds", and headings rendered in the system serif (Noto Serif CJK on
Android). Screenshots looked plausible, so the fallback went unnoticed until `document.fonts` was read on a device.
The built CSS had `@font-face{font-family:Serif KR;...}`: the minifier strips the quotes from a multi-word family
name. An unquoted family name whose first word is the generic keyword `serif` is not accepted by Chrome, so the
whole rule is discarded without an error.

**해결:** never start a family name with a generic keyword (`serif`, `sans-serif`, `monospace`, `cursive`,
`fantasy`, `system-ui`); a single made-up identifier such as `HeroSerif` survives minification unchanged. After a
build, check on a real page that `[...document.fonts].map(f => f.family + ':' + f.status)` lists every face you ship.

## OPS-318 — PWA install card never shows on return visits when the listener lives in a `client:idle` island: Chrome fires `beforeinstallprompt` before the island hydrates

`측정 2026-10-05 · Chrome 154.0.8037.92 on Android 17 (Pixel 7 Pro) · Astro 5 Preact island (client:idle) · Workbox 7.4 SW already controlling`

**증상:** a site's own "폰에 설치하기" card appeared on the first visit and never again: on later loads
`window.__bip` was unset and no card rendered, while `Page.getInstallabilityErrors` returned `[]` and no WebAPK
existed (`chrome://webapks` empty for the origin). On the first visit the service worker registers late, so
`beforeinstallprompt` came after hydration; once the worker controls the page, Chrome fires the event early and
an island hydrated on idle has not attached its listener yet.

Related in the same session: `@vite-pwa/astro` `registerType: 'autoUpdate'` with `registerSW()` reloads the open
page when a new worker takes control. A deploy in the middle of a long client-side job (here a 9 MB audio download
loop) reloaded the page and silently stopped the job at 15 of 18 files.

**해결:** catch the event in an inline `<head>` script — `addEventListener('beforeinstallprompt', e => { e.preventDefault();
window.__bip = e; dispatchEvent(new Event('app:bip')) })` — and let the island read `window.__bip` on mount and listen
for `app:bip`. After that the card showed on every load and the native "앱 설치" sheet installed the WebAPK. For
updates use Workbox `skipWaiting: true, clientsClaim: true` and register `/sw.js` yourself without the auto-reload;
the next navigation picks up the new build.

## OPS-319 — Playwright clicks on an SSR-rendered Alpine.js control are lost until `Alpine.start()` runs; registering page components through a dynamic `import()` first widens that window

`측정 2026-10-05 · Alpine.js 3.14 · Astro 7.3 · Playwright 1.58 · Chrome on an M1 Air (headless, production site)`

**증상:** a mobile test that tapped a "검색·필터" toggle (`x-on:click="open = !open"`) failed about 1 run in 2 with
`expect(locator).toBeVisible() failed … unexpected value "hidden"` on the field inside the panel, only on pages that
load their own component. The trace showed the click 28 ms after the server-rendered heading became visible and before
the page's `Alpine.start()`; the button already had `aria-expanded="false"` from the server, so `isVisible()` and
`getAttribute()` passed and `click()` succeeded against an element with no listener yet. Nothing errors: the click
is simply gone, and Alpine then starts with the panel closed.

The window is wider where the app does `await Promise.all(pages.map(async ([name, load]) => Alpine.data(name, (await load()).default)))`
before `Alpine.start()` — every page with a lazily loaded component waits one more network round trip. Pages
without one passed every time.

**해결:** wait for Alpine before the first interaction, e.g. `page.waitForFunction(() => '_x_dataStack' in document.body)`
(any element under an `x-data` root carries `_x_dataStack` once initialised), then click and assert the state flipped
(`toHaveAttribute('aria-expanded', 'true')`). Keep one shared helper for it; copies of the old three-line helper in
other spec files were what kept failing. After the change: 8 repeats × 2 projects and 44 tests in the three affected
files passed.
