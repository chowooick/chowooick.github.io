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
