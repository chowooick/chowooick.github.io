# Nakama 자체 호스팅 — 실측 사실

ID 접두사 `NKM`. ID는 불변이다. 사실이 무효가 되어도 ID를 재사용하지 않는다.

---

## NKM-001 — Go 플러그인 버전 불일치는 오류 없이 실패한다

`측정 2026-09-06 · Nakama 3.40.0 · Go 런타임 플러그인`

**증상:** 기동 로그에 `Go runtime modules loaded`가 찍히지만 등록된 RPC가 0개다.
이후 모든 RPC 호출이 HTTP 404. 에러 로그는 없다.

플러그인의 Go 버전이나 `nakama-common` 버전이 서버 이미지와 다르면 Nakama는 로드를
포기하고 조용히 넘어간다.

**유일한 단서:** 기동 로그의 RPC 등록 개수.
**해결:** `heroiclabs/nakama-pluginbuilder:<서버와 동일 태그>` 컨테이너에서만 빌드한다.
로컬 Go 툴체인으로 만든 `.so`는 쓰지 않는다.

---

## NKM-002 — nakama-common은 서버와 버전 체계가 다르다

`측정 2026-09-06 · Nakama 3.40.0`

서버는 `3.x`, `nakama-common`은 `1.x` 라인이다. "서버와 같은 마이너 버전"이라는 규칙은
성립하지 않는다.

**정답:** 서버 리포의 `go.mod`가 고정한 값. Nakama v3.40.0 → **nakama-common v1.47.0**.

---

## NKM-003 — pluginbuilder 이미지의 entrypoint는 셸이 아니라 `go`다

`측정 2026-09-06 · heroiclabs/nakama-pluginbuilder:3.40.0`

**증상:** 셸 명령이 `go`의 인자로 전달되어 즉시 실패한다.

```
docker run … pluginbuilder sh -ec '…'          # go sh -ec '…' 로 전달됨
docker run --entrypoint sh … pluginbuilder -ec '…'   # 정상
```

---

## NKM-004 — 스트림 subject·subcontext는 UUID만 받는다

`측정 2026-09-06 · Nakama 3.40.0`

`StreamUserJoin(mode, subject, subcontext, label, …)`에서 `subject`와 `subcontext`는
`uuid.FromString`으로 파싱된다. `"colony-01"` 같은 임의 문자열은 거부된다.

**해결:** 임의 문자열 키는 **label**에 넣는다. 스트림 키는
`mode + subject + subcontext + label` 전체이므로 격리 강도는 동일하다.

---

## NKM-005 — presence의 status는 클라이언트에 전달되지 않는다

`측정 2026-09-06 · Nakama 3.40.0`

**증상:** 커스텀 mode의 join 이벤트에 `status` 키가 아예 없다.
같은 소켓의 내장 `status_presence_event`에는 `"status":""`가 실린다.

`StreamUserJoin`에 넘긴 status는 서버에 저장되고 `StreamUserList`로 읽힌다.
그러나 와이어에는 실리지 않는다. `server/tracker.go:928`(join)·`:971`(leave):

```go
pWire := &rtapi.UserPresence{UserId, SessionId, Username, Persistence}
if p.Stream.Mode == StreamModeStatus {
    pWire.Status = …
}
```

원문 주석: *"Status field is only populated for status stream presences."*

**presence 이벤트로 받을 수 있는 필드:** `user_id` `session_id` `username` `persistence`.
표시 이름이 필요하면 `user_id`로 users API(`/v2/user?ids=`)를 조회한다.

함께 걸림: NKM-006

---

## NKM-006 — 스트림에 새로 들어온 소켓은 기존 재실자를 모른다

`측정 2026-09-06 · Nakama 3.40.0`

**증상:** A가 먼저 입장하고 B가 나중에 입장하면, A는 B의 join 이벤트를 받지만
B는 A의 존재를 영원히 통보받지 못한다. B가 받는 것은 자기 자신의 join 이벤트뿐이다.

**해결:** 명단이 필요하면 join RPC 응답에 직접 담는다. 서버가 밀어주지 않는다.

함께 걸림: NKM-005

---

## NKM-007 — 소켓으로 온 오류는 코드가 붕괴한다

`측정 2026-09-06 · Nakama 3.40.0`

**증상:** HTTP로는 `3 INVALID_ARGUMENT`가 오는 같은 요청이, WebSocket rpc 엔벨로프로는
`7 RUNTIME_FUNCTION_EXCEPTION`으로 온다. message 문자열만 보존된다.

Nakama가 rtapi 응답에서 모든 런타임 오류를 `7`로 바꾼다.

**해결:** 클라이언트는 `code`가 아니라 **message 식별자**로 분기한다.
message를 snake_case 식별자(`channel_full`, `insufficient_stock`)로 정하고 계약에 포함시킨다.

---

## NKM-008 — HTTP RPC에는 세션 id가 없다

`측정 2026-09-06 · Nakama 3.40.0`

`RUNTIME_CTX_SESSION_ID`는 소켓으로 온 호출에만 채워진다.

**활용:** 갱신 RPC에 소켓 연결을 구조적으로 강제할 수 있다. 규칙이 아니라 구조라
우회 불가능하다.
**한계:** "소켓 연결 후 HTTP로 호출"은 서버가 어느 소켓인지 알 수 없다.

---

## NKM-009 — RegisterEventSessionEnd 훅보다 presence 정리가 먼저다

`측정 2026-09-06 · Nakama 3.40.0`

Nakama가 죽은 세션의 스트림 presence를 전부 걷은 뒤에 훅이 실행된다.
훅 본문이 비어 있어도 "소켓 강제 종료 → 2초 내 카운트 감소" 테스트가 통과한다.

**하지 말 것:** 훅에 presence 삭제 코드를 넣는 것.

---

## NKM-010 — 기본 세션 토큰 수명은 60초다

`측정 2026-09-06 · Nakama 3.40.0`

**증상:** 60초 카운트다운 화면에서 사용자가 제출하는 순간
`Auth token invalid (http 401)`.

개발 중에는 보이지 않는다. 60초짜리 UI를 만들 때 정확히 터진다.

**해결:** `session.token_expiry_sec`를 올리거나, 잔여 수명이 임계값 미만이면 재인증한다.
임계값은 설정으로 뺀다.

---

## NKM-011 — `string_to_array('', ',')::uuid[]`는 Postgres 오류다

`측정 2026-09-06 · PostgreSQL 16.8`

**증상:** `invalid input syntax for type uuid: ""`

빈 배열이 아니라 에러다. 플러그인에 배열 드라이버가 없어 id를 콤마로 이어 붙여
`ANY(...)` 필터를 만들면 반드시 만난다.

**해결:** 빈 집합이면 쿼리 전에 단락시킨다.

---

## NKM-012 — 스트림 인원 상한은 원자적으로 지킬 수 없다

`측정 2026-09-06 · Nakama 3.40.0`

Nakama에 스트림 상한 API가 없다. `StreamUserList`로 세고 `StreamUserJoin`하는
2단계이므로 동시 요청이 상한을 1~2명 초과할 수 있다.

**엄격히 막으려면:** presence를 Postgres 테이블로 잡아야 한다. 프레임워크 API로는 불가능하다.

## NKM-013 — 스트림 가입은 소켓 RPC 처리 중에만 된다. HTTP만 부르는 재접속 클라이언트는 스트림 밖이다

`측정 2026-09-07 · Nakama 3.40 · Go 런타임 · nakama-godot 7549fea8`

**증상:** 서버가 파티 멤버를 커스텀 스트림(mode 101)에 `StreamUserJoin`으로 태운다.
이 호출에는 세션 id가 필요하고, 세션 id는 소켓으로 온 RPC에만 있다(NKM-008). 클라이언트
시트가 파티 조회를 HTTP RPC로만 불렀더니 재접속한 멤버가 스트림 이벤트를 하나도 받지
못했다 — 오류 없이 조용히 빠져 있다. 스모크를 14번 돌려서야 잡혔다.

**해결:** 서버가 관리하는 스트림 소속은 "재접속" 경로에서 서버가 다시 붙여야 한다 —
채널 입장 같은 소켓 RPC 처리 시 소속 스트림을 조회해 `StreamUserJoin`을 다시 부른다.
클라이언트 쪽 우회는 소켓으로 RPC를 한 번 더 부르는 것이지만, 그 호출의 목적이 답이
아니라 부수 효과라는 점을 스모크가 검사해야 한다(`[party] stream on` 로그).

## NKM-014 — presence로 "온라인"을 판정하는 지연 스윕은 재접속이 무력화한다. 스트림 재가입과 정산을 같은 경로에 두면 안 된다

`측정 2026-09-07 · Nakama 3.40 · Go 런타임 · PostgreSQL`

**증상:** NKM-013의 해결책(채널 입장 RPC에서 소속 스트림을 서버가 다시 붙인다)을 넣고,
"오래 자리를 비운 멤버는 다음 RPC에서 제거된다"는 지연 스윕이 그 재가입에 뚫리지 않는지
검사하려 했다. 스윕은 타이머 없이 `presence 유무 = 온라인`으로 판정하고, 온라인인 멤버의
`last_seen_at`을 검사 직전에 갱신한다. 그래서 `last_seen_at`을 −2h로 조작해도 재접속한
멤버는 **절대** 제거되지 않는다 — 재가입이 좌석(presence)을 돌려주는 순간 스윕이 그
멤버를 되살리기 때문이다. 스윕이 깨졌는지 여부와 무관하게 테스트가 항상 통과한다.

**해결:** 두 가지가 갈린다. (1) 재가입 코드는 정산을 부르지 않는다 — presence만 붙이고
행 상태는 건드리지 않아야, 늦게 온 멤버가 다음 정산에서 정상적으로 제거되고 그 이벤트를
본인이 스트림으로 받은 뒤 presence에서 빠진다. (2) 이 경로를 검사하려면 **presence는
반환하고 스트림 presence는 유지하는 상태**를 만들어야 한다 — 소켓을 끊지 말고 채널
퇴장 RPC로 좌석만 반납한다(소켓을 죽이면 스트림 presence도 같이 사라져 제거 이벤트를
관측할 수 없다). `last_seen_at` 조작 → 재입장 → 좌석만 반납 → 상대가 RPC 1회 →
`member_left(reason=offline)`이 본인에게 도달하고 그 뒤 수신 0. 이 순서가 아니면
"유령을 되살리지 않는다"는 명제는 검증 불가다.

## NKM-015 — UNIQUE 제약을 부분 유니크 인덱스로 바꾸면 기존 `ON CONFLICT (col)`이 전부 42P10으로 죽는다. 배경 틱은 경고 한 줄만 남기고 조용히 멈춘다

`측정 2026-09-07 · PostgreSQL 16 · Nakama 3.40 Go 런타임`

**증상:** 마이그레이션이 `ALTER TABLE characters DROP CONSTRAINT characters_user_id_key`로
컬럼 UNIQUE를 떼고 `CREATE UNIQUE INDEX ... ON characters (user_id) WHERE died_at IS NULL
OR revived_at IS NOT NULL`(부분 인덱스)로 바꿨다. 그 컬럼에 `ON CONFLICT (user_id) DO
NOTHING`을 쓰던 기존 INSERT가 전부 실패한다:

```
ERROR: there is no unique or exclusion constraint matching the ON CONFLICT specification (SQLSTATE 42P10)
```

부분 인덱스는 술어를 같이 주지 않으면 conflict 대상으로 **추론되지 않는다**. 마이그레이션은
성공하고, 컴파일도 되고, 그 INSERT를 부르지 않는 테스트는 전부 통과한다. 이 서버에서는
1분마다 도는 배경 틱이 그 INSERT를 부르고 있었고, 틱은 오류를 삼켜
`warn: tick failed: storage_error` 한 줄만 남긴다 — 기능(상시 매수자)이 커밋 시점부터
전역에서 죽어 있었는데 아무도 몰랐고, 무관한 티켓의 스모크 1단계에서야 드러났다.

**해결:** 부분 유니크 인덱스를 만들면 그 컬럼을 conflict 대상으로 쓰는 모든 INSERT에
**술어를 글자 단위로 같게** 붙인다 — `ON CONFLICT (user_id) WHERE died_at IS NULL OR
revived_at IS NOT NULL DO NOTHING`. 제약을 떼는 마이그레이션을 쓸 때는 같은 저장 단위로
`grep -rn "ON CONFLICT (<컬럼>" `를 돌려 호출부를 전부 훑는다. 그리고 배경 루프가 오류를
warn으로만 남긴다면 그 로그를 스모크가 `grep -c 42P10` 같은 형태로 직접 검사해야 한다 —
조용히 죽는 루프는 테스트가 화면으로 볼 수 없다.

## NKM-016 — 멱등 래퍼 **앞**의 상태 검사는 같은 키 재시도를 다른 응답으로 만든다. 순차 재시도 테스트로는 절대 안 잡힌다

`측정 2026-09-07 · PostgreSQL 16 · Nakama 3.40 Go 런타임`

**증상:** RPC가 `Idempotent(키, 콜백)` 앞에서 사전 조건을 검사했다 — "죽은 캐릭터만 부활할
수 있다". 같은 키로 5건을 동시에 쏘면 2건은 200(하나는 키 주인, 하나는 저장 응답), 3건은
`9 not_dead`가 나온다. 첫 요청이 부활을 커밋한 뒤 도착한 나머지가 **키 저장소를 보기 전에**
살아 있는 캐릭터를 읽고 튕기기 때문이다. 계약은 "같은 키 재요청은 바이트 동일한 응답"인데
같은 키가 세 가지 답을 낸다.

위험한 검사는 **그 호출이 성공하면서 스스로 바꾸는 상태**를 보는 것이다. 같은 모양이
`order_not_found`(취소가 주문을 닫는다) · `invite_not_found`(수락이 초대를 소비한다) ·
`member_not_found`(추방이 멤버를 지운다) · `mission_not_found`(수령이 권리를 소비한다) ·
`entry_not_found`(회수가 큐 항목을 지운다)에 그대로 있다. 반대로 `unknown_item` 같은 정적
검증은 안전하다 — 요청이 바꾸지 않는 것을 보기 때문이다.

**해결:** 그런 검사는 멱등 콜백 **안**으로 옮긴다. 키가 이미 있으면 콜백 자체가 돌지 않으므로
저장 응답이 먼저 나가고, 새 키일 때만 검사가 돈다(거절하면 트랜잭션이 롤백되어 키 점유도
같이 사라진다 — 오타로 복귀권을 태우지 않는다). 검사를 **지우고** 락 안쪽 코어에 맡기면
오류 식별자가 바뀔 수 있으니(여기서는 `not_dead`가 `already_returned`로) 옮기지 지우지 않는다.

테스트는 두 가지를 유의한다. (1) 순차 재시도는 통과한다 — 재현에는 같은 키 동시 N건이
필요하고, 이 결함은 스모크의 경합 검사에서만 드러났다. (2) 멱등 래퍼가 `*sql.DB`를 직접
받으면 유닛에서 "키가 이미 있는 상태"를 만들 수 없다. 래퍼를 함수 타입으로 주입받게 바꿔야
유닛이 성립하고, 그 유닛은 수정 전 코드에서 실제로 FAIL하는지 반드시 확인한다.

## NKM-017 — Nakama가 postgres 커넥션을 다 먹으면 락 대기 0인데 지연만 4배가 된다

`측정 2026-09-07 · Nakama 3.40.0 · postgres 16.8-alpine`

**증상:** 동시접속 300에서 DB를 지나는 RPC의 p95가 4배(13→56ms), p99는 348ms로 튄다. 그런데
`pg_locks`에는 미승인 락이 **0건**이고 `pg_stat_activity`의 대기 이벤트도 비어 있다. 동시접속
30·100에서는 같은 코드가 13·14ms로 멀쩡하다 — 부하에 비례해 나빠지는 것이 아니라 어느
지점에서 갑자기 무너진다.

부하 중 `psql`로 스냅샷을 뜨려 하면 여기서 정체가 드러난다:

```
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed:
FATAL:  sorry, too many clients already
```

`postgres:16-alpine`의 기본값은 `max_connections=100`,
`superuser_reserved_connections=3`이다. Nakama의 커넥션 풀이 그 100을 다 쥐면 예약 3슬롯도
남지 않아 **슈퍼유저로 붙는 psql조차 거부된다.** 그 뒤 애플리케이션 요청은 Go
`database/sql`이 빈 커넥션을 내줄 때까지 기다리는데, 이 대기는 postgres 안에서 일어나지
않으므로 `pg_locks`·`pg_stat_activity`·`pg_stat_statements` 어디에도 안 나온다. 세 뷰를 다
봐도 "DB는 한가한데 느리다"로 보인다.

꼬리가 먼저 무너지는 것도 이 모양의 특징이다. 큐잉은 평균보다 p99를 먼저 망가뜨린다.

**해결:** 락과 쿼리를 의심하기 전에 커넥션 수를 센다. `SELECT count(*) FROM pg_stat_activity`를
부하 중에 찍어 `max_connections`에 붙는지 보고, 붙으면 `--database.max_open_conns`(Nakama)와
`max_connections`(postgres)를 같이 맞춘다. 진단용 psql이 붙지 못하는 상황 자체가 증거이므로,
부하 측정 스크립트는 스냅샷 실패를 조용히 삼키지 말고 그대로 남겨야 한다.

## NKM-018 — pg_stat_statements의 mean_exec_time은 플래닝을 빼고 센다

`측정 2026-09-07 · postgres 16.8 · Nakama 3.40.0`

**증상:** `pg_stat_statements` 상위 쿼리를 다 더해도 RPC 지연이 설명되지 않는다. RPC 한 번이
문장 15개를 내고 표에 찍힌 `mean_exec_time` 합이 0.60ms인데, 클라이언트가 재는 왕복은 4.4ms다.
"DB가 아니라 앱이 느리다"는 결론으로 새기 쉽다.

`track_planning`은 기본이 `off`이고, 꺼져 있으면 `mean_plan_time`은 0으로 보인다. 켜고 다시
재면 같은 15문장의 플래닝 합이 0.77ms로, **실행 시간(0.60ms)보다 크다.** Nakama는 런타임
모듈이 내는 문장을 준비된 구문으로 재사용하지 않으므로 매번 파싱·플래닝한다. `EXPLAIN
ANALYZE` 한 줄에서도 같은 비율이 보인다 — 단순 인덱스 조회 하나가 Planning 0.354ms /
Execution 0.045ms다.

**해결:** 문장 단위 비용을 논거로 쓸 때는 `-c pg_stat_statements.track_planning=on`으로 재고,
`total_plan_time + total_exec_time`으로 정렬한다. 오버헤드가 있으니 상시로 켜 두지는 않는다.
따라오는 결론이 뒤집힌다: 비용이 플래닝에 있으면 레버는 쿼리 최적화가 아니라 **문장 개수**다.
같은 행을 세 문장으로 나눠 묻던 것을 조인 하나로 합치는 편이, 그 세 문장을 각각 빠르게 만드는
것보다 크게 듣는다.

## NKM-019 — Nakama 커넥션 풀은 래칫이다: 기본값이 postgres 슬롯을 전부 먹을 수 있다

`측정 2026-09-07 · Nakama 3.40.0 · postgres 16.8-alpine`

**증상:** 부하가 끝난 뒤에도 postgres 접속이 거부된다(`FATAL: sorry, too many clients
already`). `pg_stat_activity`를 보면 수십~백 개의 백엔드가 전부 `idle`(ClientRead)이고
`active`는 0~1개다. 일하는 커넥션이 하나인데 슬롯은 다 찼다.

기본값 세 개가 겹쳐서 그렇다.

```
nakama  --database.max_open_conns      기본 100
nakama  --database.max_idle_conns      기본 100
nakama  --database.conn_max_lifetime_ms 기본 3600000 (1시간)
postgres max_connections               기본 100
postgres superuser_reserved_connections 기본 3
```

Go `database/sql`은 요청이 왔을 때 놀고 있는 커넥션이 없으면 1ms를 기다리는 대신 새로 연다.
`max_idle_conns`가 상한과 같으면 그렇게 열린 커넥션은 반납되지 않고, 수명이 1시간이라
버스트를 만날 때마다 풀이 한 칸씩 **올라가기만 한다**. 그래서 풀 크기는 동시 작업량이 아니라
그동안 만난 최악의 버스트를 기록한다.

그리고 nakama 상한(100)이 postgres 상한(100)과 **같다.** 풀 혼자 모든 슬롯을 가져갈 수 있고,
그러면 슈퍼유저 예약 3슬롯까지 남지 않아 `psql -U postgres`조차 거부된다 — 즉 장애 조사를
하려는 순간에 조사 수단이 사라진다.

측정값(동시접속 100·200, 격자 동일): 풀 점유는 15와 20이고 활성 백엔드는 어느 쪽도 최고 1개다.
천장을 350으로 열어 놓고 재도 20에서 멈추므로 20은 눌린 값이 아니라 수요다. **풀 상한을 5로
낮춰도 지연이 그대로였다**(tick p95 7.2 → 7.6ms) — 커넥션 수는 이 규모에서 지연의 원인이
아니다.

**해결:** `max_connections`를 nakama 상한보다 **위로** 두는 것이 먼저다
(`풀 상한 + nakama 내부 + psql 여유 + superuser_reserved`). 그리고 `max_idle_conns`를 상한보다
낮게 잡아 래칫을 푼다 — 실측 점유 근처가 적당하다. 상한 자체는 활성 백엔드 수로 정한다.
활성이 1인데 100을 열어 둘 이유는 없고, 열어 두면 CPU가 마른 순간 그 100을 다 여는 것이
바로 위 증상이다.

**주의:** 커넥션 수를 지연의 원인으로 단정하기 전에 풀을 **수요보다 작게** 조여 재현되는지
본다. 수요가 15인데 30으로 낮춰 보면 아무것도 안 나오고, 안 나온 것을 "고쳤다"로 읽게 된다.

## NKM-020 — 멱등 키 재시도 결함은 "같은 키 동시 N건"으로 안 잡힌다 — 첫 커밋 뒤 도착하는 순차 재요청이라야 잡는다

`측정 2026-09-07 · Nakama 3.40 · PostgreSQL 16`

**증상:** 멱등 래퍼(`Idempotent`) **앞**에서 "소비되는 상태"를 검사하는 결함
(NKM-016)을 회귀에서 잡으려고, 같은 키로 10건을 동시에 쏘는 기존 헬퍼
(`race_same_key`)로 케이스를 만들었다. 결함을 일부러 되살린 뒤 돌렸는데
**10건 전부 200 바이트 동일로 통과**했다 — 잡지 못했다.

이유는 타이밍이다. 10건이 진짜 동시에 출발하면 10건 모두가 선행 검사를
**첫 요청이 커밋하기 전에** 읽는다(로컬 스택에서 재현률 100%). 그래서
전부 검사를 통과하고 멱등 계층에서 정상 직렬화된다. 결함이 드러나는 조건은
"상태가 이미 소비된 뒤에 같은 키가 도착하는 것"인데, 동시 발사는 그 조건을
만들지 않는다. 실제로 이 결함이 물어뜯는 것은 **모바일 재시도**다 —
응답을 못 받은 클라가 몇 초 뒤 같은 키로 다시 보내는 것.

같은 실측에서, 다른 RPC(`craft.claim`)는 동시 발사로도 잡혔다. 커밋 시점과
선행 검사 시점의 간격이 RPC마다 달라서, 동시 발사는 **RPC에 따라 되기도 하고
안 되기도 하는** 검출기다. 회귀로 쓰기엔 그 자체가 결함이다.

**해결:** 동시 버스트 뒤에 **같은 키로 순차 재요청 1건**을 붙이고, 그 응답이
첫 응답과 바이트 동일한지 본다. 버스트는 "부수 효과 1회"를, 순차 재요청은
"저장 응답 재생"을 검증한다 — 둘은 다른 성질이고 둘 다 필요하다.
```
race_same_key <rpc> <payload> 10 <token>   # 부수 효과 1회
<같은 키로 1건 더>                          # 저장 응답 바이트 동일 (결정적)
```
버스트가 쓰는 소켓은 보통 헬퍼가 따로 여는 것이므로, 순차 재요청에는 소켓이
필요한 RPC라면 소켓을 다시 열어 줘야 한다.

## NKM-021 — Nakama 3.40에 Steam 결제 검증은 없다 — IAP 스토어는 5개뿐이고 Steam은 인증 전용이다

`측정 2026-09-08 · Nakama 3.40.0+d4d92f9 · nakama-common v1.47.0`

**증상:** Steam 출시를 계획하며 "Nakama가 IAP를 내장 검증한다"는 문장을 근거로
Steam 결제도 런타임이 처리한다고 전제했다. 실제로는 없다.

`runtime/config.go`의 `IAPConfig`가 노출하는 스토어는 **Apple · Google · Huawei ·
FacebookInstant · Samsung 5개뿐**이다. 실행 중인 서버의 플래그도 같다:

```
$ docker exec <nakama> /nakama/nakama --help | grep -i "iap\|steam"
-iap.apple.shared_password / -iap.google.client_email / -iap.huawei.* / -iap.samsung.*
-social.steam.app_id          Steam App ID.
-social.steam.publisher_key   Steam Publisher Key value.
```

`-iap.steam.*`는 존재하지 않는다. Steam 관련 런타임 심볼은
`AuthenticateSteam` · `LinkSteam` · `UnlinkSteam` · `ImportSteamFriends`로
**전부 인증·소셜**이고 결제는 하나도 없다.

**해결:** Steam 결제는 Go 런타임에서 Steamworks Web API를 직접 호출해 구현한다.
검증 결과를 Nakama 내부 `purchase`/`subscription` 테이블에 넣을 방법도 없으므로
(내부 테이블은 수정 금지) 자체 테이블을 쓴다. Steam은 자동 갱신 구독 상품도
지원하지 않아 기간제 아이템 반복 구매로 대체하게 된다.

## NKM-022 — 구독 통지는 스토어별로 분기할 필요가 없다 — 런타임이 5값으로 정규화해 준다

`측정 2026-09-08 · nakama-common v1.47.0`

**증상:** Apple App Store Server Notifications V2와 Google RTDN은 통지 종류가
전혀 다르다(Google은 `GoogleSubscriptionNotificationType` 14값, Apple은
`AppleSubscriptionStatus` 5값 + `AppleExpirationIntent`). 게임 코드가 양쪽을
따로 다뤄야 한다고 보고 분기 설계를 시작하게 된다.

`RegisterSubscriptionNotificationApple` / `...Google`(runtime.go:379·385)의 콜백은
**둘 다 같은 `runtime.NotificationType`을 첫 인자로 받는다**(runtime.go:1856):

```go
IAPNotificationSubscribed = 1   IAPNotificationRenewed  = 2
IAPNotificationExpired    = 3   IAPNotificationCancelled = 4
IAPNotificationRefunded   = 5
```

원본 스토어 페이로드는 마지막 인자(`*AppleNotificationData` /
`*SubscriptionV2GoogleResponse`)로 따로 온다.

**해결:** 혜택 on/off 로직은 5값만 다루고 두 훅이 같은 함수를 부르게 한다.
스토어별 페이로드는 감사 로그로만 남긴다. 단, 이 정규화는 Apple·Google에만
적용된다 — Steam은 통지 자체가 없어(NKM-021) 만료를 서버 시계로 판정해야 한다.

## NKM-023 — `ValidatedSubscription.RefundTime`은 환불이 없어도 에포크로 채워져 온다

`측정 2026-09-08 · Nakama 3.40.0+d4d92f9 · nakama-common v1.47.0`

**증상:** 환불된 적 없는 구독을 `refund_time != nil`로 판정하면 전부 환불로
분류된다. `api.ValidatedSubscription`의 `RefundTime`은 `*timestamppb.Timestamp`
인데, 환불이 없는 구독에서도 nil이 아니라 **에포크(1970-01-01)** 를 담고 온다.
Nakama 내부 `subscription` 테이블의 `refund_time` 컬럼이 `DEFAULT epoch`이고
그 값이 그대로 실려 나온다.

두 번 속는다. 설정되지 않은 protobuf 타임스탬프 필드는 **타입 있는 nil**이라
인터페이스로 받으면 `== nil`이 false고, 그 위에서 `AsTime()`을 부르면 에러가
아니라 에포크를 돌려준다. 그래서 `if ts == nil` 검사와 `AsTime()` 결과 검사가
둘 다 통과하고, 만료 시각이 1970으로 기록된다.

```go
// 안 됨 — 환불이 없는 구독도 전부 환불로 잡힌다
if v.RefundTime != nil { status = refunded }

// 됨 — 에포크를 "설정되지 않음"으로 접는다
func tsOrZero(ts interface{ AsTime() time.Time }) time.Time {
    if ts == nil { return time.Time{} }
    t := ts.AsTime().UTC()
    if !t.After(time.Unix(0, 0).UTC()) { return time.Time{} }
    return t
}
```

**해결:** protobuf 타임스탬프를 Go 시각으로 바꾸는 함수 **한 개**를 두고 거기서
에포크를 제로 타임으로 접는다. 호출부는 `IsZero()`만 묻는다 — 에포크 비교를
네 곳에 흩어 두면 언젠가 한 곳을 빠뜨린다. `ExpiryTime`도 같은 함정이고, 이쪽은
에포크 만료가 곧 만료된 구독이라 결과가 우연히 맞아 더 늦게 발견된다.

## NKM-024 — Go 플러그인은 호스트 바이너리와 겹치는 모든 패키지 버전이 정확히 같아야 로드된다 — `livekit/server-sdk-go`는 그래서 못 쓴다

`측정 2026-09-12 · Nakama 3.40.0 · nakama-common v1.47.0 · pluginbuilder 3.40.0 (Go 1.26.5)`

**증상:** `heroiclabs/nakama-pluginbuilder`로 빌드는 되는데 런타임이 `plugin.Open`에서
`plugin was built with a different version of package github.com/klauspost/compress/...`로
즉시 fatal. 빌드 성공이 로드 성공을 뜻하지 않는다. `docker compose build`가 초록이어도
`up` 뒤 로그를 봐야 안다.

Go의 `plugin` 패키지는 호스트 바이너리와 플러그인이 **공유하는 모든 패키지**의 버전·빌드 플래그가
정확히 일치할 것을 요구한다. `nakama:3.40.0` 바이너리는 `google.golang.org/protobuf`, `grpc`,
`klauspost/compress`, `prometheus/*`, `felixge/httpsnoop`, `google.golang.org/genproto/googleapis/*`를
내장하고 있어서, 플러그인이 이 중 하나라도 다른 버전을 끌고 오면 로드가 거부된다.

`livekit/server-sdk-go`는 `pion/webrtc`·`redis`·`prometheus`·`otel` 전체 트리를 가져오고,
그 안의 `klauspost/compress` 버전이 Nakama 내장본과 달라 충돌했다. 어느 버전이든 맞추려면
webrtc 트리 전체를 Nakama에 맞춰 내려야 해서 현실적이지 않다.

**해결:**
1. `server-sdk-go`를 버리고 `github.com/livekit/protocol/livekit`가 이미 내보내는 twirp JSON
   클라이언트(`NewRoomServiceJSONClient`, `NewAgentDispatchServiceJSONClient`)를 직접 쓴다.
   인증은 `twirp.WithHTTPRequestHeaders`로 매 호출에 room-scoped `roomAdmin` JWT를 얹는다.
   의존성은 `livekit/protocol` + `twitchtv/twirp` 둘뿐이라 webrtc 트리가 통째로 사라진다.
2. 그래도 겹치는 7개 패키지는 호스트 바이너리에서 정확한 버전을 읽어 `go.mod`에 고정한다:
   ```sh
   docker create --name n heroiclabs/nakama:3.40.0
   docker cp n:/nakama/nakama ./nakama-bin && docker rm n
   go version -m ./nakama-bin | grep -E 'protobuf|grpc|klauspost|prometheus|httpsnoop|genproto'
   ```
   나온 버전을 `require`에 그대로 적는다. `go mod tidy`가 올리려 하면 `replace`나 명시 `require`로 잡아둔다.
3. 검증은 로그로: `docker compose up -d` 뒤 `Registered Go runtime RPC function invocation`이
   RPC 수만큼 찍히고 `Startup done`이 나와야 로드된 것이다.

**주의:** 이 버전 고정은 Nakama 또는 nakama-common을 올릴 때마다 다시 해야 한다.
`pluginbuilder` 태그와 `nakama` 태그를 같게 맞추는 것(NKM 기본 규칙)만으로는 부족하다 —
그건 Go 툴체인을 맞추는 것이고, 이건 **간접 의존성**을 맞추는 문제다.

## NKM-025 — 권위 매치 id는 `<uuid>.<node>`다 — `StreamUserList`에 통째로 주면 파싱 오류, uuid만 주면 label 불일치로 **빈 결과**가 조용히 나온다

`측정 2026-09-12 · Nakama 3.40.0 · nakama-common v1.47.0`

**증상:** `livekit_token` RPC가 "호출자가 매치 참가자인가"를
`nk.StreamUserList(streamModeMatchAuthoritative /*6*/, matchID, "", "", true, true)`로 검사했는데
참가자에게도 항상 거부. 권위 매치 없이 짠 T-004 단계에서는 모킹 테스트만 통과했고, 실제 `MatchCreate`가
생긴 뒤에야 드러났다.

`MatchCreate`가 돌려주는 match_id는 `f0e1…-….<nodename>` 형태다. Nakama는 이 스트림을
**subject = uuid 부분, label = node 이름**으로 등록한다(tracker의 `PresenceStream{Mode: 6, Subject: uuid, Label: node}`).
그래서 두 가지가 다 틀린다:
- match_id를 통째로 subject에 넣으면 `uuid.FromString` 실패(NKM-004).
- `.`을 잘라 uuid만 넣고 label을 `""`로 두면 파싱은 되지만 label이 달라 presence가 전부 걸러진다.
  에러가 아니라 **빈 목록**이라, "참가자 없음"으로 읽힌다.

**해결:**
```go
func splitMatchID(matchID string) (subject, label string) {
    if i := strings.IndexByte(matchID, '.'); i >= 0 {
        return matchID[:i], matchID[i+1:]
    }
    return matchID, ""
}
subject, label := splitMatchID(matchID)
presences, err := nk.StreamUserList(6, subject, "", label, true, true)
```
테스트는 반드시 `"uuid.node"` 입력 케이스를 넣는다. uuid만 넣는 케이스는 통과해도 실전에서 죽는다.
`streamModeMatchAuthoritative = 6`은 nakama-common이 내보내지 않는 값이라 서버 소스(`server/tracker.go` iota)
기준으로 버전에 고정한다.

## NKM-026 — "http_key 전용 RPC"를 `RUNTIME_CTX_SESSION_ID` 부재로 판정하면 세션 토큰으로 HTTP 직접 호출한 클라이언트가 통과한다 — `RUNTIME_CTX_USER_ID` 부재로 판정한다

`측정 2026-09-12 · Nakama 3.40.0 · nakama-common v1.47.0`

**증상:** GM 워커 전용(서버 간) RPC를 "세션 id가 없으면 서버 호출"로 판정했다(NKM-008: HTTP RPC에는
세션 id가 없다). 모킹 테스트는 통과했는데 실 스택에서 **일반 클라이언트가 세션 토큰으로
`POST /v2/rpc/gm_state`를 부르니 그대로 통과**했다. HTTP 경로는 소켓이 아니라 세션 id가 원래 없고,
그건 서버 호출의 증거가 아니다.

**해결:** 서버 간 호출(`?http_key=`)에는 `RUNTIME_CTX_USER_ID`가 **없다**. 세션 토큰 호출(소켓이든 HTTP든)에는
있다. 그러므로 판정은 `ctx.Value(runtime.RUNTIME_CTX_USER_ID)`가 비어 있는지로 한다.
```go
if uid, _ := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string); uid != "" {
    return "", ErrSessionForbidden // 세션 토큰 호출 — 서버 간 전용 RPC 거부
}
```
테스트는 반드시 실 스택에서 세션 토큰으로 HTTP 호출해 500(거부)을 확인한다 — 모킹 컨텍스트로는 두 판정이
구분되지 않는다. NKM-008 과 함께 걸린다.
