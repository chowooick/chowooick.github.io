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
