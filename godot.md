# Godot 4.7.2에서 실측한 사실

기준: Godot 4.7.2-stable (`4.7.2.stable.official.ed1daf0bf`), macOS arm64, GL Compatibility.
측정일 2026-09-06.

## nakama-godot에 `godot-4` 브랜치는 없다

```
git ls-remote --heads https://github.com/heroiclabs/nakama-godot.git
→ godot-3, master, small-performance-improvement
```

Godot 4 지원은 **master**에 있다.

## 릴리스 태그는 코드보다 2년 낡았다

- 최신 태그 `v3.4.0`: 2024-03-19
- `master` HEAD `7549fea8cb4d62a319028946de01a2993440c2d6`: 2026-08-11

태그를 고정하면 2년 전 SDK를 받고 프로젝트가 방치됐다고 오판하게 된다. **커밋을 고정할 것.**

그 커밋은 Godot 4.7.2에서 **패치 0줄**로 동작한다. 인증·RPC·소켓·스트림 presence 전부.

## SDK가 autoload를 둘 등록한다

upstream `project.godot`은 `Nakama`와 `Satori`를 모두 autoload로 등록한다.
Satori는 별도 유료 상품이다. 설정을 복사하면 쓰지 않는 서비스가 딸려 들어온다.

- `Nakama`만 등록하면 된다. `Satori/*.gd` 파일은 벤더 트리에 남아 있어도 파싱 오류 없음
- 파일을 지우면 "SDK 수정"으로 계산되므로 그대로 두고 등록만 제외

## `user://`는 프로젝트 이름에서 파생된다

한 머신의 모든 인스턴스가 같은 `user://`를 공유한다. device id를 거기 저장하면
**모든 인스턴스가 같은 계정으로 인증된다.**

- 로컬에서 두 클라이언트를 다른 플레이어로 띄우려면 인스턴스마다 `HOME`을 다르게 줄 것

## `--headless`는 3D를 렌더하지 못한다

dummy 드라이버를 쓴다. 스크립트로 렌더 결과가 필요하면 창 모드로 실행해야 한다.

## 메인 뷰포트 텍스처는 요청한 해상도를 보장하지 않는다

실제 윈도우 프레임버퍼 크기를 따른다. macOS Retina에서는 HiDPI 배율이나 디스플레이
해상도 클램프 때문에 1920×1080이 나오지 않는다.

- 고정 크기 `SubViewport`에 렌더해서 저장할 것

## 4.4+는 스크립트마다 `.gd.uid`를 자동 생성한다

생성물이지만 노이즈가 아니다. 커밋에 포함시킨다.

## GUT 관련 (테스트 프레임워크)

- `gut_cmdln.gd`는 4.7.2에서 autoload를 정상 로드한다. 문제는 `-s runner.gd` 직접 실행 경로에만 있다
- 테스트 종료 시 GUT의 `free()`가 signal emit 도중 SDK 소켓 어댑터를 파괴한다
  (`freed while a signal is being emitted` → null `_ws`). SDK 객체는 `add_child_autoqfree`로 넘길 것
- `Nakama.create_client()`는 HTTP 어댑터 하나를 공유한다. 재시도 정책을 분리하려면
  `NakamaClient.new(자체_어댑터, …)`로 직접 만들 것

## 이름 충돌 두 가지

- `INetwork.rpc()`는 `Node.rpc`를 가려 파싱 오류가 난다 → `call_rpc` 등으로 개명
- 내부 클래스 이름 `Error`는 Godot 전역 enum에 가려진다 → `RpcResult.RpcError` 식으로 중첩

## 익스포트 템플릿은 1.28GB다

`curl -C -`로 세 번에 나눠 받아야 했다. 설치 경로:
`~/Library/Application Support/Godot/export_templates/4.7.2.stable`
