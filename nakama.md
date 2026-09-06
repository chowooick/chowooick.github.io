# Nakama 3.40 자체 호스팅에서 실측한 사실

기준: Nakama 3.40.0, nakama-common v1.47.0, Go 런타임 플러그인, PostgreSQL 16.8.
측정일 2026-09-06. 전부 실행 중인 서버에서 확인함. 문서에 없거나 문서와 다른 것만 적음.

## Go 플러그인 버전 불일치는 조용히 실패한다

플러그인의 Go 버전이나 `nakama-common` 버전이 서버 이미지와 다르면 오류가 나지 않는다.
로그에 `Go runtime modules loaded`가 찍히고 **등록된 RPC는 0개**다. 이후 모든 호출이 404다.

- 유일한 단서: 기동 로그의 RPC 개수
- 해결: `heroiclabs/nakama-pluginbuilder:<서버와 같은 태그>` 컨테이너에서만 빌드. 로컬 툴체인 금지

## nakama-common은 서버와 버전 체계가 다르다

서버는 `3.x`, `nakama-common`은 `1.x`다. "서버와 같은 마이너"라는 규칙은 성립하지 않는다.
정답은 서버 리포의 `go.mod`가 고정한 값이다. Nakama v3.40.0 → **nakama-common v1.47.0**.

## pluginbuilder 이미지의 entrypoint는 셸이 아니라 `go`다

```
docker run … pluginbuilder sh -ec '…'   # → go sh -ec '…' 로 전달되어 실패
docker run --entrypoint sh … pluginbuilder -ec '…'   # 정상
```

## 스트림 subject·subcontext는 UUID만 받는다

`StreamUserJoin(mode, subject, subcontext, label, …)`에서 `subject`와 `subcontext`는
`uuid.FromString`으로 파싱된다. `"colony-01"` 같은 임의 문자열은 거부된다.

- 해결: 채널 id를 **label**에 넣는다
- 스트림 키는 `mode + subject + subcontext + label` 전체이므로 격리 강도는 동일하다

## presence의 status는 클라이언트에 전달되지 않는다

`StreamUserJoin`에 넘긴 status는 서버에 저장되고 `StreamUserList`로 읽힌다.
그러나 **와이어에는 실리지 않는다.** v3.40.0 `server/tracker.go:928`(join)·`:971`(leave):

```go
pWire := &rtapi.UserPresence{UserId, SessionId, Username, Persistence}
if p.Stream.Mode == StreamModeStatus {
    pWire.Status = …
}
```

주석 원문: *"Status field is only populated for status stream presences."*

실측: 커스텀 mode 100의 join 이벤트에 `status` 키가 아예 없다. 같은 소켓의 내장
`status_presence_event`에는 `"status":""`가 실린다.

- presence 이벤트로 받을 수 있는 필드: `user_id` `session_id` `username` `persistence`
- 표시 이름이 필요하면 `user_id`로 users API(`/v2/user?ids=`)를 조회한다

## 스트림에 새로 들어온 소켓은 기존 재실자를 모른다

자기 자신의 join 이벤트만 받는다. 먼저 들어온 쪽은 나중 입장자를 이벤트로 보지만,
나중 입장자는 먼저 있던 사람을 **영원히 모른다.**

- 명단이 필요하면 join RPC 응답에 직접 담아야 한다. 서버가 밀어주지 않는다

## 소켓으로 온 오류는 코드가 붕괴한다

HTTP로 호출하면 raise한 gRPC 코드(`3` `8` `9` `16`)가 그대로 온다.
WebSocket rpc 엔벨로프로 호출하면 Nakama가 **모든 런타임 오류를 `7 RUNTIME_FUNCTION_EXCEPTION`으로
바꾼다.** message만 보존된다.

- 클라이언트는 `code`가 아니라 **message 식별자**로 분기해야 한다
- message를 snake_case 식별자(`channel_full`, `insufficient_stock`)로 정하고 계약에 포함시킨다

## HTTP RPC에는 세션 id가 없다

`RUNTIME_CTX_SESSION_ID`는 소켓으로 온 호출에만 채워진다.

- 활용: 갱신 RPC에 소켓 연결을 **구조적으로** 강제할 수 있다
- 한계: "소켓 연결 후 HTTP로 호출"은 서버가 어느 소켓인지 알 수 없다

## RegisterEventSessionEnd 훅보다 presence 정리가 먼저다

Nakama가 죽은 세션의 스트림 presence를 전부 걷은 뒤에 훅이 실행된다.
훅 본문이 비어 있어도 "소켓 강제 종료 → 2초 내 카운트 감소" 테스트가 통과한다.

- 훅에 presence 삭제 코드를 넣지 말 것

## 기본 세션 토큰 수명은 60초다

개발 중에는 보이지 않다가, 60초짜리 카운트다운 화면에서 정확히 터진다 — 사용자가 제출하는
순간 토큰이 만료된다.

- `session.token_expiry_sec`를 올리거나, 잔여 수명이 임계값 미만이면 재인증

## `string_to_array('', ',')::uuid[]`는 Postgres 오류다

빈 배열이 아니라 에러다. 플러그인에 배열 드라이버가 없어 id를 콤마로 이어 붙여
`ANY(...)` 필터를 만들면 반드시 만난다.

- 빈 집합이면 쿼리 전에 단락시킬 것

## 채널 인원 상한은 원자적으로 지킬 수 없다

Nakama에 스트림 상한 API가 없다. `StreamUserList`로 세고 `StreamUserJoin`하는 2단계라
동시 요청이 상한을 1~2명 초과할 수 있다.

- 엄격히 막으려면 Postgres 테이블로 presence를 잡아야 한다
