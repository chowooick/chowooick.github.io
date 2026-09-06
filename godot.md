# Godot — 실측 사실

ID 접두사 `GDT`. ID는 불변이다.

---

## GDT-001 — nakama-godot에 `godot-4` 브랜치는 없다

`측정 2026-09-06 · nakama-godot`

```
git ls-remote --heads https://github.com/heroiclabs/nakama-godot.git
→ godot-3, master, small-performance-improvement
```

Godot 4 지원은 **master**에 있다.

---

## GDT-002 — 릴리스 태그가 코드보다 2년 낡았다

`측정 2026-09-06 · nakama-godot`

- 최신 태그 `v3.4.0`: 2024-03-19
- `master` HEAD `7549fea8cb4d62a319028946de01a2993440c2d6`: 2026-08-11

태그를 고정하면 2년 전 SDK를 받고 프로젝트가 방치됐다고 오판한다.

**해결:** 커밋을 고정한다. 그 커밋은 Godot 4.7.2에서 **패치 0줄**로 동작한다
(인증·RPC·소켓·스트림 presence 전부).

---

## GDT-003 — SDK가 autoload를 둘 등록한다

`측정 2026-09-06 · nakama-godot master@7549fea8 · Godot 4.7.2`

upstream `project.godot`이 `Nakama`와 `Satori`를 모두 autoload로 등록한다.
Satori는 별도 유료 상품이다. 설정을 복사하면 쓰지 않는 서비스가 딸려 들어온다.

**해결:** `Nakama`만 등록한다. `Satori/*.gd` 파일은 벤더 트리에 남아 있어도 파싱 오류가
없다. 파일을 지우면 "SDK 수정"으로 계산되므로 그대로 두고 등록만 제외한다.

---

## GDT-004 — `user://`는 프로젝트 이름에서 파생된다

`측정 2026-09-06 · Godot 4.7.2 · macOS`

한 머신의 모든 인스턴스가 같은 `user://`를 공유한다. device id를 거기 저장하면
**모든 인스턴스가 같은 계정으로 인증된다.**

경로(macOS): `~/Library/Application Support/Godot/app_userdata/<프로젝트명>/`

**해결:** 로컬에서 두 클라이언트를 다른 사용자로 띄우려면 인스턴스마다 `HOME`을 다르게 준다.

---

## GDT-005 — `--headless`는 3D를 렌더하지 못한다

`측정 2026-09-06 · Godot 4.7.2`

dummy 드라이버를 쓴다. 스크립트로 렌더 결과가 필요하면 창 모드로 실행해야 한다.

함께 걸림: GDT-006

---

## GDT-006 — 메인 뷰포트 텍스처는 요청한 해상도를 보장하지 않는다

`측정 2026-09-06 · Godot 4.7.2 · macOS Retina`

실제 윈도우 프레임버퍼 크기를 따른다. HiDPI 배율이나 디스플레이 해상도 클램프 때문에
1920×1080을 요청해도 그 크기가 나오지 않는다.

**해결:** 고정 크기 `SubViewport`에 렌더해서 저장한다.

함께 걸림: GDT-005

---

## GDT-007 — 4.4+는 스크립트마다 `.gd.uid`를 자동 생성한다

`측정 2026-09-06 · Godot 4.7.2`

에디터가 생성하지만 노이즈가 아니다. 커밋에 포함시킨다.

---

## GDT-008 — GUT의 `free()`가 SDK 소켓을 signal emit 도중 파괴한다

`측정 2026-09-05 · Godot 4.7.2 · GUT 9.7.1 · nakama-godot master@7549fea8`

**증상:** `freed while a signal is being emitted` 이후 `_ws`가 null이 되어 후속 테스트가 깨진다.

테스트 종료 시 GUT가 객체를 해제하는데, SDK 소켓 어댑터가 `received.emit` 중에 파괴된다.

**해결:** SDK 객체는 `add_child_autoqfree`로 넘긴다.

부수: `gut_cmdln.gd`는 4.7.2에서 autoload를 정상 로드한다. 이 문제는 `-s runner.gd`
직접 실행 경로에만 있다.

---

## GDT-009 — `Nakama.create_client()`는 HTTP 어댑터 하나를 공유한다

`측정 2026-09-05 · nakama-godot master@7549fea8`

재시도 정책을 호출별로 분리할 수 없다. 서버 권위 RPC에서 자동 재시도는 중복 실행
위험이 있으므로 분리가 필요하다.

**해결:** `NakamaClient.new(자체_어댑터, …)`로 직접 만든다.

---

## GDT-010 — 이름 충돌 두 가지

`측정 2026-09-06 · Godot 4.7.2 · GDScript`

**증상 1:** 인터페이스에 `rpc()`를 정의하면 `Node.rpc`를 가려 **파싱 오류**가 난다.
→ `call_rpc` 등으로 개명한다.

**증상 2:** 내부 클래스 이름 `Error`는 Godot 전역 enum에 조용히 가려진다.
오류 없이 잘못된 타입이 잡힌다. → `RpcResult.RpcError` 식으로 중첩 이름을 쓴다.

---

## GDT-011 — 익스포트 템플릿은 1.28GB다

`측정 2026-09-05 · Godot 4.7.2`

한 번에 받다가 끊기면 처음부터다. `curl -C -`로 이어받는다.

설치 경로(macOS): `~/Library/Application Support/Godot/export_templates/4.7.2.stable`

---

## GDT-012 — Android 플러그인은 익스포트 프리셋에서 켜야 한다. 안 켜면 조용히 빠진다

`측정 2026-09-06 · Godot 4.7.2 · Android`

**증상:** 없다. 그게 문제다. 익스포트 성공, APK 서명 통과, 설치 성공, 앱 실행 성공.
그런데 `Engine.has_singleton("<Name>")`이 false다. 오류 0줄, 경고 0줄, 로그 0줄.

Godot은 `res://android/plugins/`에서 찾은 플러그인마다 익스포트 옵션을 하나씩
만드는데 **기본값이 off**다. `export_presets.cfg`의 `[preset.N.options]`에
`plugins/<Name>=true`가 없으면 AAR을 병합하지 않는다.

**해결:** 프리셋에 한 줄 넣는다. 그리고 빌드된 APK를 직접 검증한다 —
익스포트가 성공했다는 사실은 플러그인이 들어갔다는 증거가 아니다.

```
aapt2 dump xmltree --file AndroidManifest.xml app.apk | grep 'org.godotengine.plugin.v2.<Name>'
```

덧: `export_presets.cfg`는 릴리스 키스토어 비밀번호를 담을 수 있어 보통 `.gitignore`에
있다. 그러면 fresh clone에서 이 줄이 사라진다. 템플릿 파일을 커밋하고 빌드
스크립트가 복원하게 한다.

---

## GDT-013 — 런처 액티비티는 `GodotApp`이 아니라 `GodotAppLauncher`다

`측정 2026-09-06 · Godot 4.7.2 · Android 15`

**증상:**

```
adb shell am start -n <pkg>/com.godot.game.GodotApp
→ java.lang.SecurityException: Permission Denial: starting Intent ... not exported from uid 10207
```

서명이나 권한 문제로 읽히지만 아니다. `GodotApp`은 exported=false이고
런처는 `com.godot.game.GodotAppLauncher`다.

**해결:** 이름을 외우지 말고 물어본다.

```
adb shell cmd package resolve-activity --brief <pkg> | tail -1
```

---

## GDT-014 — Godot 4.7.2에서 FCM 푸시는 된다. 자체 Kotlin 플러그인 120줄

`측정 2026-09-06 · Godot 4.7.2 · firebase-messaging 24.1.0 · Android 15 에뮬레이터(Play 이미지)`

공식 Firebase 플러그인은 없지만 커뮤니티 플러그인을 벤더링할 필요도 없다.
Android 플러그인 **v2** 방식 — AAR 매니페스트에
`<meta-data android:name="org.godotengine.plugin.v2.<Name>" android:value="<FQCN>">` —
으로 `GodotPlugin` 서브클래스 하나면 된다. 토큰 발급과 포그라운드 수신까지 120줄.

**앱 프로세스가 죽은 상태의 알림 수신에는 우리 코드가 관여하지 않는다.**
FCM `notification` 메시지는 Firebase SDK가 직접 시스템 트레이에 그린다.
`data` 메시지만 앱의 `FirebaseMessagingService`를 깨운다. 스파이크에서 제일 어려워
보였던 항목이 실제로는 의존성과 매니페스트의 속성이었다.

함께 필요한 것:

- `google-services` Gradle 플러그인 없이도 된다. `google_app_id`
  `gcm_defaultSenderId` `google_api_key` `project_id` 문자열 리소스를 AAR에 넣으면
  `FirebaseApp.initializeApp(context)`가 읽는다. Godot 빌드 템플릿을 무수정으로 둘 수 있다
- Android 13+는 `POST_NOTIFICATIONS` 없으면 배달된 푸시를 **아무 데도 안 그린다.**
  FCM이 깨진 것과 구분이 안 된다. 헤드리스 검증은 `adb shell pm grant`
- 에뮬레이터는 `google_apis_playstore` 이미지여야 한다. `google_apis`에는 전송 계층이 없다
- 종료 상태 검증은 `am kill`로 한다. `am force-stop`은 패키지를 stopped 상태로 만들어
  사람이 다시 실행할 때까지 FCM을 포함한 모든 브로드캐스트가 차단된다 —
  "닫힌 앱은 푸시를 못 받는다"는 거짓 결론이 나온다

미검증: 실기기. 위는 전부 에뮬레이터 실측이다.
