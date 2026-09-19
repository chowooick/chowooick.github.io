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

---

## GDT-015 — `gl_compatibility`에서 되는 것과 안 되는 것 (실측표)

`측정 2026-09-06 · Godot 4.7.2 · OpenGL API 4.1 Metal · Apple M1 Max`

같은 3D 씬을 효과별로 껐다 켜서 PNG 픽셀을 비교했다. 같은 씬을 두 번 렌더하면
차이가 **정확히 0**이라 잡음 바닥이 없다. `mean |Δ|`는 채널당 0~255 기준.

**되는 것:**

```
깊이 포그(FOG_MODE_EXPONENTIAL, aerial_perspective 포함)   23.09
디렉셔널 그림자                                            14.68
2D 그레이드(CanvasItemMaterial MUL/ADD + 그라디언트)        17.68
톤맵(FILMIC · ACES 둘 다 동작)                              9.37
adjustment(brightness/contrast/saturation)                  5.45
SSAO                                                        0.64
글로우(HDR 임계값 넘는 이미시브에서만)                       1.91
ProceduralSkyMaterial + REFLECTION_SOURCE_SKY                0.67
```

**SSAO가 된다.** 여러 자료가 Forward+ 전용으로 적어두지만 4.7.2 Compatibility에서
동작한다. `ssao_radius` 1.1→4.0, `ssao_intensity` 2.6→16.0으로 올리면 접지부
차폐가 눈에 띄게 커진다(mean 0.33 → 1.45). Compatibility에는 GI도 바운스도 없으므로
**유일한 차폐 단서**다. 기본값은 카메라가 멀면 3픽셀도 안 되니 반드시 키워야 한다.

**안 되는 것 — 켜도 경고 한 줄 찍고 무시된다. 픽셀 차이 0.000:**

```
볼류메트릭 포그   Volumetric fog is only available when using the Forward+ renderer.
SDFGI            SDFGI is only available when using the Forward+ renderer.
피사계 심도(DOF)  Depth of field blur is only available when using the Forward+ or Mobile renderer.
```

DOF 경고문은 **Mobile**도 지원한다고 말한다. Forward+ 효과를 되찾고 싶으면
`forward_plus`보다 `mobile`이 싼 문이다.

**해결:** 볼류메트릭 포그 → 깊이 포그 + `fog_aerial_perspective` + `fog_sun_scatter`
(거리 안개는 살고 광선은 못 살린다). SDFGI/바운스 → 차가운 상수 앰비언트 + fill/rim
디렉셔널 라이트. DOF → 2D 비네트로 주제 분리. 비네트는 `CanvasItemMaterial` 블렌드라
Forward+ 파일에 있어도 렌더러와 무관하게 그대로 동작한다.

---

## GDT-016 — `user://` 경로에 슬래시가 겹치면 GLES3 셰이더 캐시가 실패한다

`측정 2026-09-06 · Godot 4.7.2 · macOS 25.6 · Compatibility(OpenGL)`

**증상:**

```
ERROR: Can't create shader cache folder, no shader caching will happen: user://
   at: RasterizerGLES3 (drivers/gles3/rasterizer_gles3.cpp:352)
```

macOS `$TMPDIR`는 슬래시로 끝난다. 따라서 흔한 관용구

```
WORK="$(mktemp -d "${TMPDIR:-/tmp}/x.XXXXXX")"     # → /var/folders/.../T//x.abc123
HOME="$WORK" godot --path client ...
```

가 만드는 `HOME`에는 `//`가 들어 있고, 여기서 파생된 `user://`로는 셰이더 캐시
디렉터리 생성이 실패한다. 같은 경로로 `user://` **파일 쓰기는 정상**이라(디바이스 id
등) 원인이 경로라는 게 잘 안 보인다.

**헤드리스 실행에서는 안 나온다.** `--display-driver headless`는 래스터라이저를
아예 띄우지 않는다. 헤드리스 테스트만 돌리다가 처음 창 모드 테스트를 짤 때 나온다.

**해결:** `pwd -P`로 정규화한다.

```
WORK="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/x.XXXXXX")" && pwd -P)"
```

---

## GDT-017 — `--quit-after`는 초가 아니라 프레임이고, 가려진 창은 스로틀된다

`측정 2026-09-06 · Godot 4.7.2 · macOS 25.6`

**증상:** 창 모드 테스트가 하루의 두 번째 실행에서 `exit code 143`으로 죽는다.
같은 명령이 첫 실행에서는 통과한다. 클라이언트는 할 일을 이미 다 끝낸 상태다.

`--quit-after <n>`은 **프레임 수**다. vsync가 걸린 창이면 600프레임이 60Hz에서
10초지만, macOS가 가려졌거나 다른 Space에 있는 창을 스로틀하면 같은 600프레임에
분 단위가 걸린다. `timeout`을 시간 상한으로 걸어두면 멀쩡한 실행이 SIGTERM으로 죽는다.

**해결:** `--quit-after`를 시간 보증으로 쓰지 않는다. 스크린샷 같은 산출물은
`SceneTreeTimer`(벽시계)로 예약하면 프레임 속도와 무관하게 뜨므로, 셸은 **출력된
로그 줄과 파일 존재**로 단언하고 `timeout`에 의한 kill(124·143)을 허용한다.
스스로 `get_tree().quit()`을 부르는 실행만 종료 코드를 엄격하게 본다.

---

## GDT-018 — `gui/theme/default_font_size`는 Godot 4에 없다. 써도 조용히 무시된다

`측정 2026-09-06 · Godot 4.7.2`

**증상:** `project.godot`에 `theme/default_font_size=44`를 넣고 익스포트해도 글자
크기가 그대로다. 경고도 오류도 없다. 설정이 안 먹는 게 아니라 **이름 자체가 없다**.
Godot은 모르는 프로젝트 설정을 오류 없이 받아 저장하기 때문에, 오타와 존재하지 않는
설정과 정상 설정이 파일에서 똑같이 생겼다.

```
strings <Godot 바이너리> | grep -x 'gui/theme/[a-z_/]*'
→ custom, custom_font, default_font_antialiasing, default_font_generate_mipmaps,
  default_font_hinting, default_font_multichannel_signed_distance_field,
  default_font_subpixel_positioning, default_theme_scale, lcd_subpixel_layout
```

`default_font_size`는 없다. Godot 3의 기억이거나 LLM이 지어낸 이름이다.

**해결:** 기본 테마 전체를 키우는 **`gui/theme/default_theme_scale`**(float, 기본 1.0)
을 쓴다. 폰트뿐 아니라 여백·간격·아이콘까지 같은 비율로 커져서 버튼이 글자보다
작아지는 일이 없다. 폰트만 따로 키우려면 `Theme` 리소스를 만들어
`gui/theme/custom`에 물린다.

**존재 여부를 확인하는 법:** 위 `strings` 한 줄. 설정 이름은 바이너리에 그대로 박혀
있다.

---

## GDT-019 — `display/window/handheld/orientation`은 문자열이 아니라 정수다

`측정 2026-09-06 · Godot 4.7.2 · Android`

**증상:** `window/handheld/orientation="portrait"`를 넣었는데 앱이 여전히 가로로 뜬다.
설정을 아예 안 넣은 것과 화면이 똑같다.

Godot 4에서 이 값은 **enum 인덱스**다.

```
0 Landscape · 1 Portrait · 2 Reverse Landscape · 3 Reverse Portrait
4 Sensor Landscape · 5 Sensor Portrait · 6 Sensor
```

문자열 `"portrait"`는 int로 캐스팅되며 **0(Landscape)**이 된다. Godot 3은 문자열이었다.

**확인:** 익스포트한 apk의 매니페스트를 본다. 여기서 확정된다.

```
aapt2 dump xmltree --file AndroidManifest.xml app.apk | grep screenOrientation
→ android:screenOrientation(0x0101001e)=1
```

**해결:** `window/handheld/orientation=1`.

---

## GDT-020 — Android 익스포트가 자기 출력을 리소스로 다시 담아, 8번째 실행에서 죽는다

`측정 2026-09-06 · Godot 4.7.2 · Android · gradle build`

**증상:** 같은 프로젝트를 반복 익스포트하다 갑자기 죽는다. 코드 변경과 무관하다.

```
Execution failed for task ':packageStandardDebug'.
> Too many zip entries 92677 (MAX=65535)
```

`use_gradle_build=true`면 Godot이 익스포트 산출물을
`<project>/android/build/src/main/assets/`에 쓴다. 이 경로는 **`res://` 안**이다.
`export_filter="all_resources"`는 `res://` 전체를 담으므로, 다음 익스포트가 직전
익스포트의 assets를 리소스로 집어넣는다. 실행마다 한 겹씩 중첩된다.

```
assets/android/build/src/main/assets/android/build/src/main/assets/core/net/nakama_client.gdc
```

중간 단계에서는 이런 줄만 나오고 익스포트는 성공해서, 죽기 전까지 몇 번은 그냥 된다.

```
ERROR: Can't open file from path 'res://android/build/src/main/assets/android/build/src/main/assets/...gdc'
```

**해결:** 익스포트 프리셋에서 제외한다. 게임이 로드하지 않는 파일이고 Gradle은
디스크에서 읽으므로 pck에 들어갈 이유가 없다.

```
exclude_filter="android/*"
```

이미 쌓였으면 `exclude_filter`만으로는 안 풀린다. Gradle이 스테이징 디렉터리에 남은
것을 그대로 담기 때문이다. 한 번 비운다.

```
rm -rf client/android/build/src/main/assets client/android/build/build
```

---

## GDT-021 — ScrollContainer의 가로 스크롤을 끄면 컨테이너가 자식 크기로 커진다

`측정 2026-09-06 · Godot 4.7.2`

**증상:** 좁은 화면에서 내용이 오른쪽으로 넘치기에 `horizontal_scroll_mode`를
`SCROLL_MODE_DISABLED`(0)로 바꿨더니, 내용이 줄지 않고 패널 전체가 화면보다 커져
**좌우 양쪽이** 잘렸다.

`ScrollContainer::get_minimum_size()`는 그 축의 스크롤이 **DISABLED일 때만** 자식의
최소 너비를 자기 최소 크기에 더한다. 그리고 Control의 크기는 앵커가 아니라 최소
크기가 이긴다. 그래서 앵커로 화면에 꽉 채운 ScrollContainer라도 자식이 요구하는
너비만큼 커지고, 부모 안에서 가운데 정렬되어 양쪽으로 삐져나온다.

`SCROLL_MODE_SHOW_NEVER`(3)는 더 나쁘다. 자식은 여전히 자기 최소 너비를 받고
스크롤바만 숨어서, 잘린다는 신호까지 사라진다.

**해결:** 스크롤 모드로 내용을 줄일 수 없다. 자식의 **최소 너비 자체를** 줄여야 한다
— 긴 `Label`에 `autowrap_mode`나 `text_overrun_behavior`를 준다. 진단할 때는 기본값
`SCROLL_MODE_AUTO`로 두는 편이 낫다. 가로 스크롤바가 뜨면 그게 넘친다는 증거다.

## GDT-022 — 얼어붙은 서버로 HTTP를 보내면 Godot 프레임이 통째로 멈춘다. GDScript 타임아웃으로는 못 잡는다

`측정 2026-09-06 · Godot 4.7.2 · nakama-godot 7549fea8 · Nakama 3.40`

**증상:** 서버 컨테이너를 `docker pause`로 얼린 뒤 클라이언트가 HTTP RPC를 하나
보내면, 그 호출이 영원히 돌아오지 않고 **프로세스 전체가 멈춘다.** 로그가 그 줄에서
끊기고 그 뒤로 아무것도 찍히지 않는다.

`docker stop`으로는 재현되지 않는다. 소켓이 정상 종료되면 SDK가 대기 요청을
취소하고 클라이언트는 스스로 끝난다. **열린 채 응답만 없는** 상태여야 한다 —
`pause`는 프로세스만 얼리고 TCP 연결은 그대로 두므로 응답도 FIN도 오지 않는다.

멈춘 것이 "그 호출 하나"가 아니라 **프레임 자체**라는 근거는 두 가지다. 그 호출에
걸어둔 `SceneTreeTimer`의 `timeout`이 안 뜬다. 동시에 전혀 무관한 노드 `Timer`(30초
주기 하트비트)도 2분 동안 한 번도 안 뜬다. 프레임에 의존하는 두 가지가 같이 침묵하면
프레임이 안 도는 것이다.

`NakamaHTTPAdapter`는 막아둔 것처럼 보이지만 안 막힌다 — `timeout = 3`,
재시도 3회, `max_total_timeout_ms = 10000` 워치독이 다 있는데도 돌아오지 않는다.
그 워치독도 `create_timer`라 프레임이 필요하기 때문이다.

**해결:** GDScript 층에는 해결이 없다. `await`를 `SceneTreeTimer`와 경주시키는 흔한
패턴은 프레임이 도는 동안에만 작동하므로 이 경우엔 무력하다. 엔진의 `HTTPRequest`나
어댑터 아래층에서 막아야 한다. 반대로 **웹소켓 RPC는 GDScript로 막힌다** —
`NakamaSocket.rpc_async()`는 프레임을 멈추지 않으므로 요청과 `SceneTreeTimer`를
경주시키면 마감이 정상 동작한다. 같은 "서버 무응답"이라도 두 경로의 성질이 다르다.

**보강(2026-09-12, 대표님 승인):** 위 "요청과 `SceneTreeTimer`를 경주시킨다"는 결론만 맞고 방법 서술은
그대로 GDScript로 옮길 수 없다 — 코루틴은 `await` 없이 부를 수 없어 파스·런타임 에러가 난다. 실제 구현 방법은
**GDT-052**(`call_deferred` + 전용 시그널 + 프레임 폴링) 참고.

---

## GDT-023 — [원인 오판 — GDT-024로 정정] `gl_compatibility`에서 넓은 지형이 원거리 비탈에 사각 패치를 낸다. 방향광 그림자를 끄는 것 말고는 무엇도 듣지 않는다

`측정 2026-09-06 · Godot 4.7.2 · gl_compatibility · Apple M1 Max`

> **이 항목의 결론은 틀렸다.** 원인은 렌더러가 아니라 지형의 면 노멀이고 고칠 수 있다 — **GDT-024**를 보라. 아래 소거표(15가지가 듣지 않는다)는 재측정해도 그대로이므로 남긴다. 틀린 것은 그 표에서 끌어낸 두 추론이다: "테셀레이션 2배에 패치 크기 불변"은 오관측이고(2배로 하면 정확히 절반이 된다), 따라서 "지오메트리가 원인이 아니다"도 성립하지 않는다.

**증상:** 200×200 m 코드 생성 지형(`SurfaceTool` 플랫 셰이딩, 4×4 청크, 셀 1.56 m)을
지상 4~7 m의 3인칭 카메라로 보면, **카메라에서 50 m 이상 떨어진 비탈**에 월드 축에
정렬된 사각 패치가 밝기 차이로 드러난다. 태양을 스치듯 받는 면(크레이터 안쪽 벽)에서
가장 심하다. 패치 한 변은 화면상 30~60 px이고 지형 셀 크기와 무관하다.

**유일한 소거 조건은 방향광(키 라이트)의 `shadow_enabled = false`다.** 끄면 완전히
사라진다. 그런데 그 위치에는 그림자를 드리울 물체가 없고, 지형 자체는
`SHADOW_CASTING_SETTING_OFF`라 자기 그림자도 못 만든다.

**효과가 없음을 확인한 것** — 전부 같은 카메라·같은 프레임을 렌더해 PNG를 비교했다:

| 분류 | 시험한 것 |
|---|---|
| Environment | `ssao_enabled` off · `glow_enabled` off · `fog_enabled` off · `background_mode = BG_COLOR` |
| 그림자 파라미터 | `shadow_bias` 0.035→0.005 · `shadow_normal_bias` 1.4→0.05 · `shadow_blur` 1.4→0 · `light_angular_distance` 1.6→0 · `directional_shadow_max_distance` 60→25 및 →200 · `PARALLEL_2_SPLITS`→`ORTHOGONAL` · `blend_splits` off |
| 지오메트리 | 테셀레이션 128→256 셀 · 청크 4×4→8×8 · 삼각형 대각선 선택을 슬로프 추종에서 고정으로 |
| 머티리얼 | albedo·roughness 텍스처 제거 · `SPECULAR_DISABLED`→활성 |
| 캐스터 | 바위 139개 전부 제거 · 원거리 메사 18개 전부 제거 · 바위 `cast_shadow` off |

**테셀레이션을 2배로 해도 패치 크기가 변하지 않는다**는 것이 지오메트리가 원인이
아니라는 증거다. `directional_shadow_max_distance`를 25로 줄여 문제 구간을 그림자
사거리 밖으로 빼도 그대로라는 것은 그림자 맵의 커버리지 문제도 아니라는 뜻이다.

**반례:** 같은 아트 킷·같은 `Environment`·같은 3점 조명으로 **30 m 프레임**(고정
아이소메트릭 카메라, 건물 위주)을 렌더하면 나타나지 않는다. 카메라가 보는 거리와
지형 면적의 문제다. GDT-015의 실측표는 30 m 프레임에서 잰 것이라 이 조건을 담고 있지
않다.

**해결:** GDT-024. 이 항목을 쓸 당시에는 특정하지 못했고 "남은 방향은 엔진 소스의
Compatibility 그림자 셰이더"라고 적었는데, 그 방향이 틀렸다. 이 항목의 값어치는 위
표에 남는다 — 같은 증상을 만나면 저 15가지는 다시 시험하지 않아도 된다.


## GDT-024 — 저폴리 높이장 지형의 사각 패치는 그림자가 아니라 셀 단위 면 노멀이다. 그림자 설정으로는 잡히지 않는다

`측정 2026-09-06 · Godot 4.7.2 · gl_compatibility · Apple M1 Max`

**증상:** GDT-023과 같다 — 200×200 m 코드 생성 높이장(`SurfaceTool` 플랫 셰이딩,
셀 1.5625 m)을 3인칭 카메라로 보면 원거리 비탈에 축 정렬 사각 패치가 밝기 차이로
드러난다. 방향광의 `shadow_enabled = false`로만 사라지므로 그림자로 오진하기 쉽다.

**원인:** 그림자가 아니라 **키 라이트의 확산광이고, 셀마다 균일한 면 노멀 때문이다.**
`heightmap_chunk` 류의 빌더는 삼각형마다 면 노멀을 준다. 한 셀은 짧은 대각선으로
자른 두 삼각형인데, 대각선보다 완만한 비탈에서는 두 삼각형의 노멀이 거의 같아진다.
그래서 셀 하나가 **균일한 밝기의 축 정렬 사각형**으로 렌더된다. 원거리 비탈에서 이
사각형 수백 개가 줄을 맞추면 격자로 읽힌다. 태양을 스치듯 받는 면에서 가장 심한 것은
그 각도에서 `N·L`이 노멀 차이에 가장 민감하기 때문이다.

**어떻게 갈랐나 — 같은 프레임을 렌더해 PNG를 픽셀 비교했다:**

| 조작 | 결과 | 함의 |
|---|---|---|
| `shadow_opacity = 0` (그림자는 켠 채 효과만 제거) | 관심 영역 **바이트 동일** | 그림자가 아니다 |
| `light_energy = 0` (키 라이트 확산광 제거) | 패치 **소멸** | 키 라이트의 확산항이다 |
| 키 라이트 `yaw + 40°` | 패치 **소멸** | 광원 방향에 의존한다 |
| `TOTAL_CELLS` 128 → 256 | 패치 크기 **정확히 절반** | 셀 격자다 |
| albedo·roughness 텍스처 전부 제거 | 패치 **잔존**(오히려 강화) | 텍스처가 아니다 |
| 그림자 아틀라스 1024 / 8192 | 관심 영역 **바이트 동일** | 섀도 맵 텍셀이 아니다 |

`shadow_opacity = 0`과 `light_energy = 0`을 가르는 이 한 쌍이 결정적이다. 둘 다
"그림자를 끈다"처럼 보이지만 전자는 그림자 항만, 후자는 확산항까지 제거한다. 패치가
전자에 무반응하고 후자에 소멸하면 그림자 계통은 전부 배제된다. **`shadow_enabled`로
사라진다고 해서 그림자인 것이 아니다** — 그것을 끄면 그 광원의 확산 계산 경로까지 함께
바뀌므로, 확산항이 원인일 때도 똑같이 사라진다. GDT-023이 걸린 함정이 이것이다.

**해결:** 면 노멀을 버리고 **높이장의 해석적 노멀**을 쓴다. 정점이 놓인 격자에서
높이 함수의 중심차분으로 기울기를 구해 `(-dh/dx, 1, -dh/dz)`를 정규화한다. 격자
배열을 청크별이 아니라 전역으로 한 벌 두면 청크가 공유하는 모서리가 한 항목으로
풀려 이음매도 생기지 않는다. 실측: 패치 지표 7.52 → 1.71(패치가 원리상 불가능한
하한이 1.58), 드로우콜·삼각형 수 불변(186 / 79,354), 빌드 시간 264 ms → 288 ms
(격자 모서리당 높이 1회, 16,641회).

각면을 살리려고 면 노멀과 섞으면 격자 성분이 비율만큼 남는다. 실측으로 70% 섞어도
지표가 2.45까지밖에 안 내려가고, 시점이 바뀌면 다시 드러난다. **로우폴리 정체성은
지면이 아니라 바위·건물·인물의 실루엣이 지고 있으므로 지면은 완전히 매끈하게 두는
편이 낫다.**

## GDT-025 — nakama-godot의 `join_match_async`·`leave_match_async`에는 마감이 없다

`측정 2026-09-07 · Godot 4.7.2 · nakama-godot 7549fea8 · 서버 `docker pause``

**증상:** 소켓 RPC에는 자체 마감 래퍼를 씌워 얼어붙은 서버에서 돌아오게 만들어 두었는데
(GDT-022의 후속), 월드 퇴장이 마감 없는 `leave_match_async`를 마감 있는 채널 퇴장보다
**먼저** 부르는 순서였다. 서버를 `docker pause`로 얼리면 클라이언트가 그 줄에서 영원히
멈춘다. 매치 동기화를 넣은 커밋 이후 회귀였고, CI 클라 잡이 이 스모크를 돌리지 않아
6개 티켓 뒤에야 발견됐다.

**해결:** SDK를 고치지 않고, 소켓 RPC용 토큰 경합 래퍼(요청 토큰 + `SceneTreeTimer`
마감 중 먼저 오는 쪽)를 `join_match_async`·`leave_match_async`에도 씌운다. 원칙:
**서버로 나가는 모든 호출은 마감 래퍼 하나를 지난다** — 새 SDK 호출을 쓸 때마다
래퍼 목록을 확인한다.

**보강(2026-09-12, 대표님 승인):** "토큰 경합 래퍼"의 실제 구현 방법은 **GDT-052** 참고 — 코루틴을 `await`
없이 잡는 길이 없어 `call_deferred` + 전용 시그널로 레이스한다.

## GDT-026 — `Input.parse_input_event()`로 합성한 헤드리스 좌표는 `get_screen_transform()`을 거쳐야 한다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** 스모크가 `--tap-screen x,y` 같은 인자로 화면 좌표를 만들어 그대로
`InputEventMouseButton.position`에 넣고 `Input.parse_input_event()`로 주입하면,
헤드리스 실행에서 실제 피킹(`Camera3D.project_ray_origin` 등)이 보는 좌표가 최대
20배까지 어긋난다. 창 모드에서는 뷰포트 스케일이 1:1로 우연히 맞아 드러나지 않고,
헤드리스만의 내부 렌더 해상도 스케일 차이로만 재현된다 — 스모크를 windowed로만
돌리면 절대 못 잡는다.

**해결:** 이벤트에 넣기 전에 좌표를 `get_viewport().get_screen_transform()`으로
변환한다(`touch_input.gd`의 `_to_screen()`과 같은 처리). 원칙: 합성 입력 좌표는
스크린 스페이스처럼 보여도 뷰포트 변환을 한 번 거쳐야 실제 피킹 좌표와 일치한다.

## GDT-027 — 같은 세션에 추가한 `class_name`은 `--check-only`엔 보이고 평범한 `--headless` 실행엔 안 보일 수 있다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** 새 스크립트에 `class_name Foo`를 붙이고 다른 파일에서 맨 이름
`Foo.static_func()`로 바로 썼다. `ops/check.sh gd`(`godot --headless
--check-only --quit`로 프로젝트 전체를 파싱)는 깨끗하게 통과했는데, 실제
헤드리스 플레이 실행(`godot --headless --path client -- ...`)은
`SCRIPT ERROR: Identifier "Foo" not declared in the current scope`로 죽었다.
같은 프로젝트, 같은 파일, 다른 실행 방식만 다름. `.godot/global_script_class_cache.cfg`를
까 보면 실제로 `Foo` 항목이 없었다 — `--check-only`는 이 캐시를 최신으로
만들어 주지만, 그 결과가 곧바로 다음 평범한 실행에 반영된다는 보장이 없다.

**해결:** 같은 세션에 새로 추가한 `class_name`을 다른 파일에서 맨 이름으로
바로 쓰지 않는다. `const Foo := preload("res://path/foo.gd")`로 받아
`Foo.static_func()`처럼 쓰면 전역 클래스 캐시 상태와 무관하게 항상 된다 —
이미 이 코드베이스의 절대다수 크로스파일 참조가 이 방식(예: `push_register.gd`를
`preload(...).new()`로 붙이는 패턴)이고, `class_name` 전역 참조는 애초에
드물게만 쓰인다는 뜻이기도 하다.

추가 실측(2026-09-07, T106): 타입 힌트(`var t: Foo`)까지 쓰려면 `class_name`이
필요하다. 그때는 `godot --headless --import --path client`를 한 번 돌리면
`global_script_class_cache.cfg`에 새 클래스가 들어가고 이후 평범한 헤드리스
실행에서도 보인다(같은 `.godot/`를 쓰는 다른 세션에도 적용된다). CI는 신선한
체크아웃마다 이 `--import`를 돌리므로(`ops/ci/run-local.sh`) 거기서는 문제가
안 난다 — 로컬 첫 실행만 걸린다.

## GDT-028 — `Dictionary.get(key, fallback)`의 fallback은 키가 없을 때만 나온다 — 값이 JSON null이면 그 null이 그대로 나온다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** Go 서버의 `*string`(nullable) 필드는 비어 있어도 JSON에 키 자체가
빠지는 게 아니라 `"field": null`로 나간다. 클라에서 `String(dict.get("field", ""))`로
받았더니 `SCRIPT ERROR: Invalid call 'String' constructor: <다른 필드 값>`로
죽었다 — `dict.get(key, fallback)`은 **키가 없을 때만** fallback을 주고, 키가
있으면 그 값이 설령 null이어도 그 null을 그대로 돌려준다. `String(null)`은
빈 문자열이 아니라 스크립트 오류다.

**해결:** 서버의 nullable 필드(포인터 타입이 JSON 필드로 나가는 모든 곳)를
받을 때는 `dict.get(key, fallback)` 한 줄로 끝내지 말고 타입을 확인한다:
```gdscript
static func _opt_str(dict: Dictionary, key: String, fallback := "") -> String:
    var value = dict.get(key)
    return value if value is String else fallback
```
`!= null` 체크로 존재 여부만 보는 코드(예: `resolved_at != null`)는 안전하다 —
문제는 그 값을 다시 `String()`·`int()`처럼 타입 변환에 넣을 때만 터진다.

## GDT-029 — 방금 `instantiate()`한 노드는 `add_child()`로 트리에 들어가기 전엔 `get_tree()`가 null이다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** `var n := scene.instantiate(); n.setup(...)  # setup 안에서 get_tree() 호출; get_tree().root.add_child(n)`
순서로 짰다. `setup()` 안에서 `await get_tree().create_timer(...).timeout`을
불렀더니 `ERROR: Parameter "data.tree" is null. at: get_tree (scene/main/node.h:559)`.
`instantiate()`만 한 노드는 아직 어떤 SceneTree에도 속하지 않으므로
`get_tree()`가 null을 돌려준다 — 부모에 붙는 순간부터 유효해진다.

**해결:** `get_tree()`를 쓰는 초기화 로직이 있다면 **먼저 `add_child()`로
트리에 넣고 나서** 그 초기화 함수(`setup()` 등)를 부른다. 시그널 연결은
add_child 전후 어느 쪽이든 상관없지만, `get_tree()`를 부르는 코드는 반드시
add_child 뒤에 와야 한다.

## GDT-030 — 터치 한 번은 `_unhandled_input`에 두 번 온다: 터치 이벤트와 `DEVICE_ID_EMULATION` 마우스 이벤트

`측정 2026-09-07 · Godot 4.7.2`

**증상:** 화면 탭/드래그를 판정하는 노드에 `InputEventScreenTouch`와
`InputEventMouseButton`을 둘 다 받게 해 두었더니(PC·폰 한 코드), 합성 터치
드래그 400px 한 번에 카메라가 172도 돌았다 — 기대는 72도. 터치 오버레이가
`look_by()`로 72도를 돌리고, 같은 손가락이 **마우스 클릭으로 한 번 더** 들어와
두 번째 판정기가 100도(마우스 감도)를 더 돌린 것. 프로젝트 기본값
`input_devices/pointing/emulate_mouse_from_touch = true`가 모든 터치를 마우스
이벤트로 복제하기 때문이다. `set_input_as_handled()`는 도움이 안 된다 —
복제된 마우스 이벤트는 원본 터치와 별개의 이벤트로 따로 전달된다.

**해결:** 마우스 이벤트를 받는 자리에서 `event.device == InputEvent.DEVICE_ID_EMULATION`
(-1)이면 무시한다. 복제된 마우스 이벤트만 이 device id를 달고 오고, 실제
마우스와 `Input.parse_input_event()`로 넣은 합성 마우스는 0이다. 헤드리스에도
복제가 켜져 있으므로 스모크에서 그대로 재현·검증된다.

## GDT-031 — `Input.parse_input_event()`로 넣은 누름은 즉시 전달되지 않는다 — 창 모드 첫 프레임에서 265ms 늦게 도착해 "길게 누름"이 탭이 됐다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** 길게 누름(0.4초)을 합성하려고 press 이벤트를 넣고 `create_timer(0.55)`
뒤 release를 넣었다. 헤드리스에서는 링 메뉴가 열렸는데 창 모드(720x1280)에서는
같은 코드가 탭으로 판정됐다. 판정기에 찍어 보니 `_unhandled_input`이 press를
받은 시각 기준으로 release까지 **285ms** — 타이머는 550ms를 기다렸는데 press
자체가 265ms 늦게 처리됐다. `parse_input_event()`는 큐에 넣을 뿐이고 실제
전달은 다음 입력 플러시(프레임)인데, 창 모드 첫 프레임들은 셰이더 컴파일로
수백 ms가 걸린다. 헤드리스는 그 스톨이 없어 재현되지 않는다.

**해결:** 합성 "누르고 있기"는 press를 넣은 시각이 아니라 **판정기가 press를
받은 시각**부터 잰다: press를 넣고 `while not gesture_active: await process_frame`
로 도착을 기다린 뒤 타이머를 시작한다. 일반화하면, 합성 입력 뒤에 시간에
민감한 후속 입력을 보낼 때는 항상 앞 입력의 수신을 확인하고 넘어간다.

## GDT-032 — `AudioStreamGeneratorPlayback.push_buffer()`는 `PackedFloat32Array`를 거부한다 — `PackedVector2Array`만 받는다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** `AudioStreamGenerator`로 모노 파형을 코드로 합성해 `PackedFloat32Array`에
담고 `playback.push_buffer(samples)`를 호출했다. 파싱 자체는 통과하지만 실행
시점에 `SCRIPT ERROR: Invalid argument for "push_buffer()" function: argument 1
should be "PackedVector2Array" but is "PackedFloat32Array"`로 죽는다 — 타입은
GDScript 정적 분석이 아니라 엔진 쪽 런타임 인자 검사라서 `--check-only`도
`ops/check.sh gd`(파싱만 확인)도 잡지 못하고, 그 스크립트를 참조하는 다른 씬을
로드하는 순간(`Compile Error: Failed to compile depended scripts`) 무관해 보이는
곳에서 실패가 튄다.

**해결:** 모노도 스테레오 인터리브(`Vector2(l, r)`)로 채워 넣는다. 모노만
필요하면 좌우에 같은 값을 넣는다:
```gdscript
var stereo := PackedVector2Array()
stereo.resize(mono.size())
for i in mono.size():
    stereo[i] = Vector2(mono[i], mono[i])
playback.push_buffer(stereo)
```

## GDT-033 — `--script X.gd`(SceneTree 대체) 모드는 `_init()`에서 오토로드가 아직 없다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** 헤드리스 검사용으로 `extends SceneTree`인 스크립트를 `--script`로 돌리면서
시작 로직을 생성자 `_init()`에 넣으면, `project.godot`의 오토로드(예: `MarsNet`)를
참조하는 스크립트를 `load()`할 때마다 `SCRIPT ERROR: Compile Error: Identifier not
found: MarsNet`로 깨진다. 같은 프로젝트를 `--check-only`(일반 기동 경로)로 검사하면
멀쩡히 통과한다 — 오토로드가 문제가 아니라 **`_init()`이 엔진의 오토로드 등록보다
먼저 실행된다**는 것이 문제다. 커스텀 메인루프가 엔진 자체 시작 절차를 대체하기
때문에, 오토로드는 여전히 나중에 등록되지만 그 시점을 `_init()`이 이미 지나쳐
버린다.

**해결:** 시작 로직을 `_init()`이 아니라 `_initialize()`(엔진이 오토로드까지 끝낸
뒤 호출하는 가상 함수)에 넣는다. `_initialize()`로 옮기기만 하면 같은 스크립트가
같은 씬을 오류 없이 로드한다.

## GDT-034 — `git archive HEAD` 스냅샷은 `.godot/` 캐시가 없어 첫 헤드리스 실행이 전역 클래스를 못 찾는다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** `git archive HEAD | tar -x`로 만든 스냅샷 위에서 바로
`--headless --path client --check-only`(또는 다른 헤드리스 검사)를 돌리면
`class_name`으로 선언한 전역 클래스(`NakamaLogger`·`MarsConfig` 등)를 "Identifier
not found"·"Could not find type"로 못 찾는다. 원인은 `.godot/`(임포트·전역 클래스
캐시)가 `.gitignore` 대상이라 아카이브에 없다는 것 — 오래 써 온 실제 작업 트리에는
이 캐시가 이미 있어서 같은 증상이 재현되지 않는다.

**해결:** 검사를 돌리기 전에 헤드리스 임포트를 한 번 먼저 실행해 캐시를 만든다:
```
"$GODOT" --headless --path <snapshot>/client --import --quit
```
이후 같은 스냅샷에서 돌리는 모든 헤드리스 검사가 정상 동작한다.

## GDT-035 — 새 `class_name`은 전역 클래스 캐시를 다시 만들기 전까지 자기 파일 안에서도 못 쓴다

`측정 2026-09-07 · Godot 4.7.2`

**증상:** `class_name MarsThoughtBubble`을 선언한 새 스크립트를 `--headless`로 실행하면
`Parse Error: Could not find type "MarsThoughtBubble" in the current scope.`,
같은 파일 안의 `MarsThoughtBubble.new()`에서도 `Compile Error: Identifier not found`.
`--check-only` 파싱은 통과하고 씬 로드에서만 깨진다. 파일을 만든 직후, 에디터를 한 번도 열지 않은 상태.

`class_name` 등록은 파서가 아니라 `<project>/.godot/global_script_class_cache.cfg`가 한다.
헤드리스 실행은 이 캐시를 읽기만 하고 갱신하지 않는다. 캐시는 보통 `.gitignore` 대상이라
새 기계·새 CI 컨테이너에서도 같은 증상이 난다.

**해결:** 파일을 만든 뒤 한 번 `godot --headless --path <project> --editor --quit`을 돌린다.
전체 임포트 스캔이 돌면서 캐시에 항목이 들어가고 그 뒤로는 정상이다.
다른 스크립트에서 그 타입을 참조해야 할 이유가 없다면 `preload("res://...")`로 받는 편이
캐시 상태와 무관하게 동작한다.

## GDT-036 — 콜드 `.godot`은 빈 캐시가 아니라 깨진 프로젝트다 — `class_name` 타입이 전부 미해결이 되고 오토로드가 안 뜬다

`측정 2026-09-08 · Godot 4.7.2 · macOS 26.3`

**증상:** `.godot`을 제외하고 프로젝트를 새 기계로 복사한 뒤 첫 `--headless --path client --quit`이
이렇게 죽는다. 파일은 전부 멀쩡하고 같은 트리가 원래 기계에서는 통과한다.

```
SCRIPT ERROR: Parse Error: Could not find type "RpcResult" in the current scope.
SCRIPT ERROR: Parse Error: Could not resolve external class member "rpc_async".
ERROR: Failed to instantiate an autoload, script 'res://core/net/nakama_client.gd' does not inherit from 'Node'
WARNING: ext_resource, invalid UID: uid://ch6vw6uy3oac3 - using text path instead
```

`class_name`으로 선언한 전역 타입은 소스가 아니라 `.godot/global_script_class_cache.cfg`에서
해석된다. 그 파일이 없으면 **모든** `class_name` 타입이 미해결이고, 그래서 오토로드가 `Node`를
상속하지 않는다는 엉뚱한 말이 나온다. 실행 중에 저절로 복구되지 않는다 — 캐시는 임포트 단계에서만 쓰인다.

**해결:** 실행 전에 임포트를 한 번 돌린다. 3.2초, 기계당 1회다(캐시가 남으므로).

```sh
[ -f client/.godot/global_script_class_cache.cfg ] || godot --headless --path client --import
```

rsync로 트리를 보낼 때 `--exclude .godot`을 걸어도 캐시는 안전하다 — rsync는 제외한 경로를
`--delete` 후보로 삼지 않으므로 한 번 만들어지면 이후 증분 동기화에서 살아남는다.

## GDT-037 — 상시 HUD의 `_draw()` 프리미티브 1개가 프레임 드로우콜 약 2.5개다
`측정 2026-09-08 · Godot 4.7.2 · gl_compatibility · 900x700`

**증상:** 3D 장면 위에 `Control._draw()`로 아이콘 하나를 그렸더니
`RenderingServer.viewport_get_render_info(..., RENDER_INFO_TYPE_VISIBLE,
RENDER_INFO_DRAW_CALLS_IN_FRAME)`가 13 늘었다. 2D는 배칭되니 도형 몇 개는 공짜라고
보고 예산을 잡으면 여기서 어긋난다.

**사실:** 같은 아이콘을 세 가지로 그려 같은 장면(3D 몫 175 고정)에서 잰 값이다.
프리미티브 8개(`draw_circle` + `draw_arc` x3 + `draw_rect` x2 + `draw_line` +
`draw_string`) = 프레임 **263**, 4개(`draw_circle` + `draw_colored_polygon` x2 +
`draw_string`) = **253**, 2개(`draw_circle` + `draw_colored_polygon`) = **252**.
비용은 개수에 비례하지 않는다 — 8에서 4로 줄일 때 10이 빠졌고 4에서 2로 줄일 때는
1뿐이었다. 비싼 쪽은 `draw_arc`(폴리라인)와 `draw_string`이고, `draw_circle`과
`draw_colored_polygon`은 거의 공짜다. 종류가 다른 프리미티브는 서로 다른 배치라
연속으로 불러도 합쳐지지 않는다.

**해결:** 윤곽선(`draw_arc`/`draw_line`) 여러 겹과 상시 `draw_string`을 없애고,
노치를 판 채움 폴리곤 하나로 실루엣을 만든다. 글자는 항상 보일 필요가 없으면
열렸을 때만 그린다. 프리미티브 8개 → 2개로 프레임 11개를 되찾았다. 도형 개수를
세지 말고 **종류를 세라** — 줄일 것은 개수가 아니라 배치 전환이다.

## GDT-038 — nakama-godot의 validate_subscription은 결제창을 띄우지 않는다 — 영수증을 만드는 플러그인은 따로 필요하다

`측정 2026-09-08 · nakama-godot master 7549fea8 · Godot 4.7.2`

**증상:** `NakamaClient.gd`에 `validate_subscription_apple_async`(1002) ·
`validate_subscription_google_async`(1014) · `get_subscription_async`(411) ·
`list_subscriptions_async`(690)가 다 있어서 클라 결제가 끝났다고 보게 된다.
아니다. 이 함수들의 인자는 전부 `p_receipt : String`이다 — **영수증을 이미
가지고 있다고 전제하는 전송 함수**다.

영수증을 만들려면 Google Play Billing / StoreKit을 호출해야 하고, Godot 4에는
그 기능이 엔진에 없다. 안드로이드는 `.aar` + `.gdap` 네이티브 플러그인,
iOS는 별도 플러그인이 있어야 한다. nakama-godot는 이것을 제공하지 않는다.

**해결:** 결제 작업을 잡을 때 클라 항목을 둘로 나눈다 — (1) 스토어 결제창을
띄워 영수증을 얻는 네이티브 플러그인(직접 빌드 또는 외부 도입), (2) 그 영수증을
`validate_subscription_*_async`로 서버에 넘기기. (2)만 보고 일정을 잡으면
실제 작업량을 놓친다. 검증·저장은 서버가 하므로(NKM-022) 남는 위험은 전부 (1)이다.

## GDT-039 — Play Billing 구독은 3일 안에 acknowledge하지 않으면 Google이 자동 환불한다 — Nakama 검증은 이것을 하지 않는다

`측정 2026-09-08 · Play Billing Library 7.1.1 · Nakama 3.40`

**증상:** 구독 결제가 성공하고 서버 검증(`validateSubscriptionGoogle`)도 통과했는데
3일 뒤 결제가 조용히 환불된다. 로그에는 아무 에러도 없다. 구매 시점에는 정상으로
보이므로 테스트에서 잡히지 않고, 라이선스 테스터 계정은 갱신 주기가 짧아 더 안 보인다.

Play Billing은 구매를 앱이 **명시적으로 인수(acknowledge)** 해야 확정한다. 구독·비소모성
상품 모두 대상이고, 유예는 3일이다. 그 안에 `BillingClient.acknowledgePurchase`가
호출되지 않으면 Google이 자동으로 환불하고 구독을 취소한다.

**Nakama의 `validateSubscriptionGoogle`은 acknowledge를 하지 않는다.** 서버는 Google
Play Developer API로 영수증을 조회해 판정만 하고, 인수는 클라이언트 SDK 몫으로 남긴다.
서버 검증을 붙였다는 것과 결제가 확정됐다는 것은 별개다.

구독은 `consumeAsync` 대상이 **아니다**. 소모성 결제 예제를 그대로 따라 쓰면 여기서
틀린다 — 구독에 필요한 것은 consume이 아니라 acknowledge 한 번이다.

**해결:** 서버 검증이 성공한 **뒤에만** `acknowledgePurchase(purchaseToken)`을 부른다.
순서가 반대면 서버가 거부한 영수증을 앱이 인수했다고 스토어에 알리게 된다.
인수 실패는 반드시 에러 레벨로 남긴다 — 조용히 실패하면 3일 뒤 환불로만 드러난다.

## GDT-040 — Play Billing 8.0이 queryProductDetailsAsync 콜백 시그니처를 바꿨다 — 7.x에 고정한다

`측정 2026-09-08 · Play Billing Library 7.1.1 / 8.0.0 · Kotlin 2.1.21 · AGP 8.6.1`

**증상:** 버전을 최신으로 올리면 플러그인이 컴파일되지 않는다. 에러는 콜백 람다의
인자 개수 불일치로 나와서 Kotlin 문제처럼 읽힌다.

7.x의 `queryProductDetailsAsync`는 `(BillingResult, List<ProductDetails>)`를 주는
`ProductDetailsResponseListener`를 받는다. 8.0은 그 두 번째 인자를
`QueryProductDetailsResult` 한 객체로 바꿨다. 라이브러리 버전만 올려도 호출부가 깨진다.

7.0부터 인자 없는 `enablePendingPurchases()`도 폐기됐다. `PendingPurchasesParams`를
넘겨야 하고, 구독 선불 요금제를 받으려면 `enablePrepaidPlans()`가 필요하다. 빠뜨리면
컴파일이 아니라 **런타임에 빌더가 던진다**.

**해결:** `gradle.properties`에 버전을 한 곳으로 적고(`billingVersion=7.1.1`) `.gdap`의
`remote=` 항목과 같은 값을 쓴다. 플러그인은 그 버전으로 컴파일되고 앱은 그 버전을
Maven에서 받으므로, 둘이 어긋나면 "플러그인이 로드되지 않는다"로만 보인다.
버전을 올릴 때는 위 두 호출부를 같이 고친다.

## GDT-041 — `PrimitiveMesh`에는 `surface_get_format`이 없고, 실패가 조용히 형상을 먹는다
`측정 2026-09-08 · Godot 4.7.2 · gl_compatibility`

**증상:** `SurfaceTool.append_from`으로 메시를 병합해 드로우콜을 줄였는데 삼각형 수가 같이 줄었다
(86650 → 85844). 화면은 얼추 비슷해서 눈으로는 못 잡는다. 병합 대상을 `surface_get_format(0)`으로
묶어 포맷이 섞이지 않게 했는데도 그렇다.

**해결:** `surface_get_format`은 `ArrayMesh`의 메서드다. `CylinderMesh`·`SphereMesh` 같은
`PrimitiveMesh`에 부르면 런타임 에러(`Invalid call. Nonexistent function 'surface_get_format' in
base 'CylinderMesh'`)를 찍고 **null을 돌려주며 실행은 계속된다.** `int(null)`은 0이라 모든 프리미티브가
같은 키로 묶이고, UV 있는 면과 없는 면이 한 `SurfaceTool`에 들어가 `append_from`이 서피스를 **말없이
버린다.** `Mesh.surface_get_arrays(0)`은 두 종류 모두에서 되고, 슬롯이 null인지 아닌지의 비트열이
그대로 포맷 키가 된다. 병합 뒤 `RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME`이 전후로 같은지 반드시 본다 —
드로우콜만 보면 형상이 사라진 것이 개선으로 보인다.

## GDT-046 — 한두 프레임만 떠 있는 오버레이는 "다 끝나고 N프레임 뒤에 찍는" 스크린샷 훅으로는 안 찍힌다
`측정 2026-09-08 · Godot 4.7.2 · gl_compatibility · 창 720x1280`

**증상:** 씬에 범용 `--shot <path>` 훅이 있고(큐에 쌓인 합성 입력을 다 실행한 뒤 여섯 프레임 기다렸다가
`get_viewport().get_texture().get_image()`), 드래그처럼 **두 프레임만 존재하는** 오버레이를 찍으면
배경만 나온다. `Input.parse_input_event`로 합성한 드래그는 begin → `await get_tree().process_frame`
→ release라서, 훅이 깨어날 때는 오버레이가 이미 사라진 뒤다. 에러도 경고도 없고 PNG는 정상 크기로
저장되므로, 파일이 생겼다는 것만 보면 통과로 오해한다.

**해결:** 찍는 주체를 훅이 아니라 **그리는 노드 자신**으로 옮기고, 그 노드가 `queue_redraw()`를 부른
바로 그 자리에서 `await RenderingServer.frame_post_draw`를 기다린다. 한 프레임 안의 순서가
idle(`process_frame`) → draw → `frame_post_draw`이므로, idle 중에 `queue_redraw()`한 것은 **같은
프레임의 `frame_post_draw`에서 읽힌다** — 다음 `process_frame`(= 합성 release가 오는 시점)보다 앞선다.
읽어내는 동안 노드가 숨겨지지 않도록 가시성을 잡아 두면 경합이 남지 않는다. 이렇게 찍은 결과가
`720x1280 err=0`, 613KB(빈 프레임은 그보다 훨씬 작다). 판정은 **파일 존재가 아니라 최소 바이트 수**로
건다 — 배경만 든 PNG도 err=0으로 저장되기 때문이다.
`--headless`에서는 3D가 렌더되지 않으므로 이 촬영은 창 모드 전용이다.

## GDT-042 — 드로우콜은 메시 1개당 1, 그림자를 켜면 2다
`측정 2026-09-08 · Godot 4.7.2 · gl_compatibility · DirectionalLight3D 1개`

**증상:** 예산을 짤 때 "메시를 줄이면 얼마나 주는가"를 추정으로 잡게 된다.

**해결:** 그룹별로 `visible`을 껐다 켜며 잰 결과가 정확히 1:1이다 — 그림자를 끈 그룹은 메시 수와
드로우콜이 같고(`link` 10메시 10콜, `clutter` 10/10, `masts` 6/6), 그림자를 켠 그룹은 두 배다
(`warehouse` 10메시 20콜, `dome` 7/14). 그래서 **감축은 메시 개수 산수**로 계산할 수 있다.
같은 머티리얼끼리 묶어 100메시를 66으로 줄이자 콜로니 몫이 175 → 137로 떨어졌다.
주의: `RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`을 `visible` 토글 직후 **한 프레임만** 읽으면
그림자 캐스케이드가 dirty해진 프레임을 잡아 값이 부풀고, 그룹 델타의 합이 프레임 총합을 넘긴다
(332 대 252). 5프레임을 읽어 **최솟값**을 쓰면 합이 맞는다.

## GDT-045 — rsync로 옮긴 트리에서 새 `class_name`은 "Could not find type"이 된다 — 에디터가 돈 적 없는 기계의 전역 클래스 캐시는 갱신되지 않는다

`측정 2026-09-08 · Godot 4.7.2 · headless`

**증상:** 로컬에서 파싱이 통과한 스크립트가 다른 기계(원격 스모크 러너)에서만
`Parse Error: Could not find type "MyClass" in the current scope.`로 죽는다.
같은 파일, 같은 Godot 버전인데 한쪽만 실패한다.

`class_name`은 파일에 쓴다고 등록되지 않는다. 등록처는
`.godot/global_script_class_cache.cfg`이고, 이 파일은 **에디터 임포트**가 채운다.
헤드리스 실행(`--headless --path`)은 채우지 않는다. 그래서 에디터가 한 번도 돈 적
없는 기계로 트리를 rsync하면, 그 트리의 새 `class_name`은 어디에도 등록되어 있지
않고 참조하는 순간 전부 파싱 에러가 된다.

더 나쁜 조합: 캐시 파일이 **이미 있고 새 클래스만 빠진** 경우. `--import`를 캐시
부재로만 트리거하는 스크립트는 이때 재임포트를 건너뛰므로 그 타입이 영원히 안 잡힌다.

**증상이 남에게 번진다.** 미커밋 상태로 트리에 있는 새 `class_name` 파일 하나가,
그 파일과 무관한 남의 스모크를 같은 에러로 죽인다 — 원격 러너는 트리 전체를 받는다.

**해결:** 기계를 넘나드는 코드에서는 `class_name`에 의존하지 않는다.
`const X := preload("res://path/to/file.gd")` 후 `X.new()`가 캐시와 무관하게 항상 된다.
타입 주석도 전역 이름 대신 `Node3D` 같은 내장 타입으로 쓴다.
캐시를 고치는 쪽으로 가려면 `--import`를 캐시 유무가 아니라 **매 동기화마다** 돌려야
한다(측정 3초).

## GDT-047 — gdUnit4 CI 러너는 로드 실패한 스위트를 조용히 건너뛰고 exit 0을 낸다 — "게이트 초록"이 "테스트가 돌았다"를 뜻하지 않는다

`측정 2026-09-12 · Godot 4.7.2-stable · gdUnit4 v6.2.1`

**증상:** `godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests`가 exit 0인데, 테스트 5개짜리
스위트가 실행 목록에 없다. 그 파일은 `var p := monitor_signals(...)`의 `:=` 추론 실패로 파스 에러였고,
러너는 `Failed to load script ... Parse error`를 stderr에 찍고 **다음 스위트로 넘어간다**. 검증 세션과
리더 모두 PASS를 믿고 티켓을 닫았다. 나중에 타입을 명시해 파스가 되자 그 안의 테스트 2개가 실패 상태였음이 드러났다.

**해결:** 게이트가 exit code만 보지 않게 한다. 출력의 ANSI 코드를 벗기고 `Executed test cases : (N/M)`·
`Executed test suites : (N/M)`을 파싱해 N이 0이면 FAIL, 실행 스위트 수가 `client/tests` 아래
`test_*.gd`/`*_test.gd` 파일 수보다 적어도 FAIL. PASS 줄에 `(6 cases / 2 suites)`처럼 수를 찍어 눈으로도 보이게 한다.
검증: `GdUnitTestSuite`를 상속하지 않는 `test_x.gd`를 넣으니 러너는 exit 0, 게이트는 "3개 중 2개만 실행"으로 exit 1.

---

## GDT-048 — gdUnit4 시그널 테스트가 두 번 속인다: 람다 카운터는 값 캡처라 0에 머물고, `is_emitted("sig")`는 인자 실린 emit을 못 잡는다

`측정 2026-09-12 · Godot 4.7.2-stable · gdUnit4 v6.2.1`

**증상 1:** `var n := 0; obj.connected.connect(func() -> void: n += 1)` 뒤 `await assert_signal(obj).is_emitted("connected")`는
통과하는데 `assert_int(n).is_equal(1)`은 0이다. 시그널은 실제로 1회 났다. GDScript 람다는 바깥 지역 변수를
**값으로 캡처**해서 `n += 1`이 람다 안 사본만 바꾼다. 프로덕션 코드를 의심하며 `RefCounted`의 `call_deferred`까지 뒤졌다.

**증상 2:** `disconnected.emit("null provider")`처럼 인자를 실어 보내는 시그널에 `is_emitted("disconnected")`를 쓰면
매칭이 안 돼 실패한다. 인자 없는 호출은 인자 없는 emit만 잡는다.

**해결:** 카운터는 참조형으로 — `var hits: Array[int] = [0]` 뒤 람다에서 `hits[0] += 1`. "정확히 1회"는
`is_emitted` 뒤 `is_not_emitted`(`wait_until` 100ms)로 잡는다. 인자 있는 시그널은 `is_emitted("disconnected", "null provider")`.
이 두 실패가 GDT-047의 파스 에러 뒤에 숨어 있었다 — 게이트가 돌지 않으면 잘못 쓴 테스트도 초록이다.

---

## GDT-049 — godot-livekit 오디오 publish는 프레임 계약을 어기면 GDScript로 못 잡는 네이티브 SIGABRT로 프로세스가 죽는다

`측정 2026-09-12 · Godot 4.7.2-stable · godot-livekit v0.3.3 (44f0aa7) · client-sdk-cpp v0.3.1`

**증상:** `LiveKitAudioSource`를 publish한 뒤 `capture_frame()`이 제때 안 들어오면
`RtcError: InvalidState - failed to capture frame` 뒤 Godot 프로세스 전체가 SIGABRT. C++ 미처리 예외라
`try/catch`도 시그널도 없다. 창 드래그·씬 로딩·GC로 메인 스레드가 20ms 멈추는 순간 클라이언트가 통째로 날아간다.

SDK 헤더(`livekit/audio_source.h`)의 계약: `queue_size_ms=0`(direct 모드, 하드웨어 마이크 권장)은 **정확히 10ms
프레임만** 받는다. `>0`(버퍼 모드)은 20ms 안에 콜백을 못 받으면 던진다. 크래시는 콜드 스타트에 빈 채로
publish하고 크기가 안 맞는 프레임을 넣은 **우리 호출 실수**였다. 업스트림 `livekit/client-sdk-cpp#44`의 같은
증상은 이미 패치돼 v0.3.1에 포함돼 있다(git ancestor 확인) — 즉 SDK 버그가 아니다.

**해결:** `queue_size_ms=0`, 첫 마이크 프레임을 받은 **뒤에** publish, 10ms 고정 청크(48kHz면 480 샘플)로
잘라 넣기, 피딩을 전용 `Thread`로. 검증은 `OS.delay_msec(1500)`으로 메인 스레드를 강제로 멈춰도 살아남는지로
한다 — GUI 2프로세스 실제 마이크·스피커 15초 무크래시. 예외는 호출 스레드에서 동기적으로 던져지므로
벤더링한 wrapper에 try/catch 몇 줄을 넣는 패치도 가능하지만, 계약을 맞추는 쪽이 먼저다.

---

## GDT-050 — `audio/driver/enable_input`은 런타임 `ProjectSettings.set_setting()`으로 켜지지 않는다 — `project.godot`에 있어야 한다

`측정 2026-09-12 · Godot 4.7.2-stable · macOS CoreAudio`

**증상:** 스크립트에서 `ProjectSettings.set_setting("audio/driver/enable_input", true)` 뒤 `AudioEffectCapture`를
붙이면 `input_unit is null` 에러가 나고 마이크 프레임이 0이다. 값은 바뀌었다고 나오지만 오디오 드라이버는
프로세스 시작 시 이미 초기화돼 있어 입력 유닛을 만들지 않는다.

**해결:** `client/project.godot`의 `[audio]` 절에 `driver/enable_input=true`를 박는다. 공유 파일이라 티켓
범위 확장 승인이 필요했다 — 마이크를 쓰는 티켓은 처음부터 이 파일을 범위에 넣는다. macOS는 최초 실행 시
마이크 권한 팝업이 뜰 수 있고, 허용 후 재실행해야 한다.

---

## GDT-051 — `NodotProject/godot-cpp-builds` 프리빌트 릴리스의 `bin/`이 비어 있다 — 체크섬은 맞고 아티팩트 자체가 결함이다

`측정 2026-09-12 · Godot 4.7.2-stable · godot-livekit v0.3.3 · godot-cpp-builds godot-4.5-stable · macOS arm64`

**증상:** godot-livekit `build.sh macos`가 프리빌트 `godot-cpp-prebuilt-*.zip`을 받아 링크 단계에서
실패한다. 다운로드 손상을 의심해 체크섬을 대조했는데 일치한다 — 릴리스 zip 안의 `bin/`이 원래 비어 있다.

**해결:** `godot-cpp/` 서브모듈을 직접 `scons platform=macos target=template_release arch=arm64`로 빌드한 뒤
`build.sh`가 그 산출물을 쓰게 한다. 다른 플랫폼에서 같은 증상이면 같은 방법. 벤더링할 때 빌드 SHA와
이 우회를 `docs/versions.md`에 적어 두지 않으면 다음 사람이 체크섬부터 다시 의심한다.
부수 관찰: 이 GDExtension이 로드된 콜드 `.godot` 상태에서 `godot --headless --editor --quit-after 1`은 세그폴트가
난다(에디터 스캔 스레드 경합 추정). `--editor --quit`과 `--import`는 문제없다. GDT-017·GDT-036과 함께 걸린다.

---

## GDT-052 — 코루틴을 `await` 없이 불러 나온 Signal을 레이스시키는 방법은 없다 — 항상 `await`를 강제한다

`측정 2026-09-12 · Godot 4.7.2-stable`

**증상:** RPC를 데드라인 타이머와 레이스시키려고 `var pending = socket.rpc_async(name, payload)`처럼
`await` 없이 호출해 대기 중인 Signal을 받으려 했다. 같은 스크립트 안의 코루틴을 이렇게 부르면 파스 에러
(`Function "x()" is a coroutine, so it must be called with "await"`)가 난다. `Callable(obj,
"method").call()`로 정적 분석을 피해도 런타임 에러(`Trying to call an async function without
"await"`)로 막힌다. GDT-022가 적어 둔 "`rpc_async()`를 타이머와 나란히 `await`해 먼저 끝나는 쪽을 잡는다"는
요약은 실제 동작하는 GDScript 코드가 아니라 개념 설명이었다 — Godot에는 `Promise.race`가 없고, 코루틴을
안 기다리고 핸들만 받는 길 자체가 막혀 있다.

**해결:** 호출을 감싼 코루틴 메서드를 만들어 결과를 직접 선언한 시그널로 `emit`하고, 그 메서드 자체는
`call_deferred`로 fire-and-forget 실행한다(`call_deferred`는 코루틴 여부와 무관하게 항상 허용된다 —
반환값을 안 쓰는 defer라 "부르고 기다리기"가 아니다). 레이스는 그 커스텀 시그널과
`get_tree().create_timer(seconds).timeout`을 각각 `CONNECT_ONE_SHOT`으로 콜백에 연결해 두고,
`while not resolved: await get_tree().process_frame`로 먼저 온 쪽의 플래그를 잡을 때까지 프레임 단위로
폴링해서 얻는다. 타임아웃 쪽이 먼저 울면 뒤늦게 끝난 원래 호출의 `emit`은 아무도 안 듣는 채로 조용히
버려진다 — 크래시도, 좀비 대기도 없다. `RefCounted` 헬퍼 하나(시그널 1개 + `run()` + `_invoke()`)로
`rpc_async`·`join_match_async` 양쪽에 재사용했다. 스탠드얼론 Godot 프로젝트로 fast/slow/timeout 세 케이스를
`--headless`로 직접 돌려 검증했다(`client/src/net/net_deadline.gd`, T-005).

---

## GDT-053 — GDExtension 타입을 `ClassDB.class_call_static`/`class_get_integer_constant`로 문자열 참조하면 확장 없는 플랫폼에서도 파싱된다

`측정 2026-09-12 · Godot 4.7.2-stable`

**증상:** godot-livekit 같은 GDExtension은 플랫폼별 바이너리만 있다(예: macOS arm64뿐, Linux 미제공).
스크립트에 `var x: LiveKitRoom`처럼 정적 타입으로 쓰거나 `LiveKitAudioSource.create(...)`·
`LiveKitTrack.KIND_AUDIO`처럼 클래스명을 식별자로 직접 참조하면, 확장이 로드되지 않는 플랫폼(CI Linux
러너)에서 `Parse Error: Could not find type "LiveKitAudioSource"` / `Identifier "LiveKitRoom" not
declared in the current scope`로 그 스크립트를 의존하는 모든 스크립트까지 컴파일이 통째로 깨진다.
`ClassDB.class_exists()`로 방어해도, 정적 타입 주석이나 `ClassName.static_method()` 형태의 식별자
참조 자체가 남아 있으면 파서가 그 시점에 이미 실패한다.

**해결:** 모든 GDExtension 클래스 참조를 문자열 기반으로 바꾼다.
- 생성자: `ClassDB.instantiate("LiveKitRoom")` (변수 타입은 `Object`로 선언)
- static 팩토리 메서드(godot-livekit의 `.create()`, `.from_track()` 등, `flags` 비트 32=STATIC):
  `ClassDB.class_call_static("LiveKitAudioSource", "create", mix_rate, channels, queue_ms)`
- 정수 상수(`enum` 멤버, 예: `LiveKitTrack.KIND_AUDIO`):
  `ClassDB.class_get_integer_constant("LiveKitTrack", "KIND_AUDIO")`
- 인스턴스 메서드·시그널(`room.connected.connect(...)`, `room.get_local_participant()`)은 변수가
  `Object` 타입이면 정적 검사를 안 받고 런타임에 동적 디스패치된다 — 이건 그대로 써도 파싱이 깨지지
  않는다. 문제는 오직 "클래스명 자체를 식별자로 쓰는" 경우(타입 주석·static 호출·상수 접근)뿐이다.

`ClassDB.class_exists("LiveKitRoom")`로 먼저 가드하면 확장 없는 플랫폼에서 `false`를 받아
정상적으로 `ERR_UNAVAILABLE` 등을 리턴할 수 있다. `godot-livekit.gdextension`이 해당 플랫폼 라이브러리
경로를 선언하지 않았거나 파일이 없으면 로드만 조용히 실패하고(경고 로그는 남는다) `ClassDB`에 클래스가
등록되지 않을 뿐, 스크립트 파싱 자체는 막지 않는다. macOS(확장 있음)에서
`ClassDB.class_call_static("LiveKitAudioSource", "create", 48000, 1, 0)`이 실제 인스턴스를
반환하는 것으로 직접 확인했고, 확장 디렉터리를 통째로 옮겨 없앤 상태로 `gdunit4` 게이트가 그대로 PASS하는
것도 확인했다(`client/src/voice/livekit_voice_provider.gd`, T-016).

## GDT-054 — 람다가 캡처한 지역 `int`/`bool`은 값 복사라 `.call()`을 반복해도 증가하지 않는다

`측정 2026-09-13 · Godot 4.7.2-stable`

**증상:** 재시도 루프를 헤드리스 테스트로 돌리려고 `var attempts := 0`과
`var login_fn := func() -> int: attempts += 1; return OK if attempts >= 3 else FAILED`를 같은
함수 안에 선언하고, 그 `login_fn`을 `await`가 있는 다른 함수(`retry.run(login_fn, ...)`)에 넘겨 반복
호출했다. 매번 "attempts=1"만 찍히며 `attempts >= 3` 조건이 영원히 거짓이 되어 무한 루프 —
`while true` 안에서 `await`로 매 반복 양보하니 크래시도 안 나고 그냥 CPU를 100% 쓰며 몇 분이고 멈춘
것처럼 보인다(gdUnit4 CLI 러너에서 특정 테스트 하나가 몇 분째 STARTED에서 안 넘어가는 형태로 드러남).
`await`가 있는 코루틴 함수의 지역 변수라서 그런가 싶었지만, 실제 원인은 그것과 무관하다.

**해결:** GDScript 람다는 바깥 지역 변수의 **현재 값**을 캡처 시점에 복사해 자신만의 클로저 상태로
가진다 — 같은 `Callable`을 여러 번 `.call()`해도 그 클로저 안에서는 값이 누적되지만(람다 인스턴스
자체는 하나), 바깥의 원본 변수는 절대 갱신되지 않는다. 이 케이스가 다른 건: 람다를 딱 한 번만 만들고
그 하나의 인스턴스를 계속 재호출했는데도 값이 안 늘어난 것 — 클로저가 캡처하는 게 변수 슬롯이 아니라
매 정의 시점 스냅샷이기 때문에, 함수가 코루틴이라 재진입/재개되는 경로에서 람다 리터럴 라인이 다시
평가되면 캡처가 매번 새로 초기화된다. 원시 타입(`int`, `bool`, `String`) 카운터는 `Array`나
`Dictionary`(참조 타입)에 담아 `box[0] += 1`처럼 인덱스로 접근해야 여러 호출에 걸쳐 상태가 실제로
누적된다. `assert_int`/`assert_bool`로 재시도 횟수를 검증하는 gdUnit4 테스트를 작성할 때 특히
잘 걸린다(`client/src/main/boot_login_retry.gd`, T-028).

## GDT-055 — macOS export는 project.godot에 `import_etc2_astc=true` 없으면 arm64/universal에서 거부된다

`측정 2026-09-13 · Godot 4.7.2-stable`

**증상:** `godot --headless --export-release "macOS" ...`가 파일 하나 안 건드리고 바로
`ERROR: Cannot export project with preset "macOS" due to configuration errors: ETC2 ASTC 텍스처
형식이 비활성화된 경우 universal 또는 arm64용으로 내보낼 수 없습니다`로 실패한다. 프로젝트에
텍스처 리소스가 하나도 없어도 발생한다.

**해결:** `project.godot`의 `[rendering]` 섹션에 `textures/vram_compression/import_etc2_astc=true`
한 줄을 추가한다(에디터 GUI로는 렌더링 > 텍스처 > VRAM 압축 > ETC2 ASTC 가져오기). 이 검사는
Apple Silicon(arm64) 타깃 자체에 걸려 있어 `binary_format/architecture`를 `arm64`로 좁혀도,
텍스처를 안 써도 피할 수 없다. `export_presets.cfg`만 새로 만드는 티켓에서는 이 project setting이
빠져 있어 처음 export 시도에서 막히기 쉽다(`client/export_presets.cfg`, T-056).

## GDT-056 — macOS "universal" export는 GDExtension의 arm64·x86_64 슬라이스를 둘 다 요구하고, 없으면 조용히 크래시한다

`측정 2026-09-13 · Godot 4.7.2-stable`

**증상:** 공식 Godot 4.7 macOS export 템플릿(`macos.zip`)은 `godot_macos_release.universal`
하나만 들어있다 — arm64 전용 템플릿은 애초에 없다(`binary_format/architecture="arm64"`로 좁히면
`요청한 템플릿 바이너리 "godot_macos_release.arm64"을(를) 찾을 수 없습니다`로 즉시 실패).
그래서 macOS export는 사실상 항상 `architecture="universal"`이어야 하는데, 그 상태에서 프로젝트가
쓰는 GDExtension이 macOS arm64 슬라이스만 벤더링되어 있으면(x86_64 없음) export 후반
"앱 번들 생성" 단계에서 `ERROR: Failed to open '.../libgodot-livekit.macos.x86_64.dylib'`를
찍고, 그 직후 Godot 에디터 프로세스 자체가 `signal 11`로 죽는다(export 결과 pck는 이미 만들어져
있어서 절반만 완성된 것처럼 보임 — 실제로는 export 실패로 처리됨).

**해결:** universal 바이너리 자체는 그대로 두고, `.gdextension` 파일의 `[libraries]`·
`[dependencies]`에서 실제 벤더링 안 된 아키텍처 항목(`macos.x86_64` 등, 파일 없는 선언)을 지운다.
그러면 universal Godot 실행 파일에 arm64 슬라이스의 GDExtension만 들어가고, Intel Mac에서
실행하면 그 확장 기능만 조용히 비활성(`ClassDB.class_exists`로 감지 가능, [[GDT-016]] 참고)된
채로 나머지는 정상 동작한다. Windows·Linux처럼 애초에 안 만든 플랫폼도 같은 이유로 `.gdextension`에서
지워야 export가 그 플랫폼에서 통과한다(`client/addons/godot-livekit/godot-livekit.gdextension`,
T-056).

## GDT-057 — 헤드리스 export는 macOS/Windows 프리셋을 크로스 export한 뒤, 성공한 export와 무관하게 exit 134로 죽을 수 있다

`측정 2026-09-13 · Godot 4.7.2-stable`

**증상:** GitHub Actions `ubuntu-latest` 러너에서 `godot --headless --export-release "macOS" ...`,
`"Windows Desktop"` 둘 다 로그에 `savepack` 100%와 `[ DONE ] export`가 정상적으로 찍히고 나서
`Aborted (core dumped)`로 죽고 종료 코드 134(SIGABRT)를 낸다. 같은 프로젝트를 실제 macOS 머신에서
네이티브로 export하면(같은 Godot 4.7.2.stable, 같은 export_presets.cfg) exit 0이고 크래시가 없다
— 즉 export 로직 자체의 문제가 아니라 리눅스 호스트에서 macOS/Windows 프리셋을 크로스 export할 때
엔진 종료 단계에서만 나는 크래시로 보인다. `[ DONE ] export` 시점에 pck·바이너리는 이미 디스크에
쓰여 있다.

**해결:** 확정된 원인은 아직 없음 — 크로스 export 종료 크패시의 재현 조건을 리눅스 환경에서
직접 잡지는 못했다(증거는 CI 로그뿐). 실무 대응은 CI가 종료 코드를 그대로 신뢰하지 않고, exit 134여도
산출물(macOS는 `.app/Contents/MacOS/<실행파일>` 존재+비어있지 않음, Windows는 `.exe`+`.pck` 존재+비어있지
않음)을 직접 검사해 있으면 성공으로 친다. 산출물이 없으면 그대로 exit 1(`scripts/ci/export-client.sh`, T-094).

## GDT-058 — 안드로이드 Godot LineEdit은 `adb shell input keyevent KEYCODE_DEL`을 받지 않는다

`측정 2026-09-14 · Godot 4.7.2-stable, Pixel 7 Pro(Android 17)`

**증상:** 실기기에서 텍스트가 이미 들어있는 LineEdit(예: 기본값 "127.0.0.1:7350")을 탭으로
포커스한 뒤 `adb shell input keyevent KEYCODE_DEL`이나 `KEYCODE_FORWARD_DEL`을 아무리 반복해도
필드 내용이 전혀 줄지 않는다. `adb shell input text "..."`로 문자를 넣는 것은 커서 위치에 정상
삽입되므로 IME 경로 자체는 살아있다 — 유독 삭제 키만 GodotEditText(Android 프록시)에 전달되지
않는 것으로 보인다(Gboard의 on-screen ⌫ 아이콘을 좌표로 직접 탭해도 동일하게 무반응). 이 상태에서
계속 `input text`만 반복하면 새 문자열이 기존 텍스트 중간에 끼어들어 URL이 깨진다
(`http://trpg.busan.mxox.com0.0.1:7350` 식으로 뒤섞임) — Nakama 인증 실패의 원인이 코드가 아니라
이 adb 입력 특성이었다.

**해결:** 같은 좌표를 빠르게 세 번 탭(`input tap x y` 세 번 연속)하면 트리플탭으로 필드 전체가
선택되고(선택 시 필드 테두리가 밝아짐), 그 상태에서 `adb shell input text "새 값"`을 보내면
선택 영역이 통째로 교체된다. LineEdit을 adb로 무인 조작해야 하는 모든 헤드리스 UI 테스트에 적용
가능(`docs/android.md`, T-103).

## GDT-059 — 익스포터는 `res://`의 평범한 텍스트 파일을 "export all resources"에서도 조용히 빼놓는다

`측정 2026-09-14 · Godot 4.7.2-stable, Android(arm64-v8a) prebuilt 템플릿`

**증상:** preset이 `export_filter="all_resources"`인데도 프로젝트 안에 둔 평범한 key=value 텍스트 파일
(`client/farm.cfg`)이 익스포트한 APK에 들어가지 않는다. 익스포트는 exit 0이고 에러도 경고도 없다 —
`unzip -l farm-android.apk`로 직접 열어봐야 빠진 것이 보인다. 런타임에서는
`FileAccess.file_exists("res://farm.cfg")`가 false여서 설정을 못 읽고 기본값으로 조용히 넘어간다
(서버 주소가 기본값 `127.0.0.1`로 남아 접속 실패). 익스포터는 "모든 리소스"에서도 엔진이 리소스 타입으로
인식하는 것(`.gd`·`.tscn`·임포트된 에셋 등)만 담는다.

**해결:** 담고 싶은 값을 리소스 타입으로 바꾼다. 빌드 스크립트가 빌드 직전에 상수 하나짜리 `.gd`를 만들고
(`const CFG_TEXT := "host=...\nport=443\n"`), 익스포트 뒤 성공·실패 무관하게 지운다. `.gd`는 확실히
패키징된다. 시크릿이 담기면 `.gitignore`에 먼저 넣어라(FARM T-050).

## GDT-060 — 안드로이드에서 `OS.get_environment`는 비어 있고 실행 파일 옆에 설정 파일을 둘 자리도 없다

`측정 2026-09-14 · Godot 4.7.2-stable, Pixel 7 Pro`

**증상:** 데스크톱 배포본에서 쓰던 설정 해석(환경변수 → 실행 파일 옆 `설정.cfg` → 기본값)이 안드로이드에서는
두 단계가 통째로 죽는다. 앱을 실행한 셸이 없어 `OS.get_environment("...")`가 늘 빈 문자열이고,
`OS.get_executable_path()`의 디렉터리는 사용자가 파일을 떨어뜨릴 수 있는 자리가 아니다. 그래서 어떤 값도
주입되지 않고 항상 기본값으로 떨어진다 — 실패가 아니라 조용한 기본값이라 원인을 찾기 어렵다.

**해결:** 안드로이드는 빌드 시점에 패키지 안으로 굽는 경로를 따로 둔다(GDT-059). 탐색 순서에서 패키지 안의
값을 **맨 뒤**에 두면 데스크톱 사용자가 실행 파일 옆 파일로 덮어쓰는 길은 그대로 남는다(FARM T-050).

## GDT-061 — macOS에서 godot-livekit을 안드로이드로 빌드하면 링커가 `undefined symbol: main`으로 죽는다

`측정 2026-09-14 · godot-livekit v0.3.3(44f0aa7), Godot 4.7.2-stable, NDK 28.1.13356709, macOS 호스트`

**증상:** `./build.sh android arm64`가 C++ 11개 파일을 전부 컴파일한 뒤 링크에서만 죽는다.

```
clang++: warning: argument unused during compilation: '-dynamiclib'
ld.lld: error: undefined symbol: main
>>> referenced by crtbegin.c
>>>   .../sysroot/usr/lib/aarch64-linux-android/24/crtbegin_dynamic.o:(_start_main)
```

원인은 SCons가 **호스트**를 보고 `SHLINKFLAGS`를 정하는 것이다. macOS 호스트에서는 `-dynamiclib`이 들어가고,
`SConstruct`의 `if is_android:` 분기는 `CCFLAGS`·`LINKFLAGS`만 덮으며 `SHLINKFLAGS`는 건드리지 않는다.
안드로이드 링커는 `-dynamiclib`을 무시하고(경고만) 결과물을 실행 파일로 취급해 `main`을 찾는다.
**Linux 호스트에서는 기본이 `-shared`라 재현되지 않는다** — 그래서 상류에 버그로 남아 있다.

**해결:** `SConstruct`의 android 분기에 한 줄 추가한다.

```python
env['SHLINKFLAGS'] = ['$LINKFLAGS', '-shared']
```

그러면 `libgodot-livekit.android.arm64.so`(4.8MB)가 나온다 — `file`이 `ELF 64-bit LSB shared object, ARM aarch64`로 보고한다.

## GDT-062 — godot-cpp 안드로이드 프리빌트도 `bin/`이 비어 있고, 소스 빌드는 NDK 버전이 정확히 고정돼 있다

`측정 2026-09-14 · NodotProject/godot-cpp-builds 릴리스 godot-4.5-stable`

**증상:** 두 겹이다.

1. `godot-cpp-prebuilt-godot-4.5-stable.zip`은 소스(`include`·`gen`·`src`·`SConstruct`)는 다 들어 있는데
   `bin/`이 **빈 디렉터리**다. 그래서 `build.sh`는 "godot-cpp cache is valid!"라고 보고하고 컴파일까지 진행한 뒤
   `Implicit dependency 'godot-cpp/bin/libgodot-cpp.android.template_release.arm64.a' not found`로 죽는다.
   macOS 타겟에서 이미 같은 증상이 있었고(이 저장소 이전 기록), 안드로이드에서도 같다 — 릴리스 아티팩트 자체 결함이다.
2. 우회로 `godot-cpp`를 소스 빌드하면 NDK 버전이 고정돼 있다.
   `ERROR: Could not find NDK toolchain at .../ndk/28.1.13356709/...  Make sure NDK version 28.1.13356709 is installed.`
   설치된 28.2.13676358로는 거부한다. 또 `ANDROID_HOME`이 없으면 그 전에 `KeyError: 'ANDROID_HOME'`로 죽는다
   (`godot-cpp/tools/android.py:31`) — NDK 경로만 맞춰도 안 된다.

**해결:** 순서가 있다.

```bash
sdkmanager --install "ndk;28.1.13356709"          # 버전을 정확히 맞춘다
export ANDROID_HOME="$HOME/Library/Android/sdk"   # 없으면 KeyError
export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk/28.1.13356709"
cd godot-cpp && scons platform=android arch=arm64 target=template_release -j8   # 약 1분 30초, .a 80MB
```

그다음 상위에서 `./build.sh android arm64`를 돌린다(GDT-061 패치가 먼저 들어가 있어야 한다).
LiveKit 안드로이드 SDK는 `build.sh`가 프리빌트로 받아오므로 Rust 크로스 컴파일(`cargo-ndk`·`rustup target add`)은 **필요 없다.**

## GDT-063 — export preset의 `exclude_filter`가 방금 벤더링한 GDExtension을 exit 0로 조용히 빼놓는다

`측정 2026-09-14 · Godot 4.7.2-stable, Android(arm64-v8a) prebuilt 템플릿`

**증상:** GDExtension을 새 플랫폼(예: android arm64)에 벤더링하고 `.gdextension`에 라이브러리·의존성을
등록해도, 그 preset의 `export_presets.cfg`에 예전에 "이 플랫폼은 아직 안 됨"이라 넣어둔
`exclude_filter="addons/<extension>/*"`가 남아 있으면 익스포터가 새로 추가한 `.so`까지 통째로 걸러낸다.
익스포트는 exit 0, 로그에 에러·경고 없음 — `unzip -l <apk> | grep <arch>`로 직접 열어봐야 빠진 게
보인다(GDT-059와 같은 계열, 다른 트리거). 빠진 채로 설치하면 `.gdextension`의 다른 슬롯이 없어 GDExtension
로드 자체가 조용히 스킵되고, 그 확장이 제공하던 기능이 "미지원"으로 degrade한다 — 크래시가 없어 더 늦게
발견된다.

**해결:** 플랫폼을 벤더링하는 티켓은 `.so` 복사·`.gdextension` 등록과 같은 커밋에서 그 preset의
`exclude_filter`도 확인한다. 이전에 "미벤더링"을 이유로 넣어둔 제외 규칙이면 지운다. 지운 뒤 반드시
`unzip -l`로 직접 확인한다 — 종료 코드와 로그를 믿지 않는다(TRPG T-106).

## GDT-064 — `gui/theme/default_font_size`는 Godot 4에 존재하지 않는 키다. 조용히 무시된다

`측정 2026-09-14 · Godot 4.7.2-stable`

**증상:** 폰 UI 폰트를 키우려고 `project.godot`의 `[gui]`에 `theme/default_font_size=34`를 넣었다.
파싱 에러 없음, export한 APK의 `assets/project.binary`에도 값이 정확히 박힌다(`strings`로 확인 가능,
바이트 오프셋까지 대조함). 그런데 실기기·헤드리스 어느 쪽에서도 글자 크기가 그대로다. 원인은 이 키 자체가
Godot 4 엔진에 없다는 것 — `strings $(command -v godot) | grep default_font_size`로 엔진 바이너리를
뒤져도 `gui/theme/default_font_antialiasing`·`default_font_hinting` 같은 사촌 키만 나오고
`default_font_size`는 안 나온다. `ProjectSettings.get_setting("gui/theme/default_font_size")`는 넣은
값을 돌려주지만(설정 자체는 그냥 임의 키-값 저장을 허용하므로), 그 값을 실제로 읽어 쓰는 엔진 코드가
없어서 `ThemeDB.fallback_font_size`는 16(엔진 기본값)에서 안 바뀐다. Godot 3식 프로젝트 세팅 이름을
Godot 4에도 있을 거라 짐작하면 걸리는 함정이다.

**해결:** 진짜 키는 `gui/theme/default_theme_scale`(float, 기본 1.0)이다. 기본 테마 전체(폰트 크기·여백·
최소 컨트롤 크기)를 이 배율로 곱해서 쓴다.

```
[gui]
theme/default_theme_scale=2.2
```

헤드리스로 바로 검증된다(export까지 갈 필요 없음):

```gdscript
extends SceneTree
func _init() -> void:
    print(ThemeDB.fallback_font_size)  # 2.2 적용 시 16*2.2=35
    quit()
```

`godot --headless --path <project> -s <위 스크립트>.gd`로 몇 초 만에 확인된다. 실기기 실측(Pixel 7 Pro,
가로 스케일 1.125)에서는 `default_theme_scale=1.0`(폰트 16 논리) 대비 텍스트 실측 높이가 16px → 40px로
커졌다(TRPG T-105). 의심스러운 project setting은 export까지 가지 말고 먼저 `godot --headless -s`로
읽는 쪽(`ThemeDB`·`ProjectSettings`)을 직접 찍어 확인한다 — export 결과물에 값이 박혀 있다는 사실이
엔진이 그 값을 실제로 쓴다는 증거는 아니다.

## GDT-065 — (무효 — 전제가 틀렸다) `adb`로 화면을 못 돌린다고 봤던 원인은 사실 GDT-066이다

`측정 2026-09-14 · Godot 4.7.2-stable, Android 17(Pixel 7 Pro)`

**무효 표시:** 아래 "증상"·"해결"은 당시 설치돼 있던 APK가 `screenOrientation="landscape"`로
하드코딩된 빌드(GDT-066 참고)였다는 걸 모르고 쓴 기록이다 — `sensor` 앱을 상대로 한 실험이
애초에 아니었다. `accelerometer_rotation`·`user_rotation`·`cmd window user-rotation lock`이
안 먹은 건 그 셋 다 "landscape 고정 앱"에는 원래 의미가 없기 때문이지, `sensor` 앱이라서가
아니다. 진짜 `sensor` 앱(GDT-066 반영 빌드)에서 이 명령들이 먹는지는 재검증 전이다 — 확인되면
이 자리에 새 사실로 다시 쓴다. ID는 남기고 본문은 그대로 둔다(당시 관측 자체는 사실이었다).

**증상(당시 기록, 전제 오류 포함):** 세로·가로 두 방향을 스크린샷으로 무인 검증하려고
`adb shell settings put system accelerometer_rotation 0` + `user_rotation 1`로 가로를 강제했다.
값은 반영되지만(`settings get`으로 확인됨) 화면은 안 돌아갔다 — 그때는 `sensor` 매니페스트가
가속도계만 따라서 그렇다고 판단했지만, 실제로는 매니페스트 자체가 `landscape` 고정이라
어떤 회전 설정을 넣어도 바뀔 수 없는 상태였다(GDT-066).

**당시 시도(참고용, 재검증 필요):** `cmd window user-rotation lock 0`으로 시스템 레벨 회전
잠금을 걸면 `settings get`·`cmd window user-rotation` 조회값은 바뀌지만, 이때도 앱 화면은
그대로였다 — 이 역시 앱이 `sensor`가 아니라 `landscape` 고정이었기 때문일 가능성이 높다.

**부록 — 이것만은 유효: `adb devices`가 기기를 `offline`으로 보고하면:** USB 디버깅 재승인
팝업이 화면에 떠서 adb 명령 자체가 안 넘어가는 상태다(TRPG T-105, `am start`·`install` 도중
발생). `adb kill-server`+`start-server`로도 안 풀린다 — 사람이 화면을 보고 팝업을 눌러야
풀린다. 재시도 루프를 돌리지 말고 바로 사람에게 알린다. (이 항목은 orientation과 무관해서
전제 오류의 영향을 받지 않는다.)

## GDT-066 — prebuilt export(gradle_build=false)에서는 화면 방향을 아예 못 바꾼다. project.godot도 export_presets.cfg도 안 먹는다

`측정 2026-09-14 · Godot 4.7.2-stable, Android 17(Pixel 7 Pro)`

**증상:** 세로·가로를 다 지원하려고 `project.godot`의 `[display]`에
`window/handheld/orientation="sensor"`를 넣었다. 헤드리스 편집기에서는 문제없이 읽힌다
(`ProjectSettings.get_setting`으로 확인됨). 실기기에 설치하면 로그인 화면까지 뜨는 모든
스크린샷이 예외 없이 가로(3120x1440)였다 — 물리 방향을 세로로 눕혀도 마찬가지였다.
`"portrait"`로 바꿔 **클린 빌드**(`adb uninstall` 뒤 `adb install`, incremental install
캐시 문제 배제)해도 똑같이 가로로만 뜬다. `adb shell settings put system user_rotation`·
`accelerometer_rotation`·`cmd window user-rotation lock <n>` 전부 효과가 없었다(GDT-065,
지금 보면 당연하다).

**원인 확인 방법:** `project.binary`(export한 APK 안의 `assets/project.binary`)를 열어보면
`display/window/handheld/orientation` 값은 넣은 그대로("portrait" 등) 들어 있다 —
`strings`로 확인 가능. 하지만 **실제 안드로이드 매니페스트**는 이 값을 안 쓴다:

```
aapt2 dump xmltree TRPG.apk --file AndroidManifest.xml | grep -B5 screenOrientation
```

`com.godot.game.GodotApp` activity에 `android:screenOrientation=0`(0=landscape, Android
`ActivityInfo` 상수)이 project.godot 설정과 무관하게 항상 박혀 있었다. `project.godot`을
바꿔도 이 값은 안 바뀐다 — **project setting과 매니페스트 생성이 별개 경로**다.

진짜 제어점은 `client/export_presets.cfg`의 android preset, `[preset.N.options]`
아래의 `screen/orientation` 키다. 이 키가 **preset 파일에 아예 없으면** Godot Android
exporter는 자체 기본값(landscape)을 쓴다 — project.godot 값을 참고하지 않는다. T-103이
Android preset을 처음 만들 때 이 키를 안 넣어서 계속 landscape로 나갔던 것이다.

**착시 하나 덧붙임:** 앱 실행 직후 OS가 그리는 로딩 스플래시는 실제 물리 방향을 따라 잠깐
세로로 보이기도 한다. 그래서 "세로로 잠깐 왔다가 가로로 돌아간다"처럼 보였는데, 이건 물리
회전이 아니라 **스플래시(물리 방향) → 우리 액티비티(하드코딩된 landscape로 스냅)** 전환이었다.
스크린샷 판정은 로딩 스플래시가 아니라 실제 씬(로비 UI 등)이 뜬 프레임으로 해야 한다.

**해결(부분적 — gradle_build=false에서는 안 먹는다):** `export_presets.cfg`의 android
`[preset.N.options]`에 `screen/orientation="sensor"`를 추가해봤지만(TRPG T-106 실측),
`aapt2 dump xmltree`로 확인한 결과 `screenOrientation`은 여전히 `0`(landscape)이었다.

원인은 한 겹 더 있었다: 이 preset이 `gradle_build/use_gradle_build=false`(**프리빌트 export**)
모드라서다. 이 모드에서는 `AndroidManifest.xml`을 프리빌트 템플릿(`android_debug.apk`)에서
그대로 복사해 쓴다 — 템플릿 자체에 이미 `screenOrientation=0`이 박혀 있고, `export_presets.cfg`의
`screen/orientation` 옵션도 project.godot의 `window/handheld/orientation`도 **둘 다 이 경로에
관여하지 않는다**. 게다가 `screen/orientation`이라는 export 옵션 자체가 Godot 4.7.2 바이너리에
없다(`strings godot | grep screen/`로 확인 — `screen/background_color`·`edge_to_edge`·
`immersive_mode`·`support_*`만 있고 `orientation`은 없다). 즉 이 옵션을 preset에 적어 넣는 것
자체가 애초에 아무 키에도 매칭되지 않는 죽은 설정이었다.

**진짜 해결(미착수):** `gradle_build/use_gradle_build=true`로 전환해 커스텀 Gradle 빌드를 써야
매니페스트를 프로젝트 설정에 맞게 생성할 여지가 생긴다. Android SDK·Gradle 툴체인이 추가로
필요하고 빌드 파이프라인 자체가 바뀌는 일이라 티켓 하나의 범위가 아니다 — 별도 티켓으로
끊어야 한다(TRPG 2026-09-14, T-105·T-106 공동 확인).

## GDT-067 — godot-livekit android는 빌드·로드까지는 되지만 `connect_to_room`에서 100% 크래시한다(JNI 초기화 부재로 추정)

`측정 2026-09-14 · godot-livekit v0.3.3(`44f0aa7`), livekit-sdk(client-sdk-cpp) v0.3.1, Pixel 7 Pro, Android(4KB 페이지)`

**증상:** GDT-061·GDT-062로 android arm64 `.so` 3개를 빌드해 벤더링하고 `.gdextension`에
등록하면, 빌드도 되고 APK 패키징도 되고(GDT-063 참고) **GDExtension 로드·`ClassDB` 등록까지도
된다** — 로비 화면에서 Nakama 로그인, 방 생성(`match_create`), `livekit_token` RPC까지 전부
정상 응답을 받는다. 문제는 그다음이다. GDScript가 `_room.connect_to_room(url, token, {})`를
호출하는 순간 앱이 네이티브 크래시로 죽는다:

```
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0 (read)
Cause: null pointer dereference
tid: ...  name: tokio-runtime-w  >>> com.trpg.client <<<
backtrace 37 frames, #00~#34 전부 liblivekit_ffi.so 안
```

4번 연속 재현했고 PC 오프셋(`liblivekit_ffi.so`+`0xa6a880`)이 매번 완전히 동일 — 우연이 아니라
결정적 크래시다. `pm grant android.permission.RECORD_AUDIO`로 런타임 권한을 직접 부여하고
재시도해도 똑같이 죽어 권한 문제가 아니다. 설치 시 뜨는 "16KB 페이지 비호환" 시스템 경고와도
무관하다 — 이 기기는 `adb shell getconf PAGE_SIZE`가 4096(4KB 모드)이라 16KB 정렬 문제가
런타임에 실제로 발동할 상황이 아니다.

원인으로 보이는 것: `grep -rn -i "javavm|jni|JNIEnv|android_init|set_java" ~/work/godot-livekit/src/`
와 `livekit-sdk/include/` 양쪽 다 **0건**. Android에서 WebRTC 스택은 `JavaVM`과
ApplicationContext를 네이티브 쪽에 등록해야 오디오 디바이스 모듈·네트워크 모니터가 초기화된다 —
그 등록이 코드 어디에도 없다. 즉 **godot-livekit의 android 타겟은 컴파일은 통과하지만 런타임
연결이 한 번도 검증된 적이 없어 보인다.**

**해결(미착수):** 프리빌트 Rust 바이너리 버그가 아니라 **호출 측(C++ 레이어)의 JNI 초기화
누락**이다. `livekit-sdk`가 JNI 등록 API를 노출하지 않으면 상류 `krazyjakee/client-sdk-cpp`까지
손대야 하는 규모라 벤더링 티켓 하나로 못 끝낸다. `.so`를 다음에 다시 벤더링하려는 사람은 빌드가
성공했다고 안심하지 말고 **반드시 실기기에서 `connect_to_room`까지 실행해서 확인해라** — 빌드
성공과 런타임 동작은 별개다(TRPG T-106).

## GDT-068 — `DisplayServer.get_display_safe_area()`는 데스크톱(멀티 모니터)에서 이 창이 아니라 가상 데스크톱 전체 기준 좌표를 돌려준다

`측정 2026-09-14 · Godot 4.7.2-stable, macOS(Apple Silicon), 3840x2160 외부 모니터`

**증상:** 노치·홈 인디케이터 안전 영역을 반영하려고 `MarginContainer`에
`screen_get_size() - get_display_safe_area()`로 계산한 여백을 줬다. 안드로이드
실기기에서는 정상(노치 없는 기기라 여백이 거의 0에 가까움)이지만, **macOS
데스크톱에서 같은 코드를 돌리면 UI 전체가 화면 밖으로 밀려나 완전히 안 보인다.**
`print`로 실측:

```
screen=(3840, 2160)
safe=[P: (3456, 194), S: (3840, 1952)]
→ left = 3472px
```

`safe.position.x=3456`은 이 앱 창의 안전 영역과 무관한 값이다 — 창 자체는 720px
너비인데 왼쪽 여백만 3472px가 나온다. `get_display_safe_area()`가 데스크톱에서는
**이 스크린(또는 창)이 아니라 멀티 모니터 가상 데스크톱 전체를 기준으로 한 좌표**를
돌려주는 것으로 보인다(정확한 산출 방식은 확인 안 됨 — 이 API는 안드로이드/iOS
전용으로 설계됐고 데스크톱에서의 동작은 문서화돼 있지 않다). `screen_get_size()`도
현재 스크린의 전체 해상도라 이 둘을 단순히 빼는 계산은 데스크톱에서 아예 성립하지
않는다.

**헤드리스 gdunit4 테스트로는 못 잡는다** — 헤드리스는 실제 화면/창이 없어
`screen_get_size()`가 `(0,0)`을 돌려주고 분기 자체를 안 타므로, 이 버그는 실제
창을 띄워 실행해야만 드러난다. 로직 검증을 전부 헤드리스로만 하면 이런 "화면 렌더링
자체가 깨지는" 회귀를 완전히 놓친다(TRPG T-105 — PASS 판정이 난 뒤에 데스크톱을
직접 실행해서 발견).

**해결:** `OS.has_feature("mobile")`로 안전 영역 계산 자체를 모바일에만 적용하고
데스크톱은 완전히 건너뛴다(기본 여백만 사용). 노치 대응이 필요한 건 애초에
모바일뿐이므로 이 가드가 의미상으로도 맞다.

```gdscript
var can_query_safe_area := (
    OS.has_feature("mobile")
    and DisplayServer.has_method("get_display_safe_area")
    and DisplayServer.has_method("screen_get_size")
)
```

**일반화된 교훈:** UI 레이아웃이 프로젝트 세팅·안전 영역처럼 "플랫폼별로 다르게
동작하는" API에 의존하면, 헤드리스 테스트를 아무리 많이 통과해도 실제 창을 띄워
보기 전에는 "화면에 아무것도 안 보인다" 같은 치명적 회귀를 놓칠 수 있다. 데스크톱
빌드를 만지는 티켓은 완료 전에 최소 한 번은 실제 창을 띄워 스크린샷으로 확인한다.

## GDT-069 — macOS export의 `codesign/codesign=0`(무서명)이 "손상됨" 원인이었다. zip 왕복 자체는 서명을 안 깨뜨린다

`측정 2026-09-14 · Godot 4.7.2-stable, macOS(Apple Silicon)`

**증상:** `.app`을 GitHub Actions 아티팩트로 왕복시키면(zip 업로드 → 다운로드 →
압축 해제) Finder에서 "손상되었으므로 열 수 없습니다 — 휴지통으로 이동" 대화상자가
뜬다. 흔한 짐작은 "zip이 서명을 깨뜨린다"이지만, 실제로 zip 압축·해제 전후 바이트를
비교하면 심볼릭 링크·실행 권한 손실이 전혀 없고 `codesign --verify --deep --strict`는
왕복 전후 모두 `exit 0`으로 그대로 통과한다(재현: `zip -r -X` → 다운로드
quarantine을 `xattr -w com.apple.quarantine "0081;...;Chrome;"`로 흉내 →
`unzip`·`ditto` 둘 다 quarantine을 그대로 전파하지만 `codesign --verify`는 안 깨짐).
진짜 원인은 export preset이 애초에 **서명을 안 한 것**(`codesign/codesign=0`,
Disabled)이었다 — Apple Silicon 커널은 서명이 전혀 없는 arm64 코드를 실행할 수
없고, quarantine이 붙은 무서명 바이너리는 온디맨드 재서명도 실패해 "손상됨"으로
뜬다. 로컬에서 방금 빌드해 quarantine이 없는 상태로는 이 문제가 재현되지 않아
더 헷갈린다(무서명이어도 quarantine 없는 로컬 실행은 대체로 통과).

**해결:** `codesign/codesign=1`(Built-in, ad-hoc)로 바꾼다. 애드혹 서명은
Developer ID 없이도 Apple Silicon에서 실행 가능한 최소 요건을 만족시킨다.
`spctl --assess --type execute`는 애드혹이면 quarantine 유무와 무관하게
`rejected`가 정상이다(노터라이즈 안 됨) — 이건 여전히 실패로 보이지만 무해하고,
Finder가 quarantine 없는 로컬 빌드를 열 때는 애초에 spctl 평가 자체를 안 거친다.
다운로드본만 quarantine이 걸려 Gatekeeper 확인이 뜨고, 그건 `xattr -dr
com.apple.quarantine`이나 우클릭→열기로 우회한다(TRPG T-107).

**부록 — GDExtension `.dylib`을 쓰면 entitlement가 하나 더 필요:** 애드혹 서명된
메인 실행 파일이 애드혹 서명된 `.dylib`(다른 팀 ID/서명자)을 로드하려면
`codesign/entitlements/disable_library_validation=true`가 없으면 dyld의 라이브러리
검증에 걸려 로드가 거부된다. 마이크 등 하드웨어 접근에 필요한 entitlement 키는
Godot 편집기 바이너리에서 직접 확인 가능하다: `strings $(command -v godot) | grep
'codesign/entitlements/'`(예: `audio_input`·`camera`·`location` 등). 마이크 사용
문구는 export preset 옵션 `privacy/microphone_usage_description`을 채우면
`Info.plist`의 `NSMicrophoneUsageDescription`으로 자동 반영된다 —
`application/additional_plist_content`에 직접 꽂을 필요가 없다.

---

## GDT-070 — `Label3D.fixed_size=true`는 화면 픽셀 크기 하한 테스트를 가능하게 하지만, 먼 거리에서 "하늘에 붕 뜬 거대한 글자"로 보이는 대가가 있다

`측정 2026-09-14 · Godot 4.7.2-stable, Android 17(Pixel 7 Pro)`

**증상:** 3D 공간의 `Label3D`(예: 상점 가격표, 몬스터 이름표, 원격 플레이어 이름표)가 기본
설정(`fixed_size=false`)에서는 카메라 거리에 반비례해 화면 크기가 줄어든다 — 즉 순수 함수로
"이 라벨이 화면에서 N px 이상인가"를 판정할 수 없다(거리라는 런타임 값에 의존). `fixed_size=true`로
바꾸면 셰이더가 메시를 카메라까지의 거리만큼 스케일한 뒤 투영하므로 그 거리 인자가 상쇄되어, 화면
픽셀 높이가 `font_size`·`pixel_size`·뷰포트 높이·카메라 FOV만의 함수가 된다(카메라 기본값
`fov=75`·`keep_aspect=KEEP_HEIGHT`이면 세로 FOV는 뷰포트 종횡비와 무관하게 75°로 고정) —
그래서 gdunit4로 "뷰포트 720/1440에서 라벨이 14sp 하한을 넘는다"를 고정할 수 있게 된다.

**하지만 실기기에서 보면 다른 문제가 생긴다:** 이 계산대로 하한을 통과하도록 라벨을 설정해
실기기에 올렸더니, 상점(Pen)에서 한참 떨어진 밭 반대편에서도 상점 라벨 글자가 **가까이서 보는
것과 똑같은 화면 픽셀 크기**로 하늘을 가로질러 크게 떠 있었다. 다른 3D 오브젝트(작물·플레이어
메시)는 거리에 따라 정상적으로 작아지는데 라벨만 안 작아지니 "붕 뜬 거대한 글자"로 도드라진다.
`fixed_size`는 정의상 이렇게 동작한다 — 가까이서 봤을 때 적당한 크기를 고르면 그 크기가 멀리서도
그대로 유지된다. `font_size`를 하한에 더 바짝 맞춰 줄여도 절대 크기만 작아질 뿐 "거리 무관하게
고정"이라는 성질 자체는 없어지지 않는다.

**결론:** `fixed_size=true`는 "화면 픽셀 하한을 순수 함수·유닛 테스트로 고정한다"는 요구와
"3D 공간에 자연스럽게 녹아드는 라벨"이라는 요구가 서로 충돌하는 지점이다. 상시 근접
상호작용용 라벨(예: 플레이어 바로 위 이름표, 상호작용 반경 안에서만 보이는 상태 텍스트)에는 적합할
수 있지만, 먼 거리에서도 시야에 들어오는 라벨(넓은 맵의 상점 간판 등)에 그대로 적용하면 이 부작용을
피할 수 없다. 이 트레이드오프는 값 튜닝으로 없어지지 않고 설계 층위에서 결정해야 한다(AGT-047 3층 —
사람이 화면으로 판정해야 하는 축).

---

## GDT-071 — 헤드리스 `godot --install-android-build-template`을 단독 호출하면 CPU를 거의 안 쓰며 영원히 멈춘다. export 플래그와 같은 호출에 묶으면 10초 안에 끝난다

`측정 2026-09-14 · Godot 4.7.2-stable, macOS(Apple Silicon)`

**증상:** `use_gradle_build=true`로 전환하며 `client/android/`(gitignore 대상, 클론마다
없음)를 자동 설치하려고 `godot --headless --path client --install-android-build-template`을
**단독으로** 실행했다. 2시간 넘게 끝나지 않았다 — `client/android/`는 끝내 생성되지 않았고
로그 파일엔 시작 배너 한 줄뿐이었다. `ps`로 보면 CPU 누적 시간이 2시간 동안 겨우 91초
(1% 미만) — 계산 중이 아니라 뭔가를 기다리며 멈춰 있는 것이다. `sample <pid>`로 스택을
찍으면 메인 스레드가 `nanosleep` → `+[NSRunningApplication
runningApplicationsWithBundleIdentifier:]`(LaunchServices) 호출을 반복하며 도는 채로
멈춰 있었다. 네트워크 연결은 0개(`lsof -p <pid> -i`), 다른 Godot 프로세스도 없어서
"다른 인스턴스를 기다리는 락"류의 정상적인 대기도 아니었다. `kill`(SIGTERM)로 강제
종료해야 빠져나왔다.

**해결:** `godot --help`의 이 플래그 설명 자체가 힌트였다 — "Used in conjunction with
--export-release or --export-debug." 단독 호출을 포기하고 **같은 godot 프로세스 호출
안에** export 플래그와 함께 넘기면(`godot --headless --path client
--install-android-build-template --export-debug Android out.apk`) 10초 안에 끝나고
`client/android/`도 정상 생성된다. 이미 `client/android/`가 있으면 이 플래그는 아예
넘기지 않는다(재설치 방지) — 즉 실무 패턴은 "없을 때만 export 호출 배열 맨 앞에
플래그를 끼워 넣는다"이지, "설치 따로 export 따로"가 아니다.

**적용:** CI·로컬 스크립트가 "템플릿 설치 스텝"과 "export 스텝"을 두 개의 별도 godot
호출로 나눠 놨다면 이 함정을 100% 밟는다. `--install-*` 계열 standalone 헤드리스 플래그가
멈추는 것처럼 보이면, 재시도나 `--verbose`를 붙이기 전에 먼저 `godot --help`에서 그
플래그 설명에 "in conjunction with"·"used with" 같은 문구가 있는지부터 확인한다(TRPG
T-110).

---

## GDT-072 — `gradle_build/use_gradle_build=true`로 전환해도 Android `screenOrientation`은 여전히 project.godot과 무관하다 — GDT-066의 "진짜 해결" 가설은 틀렸다

`측정 2026-09-14 · Godot 4.7.2-stable, Android(gradle custom build)`

**증상:** GDT-066은 prebuilt export(`use_gradle_build=false`)에서 화면 방향이 project.godot과
무관하게 항상 landscape로 박히는 것을 확인하고, "`use_gradle_build=true`로 전환하면
매니페스트를 프로젝트 설정에 맞게 생성할 여지가 생긴다"고 **미착수 가설**로 적어뒀다.
전환해서 실측하니 이 가설은 틀렸다 — gradle 빌드에서도 `aapt2 dump xmltree`로 확인한
`android:screenOrientation`은 여전히 `0`(landscape)이다.

**확인한 것 세 가지(모두 재현 가능):**
1. `project.godot`의 `display/window/handheld/orientation`을 `sensor`→`portrait`로 바꾸고
   `client/android/`를 지우지 않은 채 재익스포트해도, gradle이 매 익스포트마다 다시 쓰는
   `client/android/build/src/debug/AndroidManifest.xml`(타임스탬프로 재생성 확인됨)의
   `android:screenOrientation` 값은 `landscape`로 그대로다.
2. 헤드리스 스크립트로 `ProjectSettings.get_property_list()`를 전수조사해도 이름에
   `orientation`이 들어간 키는 `display/window/handheld/orientation` 하나뿐 — 대체 키가
   없다.
3. `strings godot`로 android export 플러그인의 매니페스트 템플릿 문자열
   (`tools:replace="android:screenOrientation,android:excludeFromRecents,...`) 주변을
   뒤져보면, `excludeFromRecents`는 `package/exclude_from_recents`라는 실재하는 export
   옵션과 짝이 맞지만 `screenOrientation`에 대응하는 옵션 이름은 어디에도 없다 —
   `screen/` 프리픽스로 존재하는 옵션은 `support_{small,normal,large,xlarge}`·
   `background_color`·`edge_to_edge`·`immersive_mode`뿐이다(GDT-066도 이미 확인했던 것과
   동일).

**결론:** Godot 4.7.2의 android 커스텀(gradle) 빌드는 `screenOrientation`을 project.godot도
export_presets.cfg도 읽지 않고 매니페스트 템플릿에 고정값으로 박아 넣는다 — prebuilt
경로(GDT-066)와 마찬가지로 이 값을 바꾸는 유일한 방법은 `client/android/build/src/{main,debug}/
AndroidManifest.xml`을 **손으로** 고치는 것뿐이다. 이 디렉터리는 보통 `.gitignore` 대상이라
클론마다 사라지므로, 손으로 고친 값도 재설치 때마다 없어진다(TRPG 프로젝트는 실제로 이 이유로
손질을 하지 않기로 했다, T-110). 이 버전의 엔진에서 orientation을 재현 가능하게 통제하려면
자동화 스크립트가 매 빌드마다 생성된 매니페스트를 후처리하거나, 상류 엔진에 export 옵션을
추가하는 수밖에 없어 보인다 — "gradle 전환이 곧 project.godot 통제권 회복"이라고 가정하지
않는다.

---

## GDT-073 — `Label3D.get_aabb()`와 `Camera3D.unproject_position()`은 `--headless`에서도 실제 값을 준다 — `fixed_size` 없이 3D 라벨의 화면 겹침을 유닛 테스트로 고정할 수 있다

`측정 2026-09-14 · Godot 4.7.2-stable, macOS 15(Apple M1 Max), gdUnit4`

**증상:** 3D 공간의 `Label3D` 여러 개가 화면에서 서로 겹쳐 글자가 뭉개지는 문제는 "사람이 봐야
하는 축"으로 넘기기 쉽다. GDT-070은 화면 픽셀 **하한**을 순수 함수로 고정하려면 `fixed_size=true`가
필요하고 그 대가로 먼 거리에서 글자가 하늘에 붕 뜬다고 기록했다. 그런데 **겹침**은 `fixed_size`
없이도 잰다.

**headless에서 실제로 동작하는 것(GDT-005의 "헤드리스는 3D를 렌더하지 않는다"와 별개다):**

- `Label3D.get_aabb()`는 텍스트 메시의 월드 크기(m)를 돌려준다. 렌더 타깃이 없어도 텍스트
  레이아웃은 계산되므로 `godot --headless`에서 그대로 나온다. 노드를 트리에 붙이고 프레임 하나만
  넘기면 된다.
- `Camera3D.unproject_position()`은 투영 행렬 계산일 뿐이라 headless에서 정확하다.
- gdUnit4는 headless에서 `--ignoreHeadlessMode`가 있어야 돈다.

**빌보드 라벨의 화면 사각형**은 이 둘로 구한다(라벨 쿼드는 항상 카메라를 향하므로 월드 반치수를
원근 나눗셈으로 그대로 픽셀로 바꾸면 된다):

```gdscript
var size := label.get_aabb().size                      # m
var centre := cam.unproject_position(label.global_position)
var d: float = cam.global_position.distance_to(label.global_position)
var px_per_m := viewport_h / (2.0 * d * tan(deg_to_rad(cam.fov) / 2.0))
var rect := Rect2(centre - Vector2(size.x, size.y) * 0.5 * px_per_m,
                  Vector2(size.x, size.y) * px_per_m)
```

카메라를 게임의 3인칭 오프셋에 놓고 yaw 4방향으로 돌려가며 `rect.intersects()`를 확인하면
"어느 방향에서 봐도 라벨끼리 겹치지 않는다"가 회귀 테스트가 된다.

**같이 잰 수치 — 한글 라벨은 생각보다 훨씬 넓다.** `font_size=32`(기본), `pixel_size=0.013`에서:

| 텍스트 | 폭 | 높이 |
|---|---|---|
| `새싹이 Lv.4` + 개행 + `허기 70` | 1.99 m | 1.17 m |
| `불꽃강아지 Lv.6` + 개행 + `허기 90 · 오늘 일함` | 3.16 m | 1.17 m |
| `알 (5일차 부화)` (1줄) | 2.51 m | 0.59 m |

한글은 전각이라 6글자만 돼도 폭이 3 m를 넘는다. 오브젝트 간격이 1~2 m인 배치에서 오브젝트마다
이름표를 달면 **겹치는 것이 기본값**이다. 값을 튜닝해서 피할 수 있는 폭이 아니다(간격 1.4 m에
라벨 3.16 m). 해결은 배치가 아니라 개수다 — 상호작용 대상 하나에만 이름표를 띄우고 따라다니게
한다.

**하나 더:** 월드에 고정된 안내 라벨(간판·상태 문구)을 벽·울타리 같은 한쪽 가장자리에 붙이면,
카메라가 그 반대편에 섰을 때 라벨이 카메라 코앞에 와서 화면을 덮는다. 대상 영역의 **중앙 상공**에
올리면 카메라가 어느 방향에 있어도 거리가 같아 크기가 일정하고, 화면 위쪽에 붙어 지상 오브젝트와
분리된다. 3인칭 카메라가 대상에서 수평 `D`·높이 `H`만큼 떨어져 `P`도 내려다볼 때, 중앙 상공
높이 `Y`의 라벨이 화면 위쪽에 오는 조건은 `Y ≈ H + D·tan(P + FOV_v/2)`다 —
`D=6, H=4, P=30°, FOV_v=75°`면 `Y ≈ 4.8`, 실제로 4.2에서 3줄짜리 간판이 화면 안에 딱 들어왔다.

## GDT-075 — `export_presets.cfg`에 `#` 주석을 넣으면 바로 뒤의 키가 조용히 무시된다

`측정 2026-09-14 · Godot 4.7.2-stable · Android gradle 빌드`

**증상:** Android 플러그인을 켜려고 `[preset.N.options]`에 `plugins/<Name>=true`를 넣으면서, 왜
필요한지를 그 위에 `#` 주석 네 줄로 적어뒀다. 익스포트는 성공하고 APK도 설치되는데
**플러그인이 APK에 없다.** `aapt2 dump xmltree --file AndroidManifest.xml <apk>`로 봐도
`org.godotengine.plugin.v2.<Name>` meta-data가 없고, dex에도 플러그인 클래스가 없다.
오류 0줄, 경고 0줄 — GDT-012가 말한 "안 실린 플러그인은 아무 말도 하지 않는다"가 그대로 재현됐다.

**주석 네 줄만 지우고 같은 명령으로 다시 빌드하니 meta-data가 들어갔다.** 키 이름도 값도
위치도 그대로다. `export_presets.cfg`는 Godot의 ConfigFile 형식이고 주석 문자는 `;`다 —
`#`은 주석으로 처리되지 않으면서 파싱을 거기서 어긋나게 만든다. 같은 섹션의 그 앞 키
(`gradle_build/use_gradle_build=true`)는 정상 동작했다(gradle 빌드가 실제로 돌았다).

**해결:** **`export_presets.cfg`에는 주석을 달지 마라.** 설명이 필요하면 그 파일을 쓰는
빌드 스크립트나 문서에 적는다. 그리고 이 파일에 무언가를 넣었으면 **넣었다는 사실이 아니라
산출물을 검증해라** — Godot은 알 수 없는 키도, 파싱이 어긋난 줄도 조용히 버린다.
Android 플러그인이라면 `aapt2 dump xmltree`로 meta-data를, 그 밖이라면 패키지 안에 실제로
그 효과가 있는지를 본다. 익스포트 성공은 설정이 읽혔다는 증거가 아니다.

## GDT-076 — LiveKit Android SDK는 jitpack에만 있는 전이 의존성을 끌고 온다. Godot 플러그인은 `.gdap`에도 저장소를 적어야 한다

`측정 2026-09-14 · io.livekit:livekit-android 2.18.2 · Godot 4.7.2 Android 플러그인 v2 · AGP 8.6.1`

**증상:** LiveKit Android SDK를 `compileOnly`로 걸고 플러그인 AAR을 빌드하니 의존성 해결에서
멈춘다:

```
Could not find com.github.davidliu:audioswitch:89582c47c9a04c62f90aa5e57251af4800a62c9a.
Searched in: dl.google.com/dl/android/maven2, repo.maven.apache.org/maven2
Required by: root project : > io.livekit:livekit-android:2.18.2
```

`audioswitch`는 mavenCentral·google에 없고 **jitpack에만** 있다. 커밋 해시를 버전으로 쓰는
전형적인 jitpack 아티팩트다.

**등록할 곳이 두 군데다.** 플러그인 AAR을 빌드하는 쪽(`settings.gradle`의
`dependencyResolutionManagement.repositories`)에만 넣으면 플러그인은 빌드되지만, **앱을
익스포트할 때 Godot 자신의 gradle 빌드가 같은 의존성을 다시 해결하다 실패한다.** Godot은
`.gdap`의 `[dependencies]` 섹션을 읽어 `plugins_remote_binaries`·`custom_maven_repos`
프로젝트 속성으로 자기 빌드에 넘긴다(`android/build/config.gradle`의
`getGodotPluginsRemoteBinaries`). 그래서 `.gdap`에도 같이 적어야 한다:

```
[dependencies]
remote=["io.livekit:livekit-android:2.18.2"]
custom_maven_repos=["https://jitpack.io"]
```

**해결:** Godot Android 플러그인이 maven 의존성을 쓰면 **플러그인 빌드와 `.gdap` 양쪽에**
저장소와 버전을 적는다. 버전은 한 곳(예: 플러그인의 `gradle.properties`)에만 쓰고 빌드
스크립트가 `.gdap`에 써 넣게 하면 둘이 어긋나지 않는다 — 플러그인이 컴파일된 버전과 앱이
런타임에 해결하는 버전이 다르면 `NoSuchMethodError`로 나타나고, 원인이 플러그인 쪽에 있는
것처럼 보인다. 이 방식이면 플러그인 AAR은 16KB로 남고 SDK와 WebRTC 네이티브 라이브러리는
앱 빌드가 한 벌만 가져온다(실측: APK 176MB → 192MB, `lib/arm64-v8a/liblkjingle_peerconnection_so.so`
포함).

## GDT-077 — godot-livekit이 죽는 안드로이드에서 LiveKit 공식 Kotlin SDK를 Godot 플러그인 v2로 감싸면 음성이 된다 (실기기 확인)

`측정 2026-09-14 · Godot 4.7.2-stable · io.livekit:livekit-android 2.18.2 · Pixel 7 Pro(Android 17) · LiveKit 자체 호스팅`

**증상:** GDT-067이 남긴 벽 — godot-livekit GDExtension은 안드로이드에서 빌드·로드까지 되지만
`connect_to_room`에서 100% SIGSEGV한다(JNI/`JavaVM` 등록 부재). 상류 `client-sdk-cpp` 기여
규모라 벤더링으로는 못 넘는다.

**LiveKit 공식 Android SDK는 Kotlin이고 그 등록을 스스로 한다.** GDT-012·014의 플러그인 v2
패턴으로 감싸면 상류를 안 건드리고 넘어간다. 실기기에서 확인한 것:

```
GodotPluginRegistry: Completed initialization for Godot plugin TrpgVoice
NativeLibrary: Loading native library: lkjingle_peerconnection_so ... ok
MediaFocusControl: requestAudioFocus() ... USAGE_VOICE_COMMUNICATION
  ... io.livekit.android.audio.AudioSwitchHandler ... callingPack=com.trpg.client
AOC: H1:MSG: asp_fm.cc, 223: All mics are not blocked   (마이크 켠 동안 1초마다)
```

룸 연결·마이크 publish·원격 참가자 음성 수신까지 동작했고 **앱이 죽지 않는다** — 같은 지점에서
GDExtension은 4/4 크래시했다.

**구조(요점만):** 독립 gradle 프로젝트에서 `GodotPlugin` 서브클래스 하나를 AAR로 빌드하고,
`.gdap`과 함께 `res://android/plugins/`에 둔다. 버전은 **Godot 빌드 템플릿의
`android/build/config.gradle`과 정확히 일치시킨다**(여기서는 AGP 8.6.1 · Kotlin 2.1.21 ·
compileSdk 36 · minSdk 24 · Java 17) — 다른 툴체인으로 컴파일한 플러그인은 "로드가 안 된다"로
나타난다. Godot 클래스는 빌드 템플릿의 `libs/release/godot-lib.template_release.aar` 안
`classes.jar`를 꺼내 `compileOnly`로 건다. SDK 자체도 `compileOnly`로 두고 실제 해결은 `.gdap`의
`remote=[...]`에 맡기면 플러그인 AAR은 16KB로 남고 앱이 SDK와 WebRTC 네이티브를 한 벌만
가져온다(APK 176MB → 192MB).

**SDK 호출은 전부 비동기로 감싼다.** `room.connect`·`setMicrophoneEnabled`가 suspend이고 Godot의
호출은 렌더 스레드로 들어온다 — 즉시 반환하고 시그널로 보고하는 형태가 아니면 프레임이 멈춘다.
시그널은 `Activity.runOnUiThread`를 거쳐 넘긴다.

**해결:** GDExtension이 특정 플랫폼에서만 죽는다면, 그 플랫폼에 **공식 네이티브 SDK가 있는지
먼저 본다.** C++ 레이어의 JNI 초기화를 상류에 기여하는 것보다 그 플랫폼의 공식 SDK를 플러그인으로
감싸는 편이 훨씬 싸다 — 여기서는 Kotlin 180줄 + GDScript 100줄이었다. 데스크톱은 GDExtension을
그대로 두고 공급자 인터페이스 뒤에서 갈라 세우면 호출 지점은 안 바뀐다. 그리고 **실기기에서
룸 연결까지 실행해 확인해라** — 빌드 성공도, 플러그인 로드 성공도 런타임 동작의 증거가 아니다.

---

## GDT-078 — 같은 층끼리의 겹침을 테스트로 막아도, 층이 다른 둘은 그 테스트가 못 본다 (3D `Label3D` 대 2D HUD)

`측정 2026-09-15 · Godot 4.7.2-stable, Pixel 7 Pro(3120×1440) 실기기 + 맥 동일 화면비 재현`

**증상:** GDT-073 방식으로 월드 라벨끼리의 화면 겹침을 유닛 테스트로 고정해 뒀다(카메라 4방향에서
각 `Label3D`의 화면 사각형을 구해 `Rect2.intersects()` 확인). 통과한다. 그런데 실기기에서 보니
월드 간판이 **2D HUD 패널 위에** 그대로 얹혀 있었다. 테스트는 3D 라벨끼리만 비교하므로 이 조합을
아예 보지 않는다.

기하학적으로 당연한 일이다: 월드 라벨은 멀어질수록 **화면 구석 쪽으로** 투영된다. 그리고 HUD 패널은
대개 구석에 붙어 있다. 즉 "멀리 있는 월드 라벨"과 "화면 구석의 2D 패널"은 **서로 끌리는 관계**다.
가로로 긴 화면(폰 가로 3120×1440 = 13:6)일수록 구석까지의 각도가 커서 더 잘 만난다.

**두 좌표계가 한 화면을 나눠 쓰는 곳이면 형태가 같다.** 3D/2D뿐 아니라, 창 기준 좌표와 가상
데스크톱 기준 좌표(GDT-068), 뷰포트 좌표와 안전영역 좌표 사이에서도 "각 층 안에서는 맞는데 층을
건너면 어긋나는" 같은 모양이 나온다.

**해결 — 두 갈래다.**

1. **상황 자체를 없앤다(싸다).** 월드 라벨을 "가까울 때만 그린다"로 바꾼다. 멀리서 구석으로
   투영되는 일이 없어지므로 층 간 겹침도 같이 사라진다. 판정은 순수 함수라 테스트가 쉽다:
   `signage_visible(player_pos, anchor_pos) = 땅 위 거리 <= R`. 상호작용하러 가야 하는 안내
   (상점 가격표·상태 문구)면 이게 맞는 답이기도 하다 — 멀리서 읽을 이유가 없다.
2. **층을 건너 비교한다(정확하지만 비싸다).** 2D `Control`의 `get_global_rect()`와 월드 라벨의
   화면 사각형(GDT-073의 식)을 같은 픽셀 좌표계에 놓고 `intersects()`를 본다. HUD가 앵커·스트레치로
   자리를 잡으면 뷰포트 크기마다 달라지니 화면비 몇 개를 표로 돌려야 한다.

**실기기까지 안 가도 재현된다.** `godot --resolution 1560x720`(폰과 같은 13:6)로 창 모드 실행 +
`FARM_SHOT`류 스크린샷이면 같은 겹침이 그대로 나온다. 폰이 공유 장비라면 이쪽이 훨씬 싸다.

## GDT-079 — 안드로이드에서 "앱이 소리를 내는가"는 `dumpsys audio` 로 무인 판정된다. 단 스트림을 구분해야 한다

`측정 2026-09-14 · Android 17(Pixel 7 Pro) · Godot 4.7.2 + LiveKit Android SDK 2.18.2`

**증상:** 음성 통화 앱이 상대방 목소리를 실제로 스피커로 내보내는지를 사람 귀 없이 확인해야 했다.
로그에는 "연결됨"까지만 찍히고, 그 뒤 오디오가 실제로 흐르는지는 안 보인다.

`adb shell dumpsys audio` 의 `players:` 목록이 답을 준다. **함정이 둘이다.**

**① 필드 이름이 `uid:` 가 아니라 `u/pid:<uid>/<pid>` 다.** `uid:` 로 grep 하면 0건이 나오고
"재생 안 함"으로 오판한다. pid 로 좁히지 않으면 반대로 남의 앱 재생을 내 것으로 센다 —
폰이 공유 장비면 남의 앱은 늘 떠 있다.

**② 앱 하나가 스트림을 둘 연다.** Godot + LiveKit 조합의 실측:

```
type:OpenSL ES AudioPlayer (Buffer Queue)  usage=USAGE_MEDIA
    sampleRate=44100 channelMask=0x3(스테레오)   state:started   ← Godot 자체 오디오
type:android.media.AudioTrack  usage=USAGE_VOICE_COMMUNICATION content=CONTENT_TYPE_SPEECH
    sampleRate=48000 channelMask=0x1(모노)       state:started   ← 상대방 목소리
```

**앞엣것은 앱이 떠 있으면 항상 `started` 다.** 그것으로 PASS 를 내면 음성이 완전히 끊겨도
늘 통과하는 판정이 된다. 통화 오디오는 `USAGE_VOICE_COMMUNICATION` + `CONTENT_TYPE_SPEECH` +
48kHz 모노 쪽이다.

**해결:** 판정은 `u/pid:[0-9]+/<앱 pid> state:started` 로 좁히고 **그 위에
`USAGE_VOICE_COMMUNICATION` 을 한 번 더 건다.** 2초 간격 폴링이면 충분하다.

**반대 방향(폰 마이크 → 상대방)은 이 방법으로도, 다른 어떤 방법으로도 무인 판정이 안 된다.**
폰 스피커로 합성 음성을 재생해 폰 마이크가 줍게 하려 해도 WebRTC 의 에코 캔슬레이션이 자기
출력을 제거한다 — 그게 AEC 의 목적이다. 안드로이드는 앱 외부에서 `AudioRecord` 입력을 주입할
수단도 주지 않는다(루트·특수 빌드 제외). **이 축은 사람이 폰에 대고 말하는 것 외에 길이 없다** —
무인 하네스를 설계할 때 여기에 시간을 쓰지 마라.

## GDT-080 — prebuilt Android export does write `screenOrientation` from `project.godot`: `window/handheld/orientation=6` becomes manifest value `13`

`측정 2026-09-19 · Godot 4.7.2-stable · Android prebuilt export (gradle_build/use_gradle_build=false) · aapt2 36.1.0`

**증상:** GDT-066 and GDT-072 report that the Android manifest's `screenOrientation`
ignores `project.godot` and is always `0` (landscape). A fresh project measured
the opposite. With `[display] window/handheld/orientation=6` (the integer for
`SCREEN_SENSOR`) in `project.godot` and a prebuilt debug export
(`godot --headless --path client --export-debug Android out.apk`):

```
aapt2 dump xmltree out.apk --file AndroidManifest.xml | grep screenOrientation
A: http://schemas.android.com/apk/res/android:screenOrientation(0x0101001e)=13
```

`13` is `ActivityInfo.SCREEN_ORIENTATION_FULL_USER`, not landscape. The export
preset has no orientation key at all (none exists in 4.7.2, as GDT-066 found).
What differs from the GDT-066 setup is not yet isolated. Candidates are the
integer form (`6`) versus the string form (`"sensor"`) of the setting, and a
preset created from scratch versus an older one.

**해결:** Set the orientation as the integer enum in `project.godot` and check
the exported APK with `aapt2 dump xmltree` rather than assuming the result either way.
On the device (Pixel 7 Pro, Android 17) the game followed the system rotation: `settings put system user_rotation 1` turned it to `ROTATION_90` with no runtime `screen_set_orientation` call.

## GDT-081 — Android export fails with "ETC2/ASTC texture compression is required" until `import_etc2_astc` is on

`측정 2026-09-19 · Godot 4.7.2-stable · headless --export-debug Android`

**증상:** A project that only exported to Web (`vram_texture_compression/for_mobile=false`)
gets an Android preset and the headless export stops with exit status
non-zero and only this (the editor locale was Korean):

```
ERROR: Cannot export project with preset "Android" due to configuration errors:
ETC2/ASTC 텍스처 압축은 Android 내보내기에 필요합니다. ...
ERROR: Project export for preset "Android" failed.
```

Nothing is written. The same run also prints `cannot connect to daemon at tcp:5037`,
which is the exporter polling adb and is unrelated to the failure.

**해결:** Add `textures/vram_compression/import_etc2_astc=true` under `[rendering]`
in `project.godot`. The next export reimports the textures and succeeds (59 MB APK
for this project, about 20 s including the reimport).

## GDT-082 — `ProjectSettings.get_setting()` ignores feature-tag overrides such as `my/key.android`; use `get_setting_with_override()`

`측정 2026-09-19 · Godot 4.7.2-stable · Android prebuilt export · Pixel 7 Pro`

**증상:** A custom setting has a per-platform override in `project.godot`:

```
[battlemarble]
nakama_url="http://127.0.0.1:7350"
nakama_url.android="https://bm.mnori.com/nakama"
```

Both keys are in the exported `assets/project.binary` (`strings` shows them). On the
phone, `ProjectSettings.get_setting("battlemarble/nakama_url", ...)` still returned the
base value, so every request went to `127.0.0.1` and `HTTPRequest` finished with
`Result 2` (`RESULT_CANT_CONNECT`). The UI only showed a generic "no response" message.
`adb shell toybox nc -w 3 <host> 443` from the same phone connected, which ruled out the network.

**해결:** Read custom settings that carry `.feature` variants with
`ProjectSettings.get_setting_with_override("battlemarble/nakama_url")`. The engine's own
settings already go through the override path. When an HTTP request fails, log the full
URL and the `HTTPRequest.Result` number, not just a message: `Result 2` together with a
loopback URL is diagnosed in one line.

## GDT-083 — UI scaled up with `Control.scale` on a high-density phone is blurry: text and 3D both render at layout size

`측정 2026-09-19 · Godot 4.7.2-stable · gl_compatibility · Pixel 7 Pro (1440x3120, 560 dpi)`

**증상:** The project keeps `window/stretch/mode="disabled"` and lays out in
density-independent units: the root Control is 411 units wide and gets
`scale = 3.5` to fill 1440 physical pixels. On the phone every label is soft and
the 3D board inside a `SubViewportContainer` (`stretch=true`) is visibly pixelated.
Both are rendered at the 411-unit size and magnified 3.5x.
- Glyphs are rasterised at `font_size`. The node transform does not raise font oversampling.
- The SubViewport takes the container's unscaled size.

**해결:** Two separate fixes, both measured on the device (60 fps held with MSAA 4x on a
1440x3122 SubViewport, Mali-G710):
1. **Text:** `get_window().oversampling_override = <scale>`. This property exists on
   `Viewport` in 4.7. Glyphs are then rasterised at the displayed size.
2. **3D:** Size the container in device pixels and shrink it back with its own transform:
   `container.size = layout_size * scale` and `container.scale = Vector2.ONE / scale`.
   The SubViewport then renders at device resolution. Container-local input events are
   now in device pixels. Convert them before your camera code by scaling the event with
   `event.xformed_by(Transform2D.IDENTITY.scaled(container.scale))`. Multiply positions
   by the scale for `camera.project_ray_origin()`, and divide the result of
   `camera.unproject_position()` by it.

Do not instead set `stretch=false` and a larger SubViewport size. The container's
minimum size follows the SubViewport, so the container grows to the SubViewport's size
rather than scaling it down (a 200x200 container became 400x400).
