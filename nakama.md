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
