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
