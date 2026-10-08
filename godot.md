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

## GDT-084 — `release_focus()` deferred from a Button's mouse-press cancels the click; fast automated clicks hide it

`측정 2026-09-20 · Godot 4.7.2-stable, Web export, Chrome 14x / WebKit (Playwright)`

**증상:** 버튼을 사람이 누르면 아무 일도 없다("눌러도 멈춤"). Playwright `mouse.click()` 테스트는 전부 통과한다.
원인은 마우스 클릭 뒤 포커스 테두리를 없애려고 `gui_input`에서 **누름(pressed)** 이벤트에
`call_deferred("release_focus")`를 건 코드다. 지연 호출은 그 프레임 끝에 돈다. 사람 클릭(누름→뗌 약 100ms)은
여러 프레임에 걸치므로 뗌보다 먼저 포커스가 빠지고, BaseButton은 포커스를 잃을 때 진행 중인 누름
(`press_attempt`)을 취소한다 → `pressed` 시그널이 안 나온다. `mouse.click()`은 누름·뗌이 같은 프레임에
들어가 뗌이 먼저 처리되므로 재현되지 않는다. Godot는 누름·뗌 이벤트를 모두 받고
(`gui_get_hovered_control()`도 그 버튼), 서버 로그에는 요청이 하나도 없다.

**해결:** 포커스 해제는 **뗌(`not event.pressed`)** 에서 한다. 클릭 테스트는
`mouse.down()` → `waitForTimeout(120)` → `mouse.up()`으로 사람 속도를 흉내 내야 이런 결함이 잡힌다(FARM).

## GDT-085 — Web export: thousands of `PrimitiveMesh` resources make WebKit drop the WebGL context at startup

`측정 2026-09-20 · Godot 4.7.2-stable, Web export (Compatibility), Playwright WebKit 26 on macOS`

**증상:** Chrome에서는 멀쩡한데 WebKit에서는 시작 0.4초 만에 `WebGL: context lost.`, 이어서
`Could not create texture atlas, status: 36061`, `SceneShaderGLES3: Vertex shader compilation failed: (unknown error)`가
쏟아지고 화면이 검다. WebGL 호출을 감싸 세어 보니 잃는 순간 **살아 있는 버퍼가 12,734개**(`createBuffer` 12,734 ·
`deleteBuffer` 3)였다. 절차적으로 월드를 짓느라 `BoxMesh.new()`·`CylinderMesh.new()`를 조각마다 새로 만들어
고유 메시가 5,109개였고, 메시마다 정점·속성·인덱스 버퍼를 따로 올린다. 나중에 `SurfaceTool.append_from`으로
몇십 개 배치로 합치고 원본을 지워도 **합치기 전에 이미 한꺼번에 업로드된다** — PrimitiveMesh는
`MeshInstance3D.mesh`에 넣거나 배열을 읽는 순간 GPU에 올라간다. MSAA·그림자 크기·안개를 끈 빌드는 모두 똑같이
죽었다.

**해결:** 같은 치수의 프리미티브는 메시 하나를 공유한다(`"box%s" % size` 같은 키로 캐시). 고유 메시 5,109개 →
1,303개로 줄이자 WebKit에서 컨텍스트 손실이 사라졌다. 절차적 월드를 웹에 낼 때는 WebKit으로 한 번 띄워
`webglcontextlost` 이벤트를 확인한다(FARM).

## GDT-086 — gstack browse 기본(headless) Chromium에는 WebGL2가 없다: Godot 웹 빌드는 기능 누락 화면에서 멈춘다. `--headed`로 띄우고 캔버스는 합성 PointerEvent로 누른다

`측정 2026-09-26 · Godot 4.7.2-stable Web export(Compatibility, 스레드 없음), gstack browse(Chromium), macOS`

**증상:** 배포한 Godot 웹 페이지를 `$B goto`로 열면 HTTP 200인데 게임이 뜨지 않는다. 콘솔 원문:
`The following features required to run Godot projects on the Web are missing: WebGL2 - Check web browser configuration and hardware support`.
사이트 문제가 아니라 headless 데몬의 GPU 없는 렌더러 문제다. 이어서 `$B --headed goto ...`를 부르면 첫 호출은 창을 띄우지만,
그 뒤 플래그 없이 부른 명령은 전부 `existing daemon has different config (proxy/headed mismatch)`로 실패한다.

**해결:** `$B stop` 뒤 `$B --headed goto <url>`로 띄우고, **이후 모든 명령에도 `--headed`를 붙인다**.
확인은 `$B --headed js "String(!!document.createElement('canvas').getContext('webgl2'))"` → `true`.
Godot 캔버스는 DOM 요소가 없어 `click @ref`가 안 된다. CSS 좌표로 이벤트를 합성하면 Godot 버튼이 눌린다
(누름과 뗌 사이 120ms — GDT-084의 사람 속도 클릭과 같은 이유):

```sh
$B --headed js "(()=>{const c=document.querySelector('canvas');const o={clientX:X,clientY:Y,bubbles:true,button:0,buttons:1,pointerId:1,pointerType:'mouse',isPrimary:true};
for(const t of ['pointermove','pointerdown','mousedown'])c.dispatchEvent(t.startsWith('pointer')?new PointerEvent(t,o):new MouseEvent(t,o));
setTimeout(()=>{const u={...o,buttons:0};c.dispatchEvent(new PointerEvent('pointerup',u));c.dispatchEvent(new MouseEvent('mouseup',u))},120)})()"
```

스크린샷 픽셀은 CSS 좌표가 아니다(headed 창은 `viewport` 설정이 먹지 않았고 dpr 2). `$B --headed js "innerWidth+'x'+innerHeight"`로
실제 크기를 받아 `X = 스크린샷x × innerWidth / 스크린샷폭`으로 환산한다. 이 방법으로 로비 → 온라인 대화상자 → 방 참여까지 진행했다.

## GDT-087 — 삼항식으로 만든 배열을 `Array[float]` 변수에 넣으면 SCRIPT ERROR가 나고 그 함수만 조용히 중단된다. 테스트 러너의 종료 코드는 0으로 남는다

`측정 2026-09-26 · Godot 4.7.2-stable, --headless --script 테스트 러너`

**증상:** `var spreads: Array[float] = [0.0] if stage == 1 else [-0.22, 0.0, 0.22]` 한 줄이 실행될 때마다
`SCRIPT ERROR: Trying to assign an array of type "Array" to a variable of type "Array[float]".`가 찍힌다.
그 함수는 그 줄에서 멈추지만 호출한 쪽은 계속 돌아간다. 그래서 `_check` 기반 테스트는 "75 checks, 0 failures"로 통과했고,
이 분기(보스의 조준 사격)만 한 번도 일어나지 않았다. 밸런스 측정에서 "탄에 맞은 횟수 0"이 나와서야 알았다.
리터럴을 바로 대입하면 타입이 추론되지만 삼항식의 결과는 타입 없는 `Array`로 취급된다.

**해결:** 삼항식 결과를 받는 변수는 `var spreads: Array = ...`처럼 타입 없는 Array로 선언하거나, `Array[float](...)`로 감싼다.
테스트를 돌릴 때는 `2>&1 | grep -E "SCRIPT ERROR|checks"`처럼 출력에서 `SCRIPT ERROR`를 함께 거른다. 통과 개수만 보면 이 오류를 놓친다.

## GDT-088 — 웹 export에는 시스템 글꼴 폴백이 없다: 네이티브에서 멀쩡하던 ♥ ● ○가 웹에서만 네모(tofu)로 나온다

`측정 2026-09-27 · Godot 4.7.2-stable, Web export(GL Compatibility), headed Chromium`

**증상:** 라틴 전용 글꼴(Space Grotesk)을 쓴 Label의 `♥ 3`, `●●○`가 macOS 네이티브 실행과 네이티브 캡처에서는 정상이었다.
웹 빌드에서만 네모 상자로 나왔다. 네이티브는 글꼴에 없는 글리프를 OS 시스템 글꼴로 조용히 채우고, 웹에는 그런 폴백이 없다.
그래서 네이티브 스크린샷 검수로는 이 문제를 잡을 수 없다.

**해결:** 기호가 들어 있는 글꼴을 그 Label에 직접 지정한다(Noto Sans KR에는 ♥●○가 있다). 또는 FontVariation/FontFile의 `fallbacks`에
그 글꼴을 넣는다. 기호를 쓰는 HUD는 웹 빌드를 실제 브라우저에서 한 번은 캡처해 확인한다.

## GDT-089 — 테스트에서 `Input.parse_input_event()` 뒤에 `Input.flush_buffered_events()`를 부르면 이벤트가 그 자리에서 `_unhandled_input`까지 전달된다. 핸들러를 직접 한 번 더 부르면 두 번 처리된다

`측정 2026-09-27 · Godot 4.7.2-stable, --headless --script 테스트 러너(SceneTree)`

**증상:** `Input.is_physical_key_pressed()`로 이동을 읽는 게임에서, 테스트가 `parse_input_event()`만 부르면 키 상태가 반영되지 않았다
(프레임을 기다리지 않으면 버퍼에 남는다). `flush_buffered_events()`를 더하자 키 상태는 반영됐다. 그런데 같은 이벤트로
`app._unhandled_input(event)`도 직접 부르던 테스트에서 Esc가 두 번 처리됐다. 메뉴가 열렸다가 바로 닫혀 "Esc로 일시 정지" 검사가 실패했다.
flush가 이벤트를 루트 Viewport로 밀어 넣어 GUI와 `_unhandled_input`까지 동기로 전달하기 때문이다.

**해결:** 합성 키 입력은 `parse_input_event(e)` 다음에 `flush_buffered_events()`만 부른다. 핸들러를 직접 부르지 않는다.
GDT-031의 "누름이 늦게 도착한다" 문제도 flush로 프레임을 기다리지 않고 해결된다.

## GDT-090 — On HiDPI macOS, `window_width_override` and `DisplayServer.window_set_size()` are in device pixels: a 1280 × 800 setting opens a 640 × 400 point window

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility · macOS 27, 4K display at 2× scaling (3840 × 2160 px, 1920 × 1080 pt)`

**증상:** The project set `window/size/window_width_override=1280` and `window_height_override=800` with `allow_hidpi=true`. On a 4K display at 2× scaling, the game opened in a window one third of the screen width. The user reported that the screen was far too small. Measured values:
- `DisplayServer.window_get_size()` returned `(1280, 800)`, and `window_get_size_with_decorations()` returned `(1280, 864)`. The 64 px title bar is 32 pt at 2×, so the numbers are device pixels.
- `DisplayServer.screen_get_size(0)` returned `(3840, 2160)` with `screen_get_scale(0) = 2.0`.
- The saved framebuffer image (`get_texture().get_image()`) was 1280 × 800.
- `DisplayServer.window_set_size(Vector2i(2880, 1800))` likewise produced a 1440 × 900 point window.

**해결:** Size the window from the screen at runtime, not from the project override:

```gdscript
var screen := DisplayServer.window_get_current_screen()
var scale := maxf(1.0, DisplayServer.screen_get_scale(screen))
var usable := DisplayServer.screen_get_usable_rect(screen)   # also device pixels
DisplayServer.window_set_min_size(Vector2i(Vector2(960, 600) * scale))
DisplayServer.window_set_size(Vector2i(Vector2(usable.size) * 0.84))   # restore size
DisplayServer.window_set_position(usable.position + (usable.size - DisplayServer.window_get_size()) / 2)
DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
```

- Skip this code for `OS.has_feature("web")` and for the `headless` display server.
- Once maximized, the window measured 3840 × 2036 px, which is the whole usable area.

## GDT-091 — Under `canvas_items` stretch, `get_viewport().get_texture().get_size()` is not the framebuffer size: it is the window size multiplied by the stretch scale

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility · stretch mode canvas_items, aspect expand, base 1440 × 900 · macOS`

**증상:** A screenshot script printed `root.get_texture().get_size()` next to each saved PNG, and the numbers did not match the files:

| Window | `get_texture().get_size()` | Saved image |
| --- | --- | --- |
| 1280 × 800 | 1138 × 712 | 1280 × 800 |
| 1000 × 600 | 667 × 400 | 1000 × 600 |
| 3840 × 2036 | 8690 × 4606 | 3840 × 2036 |

In every row the texture size equals the window size multiplied by the stretch scale, which is `min(window / base)`.

**해결:**
- Read the real size from the image: `get_texture().get_image().get_size()`.
- For device pixels per layout pixel, use `get_viewport().get_final_transform().get_scale().x`. It gave 0.889 at 1280 × 800 and 2.26 at 3840 × 2036.

함께 걸림: GDT-006

## GDT-092 — The headless display server's window is square: under `canvas_items` + `expand`, a 1440 × 900 layout becomes 1440 × 1440 in `--headless` tests

`측정 2026-09-27 · Godot 4.7.2-stable · --headless --script test runner (SceneTree) · stretch canvas_items / expand, base 1440 × 900`

**증상:** A UI test checked that the HUD chose its layout for a 16:10 window. The check passed in a windowed run and failed headless. In headless mode the root Control measured `1440 × 1440`. Because `expand` keeps the base width and grows the height to the window's aspect ratio, a square headless window yields a square layout. Any layout that depends on aspect ratio, such as letterbox docking or fit-to-window boards, takes a different branch in headless tests.

**해결:**
- At the start of the test, set the root window's size before instancing the scene: `root.size = Vector2i(1440, 900)`.
- To test other aspect ratios, give the scene's root Control top-left anchors first with `set_anchors_preset(Control.PRESET_TOP_LEFT)`, then set its `size`. Setting `size` on a full-rect-anchored Control logs "Nodes with non-equal opposite anchors will have their size overridden".

## GDT-093 — `clip_children = CLIP_CHILDREN_ONLY`로 외곽선·그림자 있는 Label을 대각선으로 자르면, 마스크 다각형 중 글자가 없는 부분에 검은 사각형 띠가 생긴다

`측정 2026-09-27 · Godot 4.7.2-stable, gl_compatibility, macOS 네이티브 캡처`

**증상:** 로고를 대각선으로 잘라 두 조각을 어긋나게 하려고, 다각형을 그리는 Control에 `clip_children = CLIP_CHILDREN_ONLY`를 켜고
그 자식으로 `outline_size`·`font_shadow_color`가 있는 Label을 넣었다. 잘림은 됐지만 마스크 다각형 안에서 **글자가 덮지 않는 영역**
(로고 위 여백, 아래 여백)이 배경보다 어두운 직사각형 띠로 찍혔다. 배경이 하프톤이라 띠가 바로 눈에 띄었다.

**해결:** clip_children을 쓰지 않는다. 같은 Label 두 개에 각각 캔버스 셰이더를 걸어, `vertex()`에서 `VERTEX`를 varying으로 넘기고
`fragment()`에서 직선의 한쪽이면 `discard`한다(두 Label은 side 부호만 반대). 글리프·외곽선·그림자 모두 같은 로컬 좌표로 그려지므로
한 번에 잘리고, 검은 띠가 사라졌다. `COLOR`를 건드리지 않으면 기본 출력(텍스처 × 모듈레이트)이 그대로 쓰인다.

## GDT-094 — StyleBoxFlat 세 속성으로 "잘린 모서리·평행사변형·하드 섀도" UI 키트를 커스텀 드로잉 없이 만든다

`측정 2026-09-27 · Godot 4.7.2-stable, gl_compatibility 네이티브 + Web export(Chromium)`

**증상:** 사선으로 잘린 패널과 기울어진 버튼, 오프셋 하드 섀도(스티커 느낌)를 원했다. 매 컨트롤마다 `_draw()`를 쓰면
컨테이너 레이아웃·포커스·호버를 다시 구현해야 한다.

**해결:** `StyleBoxFlat`만으로 된다.
- **45° 잘린 모서리:** 원하는 모서리만 `corner_radius_*`를 주고 `corner_detail = 1`로 두면 곡선 대신 직선 한 번으로 깎인다.
- **평행사변형:** `skew = Vector2(0.2126, 0)`이면 12° 기울어진 버튼·칩이 된다. 텍스트는 기울지 않는다.
- **하드 섀도:** `shadow_size = 1`과 `shadow_offset = Vector2(6, 6)`, 불투명 색을 주면 흐림이 1px뿐이라 판화처럼 딱 떨어지는 그림자가 된다.

Button의 normal/hover/pressed/focus 스타일박스에 그대로 넣으면 컨테이너 배치·키보드 포커스가 기본 동작 그대로 유지된다.
웹 빌드에서도 같은 모양으로 그려졌다.

## GDT-095 — A headless run that quits while `AudioStreamPlayer`s are still playing reports leaked `AudioStreamPlaybackOggVorbis` instances; stopping them in `_exit_tree()` makes it worse

`측정 2026-09-27 · Godot 4.7.2-stable, --headless (Dummy audio driver)`

**증상:** A headless test that ends with `quit()` while OGG music or one-shot effects are still
sounding prints `WARNING: N ObjectDB instances were leaked at exit` and
`ERROR: M resources still in use at exit`. `--verbose` lists `AudioStreamPlaybackOggVorbis`,
`OggPacketSequencePlayback` and the `.ogg` resources that were playing.

- The count depends on what is sounding at the moment of quit: 26 to 34 across runs of the same
  UI test.
- Adding an `_exit_tree()` to the audio node that calls `stop()` on every player and clears its
  `stream` raised the count to 44.
- Calling `stop()` and then waiting 0.1 s before freeing removed the lines entirely. That fits the
  playbacks being released on a later audio mix step, which teardown never reaches.

**해결:** At the end of a test, stop the players, give the audio server a moment, then free and quit:

```gdscript
for child in audio_node.get_children():
    if child is AudioStreamPlayer:
        child.stop()
await create_timer(0.1).timeout
audio_node.queue_free()
await process_frame
quit(exit_code)
```

In a 156-check audio test this took the exit report from 8 leaked instances to none. The lines are
exit-only noise, but they hide real leak regressions in the same test run.

## GDT-096 — `"%x" % n` prints a negative int with a minus sign (`-5`, `-340d631b7bdddcdb`): to match a Rust `u64` hash, print the two 32-bit halves

`측정 2026-09-27 · Godot 4.7.2 · Rust 1.97.1`

**증상:** A content hash (FNV-1a 64 over the same JSON files) had to match between a SpacetimeDB Rust module
and the Godot client. FNV's offset basis `0xcbf29ce484222325` does not fit a signed int64, and GDScript
`"%016x" % -3750763034362895579` prints `-340d631b7bdddcdb` instead of `cbf29ce484222325`.

GDScript `int` multiplication wraps modulo 2^64, like Rust `wrapping_mul`, so the arithmetic itself
matched: the client and the server both produced `f256051205efd6e4` for the same files.

**해결:** Keep the value as a signed int and format the halves:
`"%08x%08x" % [(h >> 32) & 0xFFFFFFFF, h & 0xFFFFFFFF]`. Write the offset basis as its signed value
(`-3750763034362895579`) because the hex literal overflows.

## GDT-097 — Web export sample playback loops music by restarting from the `ended` event: every loop point gaps (median 11 ms, up to 113 ms). Stream playback in a no-threads build dropped out 55 % of the time under load

`측정 2026-09-27 · Godot 4.7.2-stable Web export (nothreads template), headless Chromium + SwiftShader WebGL2`

**증상:** An `AudioStreamOggVorbis` with `loop = true` loops on the Web, but not seamlessly, even
when the file itself loops sample-exactly.

On the Web the default `audio/general/default_playback_type.web` is Sample. In that mode the engine
JS (`GodotAudio.SampleNode` in the exported `index.js`) never sets `AudioBufferSourceNode.loop`.
When the source fires `ended` and the sample's `loopMode` is `forward`, `_restart()` creates a new
source and calls `start()` with the same start time. That time is "now", so the new source begins
whenever the main thread gets to the event.

Measured facts:

- **Loop gap.** Probing the `ended` event with the game's title screen rendering: the restart came
  0.7 to 112.7 ms after the buffer end, median 11.3 ms, over 24 trials. A 67.2 s music loop was
  watched end to end and restarted 67.25 s after it began.
- **Stream playback drops out.** Forcing `AudioStreamPlayer.playback_type = PLAYBACK_TYPE_STREAM`
  on the music gives sample-exact loops and working bus effects. In the no-threads build, though,
  the mixer is fed from main-thread messages to an AudioWorklet ring buffer. With frames at a
  median 41.7 ms (max 624 ms), a monitor worklet counted 4,659 of 8,389 render quanta silent:
  404 dropouts, the longest 226 quanta (0.6 s). Sample playback kept playing through the same
  stalls.
- **Decode and memory.** A sample is decoded into a Float32 `AudioBuffer` at the context rate
  (48 kHz stereo: 0.38 MB per second of audio) on its first play or on
  `AudioServer.register_stream_as_sample()`. `getAudioBuffer()` duplicates that buffer for every
  playback. A 67.2 s track's first play fell inside a 1.37 s main-thread long task during boot.
- **No bus effects.** Bus effects (for example `AudioEffectLowPassFilter`) do not process
  sample playback.
- **Reading the mode.** To check at runtime whether a build is in Sample mode, read the setting
  with `ProjectSettings.get_setting_with_override("audio/general/default_playback_type")`. In the
  Web export it returned 1 (Sample), while plain `get_setting()` of the same key returned 0,
  the base value: plain `get_setting()` ignores the `.web` feature override.

**해결:**
- Keep Sample playback for music on the Web, and put a transient (crash, kick or stab) at
  sample 0 of every loop so its attack masks the restart gap.
- Call `AudioServer.register_stream_as_sample(stream)` for the next track while the screen is
  covered, so the decode does not land on gameplay.
- Fake Web "muffle" effects with volume.
- For the measurement, wrap `AudioBufferSourceNode.prototype.start` and the `AudioWorkletNode`
  constructor in an inline `<script>` placed before `index.js`, and launch Chromium with
  `--use-angle=swiftshader --enable-unsafe-swiftshader` so the WebGL2 game runs headless.

## GDT-098 — KayKit 2.0 characters ship with no animations; the separate `Rig_Medium_*.glb` files drive them in Godot with zero retargeting (2,316 of 2,316 tracks resolve)

`측정 2026-09-27 · Godot 4.7.2-stable, KayKit Adventurers 2.0 / Skeletons 1.1 / Character Animations 1.1 (itch.io free tiers)`

**증상:** In the current KayKit packs, `Knight.glb`, `Skeleton_Minion.glb` and the other characters
import with no `AnimationPlayer`. The 1.0 repositories on GitHub embed 76 clips in each character,
on a different 41-joint rig named `Rig` (checked on `Knight.glb`); 2.0 moved every clip into `Character Animations` as `Rig_Medium_General.glb`,
`_MovementBasic`, `_MovementAdvanced`, `_CombatMelee`, `_CombatRanged`, `_Simulation`, `_Special` and
`_Tools` (131 clips plus a `T-Pose` in each file). A second, bigger rig, `Rig_Large`, has 28 clips.

Every Rig_Medium character and every Rig_Medium animation file has a root node named `Rig_Medium`
and the same 23 joints (`root hips spine chest head upperarm.l ... handslot.l handslot.r ... toes.r`).
Node translation, rotation and scale matched exactly for all six characters checked, even though
the joint order differs between files. In Godot the skeleton imports as
`Rig_Medium/Skeleton3D` on both sides. The animation tracks address bones by name, so they fit as-is.

Measured headless: add an `AnimationPlayer` under the character, copy each animation file's clips
into an `AnimationLibrary`, add the libraries. Of 2,316 tracks, 0 failed to resolve against
`Knight.glb` and 0 against `Skeleton_Minion.glb`. `play("Rig_Medium_CombatMelee/Melee_1H_Attack_Chop")`
plus `seek(0.35, true)` moved `upperarm.r`.

**해결:** Do not set up retargeting (BoneMap or SkeletonProfile) between KayKit characters.
Import the `Rig_Medium_*.glb` files once, save their clips as `AnimationLibrary` resources, and share
them across all Rig_Medium characters. Weapons attach to `handslot.l` / `handslot.r` through a
`BoneAttachment3D`.

## GDT-099 — Two free asset packs import with the wrong shading: Kenney Nature Kit as fully metallic, Quaternius Cute Animated Monsters as unshaded

`측정 2026-09-27 · Godot 4.7.2-stable glTF importer, Kenney Nature Kit 2.1, Quaternius Cute Animated Monsters (Drive glTF)`

**증상:** The models look wrong under scene lighting, and the importer gives no warning.

- **Kenney Nature Kit** (`Models/GLTF format/*.glb`): every material is a flat `baseColorFactor` with
  `metallicFactor: 1` and `roughnessFactor: 1`. The file lists `KHR_materials_unlit` in
  `extensionsUsed` but no material applies it. Godot imports `shading_mode = PER_PIXEL`,
  `metallic = 1.00`. A fully metallic material takes its color from reflections, not from lights,
  so the leaves and rocks come out dark in an ordinary scene.
- **Quaternius Cute Animated Monsters** (`glTF/*.gltf`): the materials carry
  `KHR_materials_unlit`, and Godot imports `shading_mode = UNSHADED`. Lights and shadows do not
  touch them.

For comparison, KayKit (roughness 0.5, metallic 0), Kenney Platformer/Fantasy Town (metallic 0) and
Quaternius Ultimate Monsters (metallic 0, roughness 1) import as ordinary lit materials.

**해결:** Override the materials on import. Use per-material "Use External" with a replacement
`StandardMaterial3D`, or an `EditorScenePostImport` script that sets `metallic = 0` and
`shading_mode = SHADING_MODE_PER_PIXEL`. Check `metallic` and `shading_mode` of a newly imported pack
in a headless script before judging its look.

## GDT-100 — The WAV importer copies a `smpl` chunk's loop end (last frame index, frames − 1) into `loop_end`, so an imported loop drops its final sample on every pass

`측정 2026-09-27 · Godot 4.7.2-stable · 16-bit PCM WAV loops written by Python with a `smpl` chunk (loop start 0, end = frames − 1, per the RIFF spec)`

**증상:** Music and ambience loops were rendered sample-exact with a `smpl` loop chunk. The imported
`AudioStreamWAV` reported `loop_end` = frames − 1: the RIFF `smpl` chunk stores the *inclusive* index of the last
frame, and the importer uses it as the *exclusive* end, so one sample is skipped per loop. (Measured on the stream
values; audibility of the one-sample skip was not tested.)

**해결:** Override it at load time: `stream.loop_mode = AudioStreamWAV.LOOP_FORWARD`, `stream.loop_begin = 0`,
`stream.loop_end = <total frame count>` (for 16-bit PCM, `stream.data.size() / (2 * channels)`). Alternatively omit the
`smpl` chunk and set the loop only in code or in the import settings. Note that the importer's default compression
for WAV is QOA. Reference: `~/work/cobramission/client/core/audio/audio.gd`.

## GDT-103 — A `MeshInstance3D` built in code has an empty `skeleton` path: the skin is set, nothing errors, and the mesh renders in its rest pose

`측정 2026-09-27 · Godot 4.7.2-stable · Forward+ / Metal · skinned ArrayMesh + Skin built at runtime`

**증상:** A procedural character (`Skeleton3D` → child `MeshInstance3D` with `mesh` and `skin`)
never deformed. Bone poses changed (`get_bone_pose_rotation` returned animated values), but every
screenshot showed the bind pose. No warning was printed.

`MeshInstance3D.skeleton` defaults to `NodePath("")` in 4.x (the class reference lists
`default="NodePath(&quot;&quot;)"`), not `".."`. Editor-imported scenes store the path explicitly, which is
why this only shows up for nodes created from code. With an empty path the skin is never bound to
a skeleton.

**해결:** Set the path explicitly when you build the node: `mesh_instance.skeleton = NodePath("..")`
(or the path to the `Skeleton3D`). Verify with a pose change in a screenshot, not with bone values.

## GDT-101 — An `AnimationNodeTransition` built in code outputs nothing until a state is requested

`측정 2026-09-27 · Godot 4.7.2-stable · AnimationTree with a code-built AnimationNodeBlendTree`

**증상:** A code-built AnimationTree (`BlendSpace1D` → `TimeScale` → `Transition` → `OneShot` →
output) was active and processing, the library held 13 clips, and the same library animated the
skeleton through an `AnimationPlayer`. Through the tree, every bone stayed at rest.
`parameters/state/current_state` read `""`.

A `Transition` node added with `add_input()` has no current state until the first
`transition_request`; it then passes nothing downstream, so the whole tree blends to rest.

**해결:** Right after activating the tree, request the default state for every Transition node:
`tree.set("parameters/state/transition_request", "loco")`.

## GDT-102 — An inverted-hull outline that scales its offset by `VIEWPORT_SIZE` in `vertex()` drew no silhouette lines; the same offset from `PROJECTION_MATRIX` alone works

`측정 2026-09-27 · Godot 4.7.2-stable · Forward+ / Metal (M1 Max) · next_pass ShaderMaterial, cull_front, POSITION written`

**증상:** A pixel-width outline (next pass, `cull_front`, vertices pushed along the view-space normal,
`POSITION = PROJECTION_MATRIX * vp`) showed no lines around silhouettes. The offset was
`width_px * (VIEWPORT_SIZE.y / 1080.0) * 2.0 * depth / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y)`.
A constant 12 mm offset in the same pass drew clean silhouettes. `VIEWPORT_SIZE.y` itself reads
above 100 in `vertex()` in the color pass, so the value is not simply zero. The cause is not isolated.

**해결:** Leave `VIEWPORT_SIZE` out of the vertex offset. Use a resolution-relative width:
`2.0 * depth / (abs(PROJECTION_MATRIX[1][1]) * 1080.0) * width_px`. Check an outline change by
counting outline-coloured pixels in a windowed screenshot; thin dark lines are easy to miss by eye.

---

## GDT-104 — Wrapped Korean text breaks in the middle of words; a WORD JOINER between syllables fixes it

`측정 2026-09-27 · Godot 4.7.2-stable · TextServerAdvanced (ICU) · Pretendard 32 px`

**증상:** A Korean dialogue line in an autowrapping `Label` (`AUTOWRAP_WORD_SMART`) split the word
"어디부터" into "어디부 | 터". Choice cards and speech bubbles did the same ("나가니 | 까", "받 | 아").

Godot follows the UAX #14 default for Hangul, which allows a line break between any two syllables.
`TextParagraph` with `BREAK_WORD_BOUND | BREAK_ADAPTIVE` gives the same result, and the ICU keep-all
locale keyword does nothing. The same sentence at widths 640, 700 and 760 px:

| language passed to `add_string` | 700 px |
|---|---|
| `ko` | `… 자, 어디부 \| 터 시작할까?` |
| `ko@lw=keepall` or `ko-u-lw-keepall` | `… 자, 어디부 \| 터 시작할까?` (no effect) |
| `ko`, U+2060 between syllables | `… 자, \| 어디부터 시작할까?` |

**해결:** Insert U+2060 WORD JOINER between consecutive Hangul syllables (U+AC00–U+D7A3) before you
set wrapped text. Breaks then happen only at spaces. The joiner has zero width: the measured string
width stayed 830.0 px with and without it. Two follow-ups:
- A typewriter reveal that counts characters must skip U+2060, or Korean lines type out at half speed.
- Auto-translated labels cannot be pre-processed. Set the text from code with `tr()` plus the joiners,
  and re-apply it on `NOTIFICATION_TRANSLATION_CHANGED`.

---

## GDT-105 — `variation_opentype = {"wght": 700}` is silently ignored; Noto Sans JP then renders Thin

`측정 2026-09-27 · Godot 4.7.2-stable · NotoSansJP[wght].ttf from google/fonts`

**증상:** Japanese UI text in a `FontVariation` over the variable Noto Sans JP looked hairline-thin
at every requested weight. Bold labels and body text looked the same.

- `get_supported_variation_list()` reports the axis as `{ 2003265652: (100, 900, 100) }`.
  The default instance is **Thin 100**, not Regular.
- The string key `"wght"` is ignored, even though the class reference names it as an example.

| `variation_opentype` | width of "Hamburg WWW" at 40 px |
|---|---|
| `{}` | 276.0 |
| `{"wght": 100}` / `{"wght": 900}` | 276.0 / 276.0 (ignored) |
| `{2003265652: 900}` (int tag) | 311.0 |
| `{"weight": 900}` (axis name) | 311.0 |

**해결:** Key the axis by its integer tag, `0x77676874` or `TextServer.name_to_tag("wght")`, or by the
name `"weight"`. The saved `.tres` then shows `2003265652: 700`. When you check that a weight applied,
compare string widths; do not judge by eye.

---

## GDT-106 — Pretendard has kana but no kanji: Japanese text mixes two typefaces unless Noto Sans JP comes first

`측정 2026-09-27 · Pretendard 1.3.9 (static OTF) · Noto Sans JP (variable) · Godot 4.7.2-stable`

**증상:** A body font chain of Pretendard with a Noto Sans JP fallback worked for Korean and English. In
Japanese, kana and kanji came from different fonts inside one word. They differed in stroke weight and
in x-height.

A fontTools cmap check shows why. Pretendard Regular (14,336 glyphs) contains Hangul, hiragana,
katakana, 「」, 。, 、 and full-width ！, but no CJK ideographs (事 and 件 are missing). The primary font
is always tried first, so kana come from Pretendard and only kanji fall through to Noto Sans JP.
Other coverage from the same check: Black Han Sans has no kana and no kanji. Dela Gothic One has kana
and kanji but no Hangul. Anton and VT323 are Latin only.

**해결:** Re-order the chain by locale. For `ja`, make Noto Sans JP the base font and Pretendard the
fallback. For every other locale, use Pretendard first. The chains are shared `FontVariation`
resources referenced by the Theme, so changing `base_font` and `fallbacks` once at a locale change
updates every Control. Display chains need the same swap (Dela Gothic One before Black Han Sans for
`ja`).

---

## GDT-107 — `has_method()` on a loaded GDScript resource sees its `static func`s: a data layer can probe optional helpers without `class_name`

`측정 2026-09-27 · Godot 4.7.2-stable · macOS · --headless · script with no class_name, loaded with load()`

**증상:** A data layer loads table scripts lazily (`var s = load("res://scripts/data/items.gd")`, no
`class_name`, per GDT-027/035/036) and wants to call a helper such as `s.display_name(id, data)` only
if the table script defines it, falling back to plain dictionary reads otherwise. It is not obvious
from the docs whether `Object.has_method()` on the Script resource itself (not an instance) sees
`static func`s. If it did not, the fallback would run silently and nobody would notice.

Measured on a data script with `extends RefCounted`, `const ITEMS := {...}` and static helpers:

| call on `s = load(path)` | result |
|---|---|
| `s.has_method("display_name")` (a `static func`) | `true` |
| `s.has_method("no_such_func")` | `false` |
| `s.display_name("hoe", {"lv": 2})` | the helper's return value |
| `s.get_script_constant_map()["ITEMS"].size()` | 556 |
| `load()` time for the 136 KB script (556 nested const entries) | 33–36 ms, 3 runs |

A `static var` cache inside the same script (filled on first call, reused later) also works when
the script is only preloaded.

**해결:** The pattern `if s != null and s.has_method("f"): return s.f(args)` is safe for optional
static helpers on `load()`ed scripts. Read constants with `get_script_constant_map()`, call static
funcs directly on the Script object. A catalogue of several hundred items as one `const` Dictionary
is fine to load at startup; keep values free of `null` (GDT-028).

---

## GDT-108 — Hangul breaks mid-word only where ICU break data exists: always in editor and headless runs, in a Web export only with `include_text_server_data`

`측정 2026-09-27 · Godot 4.7.2-stable · Web export (nothreads) in headed Chromium · Pretendard 15 px`

**증상:** A coach-tip `Label` (`AUTOWRAP_WORD_SMART`, 318 px wide) showed
"…실루엣만 퍼센트에 들어 | 갑니다" in every headless capture, the mid-word break of GDT-104. The same
project exported for the Web and opened in Chromium wrapped it as "…실루엣만 퍼센트에 | 들어갑니다",
at the space.

The difference is whether ICU break-iterator data is present:

| Run | `internationalization/locale/include_text_server_data` | Break |
|---|---|---|
| Editor binary, `--headless` | — | `퍼센트에 들어 \| 갑니다` |
| Web export | `false` (default) | `퍼센트에 \| 들어갑니다` |
| Web export | `true` | `퍼센트에 들어 \| 갑니다` |

With the setting on, `index.pck` grew from 15.48 MB to 20.28 MB and contained `icudt78l/brkitr/*`.

Screenshots from the editor or a headless test therefore show breaks that web players do not see.
Turning the setting on (for Thai, Khmer or CJK dictionaries) brings the mid-word breaks to the web
build as well.

**해결:**
- Judge wrapped Korean on the exported build, not on editor or headless captures.
- Or apply GDT-104's U+2060 joiners so every run breaks at spaces. In the headless run the joiners
  moved `shaped_text_get_line_breaks` at 300 px from "…퍼센트 | 에 들어갑니다" to
  "…실루엣만 | 퍼센트에 들어갑니다", and the string width stayed 374.0 px.
- A project that enables `include_text_server_data` needs GDT-104 for Korean on the web too.

---

## GDT-109 — GL Compatibility passes vertex `COLOR` and `source_color` uniforms to spatial shaders as raw sRGB: a luminance taken from `COLOR.rgb` is about 2–3× the linear value

`측정 2026-09-27 · Godot 4.7.2-stable · GL Compatibility (OpenGL 4.1 Metal, Apple M1 Max) · windowed contact-sheet render`

**증상:** A shared spatial shader recolours foliage and grass by brightness:
`float lum = dot(COLOR.rgb, vec3(0.3, 0.55, 0.15)); base = grass_color.rgb * (lum / 0.17);`.
The 0.16–0.17 reference is the *linear* luminance of a mid green. In the Compatibility renderer
every grass mesh rendered white-yellow in all seasons, and fall foliage (`foliage_color` set to
`d27a32` with `set_shader_parameter`) rendered pale yellow instead of orange. Plain albedo looked
correct, so nothing pointed at colour space.

Measured with boxes of known vertex colours (top-face pixel of the render, same light for all):

| vertex colour | plain albedo | grass branch as written | grass branch, `lum` from `to_linear(COLOR.rgb)` |
|---|---|---|---|
| `3d6a3c` | `4d8246` | `ffffb4` | `618432` |
| `56823f` | `6c9f49` | `fffffe` | `95c850` |

The written result matches a model where `COLOR`, the shader-source default of a `source_color`
uniform, and a colour set with `set_shader_parameter()` all arrive as the raw sRGB numbers and
lighting runs on them directly: for `3d6a3c`, sRGB luminance 0.336 / 0.17 = 1.98 × `(0.46, 0.62, 0.28)`
× the measured light gain 1.27 → `ffffb3` (observed `ffffb4`). The linear reading (luminance 0.100)
predicts a dark green. Fall foliage checks out the same way: predicted `ffff7a`, observed `ffff7c`.

**해결:** In a Compatibility-renderer shader, convert before any colour arithmetic that assumes
linear values: `float lum = dot(to_linear(COLOR.rgb), vec3(0.3, 0.55, 0.15));` (with
`to_linear(c) = mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c))`).
Alternatively keep sRGB maths and calibrate constants on sRGB values (a mid green is ~0.35–0.45).
Verify colour logic with a pixel probe of a rendered sheet (PIL `getpixel`), not by eye: the
washed-out result looks like "bright lighting" until the numbers are compared.

## GDT-110 — `global_shader_parameter_get()` and `global_shader_parameter_get_list()` are editor-only: in a running game `get` returns null and the list is empty, each call logging "should never be used outside the editor"

`측정 2026-09-27 · Godot 4.7.2-stable · macOS, Metal (Forward+) windowed and --headless`

**증상:** Global shader parameters (`wetness`, `city_night`, …) were registered at runtime with
`RenderingServer.global_shader_parameter_add()` and set with `global_shader_parameter_set()`. Reading them back:

| Call | Windowed (Metal) | `--headless` |
|---|---|---|
| `global_shader_parameter_get(&"probe")` right after add + set | `null`, plus `ERROR: This function should never be used outside the editor, it can severely damage performance.` | `null` |
| `global_shader_parameter_get_list()` | `[]`, same ERROR | `[&"probe"]` |

A guard "register only if not in the list" therefore never fires in a real window and a second registration logs
duplicate-add errors; gameplay code doing `float(global_shader_parameter_get(...))` hits
`Invalid call. Nonexistent 'float' constructor` on every call.

**해결:** Treat both calls as editor-only. Keep a static "registered" flag in the script that registers the
parameters, and publish the current values for gameplay yourself (for example `Engine.set_meta(&"city_wetness", v)`
next to the `global_shader_parameter_set` call). Shaders keep reading the global uniform as usual.

## GDT-111 — SDFGI costs about 2 ms in an empty test scene but about 6 ms in a dense generated city; three cascades, 0.4 m cells and half-resolution GI win most of it back

`측정 2026-09-27 · Godot 4.7.2-stable · Apple M1 Max, Metal, Forward+, 1920×1080`

**증상:** A stylized town (about 1,100 collision shapes, 166 merged meshes, 270 dynamic lights) held 60 fps on HIGH
until SDFGI was enabled with default settings; frame time rose by about 6 ms, while the same settings in an empty
scene cost about 2 ms. Measuring SDFGI in a test scene underestimates it by roughly 3×.

**해결:** `sdfgi_cascades = 3`, `sdfgi_min_cell_size = 0.4`, and `RenderingServer.gi_set_use_half_resolution(true)`
brought the HIGH preset back to 66–77 fps in the busiest shots. Budget GI in the real scene, not in an empty one.

## GDT-112 — `CharacterBody3D.move_and_slide()` can be called in a plain loop outside the physics step: fast, headless collision tests for curbs and door access

`측정 2026-09-27 · Godot 4.7.2-stable · --headless · Jolt Physics`

**증상:** Verifying that a capsule (radius 0.35, height 1.8) can climb every curb, walk every street corridor and
reach every door point by stepping the real game loop takes minutes per run.

**해결:** After the level geometry exists, set `velocity` and call `move_and_slide()` directly in a loop, then
read `global_position` / `is_on_floor()`. It resolves without waiting for physics frames; a 47-check curb, corridor
and door-access test ran this way headless (reference: `~/work/cobramission/client/world/city/tests/`).

## GDT-113 — `Control.set_anchors_preset()` keeps the control's current rect: a zero-size control anchored to full rect stays zero-size

`측정 2026-09-27 · Godot 4.7.2-stable · canvas_items stretch`

**증상:** A HUD built in code (`Control.new()`, then `set_anchors_preset(PRESET_FULL_RECT)`, then `add_child`) had
size (0, 0). Every child anchored to its centre or right edge landed at the parent's top-left: a turn pill half
off-screen, a title cut off at the top. Printed state: `anchors 1,1  offsets -1600,-900  size 0,0`. Anchors were set;
the offsets had been rewritten to keep the old zero rect.

**해결:** `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` for anything that should fill its parent. For a panel
pinned to a corner or centre, set `anchor_*` equal to the pin point, all four `offset_*` to the pixel offset, and
`grow_horizontal`/`grow_vertical` (BEGIN/BOTH/END) for which way it extends — its size is then its minimum size. Do
not use `position` on an anchored control: it is in the parent's coordinates, so it is only right at one window size.

## GDT-114 — `Input.parse_input_event()` positions are window pixels; `Camera3D.unproject_position()` answers in viewport coordinates. With `canvas_items` stretch they differ at every non-base window size

`측정 2026-09-27 · Godot 4.7.2-stable · base 1600×900, stretch canvas_items/expand`

**증상:** An automated test clicked pieces at `camera.unproject_position(piece)` and passed at 1600×900. The same
test at 1280×720 (a two-client run) missed every click: 13 of 13 moves timed out. Real mouse input in the game was
fine; only the synthesised events were off, by exactly the stretch factor 0.8.

**해결:** Convert before parsing: `var pos := get_viewport().get_final_transform() * viewport_pos`, then set
`event.position = pos`. The same transform, divided by `devicePixelRatio`, gives CSS pixels for a browser test to
click in a web export.

## GDT-115 — `JavaScriptBridge.create_callback()` drops the callable's return value: the page always receives `undefined`

`측정 2026-09-27 · Godot 4.7.2-stable · Web export (single-threaded) · Chrome`

**증상:** `window.bdev.state = JavaScriptBridge.create_callback(func(_a): return JSON.stringify(...))` and
`JSON.parse(window.bdev.state())` in the page threw *Cannot read properties of null*. The callback ran; its return
value never crossed back.

**해결:** Leave the answer on a JavaScript object the callback can reach, and read it after the call:
`dev.json = JSON.stringify(state)` inside the callback, `bdev.state(); JSON.parse(bdev.json)` in the page. Keep the
`JavaScriptObject` and the callback referenced from GDScript (a member array) or they are collected.

## GDT-116 — A SpacetimeDB 2.8 client in pure GDScript works natively and in a single-threaded web export; raise `WebSocketPeer.inbound_buffer_size` first

`측정 2026-09-27 · Godot 4.7.2-stable · SpacetimeDB 2.8.0 (v2.bsatn.spacetimedb) · macOS native + Chrome web export`

**증상:** There is no Godot SDK for SpacetimeDB 2.x and the C# SDK rules out a web export. The protocol turned out to
be small enough to write: about 400 lines for BSATN, the socket, a row cache keyed by row bytes, and reducer calls.
A whole practice match, a friend room, the ranked queue and a native-versus-browser match all ran through it. The
one Godot-specific trap: `WebSocketPeer.inbound_buffer_size` defaults to 65535 bytes and a server frame larger than
that is dropped without an error — a subscription's first message is a single frame.

**해결:** `ws.supported_protocols = ["v2.bsatn.spacetimedb"]`, `ws.inbound_buffer_size = 16 * 1024 * 1024`, poll in
`_process` with `process_mode = PROCESS_MODE_ALWAYS`. The wire facts themselves are OPS-153. Headless `--script` runs
work for protocol tests (no rendering needed).

## GDT-117 — System Chrome in headless mode (`channel: 'chrome'`) keeps the GPU on macOS: a Godot web export runs at 60 fps and takes real mouse input

`측정 2026-09-27 · Godot 4.7.2-stable Web export (Compatibility) · Playwright 1.62.1 · Chrome stable · Apple M1 Max`

**증상:** GDT-086 needs a headed window for WebGL2, which puts a browser on the owner's screen and, through gstack,
contends for a shared profile (AGT-070). Playwright's bundled Chromium in headless mode has the same missing WebGL2.

**해결:** `chromium.launch({ channel: 'chrome' })` — the installed Google Chrome, new headless mode — reports WebGL 2.0,
boots a 40 MB Godot export in 2–5 s from localhost and measures 60 fps over `requestAnimationFrame`. `page.mouse`
clicks reach Godot's `_unhandled_input` as real pointer events, so a test can play a whole match (aim with GDT-114's
transform). `page.screenshot()` captures the canvas correctly.

## GDT-118 — `Object.get_meta(name, null)` reports an error when the key is missing: a `null` default counts as no default

`측정 2026-09-27 · Godot 4.7.2-stable`

**증상:** `c.get_meta("fade_tween", null)` printed `The object does not have any 'meta' values with the key
'fade_tween'` on every call where the meta was not set yet, although a default was passed.

**해결:** `if c.has_meta(key): var v = c.get_meta(key)`, or use a non-null default of the right type.

## GDT-119 — Headless test teardown with `AudioStreamSynchronized` and a voice pool: waiting before `queue_free()` is not enough, wait after it too (extends GDT-095)

`측정 2026-09-27 · Godot 4.7.2-stable, --headless (Dummy audio driver)`

**증상:** A 426-check audio test crossfades through ten tracks (five of them three-stem
`AudioStreamSynchronized`), fires every effect through a 16-voice pool, then tears down as GDT-095
suggests: stop every player, `await create_timer(0.1).timeout`, `queue_free()`, `await process_frame`,
`quit()`. It still printed `48` and `90 ObjectDB instances were leaked at exit` (2 of 2 runs).
`--verbose` listed `AudioStreamPlaybackOggVorbis`, `OggPacketSequencePlayback`,
`AudioStreamSynchronized` and the stems and effects that played last as resources still in use.

**해결:** Add a wait after freeing the audio node as well:

```gdscript
director.stop_all()
await create_timer(0.5).timeout
director.queue_free()
await process_frame
await create_timer(0.2).timeout
quit(exit_code)
```

With the post-free 0.2 s wait the report was clean in 3 of 3 runs whether the wait before freeing was
0.1 s or 0.5 s.

## GDT-120 — A generator can set import options for new `.ogg` files by writing a minimal `.ogg.import`; `--import` fills in the uid and paths and keeps the params

`측정 2026-09-27 · Godot 4.7.2-stable, oggvorbisstr importer, godot --headless --import`

**증상:** Music loops and effect loops need `loop=true`, one-shots `loop=false`, but the OGG importer
defaults to `loop=false` and a build script cannot open the import dock.

A sidecar with only these lines was written next to each of 87 generated files before the first import:

```ini
[remap]

importer="oggvorbisstr"
type="AudioStreamOggVorbis"

[params]

loop=true
loop_offset=0
bpm=118
beat_count=0
bar_beats=4
```

After `godot --headless --path client --import` every sidecar had gained `uid`, `path`, `[deps]` and
`dest_files`, the `[params]` values were unchanged, and `load()` returned an `AudioStreamOggVorbis`
whose `loop` matched the file.

**해결:** Write the minimal sidecar only when it is missing. On later builds rewrite just the `[params]`
lines and keep the rest, so the uid Godot assigned stays stable. Leave `beat_count` at 0 unless the
file really should loop early: with `bpm` and `beat_count` both set, `AudioStreamOggVorbis` loops at
`beat_count` beats and plays the rest of the file as a tail over the restart.

## GDT-121 — `var ok := x == dict["k"]` is a parse error, and a `--script` or `--check-only` run that hits it still exits 0

`측정 2026-09-27 · Godot 4.7.2-stable, macOS, godot --headless --path client --script <test>.gd`

**증상:** A headless `extends SceneTree` data check printed
`SCRIPT ERROR: Parse Error: Cannot infer the type of "ok" variable because the value doesn't have a set type.`
and `ERROR: Failed to load script`, then the process exited 0. None of the test ran.

A dictionary element is a Variant. Any operator with a Variant operand is typed Variant during
analysis, including `==` and `and`, even though they always give a bool at run time, so `:=` refuses
to infer a type. One-line probes in the same file:

| line | result |
|---|---|
| `var ok := "v" == d["k"]` | parse error |
| `var ok := d.has("k") and d["k"] == "v"` | parse error |
| `var ok := "v" == String(d["k"])` | runs, `true` |
| `var ok: bool = "v" == d["k"]` | runs, `true` |
| `var ok := d.size() > 0` | runs, `true` |

Both `godot --headless --path client --script probe.gd` and the same command with `--check-only`
exited 0 on the broken probe. A CI step that trusts the exit code counts a test that never parsed as
passed. This is the same family as GDT-047 and GDT-087.

**해결:** Cast the element (`String(d["k"])`, `int(d["n"])`) or give the variable a declared type
(`var ok: bool = ...`). For every `--script` test, have the script print a success marker as its last
line (for example `VILLAGERS_OK`). The CI step then requires that marker and also greps the log for
`SCRIPT ERROR|Parse Error`. The exit code alone proves nothing.

## GDT-122 — Jolt `HeightMapShape3D` splits every cell along the (1,0)–(0,1) diagonal: bilinear height sampling is off by up to a metre on steep cells, and a body spawned at the bilinear height can fall through the terrain forever

`측정 2026-09-27 · Godot 4.7.2-stable · Jolt Physics · HeightMapShape3D 1024 × 1024, scale (2, 1, 2) · macOS`

**증상:** A `CharacterBody3D` placed at `bilinear_height(x, z) + 0.05` on a steep, eroded cliff cell fell straight through
the heightfield: y went from 71 to −62 in four seconds with no collision. On flat ground the same placement worked, so
walking tests passed and the bug only showed on cliffs.

400 random downward rays on that cliff, compared with three ways to interpolate the four corner samples of the cell
(`fx`, `fz` are the fractions inside the cell, `h00` at (0,0), `h10` at (1,0), `h01` at (0,1), `h11` at (1,1)):

| interpolation | mean \|ray y − estimate\| |
|---|---|
| bilinear | 0.24 m |
| triangles split (0,0)–(1,1) | 0.48 m |
| triangles split (1,0)–(0,1) | 0.00004 m |

So the collision surface is two triangles per cell cut along the (1,0)–(0,1) diagonal. A spawn point from the bilinear
estimate can be below that surface; the body then starts inside the heightfield, and a heightfield has no inside to push
it out of.

**해결:** Use the same triangles everywhere the height is read — CPU queries, the render mesh and shaders:

```gdscript
if fx + fz < 1.0:
	return h00 + (h10 - h00) * fx + (h01 - h00) * fz
return h11 + (h01 - h11) * (1.0 - fx) + (h10 - h11) * (1.0 - fz)
```

Build the render grid with the same diagonal (`[a, b, c, b, d, c]` for a=(i,j), b=(i+1,j), c=(i,j+1), d=(i+1,j+1)) so
the finest terrain level matches the collision exactly. Keep a rescue in the character: if `y < height_at(x, z) − 1.2`
(and not swimming), snap to `height_at + 0.1`.

## GDT-123 — Web export (nothreads) runs GDScript at about native speed; Jolt builds a 1024² heightfield in 110 ms; a vertex shader can displace terrain with `texelFetch` on an R32F texture

`측정 2026-09-27 · Godot 4.7.2-stable · Web export (Compatibility, nothreads) in Chrome/Metal ANGLE vs native macOS · Apple M1 Max`

**증상:** Planning an open world for the Web needs real numbers for how slow GDScript and physics setup are in
WebAssembly. One probe project measured the same code in both builds:

| step | Web | native |
|---|---|---|
| 1,000,000-iteration `sin` loop in GDScript | 99 ms | 91 ms |
| `FastNoiseLite.get_image(1024, 1024)` | 130 ms | 274 ms |
| 1,000,000-element `PackedFloat32Array` scale loop | 54 ms | 215 ms (headless) |
| Jolt `HeightMapShape3D` 1024 × 1024 created and added | 110 ms | 150 ms |

A `CharacterBody3D` dropped onto that heightfield landed correctly on the Web. A `PlaneMesh` displaced in the vertex
shader with `texelFetch` on an `ImageTexture` in `FORMAT_RF` (`filter_nearest`) rendered correctly in the Web
Compatibility renderer. Exporting the tiny probe took 3 s.

**해결:** Budget GDScript on the Web like native GDScript, not tens of times slower. Heavy one-off generation still
belongs offline (bake to resources), but per-frame logic of a few milliseconds is realistic. GPU heightmap displacement
with a float texture is a safe Compatibility-renderer technique for terrain.

## GDT-124 — In a custom `light()`, Godot multiplies `DIFFUSE_LIGHT` by `ALBEDO` afterwards and `LIGHT_COLOR` already contains π

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility · linear tonemap, ambient off, one DirectionalLight3D (energy 1) facing the quad`

**증상:** Writing a toon `light()` needs to know whether to multiply by albedo and how bright `LIGHT_COLOR` is. Four quads
with albedo (0.8, 0.2, 0.2), rendered side by side and read back from the viewport:

| light() body | pixel |
|---|---|
| `DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI;` | (0.800, 0.196, 0.196) |
| `DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR;` | (1.000, 0.349, 0.349) |
| `DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR * ALBEDO / PI;` | (0.639, 0.004, 0.004) |
| `StandardMaterial3D` (roughness 1, no specular) | (0.800, 0.196, 0.196) |

**해결:** `f * ATTENUATION * LIGHT_COLOR / PI` reproduces the engine's Lambert exactly. Do not multiply by `ALBEDO`
inside `light()` — it gets squared.

## GDT-125 — `var x := dict.get(k, default)` does not compile: inferring from a Variant is an error by default, and it breaks every script that preloads the file

`측정 2026-09-27 · Godot 4.7.2-stable, default project settings (no warnings overrides)`

**증상:** A single line `var tint := {"a": Color(...), "b": Color(...)}.get(kind, Color(...))` in a static library
script produced

```
SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
SCRIPT ERROR: Invalid call. Nonexistent function 'character' in base 'GDScript'.
```

The first line names the library. The second and third come from the test script that preloads
it: its call site fails as if the function did not exist. `Dictionary.get()` returns Variant,
and so does `Image.duplicate()` (typed as Resource): `var out := img.duplicate()` is followed by
`Cannot infer the type of "w" variable` wherever `out.get_width()` is used.

**해결:** Annotate the type: `var tint: Color = {...}.get(kind, Color(...))`,
`var out: Image = img.duplicate()`. After editing a library, run one headless script that
preloads it, because the editor is not there to show the warning.

## GDT-126 — Headless: right after `AnimationPlayer.seek(t, true)`, `Skeleton3D.get_bone_global_pose()` still returned the rest pose; read the pose from the tracks instead

`측정 2026-09-27 · Godot 4.7.2-stable --headless, SceneTree script (_initialize), KayKit Rig_Medium character`

**증상:** To check which frames raise the hands above the head, the probe called `ap.play(clip)`,
`ap.seek(len * f, true)`, then `skel.get_bone_global_pose(skel.find_bone("hand.l"))`. Over 13
clips and 5 times each, every value was identical (`hand.l - head` = +0.06, the rest pose),
including Idle_A and PickUp.

**해결:** Evaluate the chain from the Animation directly. Walk parent first. For each bone, use
`anim.rotation_track_interpolate(anim.find_track(NodePath("Rig_Medium/Skeleton3D:" + bone), Animation.TYPE_ROTATION_3D), t)`
and `position_track_interpolate`, and fall back to `skel.get_bone_rest(b)` when a track is
missing. The same probe then gave distinct values: Idle_A hands −0.59, Cheering +0.05 to +0.20,
PickUp right hand −0.73. The same `get_bone_global_rest()` / `get_bone_rest()` data can compute
new poses, for example arms aimed along a model-space direction with
`Quaternion(current_dir, wanted_dir)`, and bake them into an Animation.

## GDT-128 — Depth-of-field substitute in `gl_compatibility`: `hint_screen_texture, filter_linear_mipmap` + `textureLod` gives a real mip blur, native and in the Web export

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility · Apple M1 Max (native) and Chrome 1243 WebGL2 (Web export)`

**증상:** GDT-015 lists DOF blur as unsupported in Compatibility (the warning is printed and the image is unchanged), so a tilt-shift "miniature" look seems out of reach without Forward+.

A full-screen `ColorRect` on a `CanvasLayer` with this shader blurs what is under it:

```glsl
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
void fragment() { COLOR = vec4(textureLod(screen, SCREEN_UV, 4.0).rgb, 1.0); }
```

Probe: a 1152 × 648 frame of an 80 × 80 checkerboard, left half sampled at LOD 4, right half at LOD 0. Mean absolute difference between horizontally neighbouring pixels: **0.0008 (LOD 4) vs 0.058 (LOD 0)**, about 70× smoother. The same shader in the Web export (WebGL2, Chrome) shows the blurred bands. The screen copy is made once for the canvas layer, so the cost is one copy plus the taps you sample.

**해결:** for tilt-shift, scale the LOD with the distance from a horizontal focus band (`smoothstep(band, band + 0.3, abs(uv.y - focus))`, max LOD about 2.5) and average 4–5 taps offset by `SCREEN_PIXEL_SIZE * exp2(lod)` to hide the blockiness of a single mip sample. Put the layer below the UI layer so text stays sharp. Related: GDT-015.

## GDT-129 — `SurfaceTool` fixes the vertex format at the first vertex: later vertices that add `set_uv()` or `set_custom()` log an error per vertex and the attribute is silently dropped

`측정 2026-09-27 · Godot 4.7.2-stable · SurfaceTool (terrain mesh builder)`

**증상:** a chunked terrain builder shared one `SurfaceTool` between two helpers: one wrote vertices with `set_color` + `set_custom(0, …)`, the other (cliff lips, water beds) with `set_color` + `set_uv`. The run printed, once per vertex:

```
ERROR: Condition "!first && !(format & Mesh::ARRAY_FORMAT_TEX_UV)" is true.
   at: set_uv (scene/resources/surface_tool.cpp:325)
```

`commit()` still succeeded and the mesh rendered, so nothing looked broken at first; the mixed-in vertices simply had no UV/custom data (their shader inputs read as zero). The first vertex added decides which attributes the surface has.

**해결:** give each `SurfaceTool` exactly one attribute set and route helpers to the surface that matches (here: ground quads always with `set_custom`, cliffs and lips on a separate surface with `set_uv`). When a helper must write to a custom-format surface, make it call `set_custom` too (with a neutral value) instead of `set_uv`. Grep the run log for `surface_tool.cpp` after changing a mesh builder.

## GDT-127 — Automated Web-export check on macOS without gstack browse: Chrome for Testing from the Playwright cache with `--headless=new --use-angle=metal` has WebGL2, driven by raw CDP from Node's built-in `WebSocket`

`측정 2026-09-27 · Godot 4.7.2 Web export (single-threaded) · Chrome for Testing 1243 (~/Library/Caches/ms-playwright) · Node 26`

**증상:** GDT-086 needs a headed gstack browse daemon for WebGL2, and AGT-069/AGT-070 show that daemon silently falling back to headless or losing its profile to another session. In this session `$B --headed goto` printed `Server failed to start within 8s`, the daemon came up as `Mode: launched`, and `getContext('webgl2')` returned `false`.

Launching the Playwright-cached Chrome directly works without any npm package:

```
".../chromium-1243/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --headless=new --use-angle=metal --ignore-gpu-blocklist --remote-debugging-port=<port> \
  --user-data-dir=<tmp> --window-size=1280,800 about:blank
```

Then `fetch http://127.0.0.1:<port>/json/list`, open the page's `webSocketDebuggerUrl` with Node's global `WebSocket`, enable `Runtime`/`Log`, `Page.navigate` to the build and `Page.captureScreenshot`. Measured: `webgl2: true`, the 40 MB build left its loading screen in 28 s from a local server, the console showed `OpenGL ES 3.0 (WebGL 2.0 …) - Compatibility`, and the screenshot contained the rendered 3D scene.

**해결:** keep a ~100-line CDP script in the repo (here `tests/web_smoke.mjs`): it collects console errors, waits for the loading element to disappear and saves screenshots, and exits non-zero on errors. Serve the export with a server that sends `application/wasm` for `.wasm` (Python 3.9's `http.server` needs an explicit `extensions_map` entry). Related: GDT-086, AGT-069, AGT-070.

## GDT-130 — In `gl_compatibility`, `hint_screen_texture, filter_linear_mipmap` + `textureLod()` gives a one-pass frosted blur

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility (OpenGL 4.1 Metal, M1 Max) · windowed`

**증상:** A pause screen needed a blurred copy of the 3D world behind it. It was unclear whether the Compatibility renderer generates mipmaps for the screen texture, and a multi-tap blur costs dozens of fetches per pixel.

Measured with 48 px black/white stripes behind a `ColorRect` whose shader returns `textureLod(screen_tex, SCREEN_UV, 3.0)`. The uncovered half read `1.0 … 1.0, 0.0 … 0.0` at the stripe edges. The covered half read `0.47, 0.16, 0.01, 0.0, 0.01, 0.13, 0.48, 0.82, 0.97, 1.0` — a smooth ramp, so the back-buffer mip chain exists.

**해결:** Declare `uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;` and sample `textureLod(screen_tex, SCREEN_UV, lod)` (lod about 3–4 at 1440 × 900). Mixing 5 offset taps at the same lod removes the blocky mip look. Animate the lod from 0 for the open transition. `amount = 0` shows the unblurred screen, so the overlay can stay opaque (`COLOR.a = 1.0`).

---

## GDT-131 — The Google Fonts Korean display face Jua has only 2,367 of the 11,172 Hangul syllables

`측정 2026-09-27 · Jua-Regular.ttf (google/fonts ofl/jua, 2.1 MB) · Noto Sans KR variable · Godot 4.7.2 FontFile.has_char()`

**증상:** A rounded display face for Korean headings looked complete in every heading tested by hand. A player name or area name typed later can render in two fonts, or as tofu on the web (GDT-088).

`has_char()` over U+AC00–U+D7A3: Jua is missing **8,805** syllables (it covers the KS X 1001 set). It also has none of `▼▲◀▶…·●○※→←↑↓×✓♪〜`. Noto Sans KR has all 11,172 syllables and those symbols except `☰` and `✔`.

**해결:** Wrap Jua in a `FontVariation` with `fallbacks = [<Noto Sans KR variation>]`. Draw symbols such as ▼ or ☰ as polygons or SVG instead of glyphs. In the UI test, loop over every visible Label and assert `label_settings.font.has_char(c)` for each character. `FontVariation.has_char()` also looks at the fallbacks.

---

## GDT-132 — Godot 4.7's default `ui_accept` / `ui_cancel` have no gamepad buttons

`측정 2026-09-27 · Godot 4.7.2-stable · InputMap.action_get_events() in a --script run`

**증상:** A menu that listens only to `ui_accept` / `ui_cancel` works with a keyboard and ignores the gamepad's A and B buttons.

Defaults as printed: `ui_accept` = Enter, Kp Enter, Space. `ui_cancel` = Escape. `ui_up` = Up, `JOY_BUTTON_DPAD_UP` and `JOY_AXIS_LEFT_Y -1`. Directions reach the gamepad, confirm and back do not.

**해결:** Treat the game's own actions as menu commands (for example `interact` on `JOY_BUTTON_A` = confirm), and read `JOY_BUTTON_B` from `InputEventJoypadButton.button_index` for back. Stick motion arrives as a stream of `InputEventJoypadMotion`, and each event past the deadzone reports `is_action_pressed`. Edge-detect it with a per-axis state and hysteresis (enter above 0.6, reset below 0.3). Otherwise one flick moves the focus several steps.

---

## GDT-133 — `_input()` and the same frame's `_physics_process()` share the process frame count; the physics count is one higher

`측정 2026-09-27 · Godot 4.7.2-stable · windowed and --headless --script`

**증상:** A dialogue box closes on the press of E in `_input()`. The game polls `Input.is_action_just_pressed("interact")` in `_physics_process()` and checks `ui.is_blocking()`. The box is already closed, so the same press starts the conversation again.

One synthetic E press, logged: `_input pressed proc=8 phys=11` → `_physics_process just_pressed proc=8 phys=12` → `_process just_pressed proc=8 phys=12`. Events are delivered before the physics steps of the same iteration. The physics counter increments before `_physics_process` runs.

**해결:** At close, store `closed_proc = Engine.get_process_frames()` and `closed_phys = Engine.get_physics_frames()`. Keep `is_blocking()` true while `get_process_frames() <= closed_proc or get_physics_frames() <= closed_phys + 1`. That covers a frame without a physics step at high refresh rates. The next real press still reaches the game. For the opposite case (the press that opened a modal must not advance it), ignore events while `get_process_frames()` equals the frame the modal opened in. In headless tests, several process frames can pass without a physics tick. Wait on `physics_frame` twice before asserting that blocking ended, not on `process_frame`.

---

## GDT-134 — GL Compatibility linearises a custom shader's `ALBEDO` itself: writing `to_linear(COLOR.rgb)` into `ALBEDO` converts twice (coral `ff7a45` renders pure red)

`측정 2026-09-27 · Godot 4.7.2-stable · GL Compatibility (OpenGL 4.1 Metal, Apple M1 Max) · windowed pixel probe`

**증상:** A procedural character painted with vertex colours (`ff7a45` hood, `2b8a8e` suit) through a
spatial shader that did `ALBEDO = to_linear(COLOR.rgb)` rendered deep red and dark teal. Level geometry
using `source_color` uniforms written straight to `ALBEDO` looked right under the same light.

Probe: a plane lit by one `DirectionalLight3D` pointing straight down, ambient and reflections off,
`TONE_MAPPER_LINEAR`, centre pixel read back and converted to linear:

| light energy | value written | StandardMaterial3D (`albedo_color` = sRGB of the value) | custom `diffuse_lambert` `ALBEDO = value` | custom `unshaded` |
|---|---|---|---|---|
| 1.0 | 0.100 | 0.0999 | 0.0080 | 0.0080 |
| 1.0 | 0.214 | 0.2159 | 0.0369 | 0.0369 |
| 1.0 | 0.500 | 0.5029 | 0.2159 | 0.2159 |
| 0.25 | 0.500 | 0.1248 | 0.0529 | — |

The custom column is exactly `srgb_to_linear(value) × energy`: the engine treats `ALBEDO` as sRGB,
linearises it, lights it, and encodes the result. Together with GDT-109 (vertex `COLOR` and
`source_color` uniforms arrive as raw sRGB), the consistent rule is: **keep colours in sRGB all the way
into `ALBEDO`**. A manual `to_linear()` before `ALBEDO` is a second conversion. Same measured with
`diffuse_burley`.

**해결:** `ALBEDO = COLOR.rgb * tint.rgb;` with no conversion (do linear maths only for derived
quantities such as luminance, as GDT-109 says). Check with a probe against a StandardMaterial3D of the
same colour: after the fix a terrain shader and StandardMaterial3D both rendered `5cc43a` at energy 0.3
as `2c611b` / `32711d`, while the double-converted shader gave `0f5107`.

---

## GDT-135 — A `MultiMesh` with `use_custom_data = true` and `use_colors = false` gives the shader `COLOR = 0` in GL Compatibility: vertex colours render black

`측정 2026-09-27 · Godot 4.7.2-stable · GL Compatibility, native and Web export (Chromium)`

**증상:** Instanced flowers and grass tufts (per-instance tint in `INSTANCE_CUSTOM`, per-vertex colours
for stem vs. petal) rendered as black silhouettes. A false-colour pass (`ALBEDO = vec3(UV.y,
INSTANCE_CUSTOM.r, COLOR.g)`) showed UV and custom data arriving correctly and `COLOR.g ≈ 0` on every
vertex. MultiMeshes without custom data (blocks whose shader keys an emblem off `COLOR.a`) were fine.

**해결:** Turn colours on as well and set every instance colour to white: `mm.use_colors = true`,
`mm.use_custom_data = true`, then `set_instance_color(i, Color.WHITE)` and
`set_instance_custom_data(i, tint)`. `COLOR` is then the vertex colour (× white) and `INSTANCE_CUSTOM`
carries the tint.

---

## GDT-136 — `rendering/limits/global_shader_variables/buffer_size` set small floods the Web console with "uniform buffer that is too small"

`측정 2026-09-27 · Godot 4.7.2-stable · Web export (Compatibility, no threads), Chrome + ANGLE Metal`

**증상:** With `limits/global_shader_variables/buffer_size=128` in `project.godot` (three global
uniforms used), the native build was fine but the Web build printed an endless stream of
`GL_INVALID_OPERATION: glDrawElements: It is undefined behaviour to use a uniform buffer that is too small.`
The setting is a buffer size, not a variable count.

**해결:** Remove the line (default 65536). The flood stopped and the scene rendered at 60 fps in the
same headless Chrome run.

---

## GDT-137 — A pool of idle one-shot `CPUParticles3D` intermittently drew huge dark shapes after switching scenes; keep idle emitters hidden

`측정 2026-09-27 · Godot 4.7.2-stable · GL Compatibility · windowed, 70 pooled one-shot emitters (opaque dithered puff material)`

**증상:** Starting a second course in the same session sometimes covered most of the view with large
dark 10–12-sided shapes (a screen-darkness probe read 82 % of sample points dark). Hiding the FX parent
node removed them; the same course started first never showed them. The emitters had
`emitting = false`, `one_shot = true`, `explosiveness = 1`, `local_coords = false`, and most had never
fired.

**해결:** Create emitters with `visible = false`, connect `finished` to `hide`, and set
`visible = true` just before `restart()` in the burst call. Four consecutive course switches then
read 0 % dark (the remaining dark share was the cave's own background). Hidden idle emitters also stop
costing a draw call each.

## GDT-138 — A `godot --script` runner whose preloaded script fails to parse never exits: the call into it errors before `quit()` and the headless SceneTree idles forever

`측정 2026-09-27 · Godot 4.7.2-stable · macOS · godot --headless --path <proj> --script res://main.gd`

**증상:** A headless check script (`extends SceneTree`, `const X = preload("res://x.gd")`, `quit()` at the
end of `_initialize`) ran past a 120-second tool timeout with no output at all. `x.gd` had a
`:=` inference parse error (`Cannot infer the type of "u0" variable`). Godot prints
`Parse Error` → `Failed to compile depended scripts` → `Failed to load script "res://main.gd" with error
"Compilation failed"`, **and then still runs `_initialize`**. The first call into the broken script
fails (`Invalid call. Nonexistent function ...`), the function aborts before `quit()`, and the process
keeps idling. Piping the output through `grep | head` hides even the error lines, because nothing is
flushed until the process ends. Minimal repro (broken.gd = `var x := d["a"]`, main.gd calls it then
`quit(0)`): `timeout 25 godot --headless --script res://main.gd` → exit 124 after 26 s, output ends at
the error.

**해결:** Wrap every `--script` run in `timeout N` and treat 124 as a failure. Parse-check changed
dependencies first with `timeout 40 godot --headless --path <proj> --check-only --script res://x.gd`,
which prints the parse error and exits. Write runner output to a file instead of piping it into
`head`, then grep the file for `SCRIPT ERROR|Parse Error`.

## GDT-139 — `AudioServer.unregister_stream_as_sample()` is not exposed to scripts in 4.7.2, although `register_stream_as_sample()` and `is_stream_registered_as_sample()` are

`측정 2026-09-27 · Godot 4.7.2-stable, --headless`

**증상:** A music cache for the Web export pre-decodes the next track with `AudioServer.register_stream_as_sample()`
(GDT-097) and wanted to release tracks it no longer holds. In a headless run
`ClassDB.class_has_method("AudioServer", "unregister_stream_as_sample")` returned `false`, while
`register_stream_as_sample` and `is_stream_registered_as_sample` were callable.

- A Web sample costs about 0.38 MB per second of decoded audio (GDT-097), so releasing matters for
  long music.
- Whether dropping the last reference to the `AudioStream` unregisters its sample was not measured.

**해결:** Keep the call behind a guard so the script compiles and picks the method up if a later version
exposes it:

```gdscript
if AudioServer.has_method("unregister_stream_as_sample"):
    AudioServer.call("unregister_stream_as_sample", stream)
```

---

## GDT-140 — Headless Monte-Carlo tests in GDScript cost 30–180 µs per simulated 60 Hz step: 2,000 simulated games took 100 s

`측정 2026-09-27 · Godot 4.7.2-stable (editor binary, --headless --script), Apple Silicon`

**증상:** A minigame test ran a fixed-step simulation (about 40 lines of float math and 3–5 `RandomNumberGenerator` calls per step, in an inner `RefCounted` class) for a few thousand seeded games. The first version took 7 s; after raising the seed counts and time caps it took 292 s.

Measured costs per simulated step:
- The bare `step()` call: 30 µs.
- The same step driven through a `Callable` policy plus per-step bookkeeping: 88 µs.
- A variant that picked new random targets more often: 178 µs.

A 6-second game at 60 Hz is 360 steps, or 15–60 ms. Games that stall until a time cap dominate the total: one 120 s cap costs 7,200 steps.

**해결:**
- Budget statistical tests in steps, not in games: steps = games × average length × 60.
- Give every simulated game a short time cap (15–40 s), and exclude timed-out games from the outcome checks.
- Spend large seed counts only on the borderline case you are asserting (for example 200 seeds at the threshold difficulty, 24 elsewhere).

---

## GDT-141 — `Image.fix_alpha_edges()` takes 11.5 s on a 1792 × 1008 icon atlas

`측정 2026-09-27 · Godot 4.7.2-stable, --headless --script, Apple Silicon`

**증상:** A UI built its icon atlas at runtime: 145 SVG icons rasterised and blitted into one
1792 × 1008 RGBA8 image. It called `fix_alpha_edges()` before `generate_mipmaps()` to stop dark
fringes. The build took 14 s. The same call on an empty 1792 × 1008 image measured 11,535 ms.
For comparison, 100 `blend_rect()` calls of a 104 px icon took 161 ms, and 91 ThorVG rasterisations
took 1,405 ms.

**해결:** Do not call `fix_alpha_edges()` at runtime. Bake the atlas offline to a PNG and import it
with `process/fix_alpha_border=true` and `mipmaps/generate=true`, which does the same edge
bleeding at import time. A runtime fallback atlas can skip edge bleeding.

---

## GDT-142 — `const float TAU = …` in a Godot shader is a compile error ("Redefinition of 'TAU'"), and `--headless` runs never show it

`측정 2026-09-27 · Godot 4.7.2-stable, gl_compatibility, windowed vs --headless`

**증상:** Canvas shaders that declared `const float TAU = 6.28318530718;` compiled "fine" in every
headless test: no error, and all checks passed. The first windowed run printed
`SHADER ERROR: Redefinition of 'TAU'` and `Shader compilation failed` at
`material_storage.cpp` `set_code`, and the affected rects drew nothing. `TAU`, `PI` and `E` are
built-in constants of the Godot shading language. `--headless` uses the dummy renderer, which never
compiles shaders.

**해결:** Use the built-in `TAU`, `PI` and `E` and never redeclare them. Validate every `.gdshader`
in at least one windowed run, for example a SubViewport screenshot harness, and grep its log for
`SHADER ERROR`. A headless test cannot catch shader errors.

---

## GDT-143 — The 4.7.2 Web template has ThorVG and Brotli: runtime `Image.load_svg_from_string()` and `.woff2` fonts both work on the Web

`측정 2026-09-27 · Godot 4.7.2-stable export templates (web_nothreads_release.zip)`

**증상:** It was not clear whether SVG icons could be rasterised at runtime in a Web build, or
whether WOFF2 fonts would load. `strings godot.wasm` of the nothreads release template lists
`modules/svg/image_loader_svg.cpp`, `load_svg_from_string` and "The ThorVG Project", as well as
the Brotli decoder (`BROTLI_DECODER_RESULT_SUCCESS`).

Measured:
- A Noto Sans KR 500 subset (KS X 1001 Hangul + ASCII + symbols, fontTools, `flavor=woff2`) is
  153 KB. Godot imports it as a `FontFile`, and `has_char()` answers correctly.
- Runtime SVG rasterisation costs about 15 ms per 104 px icon (91 icons in 1.4 s, native headless).

**해결:** WOFF2 subsets are the smallest font payload: three Korean faces came to 427 KB. SVG is a
good source format for icons, but bake the atlas offline and keep runtime rasterisation only as a
fallback when the baked file is missing or stale. Hash the SVG sources into the baked file name to
detect a stale bake.

---

## GDT-144 — Without `class_name`, type a member with the preloaded script constant (`var th: Th`); an untyped member breaks every `:=` that uses it

`측정 2026-09-27 · Godot 4.7.2-stable`

**증상:** A project that bans `class_name` stored a helper object in an untyped member (`var th`).
Every `var ml := safe.position.x + th.px(34)` then failed to parse with
`Cannot infer the type of "ml" variable because the value doesn't have a set type`. A ternary
whose operands came from a Dictionary failed with the `inference_on_variant` warning, which is an
error by default. One parse error also fails every script that preloads that one
("Failed to compile depended scripts").

**해결:** Use the preload constant as the type: `const Th := preload("res://ui/theme.gd")`, then
`var th: Th` and `func setup(theme: Th)`. Calls then return typed values, so `:=` works again.
Type the results of `Dictionary.get()` and ternaries explicitly (`var big: bool = ...`). Before
running anything, check with `godot --headless --path . --check-only --script <file>`.

## GDT-145 — Toon shaders look washed out for two measurable reasons: Filmic lifts mid-tones, and the default `SPECULAR 0.5` adds a sky sheen at grazing angles

`측정 2026-09-27 · Godot 4.7.2 · gl_compatibility · Apple M1 Max`

**증상:** A custom toon `light()` world (full light colour once N·L passes the band, sky ambient) rendered pale and hazy; distant ground faded to blue-white. Tuning fog and ambient did not fix it.

Measured on a 0.5-grey plane lit by one sun (energy 1.05) and sky ambient 0.45, reading the SubViewport pixel:

| setup | pixel (sRGB) |
|---|---|
| Linear tonemap, sun + ambient | 0.545 0.604 0.667 |
| **Filmic** tonemap, same | **0.682 0.741 0.800** |
| Linear, sun only, ambient energy 0 | 0.533 0.573 0.635 (blue tint = sky reflection) |

With ambient energy 0 the surface still turns blue: default `SPECULAR` is 0.5 and `ROUGHNESS` 1.0, so the sky is reflected, and Fresnel makes it strong at grazing angles (the far ground). A toon band gives every lit face the full light colour, so any extra term shows.

`source_color` uniform defaults are not the cause: `uniform vec3 c : source_color = vec3(0.5)` and a set `Color(0.5, 0.5, 0.5)` both render 0.502 unshaded under Linear (defaults are linearized like set values).

**해결:** Write `SPECULAR = 0.0;` in painterly/toon fragment shaders (keep a custom highlight in `light()` for metal). Judge colours under Linear or compensate Filmic with lower exposure. Keep glow `hdr_threshold` above the brightest lit albedo (1.6 here) or bloom adds haze.

## GDT-146 — GL Compatibility (4.7.2) supports per-instance shader tricks: MultiMesh `MODEL_MATRIX`, instance uniforms, alpha-scissor shadows, `world_vertex_coords`

`측정 2026-09-27 · Godot 4.7.2 · gl_compatibility · Apple M1 Max`

Checked by rendering, not by docs:

- In `vertex()`, `MODEL_MATRIX[3].xyz` of a MultiMesh instance is that **instance's** world origin (six boxes coloured by it came out six colours). Per-instance tint and wind phase can be derived from it without `INSTANCE_CUSTOM`. `world_vertex_coords` also works with MultiMesh.
- `instance uniform vec3 glow_color` works: two MeshInstance3Ds sharing one ShaderMaterial showed different colours after `set_instance_shader_parameter()`. The value set on the node is saved in a PackedScene.
- An alpha-scissor card (`ALPHA` + `ALPHA_SCISSOR_THRESHOLD`, `cull_disabled`) casts a cut-out directional shadow, not a solid quad.
- With `cull_disabled`, back faces get a flipped `NORMAL` before user fragment code; `if (!FRONT_FACING) NORMAL = -NORMAL;` restores baked "outward from the canopy" normals on leaf cards.
- Godot front faces are clockwise: a quad given counter-clockwise as seen from the front must be emitted (a, c, b), (a, d, c).

**해결:** For foliage drawn with MultiMeshInstance3D, derive variation from `MODEL_MATRIX`; for per-object glow colours use instance uniforms instead of duplicating materials.

## GDT-147 — A lambda that captured a node logs `ERROR: Lambda capture at index 0 was freed` when the node is gone, even if its body checks `is_instance_valid` first

`측정 2026-09-27 · Godot 4.7.2`

**증상:** `ERROR: Lambda capture at index 0 was freed. Passed "null" instead.` at `gdscript_lambda_callable.cpp:110`, from a test run that otherwise passes. The source looks safe:

```gdscript
get_tree().create_timer(1.4).timeout.connect(func() -> void:
	if is_instance_valid(p):
		p.stop_cheer())
```

Measured in a scratch project, freeing the node before each callback ran:

- A `SceneTree` timer's lambda that captured the node: the engine logs the ERROR, then runs the body with the capture replaced by `null` (`is_instance_valid` → false). The guard works; the error is logged anyway, because it is raised while the call is being prepared, before the body runs.
- A tween created by the node itself (`node.create_tween()`, `tween_interval`, `tween_callback`): the callback never runs and nothing is logged. The tween dies with its node.
- A lambda that captured `weakref(node)` and called `get_ref()`: no error, `get_ref()` is `null`.

**해결:** For "do X to this node later", let the node own the delay (`node.create_tween().tween_interval(t)` then `tween_callback(node.method)`), so the callback cannot outlive it. When the callback has to live elsewhere, capture a `WeakRef`, not the node. An `is_instance_valid` check inside the lambda does not silence the error.

## GDT-148 — Web export on WebKit: changing `scaling_3d_scale` at runtime more than once dropped the WebGL context; a scale fixed at startup did not

`측정 2026-09-27 · Godot 4.7.2-stable Web export (Compatibility, no threads) · Playwright WebKit and Chrome (ANGLE Metal) on macOS, machine load average 200–470`

**증상:** A procedural 3D stage lowered `get_viewport().scaling_3d_scale` from 1.0 toward 0.5 whenever frame time rose. Under heavy machine load it changed the scale several times in one session, and WebKit then logged `WebGL: context lost` followed by shader link failures partway through a scripted game flow (the defense scene). WebKit runs in which the scale never changed finished the same flow without a loss. Chrome kept rendering through the same scale changes.

**해결:** On WebKit/Safari, choose the scale once at startup and never change it; elsewhere, only lower it, at most twice. With that change the full flow (menu → lobby → day with an evidence prop → night → dawn → vote → defense → execution) ran in WebKit with zero context losses; the only warning left was the engine's `WEBGL_polygon_mode` notice. Test adaptive-resolution code in WebKit under CPU load, since an idle machine never triggers the changes.

## GDT-149 — `set_process(false)` called before a node enters the tree is undone at its first ready when the script defines `_process()`

`측정 2026-09-27 · Godot 4.7.2-stable · --headless`

**증상:** A creature controller called `set_process(false)` right after `new()` and only then `add_child()`ed the node.
It kept ticking anyway.

Measured with a script that only defines `_process()`:

| Order | `is_processing()` afterwards | `_process` calls in 2 frames |
|---|---|---|
| `set_process(false)`, then `add_child()` | `true` (right after `add_child`) | 1 |
| `add_child()`, then `set_process(false)` | `false` | 0 |
| add, remove, `set_process(false)`, add again | `false` | 0 |

A script that overrides `_process()` gets processing switched on when the node first becomes ready. That overwrites an
earlier `set_process(false)`. Later re-entries into the tree do not switch it on again, because ready runs once.

**해결:** Turn processing off after the node is in the tree: in `_ready()`, or after `add_child()`. The same applies to
`_physics_process` and `set_physics_process`.

## GDT-150 — Web export sample playback ignores `AudioStreamWAV.loop_begin`/`loop_end`: a sustain loop replays the whole sample, attack included

`측정 2026-09-27 · Godot 4.7.2-stable Web export · 내보낸 index.js(GodotAudio.Sample / SampleNode)를 직접 읽음 · 귀로 확인하지는 않음`

**증상:** Instrument samples that loop only their sustain part (`loop_begin` > 0) are a common way to hold notes of
any length. In the Web build's default Sample playback mode, the loop points never reach Web Audio.

- `GodotAudio.Sample`'s constructor stores `options.loopBegin` and `options.loopEnd`, and no other code in `index.js`
  reads them.
- `SampleNode._restart()` creates a new `AudioBufferSource` with the whole buffer and calls
  `start(this.startTime, this.offset + pauseTime)`. It never sets `source.loop`, `loopStart` or `loopEnd`.

So when a looping sample ends, the whole buffer plays again from `offset`, attack included. The loop point also has
the timing gap that GDT-097 describes.

**해결:** Do not rely on WAV loop points on the Web. Make samples long enough for the longest note. For longer notes,
crossfade into a second voice started in the middle of the sample. Another option is to switch the bus to Stream
playback (`audio/general/default_playback_type.web`), but GDT-097 measured dropouts with Stream playback in a no-threads
build.

## GDT-151 — `TextMesh` fails on some glyphs of Cormorant Garamond ("Convex decomposing failed") and leaves them partly unfilled; MaruBuri works

`측정 2026-09-27 · Godot 4.7.2-stable · headless · Cormorant Garamond Latin subset woff2 (Google Fonts) · MaruBuri Regular woff2 (Naver)`

**증상:** In-world numerals built with `TextMesh` printed this for each bad glyph, and the digits rendered with missing
or wrongly filled parts:

```
ERROR: Convex decomposing failed. Make sure the font doesn't contain self-intersecting lines, as these are not supported in TextMesh.
```

A headless script that builds one `TextMesh` per character with `get_mesh_arrays()` reproduces it. With Cormorant
Garamond the error appears for `2`, `3`, `4`, `8` and `B`; `0 1 5 6 7 9 A C X I V` are fine. The failing glyphs still
return vertices (180–444), so a vertex-count check does not catch it. With MaruBuri every glyph in the same set builds
without an error.

**해결:** Check a font before using it for `TextMesh`: build every character you will show and watch the log for the
error above. Switch to a font whose outlines have no self-intersecting contours (MaruBuri worked for Korean and Latin
in one file). `Label3D` does not triangulate outlines and is not affected, but it costs one draw call per label.

## GDT-152 — A GDScript member named like a native class (`const Sky = preload(...)`) is a parse error: "The member "Sky" shadows a native class"

`측정 2026-09-27 · Godot 4.7.2-stable · GDScript`

**증상:** Two scripts that preloaded a helper as `const Sky = preload("res://lib/sky.gd")` failed to load, and every
script that depended on them failed too:

```
SCRIPT ERROR: Parse Error: The member "Sky" shadows a native class.
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
```

`Sky` is a built-in resource class. The same applies to any member, constant or preload alias that reuses a native
class name (`Sky`, `Environment`, `Font`, `Timer`, ...). It is an error, not a warning.

**해결:** Rename the alias (`const Stars = preload(...)`). When a helper script is named after an engine concept, give
its preload constant a project-specific name from the start.

## GDT-153 — Poly Haven's Vintage Grandfather Clock 01: the glass material is `BLEND` with an opaque JPEG base color, so it covers the dial like a dark slab in Godot

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility (native and Web) · polyhaven.com vintage_grandfather_clock_01 1K glTF`

**증상:** In a close-up, the clock face was dark and the hands were hard to see. The glTF material
`vintage_grandfather_clock_01_glass` has `alphaMode: BLEND`, `KHR_materials_clearcoat`, `KHR_materials_specular` and
`KHR_materials_ior`, but its `baseColorTexture` is one of the model's three JPEG images. A JPEG has no alpha channel, so
alpha is 1.0 and the "glass" is an opaque, textured pane in front of the dial. Godot does not import transmission from
these extensions.

**해결:** After instancing the model, replace every surface whose material `resource_name` contains `glass` with a
plain transparent `StandardMaterial3D` (albedo alpha about 0.07, `TRANSPARENCY_ALPHA`, roughness about 0.04) through
`set_surface_override_material`. Check other scanned models' glass the same way before a close-up relies on seeing
through it.

## GDT-154 — `HFlowContainer` and autowrapping `Label` report their real height only after a layout pass: same-frame minimum heights are 0 and 5,494 px

`측정 2026-09-27 · Godot 4.7.2-stable · headless`

**증상:** A dialog that sized its panel from `body.get_combined_minimum_size().y` right after filling it came out
far too short or far too tall, depending on the content. Measured in a 400 px wide `VBoxContainer` holding an
`HFlowContainer` with seven 130×195 children and an `AUTOWRAP_WORD_SMART` label of about 270 characters:

| When | Flow | Label | Column |
|---|---|---|---|
| Same frame, right after `add_child` | 0 | 5,494 | 5,499 |
| After one `await get_tree().process_frame` | 593 | 149 | 746 |
| After two frames | 593 | 149 | 746 |

A flow container has no rows until it has been sorted at a width. An autowrapped label measures itself at its
current width, which is 0 before the container sorts it, so it reports one word per line.

**해결:** Give the container its final width first, wait one `process_frame`, then read the minimum size and fit the
height. From a function that must not become a coroutine, connect a one-shot callback instead of awaiting:
`get_tree().process_frame.connect(func(): card.size.y = col.get_combined_minimum_size().y + pad, CONNECT_ONE_SHOT)`.
One frame was enough in every case measured; check `is_instance_valid()` because the node may be freed by then.

## GDT-155 — A Godot 4.7 `.pck` (pack format 4) can be listed in 30 lines of Python; in one Web export imported textures were 24.1 of 28.5 MB, 1.66× their WebP sources

`측정 2026-09-27 · Godot 4.7.2-stable · Web export · textures imported lossy 0.85 with mipmaps`

**증상:** A Web export grew to 28.5 MB and it was not obvious what was inside. The pack header is: `GDPC`, format
version (uint32, 4 here), engine version (3 × uint32), flags (uint32), file base (uint64), then, from format 3 on, the
directory offset (uint64). At that offset: file count (uint32), then per file a uint32 path length, the path (padded
with NUL), offset (uint64), size (uint64), MD5 (16 bytes) and flags (uint32).

```python
import struct
d = open("build/web/index.pck", "rb").read()
off = struct.unpack_from("<Q", d, 32)[0]          # directory offset (format >= 3)
n = struct.unpack_from("<I", d, off)[0]; off += 4
for _ in range(n):
    ln = struct.unpack_from("<I", d, off)[0]; off += 4
    path = d[off:off + ln].rstrip(b"\0").decode(); off += ln
    _, size = struct.unpack_from("<QQ", d, off); off += 16 + 16 + 4
    print(size, path)
```

That export held 646 files: `.ctex` textures 24.13 MB, Ogg music 1.99 MB, a subset Korean font 0.63 MB, scripts
and data under 0.4 MB. The textures came from 14.5 MB of WebP (208 card images at 600×900 and 288×432). The importer
re-encodes them (`compress/mode=1`, `lossy_quality=0.85`, `mipmaps/generate=true`), so the pack carries 1.66× the
source bytes.

**해결:** Measure the pack before optimising anything else. For UI-only art that is never minified much, turning off
mipmaps or lowering `lossy_quality` is where the megabytes are; fonts, audio and code are small in comparison.

## GDT-156 — Web export: a focused `LineEdit` takes text through a hidden `div.ime`. IME composition reaches it, but Playwright's `keyboard.type('한글')` and `insertText()` never do

`측정 2026-09-27 · Godot 4.7.2-stable Web export · Chrome 헤드리스 + Playwright · 한국어 이름 입력칸`

**증상:** A browser test clicked a `LineEdit` in the Web build and typed a Korean name with `page.keyboard.type('하늘')`.
The field stayed empty and the form answered "이름을 알려 주세요!". A player typing with a real Korean IME had no
problem.

Clicking a `LineEdit` moves `document.activeElement` to a hidden `<div class="ime">` (opacity 0, 1 px font, fixed
position) that the engine uses for text input. Measured on three fields of the same form:

| Input method | Reached the `LineEdit` |
|---|---|
| `page.keyboard.type('Haneul')`: ASCII, one keydown per character | yes |
| `page.keyboard.insertText('햇살')`: text inserted with no composition | **no** |
| CDP `Input.imeSetComposition` ('ㄸ' → '딸'), then `Input.insertText('딸기')`: composition like a real IME | yes |

Playwright's `keyboard.type()` falls back to `insertText` for characters that are not on the US layout, so every
Korean, Japanese or Chinese string takes the path that does not work.

**해결:** In tests, type CJK text as an IME would, through a CDP session:
`cdp.send('Input.imeSetComposition', {text, selectionStart: n, selectionEnd: n})`, then
`cdp.send('Input.insertText', {text})`. Before concluding that Korean input is broken, try it with a real IME.
Input methods that insert text without composition, such as some autofill and dictation tools, will not reach the
field either.

## GDT-157 — `ext_resource`에 `uid=`가 없는 손으로 쓴 `.tscn`은 Web 빌드 콘솔에 invalid UID 경고를 매 부팅 찍는다

`측정 2026-09-27 · Godot 4.7.2 · Web export (gl_compatibility, 싱글스레드) · Chrome`

**증상:** 에디터와 네이티브 실행은 조용한데, 브라우저 콘솔에만 부팅마다 이 두 줄이 나온다.
콘솔 에러·경고를 0으로 요구하는 브라우저 테스트가 이것 하나로 실패한다.

```
WARNING: 'res://scenes/main.tscn': In external resource #0, invalid UID: 'uid://s28mpx4lkckk' - using text path instead: 'res://scripts/main.gd'.
   at: open (core/io/resource_format_binary.cpp:1028)
```

원본 `.tscn`은 `[ext_resource type="Script" path="res://scripts/main.gd" id="1"]`처럼 `uid=` 없이
손으로 썼고, 경고 속 UID는 프로젝트 어디에도 없다(`grep -r`로 소스·`.godot` 모두 0건).
`main.gd.uid` 파일은 다른 값(`uid://d00neijvifb24`)을 갖고 있었다. 익스포트가 텍스트 씬을 바이너리로
바꾸면서 스크립트와 맞지 않는 UID를 박아 넣는다. 경로로 되돌아가므로 게임은 정상 동작한다.

**해결:** `ext_resource`에 스크립트의 `.uid` 파일 값을 그대로 적는다.

```
[ext_resource type="Script" uid="uid://d00neijvifb24" path="res://scripts/main.gd" id="1"]
```

재익스포트 후 콘솔 경고 0건(브라우저 e2e 19개 검사 통과). 스크립트로 씬을 생성하거나 손으로 쓸 때는
`.uid` 파일을 읽어 `uid=`를 함께 쓴다.

## GDT-158 — A method Callable does not keep its RefCounted alive: `Obj.new().method` is invalid before it is called, and code that falls back on `is_valid()` silently changes behaviour

`measured 2026-09-27 · Godot 4.7.2 headless`

**Symptom:** a seeded random generator was passed to a ranking function as `rng = Mulberry32.new(seed).as_callable()`, where `as_callable()` returns `next_float`. The function did `rng.call() if rng.is_valid() else randf()`. Every seeded run then disagreed with a reference implementation, and with itself when run twice on the same seed. No error was logged.

A Callable bound to a method holds the object's id, not a reference. Measured:

| Expression | `is_null()` | `is_valid()` |
|---|---|---|
| `var c: Callable = Gen.new().next` (temporary RefCounted) | false | **false** |
| `var g := Gen.new(); var c: Callable = g.next` | false | true |
| `func(): return Gen.new().next()` (a lambda creating its own object) | false | true |

The temporary's refcount reaches zero on the line that creates the Callable. The `is_valid()` fallback then turned a seeded run into a random one.

**Fix:** keep the object in a variable for as long as its Callable is used. In code that takes an optional Callable, tell the two cases apart: `is_null()` means none was passed, and `not is_valid()` means one was passed but its object is gone. Report the second (`push_error`) rather than falling back quietly. See also GDT-147 for lambda captures.

## GDT-159 — JSON cannot carry a float exactly in Godot: `stringify` rounds to ~15 digits, and even `full_precision=true` does not survive `parse_string`

`measured 2026-09-27 · Godot 4.7.2 headless`

**Symptom:** a check compared a GDScript port against JavaScript to the bit. A level table's jitter (`1.6 * (1 - 1/8)`, which is 1.4000000000000001 in both languages) differed after passing through JSON.

| | Output | Parsed back equal? |
|---|---|---|
| `JSON.stringify(x)` | `1.4` | no |
| `JSON.stringify(x, "", true, true)` (`full_precision`) | `1.4000000000000001` | **no**: `JSON.parse_string` of that string still returns a different double |
| `0.1 + 0.2` default / full | `0.3` / `0.30000000000000004` | |

JavaScript's `JSON.stringify` writes the shortest round-tripping form, so the two sides disagree even when both computed the same double.

**Fix:** for exact transport, send the IEEE-754 bytes. On the Godot side use `PackedByteArray.resize(8)`, `encode_double(0, x)` and `hex_encode()`, and decode with `hex_decode().decode_double(0)`. On the JS side use `DataView.setFloat64(0, x, true)` (little-endian). Only compare decimals from Godot's JSON with a tolerance.

## GDT-160 — A Godot web export refuses to start on any `http://` origin but localhost, even single-threaded: `getMissingFeatures()` requires a Secure Context unconditionally

`측정 2026-09-27 · Godot 4.7.2 · web_nothreads_release · Chrome`

**증상:** the page stays on its loading screen forever, and the console says `Secure Context - Check web server configuration (use HTTPS)`. The same build works at `http://localhost:…` and at `https://…`. Typical triggers: opening a dev server from a phone at `http://192.168.x.x:port`, or putting the production container behind a test hostname over plain HTTP.

In the 4.7.2 engine loader (`godot.js`), `Engine.getMissingFeatures({ threads })` pushes `Secure Context` whenever `window.isSecureContext` is false, **before and independent of** the `threads` flag — `threads: false` only drops the Cross-Origin-Isolation and SharedArrayBuffer requirements. The default web shell (and any custom shell that copies its boot code) calls it and stops if anything is missing. Measured: the same image loaded as `http://button.test:8081` (mapped to 127.0.0.1) never booted, and booted in 5.2 s with 0 console errors once Chrome was told to treat that origin as secure.

**해결:** serve over HTTPS, or use `localhost` (browsers treat it as potentially trustworthy). For a browser test of a non-localhost origin over HTTP, launch Chrome with `--unsafely-treat-insecure-origin-as-secure=http://host:port` (plus `--host-resolver-rules=MAP host 127.0.0.1` to route a made-up name). For a phone on the LAN, `adb reverse tcp:PORT tcp:PORT` and open `http://localhost:PORT` on the phone.

## GDT-161 — Compatibility renderer: unshadowed `OmniLight3D`/`SpotLight3D` add no draw calls; six shadowed spots added 5

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility`

**증상:** a 3D stage for a web export needed a key light, rim lights, footlights and spots, and the budget assumed every
light costs extra passes in the Compatibility renderer.

In a test scene, 0, 1, 3 and 6 unshadowed spot/omni lights all rendered in **4 draw calls**. Six spot lights with
`shadow_enabled = true` added **5**. The finished stage (all lights unshadowed, glow and post on) measured 54 WebGL draw
calls per frame in the web build at 1280×720 @2×, and 34–36 natively.

**해결:** add fill, rim and accent lights freely when they cast no shadow. Fake contact shadows with blob or projected
silhouette meshes and enable `shadow_enabled` only where it pays.

## GDT-162 — Web export: `RenderingServer.render_loop_enabled = false` stops WebGL work completely (0 draw calls in 1.2 s) for a 3D iframe hidden behind an HTML UI

`측정 2026-09-27 · Godot 4.7.2-stable Web export (Compatibility, nothreads) · Chrome, macOS`

**증상:** a Godot canvas sits in an iframe behind an HTML interface. On menu screens that cover the stage it still
rendered every frame and competed with the page's animations.

Setting `RenderingServer.render_loop_enabled = false` and `Engine.max_fps = 5` while the stage is covered, a test that
wraps the WebGL2 draw functions counted **0 draw calls over 1.2 s**. JavaScriptBridge commands still arrive in that
state, so the command that shows the stage again re-enables the loop.

**해결:** drive `render_loop_enabled` from the page's view state (hidden → false, shown → true) instead of leaving the
covered canvas rendering.

## GDT-163 — Timelines advanced by `_process(delta)` ran 13% long on a loaded web build (3.45 s → 3.9 s); wall-clock deltas × `Engine.time_scale` with `run/delta_smoothing` off stayed at 1.00×

`측정 2026-09-27 · Godot 4.7.2-stable Web export (nothreads) · Chrome, macOS, busy host`

**증상:** a cinematic authored at 3.45 s took 3.9 s in the web build while the host was loaded, overrunning the time
budget the HTML side waited on before continuing. The timeline summed the `delta` passed to `_process` with the default
`application/run/delta_smoothing = true`: under load, the summed delta trailed the wall clock.

Advancing the same timelines by wall-clock deltas (`Time.get_ticks_usec()`) multiplied by `Engine.time_scale`, capped at
0.5 s per frame, with `run/delta_smoothing = false`, replayed 48 battle events with a worst case of **1.00×** the
authored length.

**해결:** for fixed-length presentation (cut-ins, cameras, anything another system waits on), step the timeline with
wall-clock deltas scaled by `Engine.time_scale` so slow motion still works, and turn delta smoothing off. The animation
drops frames instead of stretching.

## GDT-164 — `tween_property(material, "shader_parameter/x", …)` fails with "property does not exist" until `set_shader_parameter("x", …)` has run once

`측정 2026-09-27 · Godot 4.7.2-stable`

**증상:** tweening a `ShaderMaterial` uniform that still held its shader default logged that the tweened property does not
exist, and nothing animated. After one `set_shader_parameter()` call with the same name, the identical tween worked.

**해결:** when creating the material, seed every uniform you will tween with `set_shader_parameter(name, start_value)`,
then tween `"shader_parameter/<name>"`.

## GDT-165 — GDScript `float` is 64-bit but `Vector2` math is 32-bit: a Rust port matched GDScript bit for bit only with `f32` at every spot the GDScript went through `Vector2`

`측정 2026-09-27 · Godot 4.7.2-stable (standard single-precision build) · Rust 1.97.1 · SpacetimeDB module port of a GDScript rules engine`

**증상:** a deterministic GDScript rules engine (floats for positions, `Vector2` for a few helpers such as
`Vector2(a, b).distance_to(c)`, summing capture centres, nearest-point searches) had to be ported to Rust so the
server could run the same game. In a standard Godot build `Vector2` stores `real_t = float` (32-bit), so
`distance_to()`, `+=` on a `Vector2` and every component read back from it are rounded to single precision, while
plain GDScript `float` variables stay 64-bit. An `f64`-everywhere port therefore computes different values at those
spots, and a bit-exact comparison cannot pass.

**해결:** in the port, use `f32` exactly where the GDScript builds or combines a `Vector2`, and `f64` everywhere
else; convert at the same points the GDScript does. With that, 2,025 trace records over 10 stages (solo and two
players, ~3,000 steps each, floats compared as raw 64-bit patterns) matched exactly. Two more things kept the
engines identical: aim with a shared 256-entry cos/sin table written as decimal literals in both languages instead
of calling `sin`/`cos`/`atan2`, and a 31-bit integer LCG for all randomness.

## GDT-166 — One UI scale for phones and desktops: `content_scale_size = Vector2i(S, S)` with `CONTENT_SCALE_ASPECT_EXPAND` makes the layout's short side exactly `S` in either orientation

`측정 2026-09-27 · Godot 4.7.2-stable · macOS 2× display, captures at several window sizes`

**증상:** a fixed base size (1440 × 900) with `canvas_items` + `expand` makes a portrait phone lay out at
1440 × 3116, so 16 px text lands at about 4 CSS px. Separate base sizes per device class need extra code paths.

**해결:** set a square base and let `expand` grow the long side:

```gdscript
var short_side := int(clampf(minf(window.size.x, window.size.y) / DisplayServer.screen_get_scale(), 560.0, 900.0))
window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
window.content_scale_size = Vector2i(short_side, short_side)   # re-run on size_changed
```

Measured layouts: a 3840 × 2160 px window on a 2× screen → 1600 × 900; 1920 × 1080 px at 2× → 995 × 560;
780 × 1688 px at 2× (phone portrait) → 560 × 1212. Screens then pick rail, bar or portrait layouts from the
layout size alone. Note that `window_set_size()` in a capture script is in physical pixels, so on a 2× screen a
1920 × 1080 capture is a small 960 × 540 pt window and gets the phone-sized UI.

## GDT-167 — Web export: `HTTPRequest.request("stream/…")` fails with `Invalid URL scheme: ''`; resolve against the page URL. Streaming reward art and music out of `index.pck` cut it from 34.4 MB to 13.3 MB

`측정 2026-09-27 · Godot 4.7.2-stable Web export (no threads) · headed Chromium on a local server and production`

**증상:** a loader that fetched files next to `index.html` with relative URLs logged
`ERROR: Invalid URL scheme: ''.` (`_parse_url`, `scene/main/http_request.cpp:66`) for every request on the Web; nothing
downloaded.

**해결:** build an absolute URL once:
`JavaScriptBridge.eval("new URL('stream/', window.location.href).href", true)`. The rest of the pattern worked as is:
- keep the files out of the pack with the preset's `exclude_filter` (globs such as `assets/heroines/*/t2.webp`) and
  copy the raw source files to `build/web/stream/<same path>` in the build script;
- build resources from the bytes: `Image.load_webp_from_buffer()` + `generate_mipmaps()` + `ImageTexture.create_from_image()`,
  and `AudioStreamOggVorbis.load_from_buffer()` (set `loop` yourself);
- return `null` until a file arrives and emit a signal; prefetch the next stage's files while the current one plays.

With 20 reward pictures, 20 cards and 9 music tracks streamed, `index.pck` went from 34.4 MB to 13.3 MB and the
first screen came up in 7.6 s on production; 31 files then arrived in the background with HTTP 200 and no console errors.
`ResourceLoader.exists()` still sees packed files first, so desktop builds need no special case.

## GDT-168 — Tweening `position` of a `Container` child from its `position` right after `add_child()` stacks every child at (0, 0)

`측정 2026-09-27 · Godot 4.7.2-stable`

**증상:** a menu built as a `VBoxContainer` of buttons, each given an entrance tween
(`target = control.position; control.position = target + offset; tween position → target`), rendered all six
buttons on top of each other at the container's origin. The container had not sorted its children yet, so every
`target` was (0, 0), and the tween then kept moving them there after the sort.

**해결:** do not tween `position` on a child whose parent is a `Container`; fade it (`modulate:a`) instead, or wait
for the container's `sort_children` signal and animate a wrapper control. The same helper can keep sliding free
controls: check `control.get_parent() is Container` and skip the position part.

## GDT-169 — Names that collide with the language: `var match` and a script `func _get(path, urgent)` both stop every script that preloads them

`측정 2026-09-27 · Godot 4.7.2-stable`

**증상:**
- `var match: RefCounted` in a screen script: `Parse Error: Expected expression to test after "match".` `match` is a
  keyword, so the declaration is read as a match statement.
- A loader `Node` with `func _get(path: String, urgent: bool) -> Resource:`:
  `The function signature doesn't match the parent. Parent signature is "_get(StringName) -> Variant".` `_get` is the
  `Object` property-getter virtual. Every script that preloads the loader then fails with
  `Compile Error: Failed to compile depended scripts.`, which points away from the real cause.

**해결:** rename (`rules`, `_fetch`). Avoid `_get`, `_set`, `_get_property_list`, `_notification`, `_init` and `_to_string`
as ordinary method names; a parse check that loads each script on its own (`load(path).can_instantiate()` in a small
SceneTree script) names the file that is actually broken.

## GDT-170 — Web export: `DisplayServer.keyboard_get_keycode_from_physical()` is unsupported and logs an engine error on every call; `DisplayServer.get_name()` is `"Web"`

`측정 2026-09-27 · Godot 4.7.2-stable · web_nothreads_release · Chrome (headless, channel chrome)`

**증상:** A UI that draws key prompts by mapping each action's physical key to the player's layout
(`keyboard_get_keycode_from_physical(physical_keycode)` then `OS.get_keycode_string`) worked natively and
flooded the browser console in the Web export, one pair per prompt drawn:
`ERROR: Not supported by this display server.` / `at: keyboard_get_keycode_from_physical (servers/display/display_server.cpp:1224)`.
The call returns the code unchanged, so the prompts looked right and only the console showed it. The headless display
server behaves the same way.

**해결:** skip the call where it is unsupported:
`if DisplayServer.get_name() not in ["headless", "Web"]: code = DisplayServer.keyboard_get_keycode_from_physical(code)`.
Measured: errors in the console went from dozens per screen to 0 on the same page flow. `"Web"` is the exact name
(capital W) the web display server reports.

## GDT-171 — Web export with stretch mode `disabled` draws the UI in physical pixels: half size on a Retina Mac, a quarter on phones. `content_scale_factor` fixes it without touching the 3D

`측정 2026-09-27 · Godot 4.7.2-stable Web export (Compatibility) · Playwright Chrome, deviceScaleFactor 2 and 3–3.5 with touch`

**증상:** A game laid out for 1440 × 900 with `window/stretch/mode="disabled"` looked right in a DPR-1 browser. On
a DPR-2 viewport of 1440 × 900 CSS px, the canvas was 2880 × 1800 px and the HUD, hotbar and menus came out at
half size. A phone held sideways (915 × 412 CSS px at DPR 3.5 → 3202 × 1442 px) showed 15 px text at about 4 CSS px.

**해결:** Keep the stretch mode and set the root window's `content_scale_factor` from the density and the window
size, re-running it on `get_tree().root.size_changed`:

```gdscript
var px := Vector2(get_tree().root.size)
var s := maxf(DisplayServer.screen_get_scale(), px.y / 1100.0)   # web: devicePixelRatio
s = minf(s, minf(px.y / 560.0, px.x / 1000.0))                   # a phone still gets 560 logical px of height
get_tree().root.content_scale_factor = s
```

Measured results:
- DPR 2 → factor 2, logical 1440 × 900, the same look as DPR 1. The 3D stays at 2880 × 1800 and still ran at 60 fps.
- Phone → factor 2.2–2.6, logical about 1244 × 560. Controls, mouse positions, `Camera3D.project_ray_origin()` and
  `unproject_position()` all stayed consistent in logical units.

Screens designed taller than 560 got a fit step: a top-left anchor, `size = viewport / k` and `scale = k`, with
`k = min(1, vw / 1060, vh / 670)`. Input to scaled Controls kept working.

On phones, `get_viewport().scaling_3d_scale = sqrt(2.2e6 / pixels)`, set once at startup (GDT-148), keeps the 3D
at about 2.2 million pixels while the UI stays sharp.

Multi-touch also worked, measured with CDP `Input.dispatchTouchEvent`. Custom Controls that read
`InputEventScreenTouch`/`InputEventScreenDrag` in `_gui_input` and remember `event.index` received a second
finger while the first held a stick. The emulated mouse only follows the first finger, so a `Button` would not
see the second one.

GDT-166 is the `canvas_items` alternative.

## GDT-172 — A Godot 4.7 web export inside a Docker build: download the Linux editor by checksum, vendor only the one 10 MB web template (templates ship as one 1.28 GB `.tpz`), import before exporting

`측정 2026-09-27 · Godot 4.7.2 · debian:bookworm-slim · Docker 29.7 (BuildKit) · arm64 native and amd64 under emulation`

**증상:** a production image that has to export a Godot project on the build host (Dokploy-style: build from a git clone, no artefacts committed) needs the editor and an export template. Godot publishes export templates **only** as `Godot_v4.7.2-stable_export_templates.tpz`, **1,281,349,702 bytes** of every platform, while a single-threaded web export needs one file from it, `web_nothreads_release.zip`, **10,245,903 bytes**. The Linux editors are separate zips of about 77 MB (`linux.x86_64` 77,860,424, `linux.arm64` 77,008,699), each listed in the release's `SHA512-SUMS.txt`.

What worked, both architectures:

- Pick the editor with BuildKit's automatic `ARG TARGETARCH` (`amd64` → `linux.x86_64`, `arm64` → `linux.arm64`), `curl` it from the GitHub release and `sha512sum -c` it against the value copied out of `SHA512-SUMS.txt`.
- Commit `web_nothreads_release.zip` (taken from the local `export_templates/4.7.2.stable/`) with a `.sha512` beside it, and `COPY` both to `/root/.local/share/godot/export_templates/4.7.2.stable/`. The `.tpz` itself has a published checksum; the single zip does not, so its checksum is your own.
- `godot --headless --import` **before** `godot --headless --export-release Web build/web/index.html`. A cold `.godot` is a broken project (GDT-036), and an export from it packs scripts whose `class_name`s never resolved.
- The editor prints `ERROR: Unable to load fontconfig, system font support is disabled.` about twenty times on a slim image. Harmless when the project brings its own fonts, but it makes a failed build's log open with a page of errors that are not the failure: `apt-get install libfontconfig1` took it to 0.
- Timing: the import and export took seconds natively on arm64, and **22.0 s** for the x86 editor under emulation on an M1 Max. The resulting `index.wasm` is the template's `godot.wasm` byte for byte (39,514,754), and served with nginx `brotli_static` it went out as 6,902,599 bytes.

- On the real host (Dokploy, building from a git clone), the first build of this Dockerfile went from `git push` to the new page being served in **269 s**, including the editor download and brotli 11 over the 39.5 MB engine.

**해결:** vendor the one template file with its own SHA-512, download the editor per `TARGETARCH` against the release's SHA-512, import then export, and keep the three version pins (project, editor download, template) moving in one commit.

## GDT-173 — `(dict[k] as PackedVector3Array).append(x)` appends to a throwaway copy, and `set("prop", untyped_array)` on an `Array[Color]` export does nothing without an error

`측정 2026-09-27 · Godot 4.7.2-stable · macOS · headless SceneTree script`

**증상:** a baked mesh came out empty although the loop that filled its vertex lists ran, and a character that received its palette through `node.set("colors", [...])` rendered white. Neither printed an error.

Measured in one script (`d := {"k": PackedVector3Array()}`, a node whose script has `@export var colors: Array[Color] = []`):

| Statement | Result |
| --- | --- |
| `(d["k"] as PackedVector3Array).append(Vector3.ONE)` | `d["k"].size()` stays **0** |
| `var a: PackedVector3Array = d["k"]` then `a.append(...)` | `d["k"].size()` becomes 1 (the typed local shares the array) |
| `d["k"].append(...)` | appends in place |
| `h.set("colors", [Color.RED, Color.BLUE])` (untyped literal) | `h.colors.size()` stays **0**, no message |
| `h.colors = [Color.RED, Color.BLUE]` (same untyped value) | `SCRIPT ERROR: Invalid assignment of property or key 'colors' with value of type 'Array'` |
| `h.set("colors", typed)` with `var typed: Array[Color]` | works |

The `as` cast produces a temporary; the call mutates it and the result is dropped. `Object.set()` reports a failed typed-array conversion by returning silently, where the direct assignment of the very same value raises.

**해결:** mutate packed arrays through a typed local or directly on the container (`d[k].append`), never through `(x as Packed…Array)`. Pass typed arrays to `set()` (`var c: Array[Color] = [...]`, or `Array(untyped, TYPE_COLOR, "", null)`), or assign the property directly so a mismatch fails loudly; after bulk `set()` calls, read one property back in a test.

## GDT-174 — Testing a Godot web build's touch controls in headless Chrome: `OS.has_feature("web_ios")` follows the User-Agent, and CDP `Input.dispatchTouchEvent` reaches Godot as screen touches

`측정 2026-09-27 · Godot 4.7.2 web export (nothreads) · Playwright 1.63 · Chrome channel headless with Metal ANGLE · macOS`

**증상:** a Playwright phone context `{viewport: 390×844, isMobile: true, hasTouch: true}` loaded the game but showed the desktop HUD without a joystick. The game picks the touch layout at start when `OS.has_feature("web_ios") or OS.has_feature("web_android")`, falling back to `DisplayServer.is_touchscreen_available()` together with `matchMedia('(pointer: coarse)')`. In that context the whole check was false (which half of the fallback failed was not isolated).

Adding an iPhone Safari `userAgent` to the same context made `web_ios` true: the touch layout appeared on the first frame. Godot derives the `web_*` platform features from the User-Agent string, so device emulation without a mobile UA is a desktop to the game.

Driving the controls: `page.touchscreen.tap` only taps. A CDP session drives drags:

```js
const cdp = await context.newCDPSession(page);
const touch = (type, x, y) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x, y, id: 1 }] });
await touch('touchStart', 95, 700);                     // left half: floating joystick
for (let i = 1; i <= 8; i++) await touch('touchMove', 95, 700 - i * 8);
for (let i = 0; i < 90; i++) { await touch('touchMove', 95 + (i % 2), 636); await page.waitForTimeout(25); }
await touch('touchEnd', 0, 0);
```

Godot received these as `InputEventScreenTouch` / `InputEventScreenDrag`; the traveler walked 9.1–14.9 m in five runs. Holding a stationary touch needs the alternating 1 px move — without new move events the joystick sees no drag.

**해결:** give phone contexts a real mobile User-Agent as well as `isMobile`/`hasTouch`, and drive drags through `Input.dispatchTouchEvent`, asserting on a position the game reports rather than on the screenshot.

## GDT-175 — Every headless Android export kills the machine's adb server (`export/android/shutdown_adb_on_exit`), dropping every session's phone and re-raising the USB-debugging prompt

`측정 2026-09-27 · Godot 4.7.2-stable (macOS, headless `--export-debug Android`) · adb 1.0.41 · Pixel 7 Pro, Android 17`

**증상:** a loop of `godot --headless --export-debug Android …` → `adb install` printed `* daemon not running; starting now at tcp:5037` on **every** iteration (six in a row), and the phone kept showing *USB 디버깅을 허용하시겠습니까?* (`com.android.systemui/.usb.UsbDebuggingActivity` on top). Between exports `adb devices` sometimes listed nothing at all. Nothing in the export log mentions adb.

The Android export platform shuts the adb server down when the editor process exits, because the editor setting `export/android/shutdown_adb_on_exit` defaults to true — and a headless export is an editor process that exits. There is one adb server per machine (OPS-064, AGT-044), so this is a `kill-server` for every other session using a phone too.

**해결:** add `export/android/shutdown_adb_on_exit = false` to `~/Library/Application Support/Godot/editor_settings-4.7.tres` (under `[resource]`, beside the other `export/android/*` keys). Measured after the change: `adb devices` lists the device before and after an export, and the next `adb install` no longer starts a daemon. On the phone, tick *이 컴퓨터에서 항상 허용* once so a reconnect does not prompt.

How to see it after the fact: the adb server's own log, `$TMPDIR/adb.<uid>.log` on macOS, prints `adb.cpp:1288 adb server killed by remote request` and then `--- adb starting (pid N) ---` for every kill. Measured on 2026-09-27: 13 kills between 15:45 and 16:16, one per export; 0 in the 40 minutes after the setting went off. A prompt that still comes back after that is the phone not remembering the key: the same log then shows `transport.cpp:1222 <serial>: connection terminated: read failed` repeating about once a second for as long as the dialog is up (two bursts of 12–17 lines, at 16:52 and 16:54), and isolated `read failed` lines where the USB link itself dropped.

## GDT-176 — Android back gesture: `get_tree().quit()` from `NOTIFICATION_WM_GO_BACK_REQUEST` restarts the app; toggle `SceneTree.quit_on_go_back` per screen instead

`측정 2026-09-27 · Godot 4.7.2-stable Android export (non-Gradle, debug) · Pixel 7 Pro, Android 17`

**증상:** with `application/config/quit_on_go_back=false` (so the back gesture could close panels and ask before leaving a match), the title screen's handler called `get_tree().quit()`. The notification arrived (logged), but the app stayed on screen: its pid changed from 4065 to 4162 and `dumpsys activity activities` still showed `com.godot.game.GodotAppLauncher` as `topResumedActivity`. The script quit ends the process, and Android brings the activity straight back.

With the project setting left false, the default `quit_on_go_back=true` would instead close the app mid-match on any accidental back swipe.

**해결:** keep the project setting false and flip the `SceneTree` property per screen — `get_tree().quit_on_go_back = screen == "home"` — so the engine finishes the activity itself on the title, while `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` handles every other screen (close the open panel, drop the selection, confirm before leaving). Measured: back on the title → `topResumedActivity` is no longer the game; back in a match → the confirm dialog.

## GDT-177 — Web export: a scene of ~150–300 instances of an `instance uniform` material logged "Too many instances using shader instance variables … Maximum items supported by this hardware is: 1024"; an isolated 1,030-box test did not

`측정 2026-09-27 · Godot 4.7.2-stable · Web export (Compatibility, no threads), GPU Chrome on macOS; native GL Compatibility on M1 Max`

**증상:** a board game drew 48 tiles (tile + figure MeshInstance3D each, sometimes a third) plus a title diorama of ~43 pieces, all sharing one ShaderMaterial whose per-piece state was `instance uniform`s (first four floats, then packed into one `vec4` — same result). The web build printed `ERROR: Too many instances using shader instance variables. Consider increasing rendering/limits/global_shader_variables/buffer_size … Maximum items supported by this hardware is: 1024.` repeatedly once a match started; at the title alone (~180 instances) it printed nothing. Natively the cap reads 4096 and nothing was printed; setting `limits/global_shader_variables/buffer_size=1024` natively reproduced the errors **at the title**. Pieces' meshes were reassigned often (a face-down tile's figure mesh set to `null`, then to a kind's mesh on reveal).

An isolated project did **not** reproduce it with `buffer_size=1024`: 1,030 BoxMesh instances with one instance uniform, 300 instances with four, and 300 rounds each of mesh swapping, mesh ↔ null, material swapping and instance free — zero errors. So the trigger is something in the real scene not yet isolated; the practical ceiling is lower than "1,024 instances".

This is a caveat to GDT-146, which recommends instance uniforms for per-object glow.

**해결:** made per-piece state an ordinary `uniform vec4 state` and let a piece borrow a private `duplicate()` of the shared material only while its state is non-zero (hover, selection, a flash) — at most a handful at once. The same web flow then logged no engine errors (15 clicked moves, GPU Chrome). If a web build must use instance uniforms at scale, watch the console for this line early; the native build will not show it at the default buffer size.

## GDT-178 — A GDScript lambda captures locals by value: assigning to a captured `String` inside a polling lambda never reaches the outer variable

`측정 2026-09-27 · Godot 4.7.2-stable · headless `--script` test`

**증상:** a two-process test polled a file for a room code with `var code := ""` and `await _wait(func() -> bool: code = FileAccess.get_file_as_string(f).strip_edges(); return code.length() == 4, 15.0)`. The wait returned true (the lambda saw four digits), and the next line `join(code)` sent `""` — the outer `code` was never assigned. No warning or error.

**해결:** capture a container and write into it: `var code := [""]` … `code[0] = …` … `join(code[0])`. Arrays and Dictionaries are references, so the lambda and the caller see the same object; primitives (`int`, `String`, `bool`, `Vector2`) are copied at capture time.

## GDT-179 — Frosted-glass HUD panels in `gl_compatibility`: a `hint_screen_texture` material on a `PanelContainer`, and a second `CanvasLayer` gets its own screen copy (it sees the layer below already post-processed)

`측정 2026-09-27 · Godot 4.7.2-stable · gl_compatibility · Apple M1 Max (native) and Chrome WebGL2 (Web export)`

**증상:** A full-screen post pass (tilt-shift + grade, `CanvasLayer.layer = 0`) and blurred-glass HUD panels (`layer = 2`) both need the screen texture. It was unclear whether the HUD's copy would be the raw 3D frame or the post-processed one, and how to keep a stylebox's rounded, anti-aliased edge when a shader replaces its colour.

- Each `CanvasLayer` that uses `hint_screen_texture` gets a fresh copy: the HUD panels showed the **post-processed** (blurred, vignetted) frame, not the raw 3D. Order the layers so the glass sees what you want.
- A `ShaderMaterial` set as `material` on a `PanelContainer` affects only its own stylebox draw; child Labels keep the default material and stay sharp.
- In the fragment, `COLOR` is the stylebox colour with its alpha. `COLOR = vec4(mix(blur, COLOR.rgb, COLOR.a), clamp(COLOR.a / 0.1, 0.0, 1.0))` gives an opaque glass body (any alpha above 0.1) with the corner anti-aliasing intact. Set the stylebox `shadow_size = 0` — the drop shadow would be frosted too. Do not put this material on a `Button` with text: glyph edges have low alpha and get the same treatment.
- Five `textureLod` taps at lod ≈ 3.4 (GDT-130) ran in the Web export with no console errors; the whole scene stayed at 110 fps natively.

**해결:** post layer below, HUD layer above, glass material on panels only, shadow off, alpha divided by a small threshold. Related: GDT-128, GDT-130.

## GDT-180 — Web export: `document.documentElement.requestFullscreen()` called through `JavaScriptBridge.eval` from a `Button.pressed` handler succeeds — Godot's delayed input dispatch still counts as the user's gesture

`측정 2026-09-28 · Godot 4.7.2-stable · Web export (debug) · Chrome 153 (GPU, macOS), clicks sent by CDP Input.dispatchMouseEvent`

**증상:** Browsers only allow full screen during a user gesture. Godot's web build does not run GDScript inside the DOM `pointerup` handler; it queues the event and dispatches it on the next frame. It was unclear whether a `Button.pressed` callback still counts as the gesture.

- A GDScript `pressed` handler that runs `JavaScriptBridge.eval("document.documentElement.requestFullscreen()")` entered full screen on one click. A second click in the same handler ran `document.exitFullscreen()` and left full screen. `document.fullscreenElement` confirmed each state within 200 ms.
- Requesting full screen on `documentElement` rather than through `DisplayServer.window_set_mode` also takes the page's own HTML (background, overlays) into full screen, not only the canvas.
- The browser leaves full screen on Esc without telling GDScript. `get_tree().root.size_changed` fires either way, so it is a good place to refresh the button's icon.
- Hide the button when `document.fullscreenEnabled || document.webkitFullscreenEnabled` is false. This is a feature check, not a measurement; iPhone Safari was not tested.

**해결:** call `requestFullscreen`/`exitFullscreen` through `JavaScriptBridge.eval` straight from the button handler (with `webkit*` fallbacks), and refresh the button's state on `root.size_changed`.

## GDT-181 — A multi-line GDScript lambda must be the last argument of the call: `f(func(): … return x), a, b)` is a parse error

`측정 2026-09-29 · Godot 4.7.2-stable`

**증상:** `Parse Error: Expected end of statement after expression, found "," instead.` on the line that closes a multi-line lambda passed as an argument, when more arguments follow it:

```gdscript
_mi("crate", func() -> Kit.Builder:
    var b := Kit.Builder.new()
    return b), material, self)      # parse error here
```

The same lambda as the **last** argument parses — `x.connect(func() -> void:` … `)` and `cache("k", func():` … `return b.build())` are everywhere and fine. Only an argument *after* the multi-line body breaks it: the indented block ends the lambda, and the parser then expects the statement to end, not the argument list to continue.

**해결:** reorder the parameters so the Callable comes last (`_mi(key, material, parent, make: Callable)`), or bind the lambda to a local first (`var make := func(): …` then `_mi("crate", make, material, self)`), or make it a named `static func` and pass `_name` / `_name.bind(…)`.

## GDT-182 — Engine focus navigation steps once per stick push, but custom `is_action_pressed` handlers see every motion event; replaying axis bindings as `InputEventAction` fixes both and adds hold-repeat

`측정 2026-09-29 · Godot 4.7.2-stable · --headless, events injected with Input.parse_input_event`

**증상:** one left-stick push with jitter (`0.1 → 1.0 → 0.97 → 1.0 → 0.0`, 12 `InputEventJoypadMotion` events) reported `is_action_pressed("ui_down")` on 8 of them. The engine's own focus navigation in a `VBoxContainer` of buttons still moved **one** row. Handlers that test `event.is_action_pressed(...)` themselves (a quantity stepper on `ui_left`, a duel `attack` bound to the right trigger) fire on every one of those events. Holding the stick does not repeat in menus either: no new motion events arrive while the value is steady. This narrows GDT-132: the multi-step problem is in custom handlers, not in built-in focus navigation.

A small autoload removes the problem for every consumer:

- At start, walk `InputMap.get_actions()`. For each action that is not analog (movement, camera), take its `InputEventJoypadMotion` events out with `action_erase_event` and remember `(axis, sign) → actions`. Engine `ui_up/down/left/right` carry left-stick axes by default and are included.
- In `_input`, keep a per-`device:axis:sign` state: press when the value crosses 0.6, release below 0.3. On each edge, send `InputEventAction` (`pressed`, `strength`, `device`) through `Input.parse_input_event.call_deferred(e)`, because the call happens inside the dispatch of the motion event.
- For `ui_*` directions, re-send the press after 0.38 s and then every 0.09 s while held. Engine focus navigation accepts repeated `InputEventAction` presses.

Measured with that autoload: the same flick produced 1 `ui_down` and moved focus 1 row. Holding the stick for 0.8 s scrolled to row ≥ 5 and stopped on release. A jittery trigger pull (`0.65 → 0.7 → 0.68 → 0.9 → 1.0 → 0.95`) produced exactly 1 `attack`, `Input.is_action_pressed("attack")` stayed true while held and went false below 0.3. Analog `Input.get_vector` on movement is untouched.

**해결:** strip axis bindings off button-like actions and replay them as edge-detected `InputEventAction`s from one autoload, as above. Call its rebuild again after remapping.

## GDT-183 — macOS: an 8BitDo Ultimate 2 Wireless over Bluetooth LE reports `Input.get_joy_name()` = `"HID"` with Apple's vendor id, so name-based controller-family detection never sees "8BitDo"

`측정 2026-09-29 · Godot 4.7.2-stable (windowed) · Darwin 27.0 · 8BitDo Ultimate 2 Wireless, BLE (system_profiler: vendor 0x2DC8, product 0x6012)`

**증상:** code that picks button glyphs from `Input.get_joy_name(device)` (for example "dualsense" → PlayStation shapes) found nothing to match. Godot printed:

`name=HID guid=0500b7b5ac05000004000000c4ef6d04 info={ "raw_name": "HID", "vendor_id": "1452", "product_id": "4" }`

1452 is 0x05AC (Apple), not 8BitDo's 0x2DC8, and the product id is 4. The same pad showed as 0x2DC8/0x6012 in `system_profiler SPBluetoothDataType`. When the pad went to sleep it dropped out of `Input.get_connected_joypads()` and moved to "Not Connected" in `system_profiler`.

**해결:** do not rely on the joypad name or vendor id to pick a family on macOS. Fall back to the Xbox layout, and offer a manual glyph-style setting if exact labels matter. The positional mapping itself is right. In a focused window, a 90 s run captured every control: south = `JOY_BUTTON_A`, east = B, west = X, north = Y, LB/RB = 9/10, Back/Start = 4/6, all four D-pad buttons, both sticks, and LT/RT as axes 4/5 going positive.

Two runs, 50 s each, captured nothing. In both, the tester read the prompt only after the window had closed. Do not read a silent probe as "the pad does not reach Godot" until the tester confirms they pressed buttons while it was running.

## GDT-184 — Web export always ships the raw `application/config/icon` file in the pck, even when `exclude_filter` names it; a `config/icon.web` override swaps in a small one

`측정 2026-09-29 · Godot 4.7.2-stable, Web (nothreads) and Android (template APK) export, macOS`

**증상:** Setting a 1024 px PNG as `application/config/icon` grew a Web pck by 2.0 MB: the imported
`.ctex` (0.84 MB) plus the raw PNG file (1.19 MB). Adding the PNG to the Web preset's `exclude_filter`
dropped the `.ctex` but the raw PNG stayed (`strings index.pck | grep` still listed it). The exporter
copies the icon file outside the import system so `Main` can load it as an image at startup.

`html/export_icon=true` writes `index.icon.png` and `index.apple-touch-icon.png` from that same icon,
so an icon drawn with transparent margins (a macOS-style squircle) becomes an apple-touch icon with
transparent corners. `html/export_icon=false` removes both files and both `<link>` tags;
`html/head_include` is then the place for your own favicon, touch icon, manifest and `theme-color`.
The engine JS still keeps `godot_js_display_window_icon_set`, which creates or rewrites
`<link id="-gd-engine-icon" rel="icon">` with a PNG blob when the window icon is set.

**해결:**
- Put a per-platform override in `project.godot`: `config/icon.web="res://<small favicon>.svg"`.
  The Web export then stores the 1.2 KB SVG instead of the PNG (pck back to its previous size to
  within 12 KB), and any runtime window-icon update on the Web also shows the favicon.
- Keep the desktop icon in `exclude_filter` of the Web preset to drop its `.ctex` too.
- Android preset keys that work with the template APK (no Gradle build), checked by unzipping
  `res/mipmap-xxxhdpi-v4/`: `launcher_icons/main_192x192`, `launcher_icons/adaptive_foreground_432x432`,
  `launcher_icons/adaptive_background_432x432`, `launcher_icons/adaptive_monochrome_432x432`
  (`res://` PNG paths; each lands as `icon*.webp` at 192 or 432 px). The launcher shows only the
  centre 288 of the 432 px layers, so a feathered edge on pasted art must sit outside that window.

## GDT-185 — Web export: CDP `Input.dispatchKeyEvent` with a `text` field per character types into a focused `LineEdit` without an IME (extends GDT-156)

`측정 2026-09-29 · Godot 4.7 Web export · Chrome stable 153 headless=new (ANGLE Metal) · raw CDP from Node 26`

**증상:** a name form in a Godot web build (a `LineEdit` inside the canvas) stayed empty after
`Input.insertText({text: "portal-review"})`, the same failure GDT-156 records for Playwright's `insertText`.
A script that only wants ASCII into the field does not need GDT-156's IME composition route.

Sending one `Input.dispatchKeyEvent` pair per character, `{type: "keyDown", key: c, text: c, unmodifiedText: c}`
then `{type: "keyUp", key: c}`, filled the field and the form submitted with that name. The `text` field is what
produces the `keypress`/`input` Godot reads; a `keyDown` without it moves nothing.

**해결:** for ASCII, dispatch key events with `text` per character. For Hangul, use GDT-156
(`Input.imeSetComposition` then `Input.insertText`).

## GDT-186 — `Label3D` drops the leading spaces of every line after the first; a U+2060 WORD JOINER in front keeps them

`측정 2026-09-29 · Godot 4.7.2 · headless, Label3D.get_aabb() (GDT-073)`

**증상:** a multi-line `Label3D` meant to stagger its lines ("ㅋㅋㅋ" drifting right, a chat line
indented under another) drew every line flush left. Leading spaces on the first line were kept.

Measured with `get_aabb()` on four texts, `HORIZONTAL_ALIGNMENT_LEFT`, default font:

| text | aabb width |
|---|---|
| `"WW\nA"` | 0.305 |
| `"WW\n      A"` | 0.305 (the six spaces are gone) |
| `"WW\n⁠      A"` | 0.345 (kept) |
| `"      WW\nA"` | 0.545 (first line keeps them) |

**해결:** start each indented line with U+2060 (WORD JOINER, zero width) before the spaces. The
line then begins with a non-space glyph that draws nothing, and the spaces after it are laid out.

## GDT-187 — A loading cover over a 3D scene still pays for drawing the 3D world every frame; `Viewport.disable_3d` under the cover made a time-sliced build 6.7x faster

`측정 2026-09-29 · Godot 4.7.2 · Forward+ · MacBook Air M1 (windowed)`

**증상:** a city built at runtime was split into slices (yield a frame after ~32 ms of work) so a
loading screen could animate over it. On an M1 Max the build stayed near its unsliced 1.9 s, but on
an M1 Air it took **26.2 s** and the whole boot 95 s. The loading screen is an opaque `Control` on a
`CanvasLayer`, yet every yielded frame still rendered the half-built city behind it (273 lights,
166 meshes): about 55 frames of full 3D cost.

**해결:** set `get_viewport().disable_3d = true` while the opaque cover is up and back to `false`
a few frames before revealing, so the first real frames (pipeline compiles: 90 ms and 64 ms measured)
still happen under the cover. Same Air, same build: **3.9 s**, boot 5.4 s. Remember whether you
turned it off yourself before turning it back on.

## GDT-188 — Web export: `engine.startGame()` can resolve before the last `onProgress` call; a custom shell that reacts to "download complete" must ignore it after resolve

`측정 2026-09-29 · Godot 4.7.2 Web export (single-threaded) · Chrome for Testing 1243 headless, local server`

**증상:** a custom HTML shell ran its bar to 100 % in `startGame().then(...)` and, in `onProgress`,
switched to a "starting the engine" state (cap at 99 %) when `current >= total`. From an unthrottled
local server the bar showed 100 % at 1.0 s, then 99 % from 3 s on, and the overlay never left
(still up at 30 s) although the game was running behind it: an `onProgress` with `current >= total`
arrived after the promise had resolved and put the cap back. Throttled runs were not followed to the
end, so whether slow downloads hit it too is not measured.

**해결:** once `startGame()` has resolved, ignore `onProgress`, and never let a cap lower the target
(`target += max(0, cap - target) * k`). After the fix the same run left the loading screen at 2–3 s.
Related: GDT-127 (driving the check with raw CDP).

## GDT-189 — On the Web export, `DisplayServer.get_name()` is `"web"` while `OS.get_name()` is `"Web"`: a guard written against `"Web"` never matches, and `keyboard_get_keycode_from_physical` logs an error on every call

`측정 2026-09-29 · Godot 4.7.2-stable · Web export (release, no threads) · headless Chromium (Playwright 1243)`

**증상:** a key-glyph helper skipped `DisplayServer.keyboard_get_keycode_from_physical()` on servers that cannot map keyboard layouts, with `if DisplayServer.get_name() not in ["headless", "Web"]`. The web console still repeated `at: keyboard_get_keycode_from_physical (servers/display/display_server.cpp:1224)` every time a prompt was drawn.

A probe scene exported to the web printed `DisplayServer.get_name()` = `web`, `OS.get_name()` = `Web`, `OS.has_feature("web")` = `true`. With the old guard, three label lookups for a physical-key binding logged the error 3 times. With `not OS.has_feature("web")` it logged 0, and the label was the same (`E`).

The call only fires for events with `physical_keycode` set. Engine defaults such as `ui_accept` (Enter) use `keycode`, so a title screen that only shows those prompts stays clean and hides the problem until a game action's prompt appears.

**해결:** test platforms with feature tags (`OS.has_feature("web")`), not display-server names. When a name check is unavoidable, compare case-insensitively. Evaluate the check once, for example in a `static var`.

## GDT-190 — Web export: the first drawn frame compiles every shader and freezes the whole page; a "ready" signal sent from `_ready()` fires seconds before the page responds

`측정 2026-09-29 · Godot 4.7.2 Compatibility Web export (single-threaded) · Chrome 154, M1 Max and M1 Air`

**증상:** a page shell enabled its start button when Godot called `ui.ready()` at the end of `_ready()`. Timestamps
from the parent page: on an M1 Max, headless Chrome (`channel: 'chrome'`, `--enable-gpu`), `_ready` finished at
5.6 s but the next `RenderingServer.frame_post_draw` came at 20.9 s; headed Chrome, same build: 2.05 s → 3.55 s.
On an M1 Air against the live site: headless 27 s to a usable page, headed 9.7 s. During that first frame the
iframe and the parent page share one main thread, so every timer, `waitForFunction` poll and input handler in the
parent is frozen: the button looked enabled but the page did not react. Frames after the first took ~10 ms.

**해결:** send "ready" after `await RenderingServer.frame_post_draw`, not at the end of `_ready()`. To show a
"preparing" state before the freeze, report it, then set `get_viewport().disable_3d = true`, `await
get_tree().process_frame` twice so the browser paints, set it back to `false` and await `frame_post_draw`.
A/B on the M1 Air, headed, three runs each: old 6.4–6.9 s, new 6.6–6.9 s to a responsive page — the two
skipped 3D frames cost nothing measurable. Time boot in headed Chrome; headless numbers are 3–6x too slow.

## GDT-191 — Movie Maker on macOS: the project's `window_width_override` beats `--resolution`, and a frame the window does not draw is missing from the movie while `_process` keeps running

`측정 2026-09-29 · Godot 4.7.2-stable · Compatibility · MacBook Air M1 (2× display), --write-movie .avi --fixed-fps 30`

**증상:** `godot --path godot --resolution 1920x1080 --write-movie raw.avi …` logged
`recording movie in 1440×810` — the project's `display/window/size/window_width_override=1440` /
`window_height_override=810`, not the flag. A later 1080p take logged `5715 frames at 30 FPS` while
`Engine.get_process_frames()` had reached 10,932; the footage froze at the same frame from about the fifth minute
of the run, with game time (tweens, timers, network) still advancing underneath. Another session's windowed Godot
test was open on the same display during that run. Marks keyed to `Engine.get_process_frames()` then point past the
end of what was recorded.

**해결:** put the size in an `override.cfg` beside `project.godot` for the run (`[display]
window/size/window_width_override=1920` and `window_height_override=1080`; on a 2× screen that is a
960 × 540 pt window, which fits). Run with `--always-on-top` (and `caffeinate -d`) so the window keeps drawing, key
every mark to `Engine.get_frames_drawn()` — one per movie frame — and fail the run when
`get_process_frames() - get_frames_drawn()` grows. With those three the next take wrote 9,787 frames for
9,770 marked. MJPEG at `editor/movie_writer/mjpeg_quality=0.92` was about 180 KB a frame (1.9 GB for 5.5 min).
A run that is killed leaves an AVI with no index: `ffmpeg -i raw.avi -map 0:v -c copy footage.mkv` once makes it
seekable. An fps-measuring quality ladder sees exactly the fixed fps (30 here), so force its level from the
command line.

## GDT-192 — `Control.reset_size()` ignores `grow_horizontal`: a control pinned by its centre ends up starting at the centre

`측정 2026-09-29 · Godot 4.7.2-stable · Web export, headless Chrome screenshot at 390 × 844`

**증상:** a `PanelContainer` anchored at `(0.5, 1)` with `offset_left = offset_right = 0` and
`GROW_DIRECTION_BOTH` sat centred until its label got a larger minimum width and the layout code called
`reset_size()`. After that the panel's left edge was at the screen centre and its right half ran off the screen.
`reset_size()` sets the size by moving `offset_right`/`offset_bottom` whatever the grow direction says.

**해결:** do not call `reset_size()` on an anchored control. Set its offsets back to the anchor point
(`offset_left = offset_right = x`) and let the minimum size re-apply along `grow_*` on the next layout — that path
honours the grow direction.

## GDT-193 — Web export under CDP: a page that is not the front target gets no animation frames, so a Godot build in it stops dead

`측정 2026-09-29 · Godot 4.7.2 Web export (single-threaded) · Chrome 154, one browser with several targets from Target.createTarget, M1 Air`

**증상:** a check opened a second page in the same browser (second player of a room), and the first page's
game state stopped changing: it never saw the deal the server had already sent, and a wait on it timed out. The
engine runs on `requestAnimationFrame`, and only the front target was getting frames.

**해결:** `Page.bringToFront` on the page before reading or clicking it (and before a screenshot). With that one
call the same check passed all 19 assertions, including the one that had timed out.

## GDT-194 — `WebSocketPeer.close()` finishes later, in `poll()`: a `close()` then an immediate reconnect reports the clean close as an unexpected drop, and the reconnect happens twice

`측정 2026-09-29 · Godot 4.7.2-stable · hand-written SpacetimeDB client (GDScript), Web export on production and headless native`

**증상:** on sign-in, the client logged `disconnected (unexpected): 1000 bye` and then connected twice as the same
identity. On sign-out it did the same. The code called `close()` and then `open()` in the same frame.
`WebSocketPeer.close(1000)` only starts the handshake. `STATE_CLOSED` shows up frames later, in the `_process`
that polls the peer. By then `open()` had already reset the "closing on purpose" flag, so the close was reported as
a dropped line. The reconnect-with-back-off path then dialled a second time. The two dials also shared one
`HTTPRequest`, and the second `request()` returned `ERR_BUSY` (44). A test that does `close(); open(token)`
reproduces it natively: 5 of 11 assertions fail.

**해결:** do not reuse one flag across connections. In `close()`, report the deliberate disconnect at once. Then
move the peer to a "retiring" list that `_process` polls until `STATE_CLOSED`, and it emits nothing more. At the
start of `open()`, retire whatever came before and call `cancel_request()` on the token `HTTPRequest`. Also give
every dial a generation number, so a stale async callback (token fetch, back-off timer) does nothing.

## GDT-195 — Web export: reveal the scene a few meshes per frame to spread first-draw shader compiles; the page's longest freeze on a Pixel went from 9.8 s to 2.7 s

`측정 2026-09-29 · Godot 4.7.2 Compatibility Web export (single-threaded) · Pixel 7 Pro, Android 17, Chrome 154`

**증상:** GDT-190's fix (report ready after the first drawn frame) still left one long task: the frame that first
draws the room compiled every material's shaders. On the phone the page could not repaint for 9.8 s, and a
recording showed the loading bar parked at 82% for 8.7 s. CSS `transform` transitions started just before a
long task did not keep advancing on this phone.

**해결:** hide every visible `GeometryInstance3D` after building, then show them in batches, one batch per frame,
awaiting `RenderingServer.frame_post_draw` between batches and reporting `shown / total` to the page. Start at
2 pieces, double while a frame takes under 50 ms, halve over 150 ms (cap 64). Also build the scene one
section per `await get_tree().process_frame`, with `get_viewport().disable_3d = true` until the reveal (GDT-187)
and `set_process(false)` on scripts that assume the scene is complete.
Measured on the phone: longest freeze 2.7 s (engine start before `_ready`, cannot be split), then no frame over
1.2 s; loading-bar stall 1.1 s; 44–47 progress reports instead of 3; total download→ready 9.9 s → 8.8 s.
For the remaining engine-start freeze, a CSS `@keyframes` sweep on `transform` kept moving in the recording.

## GDT-196 — A custom Godot 4.7.2 web template for a procedural 3D game: 39.5 MB → 22.8 MB engine (3.7 MB brotli); `target` in the SCons profile is ignored, and `deprecated=no` breaks scripts at load

`측정 2026-09-29 · Godot 4.7.2-stable source · Emscripten 4.0.11 · SCons 4.11.1 · built on an M1 Air (8 cores) · Chrome headed`

**증상:** the stock `web_nothreads_release` engine is 39,514,754 bytes (6.9 MB brotli 11). A game that builds its 3D
world in GDScript (meshes, Label3D, CPU particles, shaders; no physics, navigation, audio streams or complex scripts)
downloads code it never runs.

**해결:** a profile file passed with `profile=`:

```python
platform = "web"; target = "template_release"; threads = "no"; lto = "full"
disable_physics_2d = "yes"; disable_physics_3d = "yes"; disable_navigation_2d = "yes"
disable_navigation_3d = "yes"; disable_xr = "yes"; disable_advanced_gui = "yes"
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"; module_freetype_enabled = "yes"
module_text_server_fb_enabled = "yes"; module_webp_enabled = "yes"
```

- **`target` in the profile was ignored:** the first build produced `template_debug`. Pass `platform=web
  target=template_release` on the command line as well.
- **`deprecated = "no"` broke the game at load:** `Parse Error: Static function "create()" not found in base
  "GDScriptNativeClass"` for `Image.create(...)` (use `Image.create_empty`), then every script depending on it failed
  and the page sat at "loading 99 %". Untyped calls to removed APIs would only fail at run time, so keep `deprecated`.
- **The fallback text server draws Hangul** (precomposed syllables) in Label3D with a TTF font; no HarfBuzz or ICU needed.
- Result: 22,766,673-byte wasm, 3,708,341 bytes with brotli 11 (5.5 MB template zip). Release build 14 min 50 s on the
  Air (a debug build of the same profile 8 min).
- Cold first visit on the live site, Chrome headed on the Air, 3 runs each, stock → custom: 10 Mbps throttle, manor
  ready 10.3–11.2 s → 7.6–8.0 s; Wi-Fi 5.2–5.5 s → 4.2–5.2 s.
- Point the preset at it with `custom_template/release="res://engine/web_nothreads_release.zip"` and put a `.gdignore`
  in `engine/`; the export reads the `res://` path.
- `emsdk` needs Python ≥ 3.10 (`EMSDK_PYTHON=`); the macOS system Python 3.9 fails with
  `emsdk requires python 3.10 or above`.

## GDT-197 — Android: the on-screen keyboard covers a focused `LineEdit` and Godot moves nothing; `DisplayServer.virtual_keyboard_get_height()` reports it, and the window excludes the system bars

`측정 2026-09-29 · Godot 4.7.2-stable · Pixel 7 Pro (Android 17) · landscape, canvas_items stretch, immersive_mode=true`

**증상:** A centred form (three `LineEdit` date fields and a confirm button) opened on a phone in landscape. Focusing a field raised the number keyboard, which covered the lower part of the screen, the fields with it. Nothing scrolled: unlike Android views, a Godot `Control` tree gets no `adjustResize`/`adjustPan` behaviour.

Values while the keyboard was up, printed from `_process`: `virtual_keyboard_get_height()` = 846 px; `window_get_size()` = 2976×1258 (the physical panel is 3120×1440: the status bar and the navigation area are outside the window even with `immersive_mode`); `get_display_safe_area()` = the whole window, so `Touch`-style safe-area insets were 0. With the root transform scale 1.57 the keyboard took 538 of 800 canvas units, leaving 33% of the height (about 260 units). On desktop and web the call returns 0.

**해결:** Put the form in a `ScrollContainer` and, each frame, set `offset_bottom = -virtual_keyboard_get_height() / root_scale` (root scale from `get_tree().root.get_final_transform().get_scale().y`). When the height becomes non-zero, `ensure_control_visible()` on the confirm button and then on the focused field's row (deferred), so both land in the strip above the keyboard; tighten spacing and drop reserved error lines while it is up, since 260 units fit only a caption row, the fields and one button. Poll rather than wait for a signal: there is none. Keep a test hook (`keyboard_override`) so a windowed capture can simulate the keyboard on a desktop.

---

## GDT-198 — 웹 셸에 넣은 분석 태그는 재빌드 한 번에 소리 없이 사라진다

`측정 2026-09-29 · Godot 4.7.2 웹 익스포트 · Umami`

**증상:** 게임 사이트 방문 수가 0으로 떨어졌는데 빌드·배포·게임 동작은 모두 정상이다.
포털 쪽 사후 점검(`verify-live`)만 `declares its own website id — FAIL`로 8회 연속 빨갛게 떴다.

추적 스크립트(`data-website-id`)는 익스포트가 만드는 `index.html`에만 들어 있고, 그 원본은
`custom_html_shell`로 지정한 셸 파일 하나다. 클라이언트를 Godot로 다시 만들면서 셸을 새로 쓰면
태그가 빠져도 익스포트는 성공하고, 게임은 멀쩡히 돌며, 헤드리스 브라우저로 보면 Umami가 봇 요청을
조용히 버려 원래도 아무것도 안 보인다. 태그가 인라인 스크립트의 `setAttribute`로 붙는 형태면
`grep umami`나 `grep data-website-id`도 아무것도 찾지 못한다 — 사이트 ID 문자열로 찾아야 한다.

배포 후 점검은 경보일 뿐이다. 이미 나간 뒤에 울리고, 다른 저장소의 파이프라인에서 울리면
그 저장소의 고장으로 읽혀 3시간 동안 아무도 원인 저장소를 건드리지 않았다.

**해결:** 이미지 빌드의 익스포트 단계에서 `build/web/index.html`에 사이트 ID와 추적 스크립트
주소가 있는지 `grep -q`로 확인하고 없으면 빌드를 실패시킨다. 빌드가 실패하면 Dokploy는 이전
컨테이너를 계속 띄우므로 태그 빠진 버전이 운영에 나가지 않는다. 배포 후 점검의 실패 문구에는
고칠 저장소와 파일을 적는다.

## GDT-200 — A Godot 4.7.2 web export has no partial start: the whole `index.wasm` + `index.pck` lands before the shell can report `ready`, so "MB to playable" equals total transfer

`측정 2026-09-29 · Godot 4.7.2 · Chrome 141 · nginx 1.29 (gzip_static)`

**증상:** measuring what a first visit downloads before a Godot web game can be played, the figure at the
shell's `ready` event, at the title screen and after a course was running were all the same number. There is
no point at which some of the payload is still arriving while the player can already do something.

The game (KIDS, `https://kids.mnori.com/`, 390x844 portrait, CDP cache disabled, bytes counted with
`Network.loadingFinished.encodedDataLength` per OPS-228):

```
atReady 12.43 MB · atTitle 12.43 · atCoursePlaying 12.43 · total 12.43 · 35 requests · 26.2 s
index.wasm 10.06 · index.pck 1.79 · hero art .32 · everything else < .08
```

Two consequences for a manifest or a load budget:

- Do not build a "playable at X MB, rest streams in" story into a number you publish. Measure at the first
  moment the player can act; for a stock web export it is the same as the total.
- The build script's own gzip total understates the wire figure. `scripts/build.py` printed `12.0 MB gzip
  total` for the same build: it sums only the `.gz` files it wrote, missing the images, fonts and the WebM
  that nginx serves uncompressed. The gap was 0.43 MB (3.5%), enough to cross an integer boundary.

Content that is not in the boot payload is the only way to move this: GDT-167 streamed art and music out of
`index.pck` and cut 34.4 MB to 13.3 MB.

**해결:** count bytes to the first playable moment, not to `load`; expect it to equal the total for a stock
web export, and read it off the browser rather than off the build's gzip sum.

---

## GDT-201 — Android: `window_set_mode(WINDOW_MODE_WINDOWED)` at startup turns immersive mode off; the status bar, the gesture bar and a black band beside the camera cutout come back

`측정 2026-09-29 · Godot 4.7.2-stable · Pixel 7 Pro (Android 17) · landscape, export preset screen/immersive_mode=true`

**증상:** the exported APK runs with the status bar on top, the gesture bar at the bottom and black bands left and right, although the preset has `screen/immersive_mode=true`. `adb exec-out screencap` shows the game in about 2976×1258 of the 3120×1440 panel (the same numbers GDT-197 measured as the window size).

The cause was the project's own settings code, shared with desktop: it applied the saved "fullscreen" option on every platform, and the default is off, so it called `DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)` on the phone. On Android that call leaves immersive mode. Nothing is logged.

**해결:** on mobile always ask for fullscreen, whatever the desktop option says:

```gdscript
var fullscreen := bool(get_value("graphics/fullscreen")) or OS.has_feature("mobile")
DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
```

With that one line the same APK fills 3120×1440, including the strip beside the punch-hole camera, and `get_display_safe_area()` starts to report the cutout (78 canvas units on the camera side at a root scale of 1.8; 0 before). Check with a screenshot, not with the preset.

## GDT-202 — `--export-release Android` without a release keystore still writes an APK, which then fails to install with `INSTALL_PARSE_FAILED_NO_CERTIFICATES`

`측정 2026-09-29 · Godot 4.7.2-stable headless, macOS · adb install on Android 17`

**증상:** `godot --headless --path client --export-release Android out.apk` prints one warning in the editor language ("release keystore not found") and `ERROR: Project export for preset "Android" failed.`, but leaves an 87 MB `out.apk` behind. A script that only checks `test -s out.apk` goes on, and `adb install -r` fails with:

```
adb: failed to install out.apk: Failure [INSTALL_PARSE_FAILED_NO_CERTIFICATES: Failed to collect certificates from /data/app/vmdl….tmp/base.apk: Attempt to get length of null array]
```

The file is the aligned but unsigned APK.

**해결:** for device testing export with `--export-debug Android`, which signs with the debug keystore from the editor settings (`export/android/debug_keystore`); it installs over an earlier debug build with `adb install -r` and keeps the app data. Export plus install of an 87 MB APK took 15 s, so a phone is a practical edit-and-look loop. For a release build, check the exit code of the export, not the file.


## GDT-203 — A Godot 3D web game that fills the screen at 844×390 can be unplayable at 390×844: the camera frames to width, so portrait zooms in and leaves the player off-screen

`측정 2026-09-29 · Godot 4.7.2 Web (GL Compatibility) · window/stretch/mode="canvas_items", aspect="expand" · Chrome (headed) on an M1 Air, Playwright touch emulation`

**증상:** a top-down 3D game loaded, drew its HUD and its on-screen stick, and took touch input at a 390×844 phone viewport — every sign a "plays in portrait" check looks for. The room itself was a blurred close-up of one wall: the player character and the NPC were outside the frame, and holding the stick for 7 s changed nothing visible. The same build at 844×390 showed the whole room, the player and every control, and the player walked.

With `aspect="expand"` the 3D camera keeps its horizontal field of view and gains or loses vertical, but the visible world scales with the **narrow** dimension, so a portrait viewport magnifies the scene by the ratio of the two widths (here 844/390 ≈ 2.2×) instead of showing more of it. Nothing errors, nothing logs, and a screenshot of the title screen looks perfect, because 2D UI stretches correctly.

**해결:** decide "portrait / landscape / desktop" from a real playthrough — start a game, move, and look at the frame — not from a successful load or a title-screen screenshot. The 2D UI passing at 390×844 says nothing about the 3D camera. If portrait has to work, drive `Camera3D.keep_aspect = KEEP_HEIGHT` (or raise `fov`/lift the camera) when the viewport is taller than it is wide; otherwise publish the game as landscape-only and say so.


## GDT-204 — A Godot `ScrollContainer` does not scroll when the touch drag starts on a `Button`, so an automated portrait check can wrongly conclude the screen is stuck

`측정 2026-09-30 · Godot 4.7.2 Web (GL Compatibility) · input_devices/pointing/emulate_mouse_from_touch=true · Chrome (headed) on an M1 Air, Playwright + CDP Input.dispatchTouchEvent at 390×844`

**증상:** a setup screen taller than a 390×844 viewport hid its primary button ("대전 시작") below the fold. Touch drags from the middle of the screen moved nothing — with `Input.dispatchTouchEvent` in 12, 24 or 40 steps, and with `Input.synthesizeScrollGesture({gestureSourceType:"touch"})` as well. The only visible effect was the card under the finger lighting up, exactly as a hover would. A mouse wheel over the same spot scrolled normally, which makes the screen look like desktop-only.

The drags had all started on a `Button` (a map card filling the width). A `Button` grabs the touch and never passes it to the `ScrollContainer` above it, so nothing pans. The same gesture started on a gap or a `Label` — 20 px of margin at the right edge, or the "CPU 상대" heading — scrolled the container on the first try and revealed the button.

**해결:** when deciding `mobile: yes|landscape|desktop` or QAing a phone layout, start the drag on empty space or a label, never on a control, before concluding a screen cannot be scrolled. On a real phone the same rule holds for the player, so a screen whose scrollable area is wall-to-wall buttons has no place left to drag: leave a gutter or give the container `follow_focus` plus a visible scrollbar.


## GDT-205 — Web export, custom shell: an image the boot screen loads with `new Image()` queues behind the engine's wasm/pck download; set `fetchPriority = 'high'`

`측정 2026-09-29 · Godot 4.7.2 Web export (single-threaded) · headed Chrome on an M1 Air, CDP throttle 40 Mbit/s, 58.6 MB wasm+pck`

**증상:** a custom HTML shell created its boot-screen picture (258 KB WebP) with `new Image()` before calling `engine.startGame()`. A 10 KB mask requested the same way showed at once, but the picture was still missing at 41 % of the download (6.5 s) and only appeared somewhere before 78 %. An off-DOM image is a low-priority request; the engine's `fetch()` calls for the wasm and pck are high priority and take the bandwidth first.

**해결:** set `image.fetchPriority = 'high'` before `image.src` (or use `<link rel="preload" as="image" fetchpriority="high">`). Same run after the change: `performance.getEntriesByType('resource')` reports the picture's `responseEnd` at 0.35–0.42 s from a local server and 1.8 s from the live site. Check it with a throttled run; an unthrottled local server hides the problem.

## GDT-206 — Web export: a "ready" call sent from the game after `frame_post_draw` can reach the page before `engine.startGame()` resolves

`측정 2026-09-29 · Godot 4.7.2 Web export (single-threaded) · headed Chrome on an M1 Air`

**증상:** the game called `JavaScriptBridge.eval("window.gameReady()")` after `await RenderingServer.frame_post_draw` (GDT-190), and the shell's `startGame().then(...)` set a "STARTING" label and a 94 % cap. The boot screen showed `100 %` with the label `STARTING`: the ready call had already run, and the `.then` callback ran after it and overwrote the state. Order between the two is not guaranteed.

**해결:** make both handlers idempotent and order-free: keep a `finished` flag set by the ready call, return early from `.then` when it is set, and only ever raise the progress target (`target = Math.max(target, x)`). Related: GDT-188 (late `onProgress`), GDT-190 (when to send ready).

## GDT-207 — A hand-sized `VBoxContainer` with autowrapped labels stays as tall as their first-pass minimum, so its bottom row leaves the panel on narrow screens

`측정 2026-09-30 · Godot 4.7.2-stable · desktop window 780×1688 and Web export at 390×844`

**증상:** a modal set `body.size = panel_size - margins` once (and on `resized`), then added `AUTOWRAP_WORD_SMART` labels, an expanding spacer and a button row. On a wide screen it looked right. On a phone-width screen the buttons were gone: no 이전/다음, and with no Esc key the modal could not be closed. Printed: panel 528×600, `body.size.y` **6,070**, button row at y = 6,022, while `body.get_combined_minimum_size().y` was already back to 395. A control's size cannot be below its minimum, so the assignment was raised to the labels' first-pass minimum (GDT-154: one word per line before the width is known). When the minimum later shrinks, a container that is not inside another container is not shrunk back. Nothing logs.

**해결:** re-apply the size when the minimum changes: `body.minimum_size_changed.connect(_layout_panel, CONNECT_DEFERRED)`. Same run afterwards: body 552, row at y = 504, inside the panel. Narrower widths wrap more, so check modals at phone width, not only at the design size.

## GDT-208 — Web export: `DisplayServer.window_set_title()` in the main scene's `_ready()` is overwritten by the project name, and a hand-written `<title>` in the custom shell is lost the same way

`측정 2026-09-30 · Godot 4.7.2 Web export (single-threaded) · headless Chrome on an M1 Air`

**증상:** the custom HTML shell had `<title>땅따먹기 — LANDGRAB</title>` instead of `$GODOT_PROJECT_NAME`, and the main scene's `_ready()` called `DisplayServer.window_set_title("땅따먹기 — LANDGRAB")`. `curl` of the page showed the Korean title, but after the engine started `page.title()` was `LANDGRAB` (`application/config/name`). The engine sets `document.title` to the project name during start-up, after the main scene's `_ready()` has run. Nothing logs, and a check of the served HTML alone passes.

**해결:** set the title again once the game is running. Measured together (not separately): `DisplayServer.window_set_title.call_deferred(...)` in `_ready()`, and in the shell `const PAGE_TITLE = document.title` before the engine loads, restored in the game's "first frame drawn" callback (GDT-190). `page.title()` after boot was then `땅따먹기 — LANDGRAB`. Renaming `application/config/name` also works but changes the desktop `user://` folder. Check the tab title in a real browser after boot, not with `curl`.

## GDT-209 — Touch screens: `Button` follows only the first finger, so a player resting a thumb on a virtual joystick cannot press any button with the other thumb

`측정 2026-09-30 · Godot 4.7.2-stable · Android export on Pixel 7 Pro (also the Web export on phones)`

**증상:** on the game-over card the owner reported that CUT responded but "이어하기" and "타이틀로" did not. The virtual joystick and CUT read `InputEventScreenTouch` in `_input` per finger, so they work with any finger. `Button` is driven by the mouse that the engine emulates from touch (`input_devices/pointing/emulate_mouse_from_touch`), and that emulation uses the first finger (index 0) only. When the left thumb is still down on the joystick, the right thumb is index 1: no mouse event, no press, no log.

**해결:** press buttons for later fingers yourself, in the app root:

```gdscript
func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch or event.index == 0:
		return
	if event.pressed:
		var hit: Button = _button_at(screen_root, event.position)   # topmost visible, enabled Button under the point
		if hit != null: _extra_touch[event.index] = hit
	elif _extra_touch.has(event.index):
		var held: Button = _extra_touch[event.index]; _extra_touch.erase(event.index)
		if is_instance_valid(held) and _button_at(held, event.position) == held: held.pressed.emit()
```

Measured on the phone with a finger held on the joystick: a second finger on the pause button opened the pause card and on "계속하기" closed it. A single-finger `adb shell input tap` test never shows this bug; test with two pointers (GDT-210).

## GDT-210 — Injecting real multi-touch into an Android app without root: `adb shell uinput` with a virtual touch screen (`sendevent` is denied, `monkey` has no timing)

`측정 2026-09-30 · Pixel 7 Pro, Android 17, adb shell (uid 2000) · Godot 4.7.2 Android export`

**증상:** a game needs "hold CUT with one finger, steer with another". `adb shell input` sends one pointer. `sendevent /dev/input/event4 …` prints `Permission denied` although the shell is in the `input` group. A `monkey -f` script with `PinchZoom(...)` does send two pointers, but all 600 steps ran in 78 ms, so nothing was held.

**해결:** `adb shell uinput <file>` reads one JSON object per line: a `register` command creating a virtual direct-touch device, then `inject` (flat list of type, code, value triples) and `delay` (ms) commands. The device disappears when the command exits.

```
{"id":1,"command":"register","name":"virtual touch","vid":6353,"pid":19251,"bus":"usb","configuration":[{"type":100,"data":[1,3]},{"type":101,"data":[330]},{"type":103,"data":[47,48,53,54,57,58]},{"type":110,"data":[1]}],"abs_info":[{"code":53,"info":{"value":0,"minimum":0,"maximum":1439,"fuzz":0,"flat":0,"resolution":0}}, … 54 (max 3119), 47 (9), 48 (255), 57 (65535), 58 (255)]}
{"id":1,"command":"delay","duration":1500}
{"id":1,"command":"inject","events":[3,47,0, 3,57,9100, 3,53,324, 3,54,2797, 3,58,60, 3,48,8, 1,330,1, 0,0,0]}
```

`type` 100/101/103/110 are UI_SET_EVBIT/KEYBIT/ABSBIT/PROPBIT; events are multi-touch protocol B (47 slot, 57 tracking id, -1 to lift, 53/54 position, 330 BTN_TOUCH). Give the first `delay` about 1.5 s so the device is registered before the first event. Coordinates are in the panel's natural (portrait) axes: with the screen at ROTATION_90, a landscape point (sx, sy) is (1439 − sy, sx). Measured: a 4 s hold drew a cut line in the game, and a second pointer pressed UI buttons while the first stayed down.

---

## GDT-211 — GDScript: a typed `Array[Font]` cannot take a ternary of two array literals, and a property of a `const` preloaded resource cannot be assigned through the const name

`측정 2026-09-30 · Godot 4.7.2 (headless script tests and Web export)`

**증상:** two lines written while adding per-language font fallbacks, in a script that holds its fonts as `const FONT_BODY: FontFile = preload(...)`.

1. `FONT_BODY.fallbacks = chain` does not parse: `Parse Error: Cannot assign a new value to a constant.` The const is the resource reference, but the parser also refuses a write to one of its properties. Every script that preloads this one then fails with `Compile Error: Failed to compile depended scripts`, so a headless test prints hundreds of `Nil` errors that hide the single real line.
2. `var medium: Array[Font] = [A, B] if zh else [B, A]` parses, and fails only when the line runs: `Trying to assign an array of type "Array" to a variable of type "Array[Font]".` A lone literal is typed from the declaration; the result of a ternary is a plain `Array`. The function stops there, so in an exported game the fallbacks are silently never set and every character outside the base font is a box, with nothing in the browser console a player would notice.

**해결:** for 1, go through a local: `var body: FontFile = FONT_BODY` then `body.fallbacks = chain` (a loop variable over `[FONT_BODY, FONT_BOLD]` works too, which is why `f.allow_system_fallback = false` in a `for` was fine). For 2, build the typed array in one order and change it in place (`medium.reverse()`), or start from `var chain: Array[Font] = []` and `append_array([...])`; `Array.slice()` also returns an untyped array, so assign it to `FontVariation.fallbacks` through `append_array` as well. A test that walks each language's chain with `FontFile.has_char()` over the real strings catches both before the export.

## GDT-212 — `TextMesh` with a Noto Serif CJK cut: variable-font overlaps fail "Convex decomposing failed", and the error is on stderr with exit code 0

`측정 2026-09-30 · Godot 4.7.2-stable · headless and Web export · Noto Serif SC/JP [wght] (Google Fonts) subset with fontTools 4.60.2`

**증상:** In-world text built with `TextMesh` in Chinese and Japanese printed, in the browser console of the Web export,

```
ERROR: Convex decomposing failed. Make sure the font doesn't contain self-intersecting lines, as these are not supported in TextMesh.
   at: _generate_glyph_mesh_data (scene/resources/3d/primitive_meshes.cpp:3191)
```

for 2 of 19 Chinese and 5 of 18 Japanese characters. The font was a static instance (`wght=500`) cut from the
variable Noto Serif with `fontTools.varLib.instancer`. Variable fonts keep overlapping contours, and the instancer
keeps them by default; `TextMesh` cannot triangulate them (same error as GDT-151, different cause).

A headless per-character check (GDT-151) had passed before that: Godot writes this error to **stderr** and the script
still exits 0, and the wrapper read only stdout (`execFileSync` returns stdout). The glyphs also return vertices, so a
vertex-count check does not catch it.

**해결:** Merge the overlaps when cutting the static instance:
`instancer.instantiateVariableFont(font, {"wght": 500}, overlap=instancer.OverlapMode.REMOVE)` (needs
`pip install skia-pathops`). That fixed every character except `ち` (U+3061) in Noto Serif JP, which still fails;
the line was reworded to avoid it. In the check, read stdout and stderr together (`spawnSync`, join both) and fail on
the text `Convex decomposing failed`, not on the exit code. In a browser test, fail on the same text in the console.
MaruBuri (GDT-151) built every Korean and Latin character without this step.

## GDT-213 — Five-language UI: Chinese and Japanese need opposite fallback orders, and only a per-character `has_char` test catches missing glyphs

`측정 2026-09-30 · Godot 4.7.2-stable · Pretendard base with Noto Sans SC / JP subsets as fallbacks`

**증상:** Chinese and Japanese share code points with different shapes (直, 骨, 角). With one fallback order, one of the two languages is drawn with the other's glyphs; nothing logs. Separately, a string-table test (all keys present, no Hangul in other languages) passes while the screen shows boxes for characters the subset fonts lack.

**해결:** build the body font per language: a `FontVariation` on the base with `fallbacks = [JP, SC]` for Japanese and `[SC, JP]` otherwise, cached under a key that includes the language; drop the cache and rebuild the `Theme` when the player switches language. In the test, for each language walk every character of every string and assert `font.has_char(code)` on the font the game really uses (it follows fallbacks). Subset the CJK fonts from the same table in the same script, so a new string cannot ship without its glyphs (fontTools order: OPS-245; typed arrays: GDT-211). Fixed widths sized for Korean clip "Back", "Close", "Cerrar": size buttons from `font.get_string_size()` and shrink one-line drawn text to fit instead of letting `draw_string` cut it; check Spanish at phone width first.

## GDT-214 — `godot --headless --export-release` exits 0 and writes the pack when a script does not parse: the build ships and boots to nothing

`측정 2026-09-30 · Godot 4.7.2-stable · Web export, macOS host`

**증상:** A GDScript edit assigned to a property through a `const` (`const FONT = preload(...)` then
`FONT.fallbacks = [...]`). The export printed

```
SCRIPT ERROR: Parse Error: Cannot assign a new value to a constant.
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
ERROR: Failed to load script "res://scripts/main.gd" with error "Parse error".
```

in the middle of its progress output, finished with `[ DONE ] savepack`, wrote `index.pck` and exited 0. A build
script using `subprocess.run(..., check=True)` carried on and produced a deployable bundle whose main script cannot
load. Nothing after the export step complained.

**해결:** capture the export's stdout and stderr and stop the build when either contains `SCRIPT ERROR`
(`capture_output=True, text=True`, then re-print both so the log is not lost). A faster check before exporting is a
headless script that `load()`s every `.gd` and counts failures. For the assignment itself, go through a local
variable (`var font: FontFile = FONT; font.fallbacks = [...]`): the constant forbids rebinding through its own name,
not changing the resource it points to.

## GDT-215 — A Callable kept in a `static var` until shutdown crashes Godot 4.7 at exit: `recursive_mutex lock failed: Invalid argument`, or signal 11 in `recursive_mutex::lock()`

`측정 2026-09-30 · Godot 4.7.2-stable · macOS arm64, --headless --script test runners`

**증상:** A script with `static var _listeners: Array[Callable]` had a callback registry
(`static func on_change(cb): _listeners.append(cb)`). Two other scripts registered once from static
code: a lambda (`L.on_change(func(): _cache.clear())`) and a static method (`L.on_change(_apply_faces)`).
Every test that reached the registration printed its normal result (`SAVE OK …`, `TABLES_OK …`) and
then died while quitting, one of:

```
libc++abi: terminating due to uncaught exception of type std::__1::system_error: recursive_mutex lock failed: Invalid argument
handle_crash: Program crashed with signal 11
[2] libc++.1.dylib - std::__1::recursive_mutex::lock()
```

The process exit code is then non-zero although the test passed, so a runner that checks exit
codes reports a failure with a passing last line. Tests that loaded the script but never
registered a callback exited cleanly. Callbacks bound to a node and unregistered in `_exit_tree`
do not crash.

**해결:** do not keep Callables in static storage for the life of the process. For static
listeners use a counter instead: `static var epoch := 0`, incremented on every change; each static
consumer keeps the last value it saw and compares (`if _epoch != L.epoch: _epoch = L.epoch; _cache.clear()`).
Keep the callback list for nodes only, and remove the callback in `_exit_tree`.

## GDT-216 — Text that lives in `const` tables can be localised without touching the tables' shape: `"@{key}"` tokens, resolved on read, plus a plain `Translation` for whole-token text

`측정 2026-09-30 · Godot 4.7.2-stable · 5,193 keys × 5 languages, Web export`

**증상:** A game keeps its text in `const` dictionaries (items, dialogue, events: 4,000 strings).
A `const` cannot call a function, so `tr()` / a lookup cannot be written into the table, and the
tables are read in 40 places.

Measured approach that kept every table and every reader:
- A one-time script replaced each Hangul literal inside a `const` with a token string,
  `"@{items.hoe.name}"` (key = file + path inside the literal), and each literal in code with
  `L.t("key")`, or `L.f("key", [args])` when it was followed by `%`.
- The table accessor returns `deep(constants[name])`, a copy with tokens replaced, cached and
  dropped when the language changes. Code that reads a const directly calls `x(text)` before any
  string operation: `.replace("{name}", …)`, `.split("|")` and `%` silently do nothing useful on a
  token.
- A `Label`, `Button` or `Label3D` whose whole text is one token is translated by the engine
  itself if a plain `Translation` with `add_message("@{key}", text)` for every key is registered
  for the locale (`TranslationServer.add_translation`, `set_locale`). 5,193 `add_message` calls
  cost nothing noticeable, and such text follows a language switch with no code (signs in the 3D
  world).
- ~~`res://locale/strings.json` is not a resource, and an export preset with
  `export_filter="all_resources"` packs resources only: set `include_filter="locale/*.json"`
  (done before the first export here; the build without it was not run).~~
  **정정 (2026-10-05, GDT-281 실측):** 이 항목은 틀렸습니다. Godot 4에서 `JSON`은 리소스 타입이라
  `all_resources`가 include filter 없이도 `.json`을 팩에 넣습니다. `include_filter`를 둬도 해는 없지만 필요하지 않습니다.
- Same text under different keys is no longer equal: a table that grouped rows by a Korean label
  (`"농작물"` used as a dictionary key for four categories) split into four groups after the
  migration. Give such labels one shared key.

**해결:** tokens in consts, resolve at the accessor, `x()` before string work, one `Translation`
for whole-token text. Test it: every key in five languages, every key used by the code present,
no Hangul literal left in scripts, placeholders equal across languages. A regex for format specs
must not allow the space flag: `%[-+0 ]*…[sdf]` reads "10% faster" and "25% de" as `% f` / `% d`
and makes translators rewrite correct sentences; use `%(?:%|[-+0]*\d*(?:\.\d+)?[sdfcx])`.

## GDT-217 — A `--script` SceneTree test is compiled before the autoloads exist: naming a class that uses one fails with `Identifier not found`, and the run never exits

`측정 2026-09-30 · Godot 4.7.2-stable · macOS · --headless --script res://tests/x.gd`

**증상:** a test script (`extends SceneTree`) called a static function of a `class_name` script (`Look.display_for("zh")`). That script mentions an autoload (`Sfx.play(...)`). The run printed:

```
SCRIPT ERROR: Compile Error: Identifier not found: Sfx
          at: GDScript::reload (res://ui/look.gd:314)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
ERROR: Failed to load script "res://tests/strings_test.gd" with error "Compilation failed".
```

and then did not exit: `_initialize()` never reached its `quit()`, and the process sat at 0% CPU until it was killed (one run also crashed with signal 11 in the backtrace after the same errors). The same class compiles without error when the game runs, because by then every autoload is registered. Tests that only do `load("res://main.tscn")` inside `_initialize()` never see this.

**해결:** do not name such a class at the top level of a `--script` test. Load it inside `_initialize()` and type the results by hand: `var Look: GDScript = load("res://ui/look.gd")`, `var f: Font = Look.display_for("zh")` (`:=` cannot infer through an untyped script). Reach autoloads with `root.get_node("Name")`. Run every `--script` test under a time limit (`perl -e 'alarm 90; exec @ARGV' -- godot ...` on macOS), because a compile error is a hang and not an exit code.

## GDT-218 — A `Label` with autowrap inside a panel that is `reset_size()`d reports the height of one word per line: the panel comes out taller than the screen

`측정 2026-09-30 · Godot 4.7.2-stable · Web export and macOS · PanelContainer > VBoxContainer > Label`

**증상:** a banner (`PanelContainer` pinned by its centre) sets its subtitle, switches the subtitle to `AUTOWRAP_WORD_SMART` with `custom_minimum_size.x = 450` when the text is wider than the window, and calls `reset_size()`. With a short Korean subtitle the branch was never taken. With the English one ("You are the Animals · Bear·Fox · you move first", wider than 450) the panel was drawn about 450 wide and taller than an 844-unit screen, with both labels outside the visible area: the screenshot showed only a large empty glass rectangle. The label was asked for its minimum height while its own width was still the old one, so the height was that of a column of single words.

**해결:** for one-line captions that may be too long in another language, shrink the type instead of wrapping: loop `font.get_string_size(text, ALIGN_LEFT, -1, size).x > max_w` down to a floor and set `font_size`. The same banner then measured one line at 19 px in Spanish. Keep autowrap for labels whose container already has its width (a child of a `VBoxContainer` with a fixed minimum width wrapped correctly in the same build).

## GDT-219 — Web export: a `.woff2` fetched at run time with `HTTPRequest` becomes a usable font with `FontFile.data = bytes`, and labels already on screen pick it up when it is added to a fallback chain

`측정 2026-09-30 · Godot 4.7.2-stable · Web export (single-threaded) · Chrome on an M1 Air · Noto Sans SC/JP static 600, 570 KB each`

**증상:** a game in five languages needs glyphs for names players type. The strings of the game need 340 Chinese and 240 Japanese characters (36 to 116 KB per face as `.woff2`), but a set for typed names (GB 2312 level 1, 3,755 characters; JIS X 0208 level 1 plus kana) is 573 KB and 569 KB. Packing both costs every visitor 1.1 MB.

**해결:** keep the small subsets in the pack and serve the large ones as plain files beside `index.html`. At run time: `HTTPRequest.request(new URL('fonts/', location.href).href + file)`, and in `request_completed` with status 200: `var f := FontFile.new(); f.data = body`, then append `f` to the `fallbacks` of the `FontVariation` the UI uses. Measured: the fetch finished within the first seconds of the title screen (`Look._names.keys()` reported `["zh"]` and `["ja"]` in the browser check), no error was logged, and no label had to be rebuilt. Put a `.gdignore` in the folder that holds those files so the editor does not import them into the pack, and copy the folder next to the export yourself (the export does not).

## GDT-220 — Font coverage measured for a five-language UI: Jua has no accented Latin, ZCOOL KuaiLe has no kana, and Noto Sans SC/JP default to Thin unless instanced

`측정 2026-09-30 · fontTools 4.60.2 cmap check · google/fonts main · Godot 4.7.2 FontFile.has_char()`

**증상:** a Korean game set in Jua was translated to Spanish. Jua-Regular.ttf (2,519 code points) has none of `á é í ó ú ñ ü ¿ ¡`, so every accented letter would come from the fallback face inside a word. The Google Fonts "latin" subset of Jua has 97 glyphs (ASCII only).

| Face | code points | Spanish accents | kana | Han |
|---|---|---|---|---|
| Jua | 2,519 | no | 0 | 0 |
| Fredoka (variable wght, wdth) | 320 | yes | 0 | 0 |
| ZCOOL KuaiLe | 7,053 | no | 0 | 6,766 |
| M PLUS Rounded 1c ExtraBold | 8,201 | yes | 189 | 4,954 |
| Mochiy Pop One | 14,293 | yes | 184 | 12,745 |
| Noto Sans JP (variable) | 16,732 | yes | 189 | 12,747 |
| Noto Sans SC (variable) | 30,890 | yes | 189 | 20,976 |

**해결:** use a rounded Latin face with Latin-1 (Fredoka) as the display face for English and Spanish, and put each reader's own script first in the fallback chain (GDT-106). Instance the variable Noto faces to a static weight with `fontTools.varLib.instancer` after subsetting (the default instance is Thin, GDT-105; subset first, OPS-245). A test that loops over every character of every string and asserts `FontVariation.has_char()` on the chain found a real gap on its first run (日 of 日本語 was in the display subset but not in the body subset).

## GDT-221 — Web export: the engine sets `document.title` to the project name after the main scene's `_ready`, so a title set there is overwritten

`측정 2026-09-30 · Godot 4.7.2-stable · Web export (debug), Chrome 154`

**증상:** the game sets the tab title to its name in the player's language with
`DisplayServer.window_set_title()` in the main scene's `_ready`. A Playwright check read `document.title` once
the game was up and got the project's `config/name` with `(DEBUG)` appended, not the localized name. The page's
own script had also set `document.title` before the engine loaded, and that was overwritten too.

**해결:** set it again a few frames later. `DisplayServer.window_set_title(name)`, then
`for i in 3: await get_tree().process_frame`, then the same call once more. After that the title stays.
`application/config/name_localized` does not help here: it follows the OS locale, not a language the player chose.

## GDT-222 — `var x := typed_array if cond else []` compiles, then fails at run time: "Trying to assign an array of type Array to a variable of type Array[Node]"

`측정 2026-09-30 · Godot 4.7.2-stable · GDScript`

**증상:** `var choices := panel.get_children() if panel.visible else []` passed the parser and a headless parse
check. At run time, on the branch that takes `[]`, it raised
`SCRIPT ERROR: Trying to assign an array of type "Array" to a variable of type "Array[Node]"`. `:=` infers the
type from the first operand (`Array[Node]`), and the untyped literal on the other branch does not convert. The
function returned early, so the caller got an empty result and no exception of its own.

**해결:** declare the variable untyped-array: `var choices: Array = … if … else []`. A parse-only check cannot
catch this. It needs a run that takes the `else` branch.

---

## GDT-223 — Web export: Chinese and Japanese text in an autowrapping `Label` does not wrap at all; a U+200B at each break point makes it wrap

`측정 2026-09-30 · Godot 4.7.2-stable · Web export (nothreads, `include_text_server_data` off) in headed Chrome · Noto Sans SC / JP subsets`

**증상:** A Web export has no ICU break data (GDT-108), so the text server breaks lines only at
whitespace. Korean, English and Spanish keep wrapping. Chinese and Japanese have no spaces: a
paragraph in a `Label` with `AUTOWRAP_WORD_SMART` has no break opportunity. The editor and headless
runs carry ICU data and wrap the same text correctly, so native captures do not show the problem.

Turning on `internationalization/locale/include_text_server_data` fixes it but adds 4.8 MB to the
`.pck` and brings mid-word breaks to Korean (GDT-108).

**해결:** Insert U+200B ZERO WIDTH SPACE wherever a line may break, in the function that returns
translated strings, for `zh` and `ja` only. The no-ICU fallback treats it as a break opportunity.
Measured in the exported build at 390 px: map descriptions, coach tips and the rules dialog wrap
inside their panels in both languages. Rules that were enough: break only where one side is a CJK
character; never before closing punctuation, small kana or `ー`; never after an opening bracket;
never after an ASCII digit (keeps `1枚` together); never inside a `{0}` or `[b]` token.

Three things to watch:
- Noto Sans SC and Noto Sans JP have no glyph for U+200B, and `Font.has_char(0x200B)` is false for
  them. Add a cmap entry that maps U+200B to the space glyph when subsetting (fontTools:
  `table.cmap[0x200B] = table.cmap[0x20]` for each Unicode subtable); the shaper draws it with no advance.
- Strip the marks before putting a translated string into a `LineEdit`, and before comparing what
  the player typed with a translated default.
- `String.left(n)` counts the marks: a 46-character cut shows about half as many visible characters.

---

## GDT-224 — A `Container` is never narrower than its content: `size.x` of an overflowing `HBoxContainer` is the overflowing width, not the width you set

`측정 2026-09-30 · Godot 4.7.2-stable`

**증상:** A row of action buttons (`HBoxContainer`, positioned by hand, `size = Vector2(362, 56)`)
ran off a 390 px screen in Spanish. A fit routine that compared `get_combined_minimum_size().x`
with `action_bar.size.x` never shrank anything: the container had already grown to its minimum
size (410), so the row always "fit".

The same rule hides overflow inside a `ScrollContainer` with horizontal scrolling disabled: one
wide `HBoxContainer` row (three 150 px buttons) makes the whole `VBoxContainer` column wider than
the viewport, and every sibling (cards, full-width buttons, wrapped paragraphs) is cut at the right
edge, although each of them would fit on its own.

**해결:** Keep the available width in a variable set by the layout code and compare against that,
then set `size` again after shrinking the content. For rows of choices use `HFlowContainer`, and
give the scroll's column `custom_minimum_size.x` = the viewport width so wrapped labels have a
width to wrap to. Look at the longest language at phone width: the Korean strings had fit by luck.

---

## GDT-225 — Android prebuilt export: `application/config/name_localized` sets the launcher label per language; the keys are Godot locale names (`zh_TW`, not `zh-rTW`)

`측정 2026-09-30 · Godot 4.7.2-stable headless, `--export-debug Android`, `gradle_build/use_gradle_build=false` · aapt2 36.1.0`

**증상:** It was not clear whether the non-Gradle Android export honours `config/name_localized`,
or what the default label is.

With `config/name_localized={"en": …, "es": …, "ja": "バトルマーブル", "ko": "배틀마블", "zh": "战斗弹珠", "zh_HK": …, "zh_TW": …}`
and `package/name="Battle Marble"` in the preset, `aapt2 dump badging app.apk` prints:

```
application-label:'Battle Marble'
application-label-ja:'バトルマーブル'
application-label-ko:'배틀마블'
application-label-zh:'战斗弹珠'
application-label-zh-CN:'战斗弹珠'
application-label-zh-HK:'战斗弹珠'
application-label-zh-TW:'战斗弹珠'
application-label-fr:'Battle Marble'   (and every other language of the template)
```

`zh` also fills `zh-CN`. Every language without an entry gets the preset's `package/name`
(the project name when that is empty), so the default label is whatever `package/name` says.

**해결:** Put the languages in `config/name_localized`, add `zh_HK` and `zh_TW` explicitly if
Traditional-locale phones should not fall back to the default, and set `package/name` to the
label every other language should see. Check the result with `aapt2 dump badging`, no phone needed.

## GDT-226 — Web: Label3D names in Chinese, Japanese or accented Latin need font fallbacks; add them with `set_fallbacks()`, and load the big CJK font lazily through `JavaScriptBridge.eval`
`측정 2026-09-30 · Godot 4.7.2 (web, custom template with text_server_fb, no HarfBuzz)`

**증상:** A `Label3D` using a bundled Korean font (NanumGothic) drew nothing for `José`, `レイヴン`
or `瑞文`: the font had Hangul and plain ASCII only (checked with fontTools: `á é ñ ü`, all kana
and all Han missing). The web build has no system fonts to fall back on.

Setting fallbacks on a preloaded font is a parse error when written as an assignment:

```
const FONT = preload("res://assets/NanumGothic-Regular.ttf")
FONT.fallbacks = [other]      # Parse Error: Cannot assign a new value to a constant.
```

**해결:**

- `var list: Array[Font] = [FONT_KANA, FONT_HAN]` then `FONT.set_fallbacks(list)`. Every script that
  preloads the same file shares the resource, so one call in `_ready` covers all labels. The
  fallback text server (no HarfBuzz) uses the fallbacks for Latin, kana and Han.
- Two small subsets in the pack cover accented Latin, kana and fixed names (55 KB + 6 KB).
- Names players type need thousands of Han characters (GB 2312 + JIS level 1: 7,882 glyphs,
  2.4 MB TTF, 1.6 MB gzipped). Fetch that only when a name needs it, without `HTTPRequest`:
  `JavaScriptBridge.eval("fetch(url).then(r=>r.arrayBuffer()).then(b=>{window.f=new Uint8Array(b)})", true)`,
  then poll `JavaScriptBridge.eval("window.f||null", true)`. A `Uint8Array` comes back as a
  `PackedByteArray`; `var f := FontFile.new(); f.data = bytes`, add it with `set_fallbacks`, then
  set each label's text to `""` and back so it is drawn again. `FONT.has_char(code)` tells whether
  a name needs it (it checks that font only, not its fallbacks).

## GDT-227 — `Invalid break insert count!` floods the log when the first font of a chain has no U+0020 and the text contains U+200B; keep the space in every subset
`측정 2026-09-30 · Godot 4.7.2-stable · headless macOS (TextServerAdvanced) and Web export in Chrome · fontTools subsets of ZCOOL KuaiLe and Noto Sans SC`

**증상:** After a Chinese display face was subset to Han only (no ASCII, so no U+0020), every
Chinese string shaped with it printed
`ERROR: Invalid break insert count!` / `at: _shaped_text_update_breaks (modules/text_server_adv/text_server_adv.cpp:6717)`.
The Web build logged 200 of them in its first minute; a headless loop over the string table, 355.
The strings carried U+200B break hints (GDT-223). Lines still wrapped where they should, so
the only sign is the log.

Measured with a `TextParagraph` per case (Han-only face with no U+0020 = "no-space face"):

| First font in the chain | Fallbacks | Text | Errors |
| --- | --- | --- | --- |
| no-space face | Noto Sans SC | `怪​物​世​界` or `v3 · 第​1​章` | 1 each |
| no-space face | none | same | 1 each |
| no-space face | Noto Sans SC | `怪物世界`, `v3 · 第1章`, `A B` (no U+200B) | 0 |
| Noto Sans SC | no-space face | with U+200B | 0 |
| same face with U+0020 kept | Noto Sans SC | with U+200B | 0 |

Autowrap on or off made no difference, and neither did whether the face had its own U+200B
glyph. A space in the text that the fallback draws is fine; the error needs U+200B shaped
with a first font that has no U+0020.

**해결:** Keep U+0020 in every subset that can come first in a chain, even a face meant for one
script only (fontTools: add `0x20` to the unicodes passed to `Subsetter.populate`). It costs one
empty glyph. To check a build, count the message in a run that opens every screen in `zh` and `ja`.

## GDT-228 — Web: a tap is followed by the browser's own mouse events, and they arrive with `device` 0, not `DEVICE_ID_EMULATION`; a "last input device" switch that rebuilds the HUD on them can drop an awaited dialogue and softlock the game

`측정 2026-09-30 · Godot 4.7.2-stable · Web export · Chrome (Playwright, 390x844, isMobile, hasTouch, headed) · project has emulate_mouse_from_touch=false`

**증상:** On a touch phone, the first tap in the opening dialogue left a new player on a black
screen forever: the HUD appeared, the dialogue box vanished, the fade-in never ran. With a
keyboard (same page, same size) the opening finished. The UI switched layout on the last input
device (`ScreenTouch` → touch, `MouseButton` → keyboard, skipping
`DEVICE_ID_EMULATION`), and each switch rebuilt the HUD, which freed the dialogue node; the story
`await`ed its `finished` signal, which the new node never emitted.

The skip did not help: with `emulate_mouse_from_touch=false` Godot emulates nothing, but the
browser fires its compatibility `mousedown`/`mouseup` after the touch, and Godot's Web platform
turns them into ordinary `InputEventMouseButton` with `device == 0`. GDT-030's filter only
catches Godot's own emulation.

**해결:**
- Ignore mouse buttons for a short window after a touch (1.5 s here) when deciding the input
  device: `if e is InputEventMouseButton and Time.get_ticks_msec() - last_touch_ms < 1500: return`.
- Make any HUD rebuild re-open an open conversation (keep its lines and the current line index)
  so nothing awaiting it is orphaned.
- Related, same session: a menu that sets `get_tree().paused = true` also pauses the node whose
  `_process` flushes events to JavaScript, so the page heard `menu_open` only after the menu
  closed. Send UI events to the page immediately while the tree is paused.

## GDT-229 — Android prebuilt export: the template's `es-rES`, `zh-rHK` and `zh-rTW` folders get the default label unless `config/name_localized` names them; `"es"` alone leaves a Spain phone on the default name

`측정 2026-09-30 · Godot 4.7.2-stable headless, `--export-release`, `gradle_build/use_gradle_build=false` · aapt2 dump resources · Android 35 emulator launcher`

**증상:** With `config/name_localized={"en": "Button", "es": "Botón", "ja": "ボタン", "zh": "按钮"}` and
`config/name="버튼"`, a phone set to Spanish (Spain) showed the Korean default `버튼` in the app
drawer, while English, Japanese and Chinese (China) phones showed their names. The template APK
carries region folders for this string, and the exporter writes every folder it has:

```
$ aapt2 dump resources app.apk | grep -A200 godot_project_name_string
  (es)     "Botón"
  (es-rES) "버튼"     <- default, not the "es" entry
  (zh)     "按钮"
  (zh-rHK) "버튼"
  (zh-rTW) "버튼"
```

Android picks the exact `es-rES` folder before falling back to `es`, so the default wins. `es-MX`,
`es-US` and plain `es` are fine (no such folder). This extends GDT-225, which covers `zh_HK`/`zh_TW`
but not `es_ES`. A project whose default name equals its Spanish name hides the problem.

**해결:** Add `"es_ES"`, `"zh_HK"` and `"zh_TW"` keys next to `"es"` and `"zh"`, then check every
region row of `godot_project_name_string` with `aapt2 dump resources` (the badging output does not
list `es-ES`).

## GDT-230 — On an arm64 Linux host, macOS export also needs `import_s3tc_bptc=true`, which x86 hosts default on

`측정 2026-10-01 · Godot 4.7.2-stable linux.arm64, headless, Ubuntu 24.04 aarch64`

**증상:** a project whose macOS export worked on an x86_64 Linux CI runner failed on an arm64 Linux runner: `ERROR: Cannot export project with preset "macOS" due to configuration errors:` / `Cannot export for universal or x86_64 if S3TC BPTC texture format is disabled. Enable it in the Project Settings (Rendering > Textures > VRAM Compression > Import S3TC BPTC).` `project.godot` set only `import_etc2_astc=true` (GDT-055).

The default of `rendering/textures/vram_compression/import_s3tc_bptc` depends on the host CPU, so an unset value is true on x86 and false on arm64.

**해결:** set both lines in `[rendering]`: `textures/vram_compression/import_etc2_astc=true` and `textures/vram_compression/import_s3tc_bptc=true`. On an x86 host the second line changes nothing. The Linux arm64 editor binary is `Godot_v<ver>_linux.arm64.zip`; export templates are the same `.tpz`. A GDExtension without a `linux.arm64` library (e.g. godot-livekit) fails to load there, so UI text that shows that error can differ from an x86 run.

## GDT-231 — godot-livekit's prebuilt macOS `liblivekit_ffi.dylib` links Homebrew's `libjpeg.8.dylib` by absolute path, so voice fails on any Mac without Homebrew jpeg-turbo

`측정 2026-10-02 · Godot 4.7.2-stable · godot-livekit v0.3.3 prebuilt macos-arm64 · macOS arm64`

**증상:** an exported `.app` starts and plays, but voice never connects. The log says
`ERROR: Can't open dynamic library: addons/godot-livekit/bin/libgodot-livekit.macos.arm64.dylib. Error: dlopen(...): Library not loaded: /opt/homebrew/opt/jpeg-turbo/lib/libjpeg.8.dylib`
and then `Error loading extension: 'res://addons/godot-livekit/godot-livekit.gdextension'`. Every class from the
extension is then missing at runtime. The developer's machine works because it has `brew install jpeg-turbo`, so
the bug only shows on a clean Mac (here, a test Mac with no `/opt/homebrew` at all).

`otool -L liblivekit_ffi.dylib` shows `/opt/homebrew/opt/jpeg-turbo/lib/libjpeg.8.dylib` next to the `@rpath`
entries. The export copies the three dylibs into `Contents/Frameworks/` unchanged, so the absolute path ships too.
The library is also `arm64` only, so an Intel Mac has no voice even when the main binary is universal.

**해결:** before export, run `otool -L` on every dylib in the extension's `bin/` and fail the build on any path
under `/opt/homebrew` or `/usr/local`. To fix it, copy `libjpeg.8.dylib` next to the other dylibs, point the
reference at it with `install_name_tool -change /opt/homebrew/opt/jpeg-turbo/lib/libjpeg.8.dylib @rpath/libjpeg.8.dylib liblivekit_ffi.dylib`,
set its id with `install_name_tool -id @rpath/libjpeg.8.dylib`, list it under `[dependencies]` in the
`.gdextension`, then re-sign. Check on a Mac without Homebrew; a headless run of the exported binary
(`TRPG.app/Contents/MacOS/TRPG --headless --quit-after 200`) prints the `dlopen` error within seconds.

## GDT-232 — macOS export on a Linux host: built-in CodeSign fails with "Failed to extract thin binary", but the export still exits 0 and ships the template's stock signature, which does not verify

`측정 2026-10-02 · Godot 4.7.2-stable linux.arm64 headless · preset architecture=universal, codesign/codesign=1`

**증상:** the CI job that runs `--export-release "macOS"` passes and uploads a `.app`. The job log has
`ERROR: CodeSign: Failed to extract thin binary.` and `WARNING: Code Signing: Built-in CodeSign failed with error "Failed to extract thin binary.".`
The `.app` keeps the export template's signature (`Authority=Developer ID Application: Prehensile Tales B.V.`)
with `flags=0x0(none)` and no entitlements, so the preset's `audio_input` and `disable_library_validation`
entitlements are not applied. `codesign --verify --deep --strict` and `spctl -a -t exec` both answer
`code has no resources but signature indicates they must be present`. When the archive is downloaded through a
browser, Gatekeeper rejects it. With the quarantine attribute removed, the binary still starts.

**해결:** do not trust the job's exit code for signing. After export, run `codesign --verify --deep --strict` on
the `.app` (on a Mac) and fail on non-zero. To get a valid bundle, sign on a macOS host (`codesign --force --deep -s -`
for ad-hoc, a Developer ID for distribution), or re-sign the exported bundle there after a Linux export.

## GDT-233 — A ReflectionProbe leaves "7 RIDs of type Texture were leaked" at exit on Metal, whatever its update mode and even when freed before quitting

`측정 2026-10-02 · Godot 4.7.2-stable · macOS 27 Metal, Forward+ windowed · MacBook Air M1 test host`

**증상:** a windowed run that quits cleanly prints `WARNING: 7 RIDs of type "Texture" were leaked.` from `servers/rendering/rendering_device.cpp` `finalize`. A gate that rejects leak warnings then fails although nothing in the game leaks. Bisecting one scene (two interior `ReflectionProbe`s, two procedural `ImageTexture`s, one `GPUParticles3D`) with an environment switch per suspect: without the probes the warning is gone (0 of 1 runs); without the textures or the particles it stays (1 of 1 each). `update_mode = UPDATE_ALWAYS` instead of `UPDATE_ONCE` still leaks 7. Calling `queue_free()` on the probes and waiting 150 ms before `get_tree().quit()` still leaks 7: the reflection atlas outlives the probe nodes.

**해결:** do not use a `ReflectionProbe` in anything a leak-checking gate runs. For an interior's ambient, scale `Environment.ambient_light_energy` down while the camera is inside the room's bounds, and switch `reflected_light_source` to `REFLECTION_SOURCE_DISABLED` there so glossy floors stop mirroring the sky.

## GDT-234 — Forward+ on an M1 MacBook Air: MetalFX spatial upscaling buys more than any single effect, and FSR 2 buys less than FSR 1

`측정 2026-10-03 · Godot 4.7.2-stable · Forward+ on Metal, windowed 1920x1080, VSync off · MacBook Air M1 (adapter name "Apple M1 (Apple7)")`

**증상:** a stylized city scene that holds 60 FPS on an M1 Max ran at 25 FPS on the base M1 at the HIGH preset (SDFGI, SSIL, SSR, SSAO, volumetric fog, glow, 4-split soft sun shadows, about 50 omni/spot lights). Turning off one feature at a time gave these savings: sun shadows 7.3 ms, SDFGI 5.9 ms, lights 5.3 ms, SSIL 4.0 ms, SSR 2.4 ms, fog 2.2 ms, glow 1.8 ms, SSAO 1.3 ms. No single switch got near 60 FPS.

Setting `Viewport.scaling_3d_mode` and `scaling_3d_scale` on the root viewport gave this (frame ms, HIGH / MEDIUM):

| Mode | HIGH | MEDIUM |
|---|---:|---:|
| native | 39.6 | 25.7 |
| FSR 1, 0.77 | 29.3 | 18.8 |
| FSR 2, 0.67 | 30.1 | 20.9 |
| MetalFX spatial, 0.67 | 24.9 | 15.7 |
| MetalFX temporal, 0.5 | 22.1 | 14.7 |

FSR 2 at 0.67 was slower than FSR 1 at 0.77; its own pass costs about as much as it saves. MetalFX spatial needs no motion vectors or jitter, and the UI is not scaled.

**해결:** on Metal, use `SCALING_3D_MODE_METALFX_SPATIAL` and choose the starting quality per GPU. `RenderingServer.get_video_adapter_name()` returns `Apple M1 (Apple7)` for the base chip, so "starts with `Apple M` and has no ` Pro`, ` Max` or ` Ultra`" identifies the small GPUs. MEDIUM with MetalFX spatial at 0.67 measured 61-70 FPS (p99 under 17.7 ms) in a moving playthrough. Use FSR 1 on other Forward+ or Mobile drivers and bilinear on Compatibility, where neither upscaler exists.

## GDT-235 — `ShaderMaterial.get_shader_parameter()` returns `null` for a uniform that was never set, so `float(...)` on it is a SCRIPT ERROR, not the shader's default

`측정 2026-10-03 · Godot 4.7.2-stable · macOS 27 Metal, Forward+`

**증상:** a fade helper read the current value before tweening it: `var from := float(mat.get_shader_parameter("amount"))`. The uniform has a default in the shader code (`uniform float amount = 0.0;`), but the material had never set it. The first call printed `SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.` with the helper's line, because `get_shader_parameter()` returned `null` — it reports what the material overrides, not the shader's default. The tween still ran from 0, so the effect looked fine; only a gate that greps logs for `SCRIPT ERROR` caught it.

**해결:** set every uniform you will read back right after creating the material (`mat.set_shader_parameter("amount", 0.0)`), or read defensively: `var v: Variant = mat.get_shader_parameter("amount"); var from: float = v if v is float else 0.0`.

## GDT-236 — Windowed quit on macOS: `stop()` then a 0.15 s wait is not always enough to release WAV playbacks; 0.5 s was (extends GDT-095)

`측정 2026-10-03 · Godot 4.7.2-stable · macOS, MacBook Air M1, windowed, CoreAudio`

**증상:** a screenshot tool quit through the audio autoload's quit helper: stop every `AudioStreamPlayer`, set its `stream` to `null`, drop the stream cache, `await create_timer(0.15, true, false, true).timeout`, `quit()`. When music and a one-shot were still sounding at that moment, 2 of 3 runs printed `WARNING: 4 ObjectDB instances were leaked at exit` and `ERROR: 2 resources still in use at exit`; `--verbose` listed `AudioStreamPlaybackWAV` and `AudioStreamWAV` for the music track and the last effect. The same wait is enough headless (GDT-095); the real CoreAudio driver releases playbacks later and less predictably.

**해결:** wait 0.5 s between stopping and `quit()`. Same tool, same timing of the last sounds: clean in 9 of 9 runs.

## GDT-237 — Poing godot-admob v5.1.0 (GMA Next-Gen SDK 1.4.0) kills the Android app if an ad is loaded before `on_initialization_complete`

`측정 2026-10-03 · Godot 4.7.2-stable · poing godot-admob 5.1.0 (android-template-v4.7.2.zip) · ads-mobile-sdk 1.4.0 · Pixel 7 Pro, Android 17`

**증상:** calling the `PoingGodotAdMob` singleton's `initialize()` and then, in the same frame, `PoingGodotAdMobInterstitialAd.load(...)` crashes the whole app about two seconds after launch. No GDScript error; logcat shows:

```
D poing-godot-admob: loading interstitial ad
E AndroidRuntime: java.lang.IllegalStateException: MobileAds.initialize must be called before using the Google Mobile Ads SDK.
E AndroidRuntime: 	at com.google.android.libraries.ads.mobile.sdk.interstitial.InterstitialAd$Companion.load(SourceFile:53)
E AndroidRuntime: 	at com.poingstudios.godot.admob.ads.PoingGodotAdMobInterstitialAd.load$lambda$0(PoingGodotAdMobInterstitialAd.kt:84)
```

`initialize()` returns at once; the Next-Gen SDK finishes starting on a background thread, and the load runs on the UI thread, where an exception is fatal.

**해결:** connect the singleton's `on_initialization_complete(status: Dictionary)` signal and do the first load (and `set_app_muted`) there. Measured after the fix: the load starts 50 ms after the signal and the test interstitial shows. Other facts from the same setup:

- The plugin works with a **gradle** export only (it brings the maven dependency `com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0`). A prebuilt export with no `_get_android_dependencies` still exports fine; keep the debug app prebuilt and return nothing from the export plugin there (`get_option("gradle_build/use_gradle_build")`).
- You do not need their editor addon (it downloads binaries when the editor opens). Two AARs from `android-template-v4.7.2.zip` (`ads/libs/poing-godot-admob-{ads,core}-{debug,release}.aar`) plus a 20-line `EditorExportPlugin` returning them from `_get_android_libraries`, the two maven deps from `ads/poing_godot_admob_ads.gd`, and `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" …/>` from `_get_android_manifest_application_element_contents` is enough. Call the singletons directly: `PoingGodotAdMob`, `PoingGodotAdMobInterstitialAd` (`create()→uid`, `load(unit, request_dict, keywords, uid)`, `show(uid)`, `destroy(uid)`), `PoingGodotAdMobConsentInformation` (`update(dict)`, status ints 0 unknown · 1 not required · 2 required · 3 obtained), `PoingGodotAdMobUserMessagingPlatform`.
- The Pixel's hashed test-device id appears in logcat as `GMA(BG) 4: Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("…"))`, and UMP prints the same hash.
- A script that `preload`s an autoload script from an `EditorExportPlugin` or a `--script` test fails to compile if that script names another autoload as a global (`Identifier not found: Sfx`); look it up with `get_node_or_null("/root/Sfx")` instead.

Classic `play-services-ads` 25.5.0 is a different path with a different trap (Kotlin 2.3 metadata against the template's Kotlin 2.1.21) — the bearhunter session wrote its plugin in Java for that reason.

## GDT-238 — Godot 4.7.2 gradle export: `window/handheld/orientation=1` does reach the manifest as portrait; and `android/` in `.gitignore` also ignores `assets/android/`

`측정 2026-10-03 · Godot 4.7.2-stable · gradle_build/use_gradle_build=true · aapt2 36.1.0`

**증상 1:** GDT-072 found a gradle build that kept `screenOrientation` landscape. With `[display] window/handheld/orientation=1` (an integer, GDT-019) a gradle export of a portrait game gives `android:screenOrientation(0x0101001e)=1` (portrait) in `aapt2 dump xmltree --file AndroidManifest.xml`, and the app runs upright on a Pixel 7 Pro. So the integer setting is honoured by gradle builds as well as prebuilt ones (GDT-080); GDT-072's project used a string.

**증상 2:** `--install-android-build-template` writes the template to `<project>/android/`. Ignoring it with a line `android/` in the project's `.gitignore` also matches **every** directory named `android` below, e.g. `assets/android/` holding the launcher icons; `git add` then refuses them ("paths are ignored by one of your .gitignore files") and a commit chained with `&&` silently does not happen.

**해결:** anchor it: `/android/`. Check with `git check-ignore -v <project>/assets/android/<file>` (prints nothing when not ignored). Also exclude it from export presets (`exclude_filter="android/*"`, GDT-020).

## GDT-239 — `keytool -printcert -jarfile` says a Godot release APK is unsigned; it is v2/v3-signed only. Use `apksigner verify --print-certs`

`측정 2026-10-03 · Godot 4.7.2-stable gradle export · JDK 17 keytool · build-tools 36.1.0`

**증상:** a check after `--export-release` that runs `keytool -printcert -jarfile out.apk` prints `서명된 jar 파일이 아닙니다.` (Not a signed jar file) and fails, although the APK installs and is signed with the release key. Godot's APKs carry only the APK Signature Scheme v2/v3 block (minSdk 24), which `keytool` cannot read.

**해결:** for an APK, `$ANDROID_HOME/build-tools/<v>/apksigner verify --print-certs out.apk` (prints `Signer #1 certificate DN: …` and the SHA-256). An `.aab` is jar-signed, so `keytool -printcert -jarfile out.aab` does work for bundles. Either way, check the signer, not that the file exists (GDT-202).

## GDT-240 — A Kotlin Godot plugin cannot compile against `play-services-ads` 25.5.0: its Kotlin 2.3 metadata is refused by the build template's Kotlin 2.1.21; write the plugin in Java

`측정 2026-10-03 · Godot 4.7.2-stable Android build template · AGP 8.6.1 · play-services-ads 25.5.0 · JDK 17`

**증상:** a plugin v2 library module with `id 'org.jetbrains.kotlin.android' version '2.1.21'` (the template's own Kotlin, `android/build/config.gradle`) and `compileOnly "com.google.android.gms:play-services-ads:25.5.0"` fails in `:compileReleaseKotlin` with one line per module of the SDK:

```
e: file:///…/play-services-ads-25.5.0-api.jar!/META-INF/…kotlin_module Module was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.3.0, expected version is 2.1.0.
```

The same code in Java compiles and the app links. The template's app module compiles no Kotlin for the `standard` flavour (its `.kt` files are under `instrumented/` and `androidTestInstrumented/`), so the SDK on its classpath does no harm there. The SDK pulls in `user-messaging-platform` 4.0.0 through `play-services-ads-api`, so a separate UMP dependency is not needed.

`godot-lib.jar` for `compileOnly` is not a file in the export templates directory. It is `classes.jar` inside `libs/release/godot-lib.template_release.aar`, which is inside `android_source.zip`.

**해결:** write the plugin in Java (drop the Kotlin plugin from the module), or compile with `-Xskip-metadata-version-check`. Read the SDK's own metadata version before you choose the plugin's language.

## GDT-241 — Android AAB from a Godot 4.7.2 gradle export: 54.9 MB bundle, 31 MB Play download, 149 MB universal APK; `GODOT_ANDROID_KEYSTORE_RELEASE_*` signs it headless

`측정 2026-10-03 · Godot 4.7.2-stable · gradle_build/export_format=1 · arm64-v8a + armeabi-v7a · bundletool 1.18.3`

**증상:** a sideload APK made from the bundle is three times the bundle and five times what Play delivers, which reads like a broken export.

Measured for a small 3D game: `.aab` 54.9 MB, of which `libgodot_android.so` is 71.1 MB (arm64) and 74.9 MB (armv7) before zip compression. `bundletool get-size total --dimensions=ABI` gives 31.4 MB (arm64) and 32.9 MB (armv7) downloaded. `bundletool build-apks --mode=universal` makes one 148.7 MB APK: both ABIs, with the native libraries stored uncompressed (`compress_native_libraries=false`).

A headless `--export-release` of a gradle preset signs with the keystore in the environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD`, so the password stays out of `export_presets.cfg`. The universal APK takes the same key: `--ks=… --ks-pass=file:… --ks-key-alias=upload --key-pass=file:…`.

**해결:** upload the `.aab`. For a phone on a cable, install the universal APK. Its size is not what players download. To test exactly what was uploaded, cut the APK from the bundle rather than exporting an APK separately.

## GDT-242 — Android: a Godot 4.7.2 GL Compatibility scene renders at the panel's full resolution; on a Pixel 7 Pro that was 17 fps, and `screen_get_scale()` reports 2.40 where the density is 3.5

`측정 2026-10-03 · Godot 4.7.2-stable · Pixel 7 Pro (Android 17, 3120 × 1440, `wm density` 560) · gradle export, release template`

**증상:** a 3D title scene (grass, SSAO, glow, 4× MSAA, a 4096 shadow atlas) that runs at 80 fps on an M1 desktop at 1600 × 900 ran at **17 fps** on the phone. The window is the whole panel, 3120 × 1440, and the 3D renders at that size by default.

Measured on the same phone (frames per second, title screen, averaged over 5 s windows):

| 3D scale | Effects | fps |
|---|---|---|
| 1.00 (4.5 Mpx) | all | 17.0 |
| 0.75 | no SSAO, glow or lens blur, 2× MSAA | 21–29 |
| 0.52 (1.2 Mpx) | all | 34–40 |

The phone reached thermal status 2 during the session (`dumpsys thermalservice`), and later runs at the same settings read lower. Compare settings back to back, not across a session.

`DisplayServer.screen_get_scale()` returned **2.40** on this phone, while `wm density` 560 is 3.5. A layout that divides the window by it gets 600 units on the short side, not 411 dp.

**해결:** on `OS.has_feature("mobile")`, cap the 3D at a pixel budget before anything else: `get_viewport().scaling_3d_scale = min(1, sqrt(1.2e6 / (w * h)))` from `DisplayServer.window_get_size()`. The 2D UI keeps the panel's resolution, so text stays sharp. Do not assume `screen_get_scale()` is the Android density.

## GDT-243 — Android: setting `launcher_icons/adaptive_foreground_432x432` also replaces the start-up splash with that bare foreground layer

`측정 2026-10-03 · Godot 4.7.2-stable · gradle export (AAB → universal APK) · Pixel 7 Pro, Android 17`

**증상:** after adding adaptive launcher icon layers to an Android preset, the owner called the full-screen logo at app start "tacky". The launcher icon itself was fine. The splash showed the foreground layer on its own, unmasked, on the system splash background (white in the owner's view): a motif drawn to run past the 66 dp safe circle (lines bleeding off the edge, meant to be cut by the launcher mask) shows its loose ends there.

Measured from the APKs: without `launcher_icons/*`, `res/drawable/splash_icon.webp` is the 512 px `application/config/icon` (the whole rounded-square logo, 2,412 B). With `launcher_icons/adaptive_foreground_432x432` set it becomes a 432 px copy of that foreground (17,038 B, the same size as `res/mipmap-xxxhdpi-v4/icon_foreground.webp`). The export has no separate splash-image option; `boot_splash/*` only covers Godot's own boot screen after the activity starts.

**해결:** decide what the splash should show before adding adaptive layers. Either draw the foreground so that it also stands alone on a plain white or dark background (motif inside the safe circle, nothing that relies on the mask), or leave `launcher_icons/*` unset so the splash and the launcher keep `config/icon`. Check the splash by recording a cold start (`adb shell screenrecord`, launch with `monkey -p <pkg> -c android.intent.category.LAUNCHER 1`); it is on screen for well under a second, too short for `screencap`.

## GDT-244 — Android splash colours: `[splash]` keys in `gradle_build/custom_theme_attributes` apply, but `android:windowBackground` is reserved and skipped. Without `screen/background_color`, the black main theme shows as a grey circle for about 100 ms

`측정 2026-10-03 · Godot 4.7.2-stable · gradle export · Pixel 7 Pro (Android 17) · adb screenrecord at 30 fps`

**증상:** the goal was a white launch with no icon, then Godot's boot splash (a logo on white). The preset had:

```
gradle_build/custom_theme_attributes={
"[splash]android:windowSplashScreenBackground": "#FFFFFF",
"[splash]windowSplashScreenAnimatedIcon": "@android:color/transparent",
"android:windowBackground": "#FFFFFF"
}
```

In the generated `android/build/res/values/themes.xml`, the two `[splash]` items replaced Godot's own (`@mipmap/icon_background`, `@drawable/splash_icon`). `GodotAppMainTheme` still had `<item name="android:windowBackground">#000000</item>`. The editor binary carries the message *Skipped custom_theme_attribute '%s'; this is a reserved attribute configured via other export options or project settings*. On the phone, a cold start went white, then for 4 frames (about 130 ms) a grey circle grew from the top before the boot splash appeared. That was the splash's exit animation revealing the black window behind it.

**해결:** set the main theme's window colour with the export option `screen/background_color=Color(1, 1, 1, 1)`. It becomes `android:windowBackground` `#ffffff`. The recording then went white, then the logo, with no grey or black frame. Godot's boot splash can be Android-only through feature overrides in `project.godot` (`boot_splash/image.android`, `bg_color.android`, `stretch_mode.android`, `show_image.android`, `minimum_display_time.android`). The image showed on the device with only the `.android` key set, and the web build kept its own splash. GDT-243 covers why the system splash icon must be set explicitly once adaptive icons exist.

## GDT-245 — Web export: `user://` lives at `/userfs/godot/app_userdata/<config/name>/` in IndexedDB; a save written into IndexedDB from a running page is wiped, inject it before the engine boots

`측정 2026-10-03 · Godot 4.7.2 Web export (release) · Chrome 154 headed via Playwright · Air`

**증상:** a browser test wanted the game to start with progress, so it wrote `/userfs/landgrab_save.cfg` into IndexedDB `"/userfs"`, store `FILE_DATA`, then reloaded. The record stayed in the database but the game started with an empty save. Writing the right path from the running page and reloading also did not work: the engine's own sync from memory to IndexedDB removes entries it does not have.

`OS.get_user_data_dir()` on the web is not `/userfs` but `/userfs/godot/app_userdata/<application/config/name>` (here `LANDGRAB`, the project's `config/name`, not the localized name). Emscripten IDBFS keeps one record per path: directories `{timestamp: Date, mode: 16893}`, files `{timestamp: Date, mode: 33206, contents: Uint8Array}`; the database is version 21 and exists after the first boot.

**해결:** boot once in the context (creates the database), close that page, open a new page in the same context and `page.addInitScript` a function that `put`s the three directory records (`/userfs/godot`, `/userfs/godot/app_userdata`, `/userfs/godot/app_userdata/LANDGRAB`) and the file record, then `goto`. The write finishes long before the engine loads its 40 MB wasm and syncs IndexedDB into memory; the title then showed the injected progress. A ConfigFile in plain text (`[cuts]\nopen_s0=2\n`) is enough as `contents`.

## GDT-246 — New textures import with Godot's defaults: a 1536×1024 WebP took 1.7 MB in the package, and masks sampled with `textureLod` had no mipmaps

`측정 2026-10-03 · Godot 4.7.2 · Web export and editor import`

**증상:** after adding 96 illustrations next to 16 older ones, `index.pck` grew by 16 MB although the new pictures were excluded from the web package. The imported thumbnails (512×341) were 264 KB each and the illustrations 1.7 MB each in `.godot/imported`: Godot gave every new file a fresh `.import` with `compress/mode=0` (lossless), `lossy_quality=0.7` and `mipmaps/generate=false`. The older files had been set by hand to lossy 0.88 with mipmaps; nothing carries those settings over to new files. A shader that reads a mask with `textureLod(mask, uv, 3.5)` silently gets level 0 when the mask has no mipmaps.

**해결:** after the first `godot --headless --path client --import`, copy the `[params]` block of an existing file of the same kind into each new `.import` and import again; Godot rebuilds the textures because the parameters changed (here: illustrations 1.7 MB → 480 KB, thumbnails 264 KB → 62 KB at lossy 0.72, masks with mipmaps). Keep the copy as a script, since every later import of a new file starts from the defaults again.

Separately, `exclude_filter="assets/stages/*_c?.webp,..."` in the Web preset left both the `.import` remap and the `.ctex` out of the package (checked with `strings index.pck`). The excluded pictures were served as plain files and loaded at run time with `HTTPRequest` (absolute URL from `JavaScriptBridge.eval("location.origin")`), `Image.load_webp_from_buffer` and `image.generate_mipmaps()` before `ImageTexture.create_from_image`, which worked in Chrome with no console errors.

## GDT-247 — Headless tests: `Input.parse_input_event` of joypad events updates `get_joy_axis` and `is_joy_button_pressed`, but the device never appears in `get_connected_joypads()`

`측정 2026-10-04 · Godot 4.7.2-stable · --headless --script, no pad attached`

**증상:** gameplay code that loops over `Input.get_connected_joypads()` to read the stick or a held button saw nothing in a headless test that injected `InputEventJoypadMotion` / `InputEventJoypadButton` for device 0, although the same events moved menu focus.

Parsed joypad events do update the polled state: after `Input.parse_input_event(motion)` + `Input.flush_buffered_events()`, `Input.get_joy_axis(0, JOY_AXIS_LEFT_X)` returns the injected value and `Input.is_joy_button_pressed(0, JOY_BUTTON_A)` follows press/release. Only the connection list stays empty, because it is filled by the joypad driver, not by events.

**해결:** read the pads from `get_connected_joypads()` plus the last device id seen in `_input` (`InputEventJoypadButton.device` / `InputEventJoypadMotion.device`). Real play is unchanged and headless tests then drive stick movement and held buttons with parsed events (45 checks in one suite, including 8-way stick reading and cutting while A is held).

## GDT-248 — Web export: a scripted gamepad from `navigator.getGamepads` + a `gamepadconnected` event drives Godot 4.7 like a real pad

`측정 2026-10-04 · Godot 4.7.2-stable Web export · Chrome (headed, Playwright) on macOS`

**증상:** a gamepad feature on the web build could not be checked end to end without a physical pad in front of the test machine.

In `page.addInitScript`, replace `navigator.getGamepads` with a function returning `[pad, null, null, null]`, where `pad` is a plain object `{id, index: 0, connected: true, mapping: 'standard', timestamp, axes: [0,0,0,0], buttons: 17 × {pressed, touched, value}}`. After the engine has booted, click the page once and `dispatchEvent` an `Event('gamepadconnected')` with `e.gamepad = pad`. Changing `pad.buttons[i]` (and bumping `timestamp`) is then read by the engine's polling: standard button 0 arrived as `JOY_BUTTON_A`, 9 as `JOY_BUTTON_START`, 12/13 as D-pad up/down. The deployed game started a run from the title on A and paused on Start, both visible in screenshots.

**해결:** use this as the web gamepad smoke test. Wait for the download to finish before connecting (a 64 MB build over the LAN needed about 80 s; at 15 s the boot screen was still at 38%), and hold each button for about 150 ms so at least one engine frame sees it pressed.

## GDT-249 — A `PlaceholderTexture2D` set as a `Button.icon` draws Godot's magenta-and-black checker, not nothing

`측정 2026-10-04 · Godot 4.7.2-stable · macOS, windowed (Metal)`

**증상:** a Button that reserves room for a glyph it draws itself (`icon = PlaceholderTexture2D` with `size = Vector2(30, 30)`, glyph painted in `_draw()`) showed a 30 px magenta/black checkerboard under the glyph in every windowed capture. Headless tests cannot see it.

The placeholder renders as the "missing texture" pattern. Code that uses the same trick only looks right when the button's `icon_*_color` theme colours are fully transparent, which hides the problem until the trick is reused on a normally themed button.

**해결:** reserve the room with a clear texture instead: `icon = ImageTexture.create_from_image(Image.create_empty(30, 30, false, Image.FORMAT_RGBA8))`. The checker was gone in the next capture.

## GDT-250 — Web export: `root.size_changed` misses a full-screen change when the page keeps its size; listen to `fullscreenchange` through `JavaScriptBridge.create_callback`

`측정 2026-10-04 · Godot 4.7.2-stable Web export · Chrome (headed, Playwright, fixed 1440×900 viewport) on macOS`

**증상:** a full-screen button refreshed its label on `get_tree().root.size_changed` (GDT-180). After `document.exitFullscreen()` the page left full screen (`document.fullscreenElement` null) but the button kept saying it was full screen. With Playwright's fixed viewport the page size does not change on entering or leaving full screen, so no resize reached Godot. The same can happen in any embedding that keeps the canvas size.

**해결:** report the DOM event as well:

```gdscript
static var _cb: JavaScriptObject  # keep a reference, or the callback is collected
_cb = JavaScriptBridge.create_callback(func(_args: Array) -> void: changed.emit())
var doc := JavaScriptBridge.get_interface("document")
doc.addEventListener("fullscreenchange", _cb)
doc.addEventListener("webkitfullscreenchange", _cb)
```

Connect it deferred and read `document.fullscreenElement` in the handler. With this the label switched back within 1.2 s of `exitFullscreen()` in the same test, and a click on the button (CDP mouse event) still entered and left full screen.

## GDT-251 — A container page that is wider than the phone: a Control never gets smaller than its minimum size, and switching `BoxContainer.vertical` in the same layout pass is too late

`측정 2026-10-04 · Godot 4.7.2 · ScrollContainer > VBoxContainer > BoxContainer (two panels), phone layout at 411 px`

**증상:** a screen built from containers (a header and a body `BoxContainer` with two panels inside a `ScrollContainer` with horizontal scrolling disabled) rendered wider than a 411 px phone: the right panel edge and the back button were off screen. Dumping sizes showed the screen at 411 but the scroll at 548-915. Two separate causes:

1. `scroll.set_anchors_preset(PRESET_FULL_RECT)` together with a manual `scroll.size = ...` in `_layout`: anchored sizes win on the next layout, and the manual size is ignored.
2. `_layout` set `scroll.size` and then `body.vertical = narrow`. At that moment the body was still side by side, so its minimum width (left panel + right panel) was larger than the phone. A Control's size is clamped to its combined minimum size, so the scroll kept the wide size. After `vertical` flipped, the minimum dropped, but nothing laid out again: no `resized` signal followed.

**해결:** do not give a manually sized control full-rect anchors. In the layout function, change orientation and other minimum-size-changing properties first; when the orientation actually changes, run the layout again with `_layout.call_deferred()`, and once more deferred after `enter`. Do not pin the scroll child's width with `custom_minimum_size.x`: with horizontal scrolling disabled, the ScrollContainer fits its child to its own width. A size dump (`get_combined_minimum_size()` against `size` for each node) finds the widest child in one run.

## GDT-252 — `--headless`: `RenderingServer.frame_post_draw` never fires, so an `await` on it hangs forever

`측정 2026-10-04 · Godot 4.7.2-stable · macOS (MacBook Air M1), --headless`

**증상:** a loading screen's "warm up" step did `for i in 3: await RenderingServer.frame_post_draw` so the first frames of a new scene compiled under cover. An end-to-end test that ran the real scene transition headless stopped there: the transition never finished, the game kept its "switching" flag, and every later transition returned early. No error is printed. A probe that counted the signal for one second under `godot --headless --script` printed `FPD 0`; `process_frame` keeps ticking.

**해결:** wait for draws only when something draws:

```gdscript
var drawn := DisplayServer.get_name() != "headless"
for i in frames:
	if drawn:
		await RenderingServer.frame_post_draw
	else:
		await get_tree().process_frame
```

Search a project for `frame_post_draw` before running its real UI flow headless; any `await` on it is a hang there.

## GDT-253 — Taking a SpacetimeDB game offline: run each former reducer at the end of the frame as one transaction, emit one row signal per changed row, and world code written for async reducer callbacks keeps working unchanged

`측정 2026-10-04 · Godot 4.7.2 · SpacetimeDB 2.8.0 module (2,019 lines Rust) ported to GDScript · Air`

**증상:** a game built on SpacetimeDB (reducers + subscribed tables + row signals) had to become single player with no server. The world, duel screen and UI were written against the client cache's semantics: a reducer's effect arrives frames later, all at once, `row_updated(old, new)` per row, `callback(ok, err)` after, and a `warp` counter in the pose row to tell "snap" from "smooth". Applying writes immediately and synchronously would reorder these flows (zone-change loading sign, dialogue → story action → end card) and re-enter world code mid-write.

**해결:** keep the same shape locally. `act(name, args, callback)` queues the call and runs it with `call_deferred` (end of the frame); the action writes rows through `_put/_insert/_delete`, which log `[table, key, old, new]` and never mutate a stored row in place (always `duplicate()`, so the old row handed to a signal stays intact). On a returned error string the log is rolled back in reverse (a reducer `Err`); on success the log is collapsed to the first old and last new row per key and emitted as insert/update/delete, then `transaction_applied`, then the callback. Ticks (`combat 50 ms`, `enemy 200 ms`, `world 1 s`) are the same functions driven from `_process` and committed the same way. Keep the facade's API (accessors, signals, wire codes) so gameplay code only needs `Net.` → `Game.`. Result: the existing 7-case end-to-end test, adapted only for removed online checks plus a save/reload, passed 468 PASS / 0 FAIL on the first full run (about 19 min). Saves: `JSON.stringify(JSON.from_native(data))` / `JSON.to_native(JSON.parse_string(text))` keep ints as ints (plain JSON turns every id into a float). Use a game clock (`base + ticks - origin`, frozen while paused) for every `*_ms` field instead of unix time, so meters, deadlines and the save survive pauses and restarts.

## GDT-254 — CSV translations are imported next to the CSV (`*.<lang>.translation`), not into `.godot/`: syncing a tree that skips only `.godot` ships stale tables, and the game shows raw keys while a CSV-reading test passes

`측정 2026-10-05 · Godot 4.7.2 · rsync from a dev Mac to a test Mac`

**증상:** new keys added to `client/i18n/ui.csv`, the project imported on the test machine, then the tree was rsynced again from the dev machine (excluding `.godot`). Windowed captures showed `MENU_CONTINUE` and `CONFIRM_NEW_TITLE` as literal text. A string-table test that parses the CSV itself passed (15,849 checks, 0 failures), so nothing failed.

The CSV importer writes `ui.en.translation`, `ui.ko.translation`, … beside `ui.csv` (projects usually gitignore them). Those files belonged to the dev machine's last import, a day old; rsync saw them differ and overwrote the fresh ones.

**해결:** exclude `*.translation` (with `.godot/`) from any tree sync, or run `godot --headless --path <project> --import --quit` after every sync and before captures or exports. A test that only reads the CSV does not prove the game shows the text; check a capture, or load the `.translation` resources in the test. Separately, on the Web export, `DirAccess.remove_absolute()` on a `user://` file reached IndexedDB at once: the `FILE_DATA` record was gone when read right after, and a reload found no file.

## GDT-255 — Web export: Chrome's HTTP cache does not keep a 117 MB `index.pck` (every visit downloads it again), and a service worker relaying it is stopped after about 5 minutes; keep the file in Cache Storage from the page

`측정 2026-10-05 · Godot 4.7.2 Web export (release) · Chrome headed via Playwright, persistent profile · Air`

**증상:** the server sent `Cache-Control: no-cache` with an ETag, and a conditional GET with curl answered 304. Yet in a normal persistent Chrome profile the second visit downloaded `index.pck` (116.6 MB) in full again, while `index.wasm` (39.5 MB) came back 304 with a 300 B transfer. Chrome does not store an entry that large in its HTTP cache, so revalidation never happens.

A service worker that served the two files from Cache Storage fixed repeat visits on a fast local server, but on a slow line (live site, about 0.2 MB/s) the boot download hung at 52 % (86.4 of 148.9 MB) after about 317 s with `net::ERR_FAILED` / `TypeError: network error`. Chrome stops a service worker that is still busy with one event after about 5 minutes, and the response it relays dies with it. That worker had also used `event.waitUntil(cache.put(...))`.

**해결:** do it in the page. Godot's `index.js` loads files with plain `fetch(file)`, so before `engine.startGame()` replace `window.fetch` with a wrapper that handles only `index.pck` and `index.wasm`. The wrapper opens `caches.open(name)` and sends a `HEAD` with `cache: 'no-store'`. If the kept copy's ETag (or Last-Modified) matches, it returns the copy. Otherwise it fetches the file, starts `cache.put(path, response.clone())` without awaiting it (the engine reads the original, so the progress bar keeps moving) and returns the response. Every other request falls through to the original fetch, and so does the case where `caches` is missing or throws (private mode).

Measured at 300 KB/s: a 7-minute download finished and reached the title; the next visit sent two HEADs and showed the title in 12 s. On the live site over the Air's line: 11.7 min, then 13 s.

To retire a worker already installed, serve a `sw.js` that calls `skipWaiting()`, `registration.unregister()` on activate and navigates its clients. Also have the page unregister any registration once while `navigator.serviceWorker.controller` is set, then reload, guarded by a sessionStorage flag. After that reload the page is not controlled (`getRegistrations()` returns 0). OPS-234 explains why CDP byte counts miss a worker's fetches; count on the server log instead.

**추가 (2026-10-05, 같은 날):** on the Air, `Cache.put` of the 39.5 MB `index.wasm` (gzip, `Vary: Accept-Encoding`) later failed with `NetworkError: Failed to execute 'put' on 'Cache': Cache.put() encountered a network error`, in a fresh profile, over HTTP/2 or QUIC. Smaller files (`index.js`, `logo.svg`, `robots.txt`) were stored fine. The data volume had 585-944 MiB free (`df -h /System/Volumes/Data`) at that point. The same steps had kept both files a few hours earlier, when the disk had more room. `navigator.storage.estimate()` still reported a 10.7 GB quota, so it does not warn you. Chrome sizes its HTTP cache and Cache Storage from free disk space and caps a single entry well below the total, so large files are only kept on a machine with room. The "HTTP cache does not keep the pck" result above is therefore partly a property of the machine it was measured on. Check free disk before measuring caching on a shared test machine. In the game, a failed `put` costs only the keeping: the download itself completed and the game started.

## GDT-256 — Web export sample playback: `play(position)` on a second player starts about 0.8 s late, so stems cannot be crossfaded by starting one at the other's position; start them together instead

`측정 2026-10-05 · Godot 4.7.2 Web export (no threads, default Sample playback) · headed Chrome on macOS · Vorbis music 94.5 s`

**증상:** layered music was built as versions of one track (groove, +melody, full mix), sample-aligned. The first design crossfaded by starting the next version on the second music player with `play(current.get_playback_position())`. Natively that lines up within 0.06 s. On the Web the new player's `get_playback_position()` stayed frozen at the requested start for 0.8-0.9 s and then advanced from there, while the old player kept going: the new version came in about 0.85 s behind. This held even with the stream prewarmed by `AudioServer.register_stream_as_sample()` 3 s earlier. Without the prewarm, the delay was about 1.2 s.

- `get_playback_position()` itself is reliable for Web samples: it advances smoothly (0.30, 0.82, 1.32 s at 0.5 s intervals) and matched the audible timeline in this test.
- Several players started with `play()` in the same frame report identical positions and stay together.
- A sample with its loop flag on restarts itself on its own `ended` event (GDT-097), so stems looping independently can drift apart by the per-loop gap.

**해결:** start every stem in the same frame and crossfade only their volumes. For the Web, set the stems' loop flag off, and on the main stem's `finished` signal call `play()` on all of them in one frame. Measured after that: the three players reported the same position after every level change and after the 94.5 s loop point. Cost: each stem plays (and on the Web is decoded into a float32 buffer, about 33 MB per stereo 94 s stem) the whole time.

## GDT-257 — A sidecar `.png.import` without `path`/`dest_files` loads only after `--import` rewrites it; syncing the sidecar back over the rewritten one gives "Failed loading resource"

`측정 2026-10-05 · Godot 4.7.2-stable · texture importer · tree synced to a test Mac with rsync --exclude .godot`

**증상:** new sprites showed the fallback art and the log printed `ERROR: Failed loading resource: res://assets/sprites/boss_mio.png.`
although `.godot/imported/` held their `.ctex` files and `ResourceLoader.exists()` was true.

The `.import` sidecars had been written by hand (copied from an older sprite, with `uid`, `path` and `dest_files` deleted, as in
GDT-120). `godot --import` on the test Mac filled those lines in, but every later `rsync -az --exclude .godot client ...` from the
dev Mac pushed the hand-written sidecar back, so the remap had no `path` again and loading failed at run time. The import step
does not rewrite a sidecar whose source and params did not change.

**해결:** do not keep hand-written sidecars in the tree. Import once, take the `.import` files Godot wrote (with `uid`, `path`,
`dest_files`), replace only their `[params]` block with the one from a similar asset, commit those, and import again.

## GDT-258 — Web export: buses made at runtime with `AudioServer.add_bus()` can leave the whole game silent (Master feeds another bus, the graph loops); define buses in `default_bus_layout.tres` instead

`측정 2026-10-05 · Godot 4.7.2-stable Web export (no threads, default Sample playback) · Brave 1.96 on macOS`

**증상:** The Web build played no sound at all, on every browser, while the desktop and Android builds were fine. No error in the console. The `AudioContext` was `running`, `AudioBufferSourceNode.start()` was called for music and effects, and the decoded buffers held signal (peak 0.5-0.76), yet an `AnalyserNode` tapped on everything connected to `ctx.destination` read 0.

The game created its buses in code: `AudioServer.add_bus(AudioServer.bus_count)`, `set_bus_name`, `set_bus_send(index, "Master")` for Music, SFX, UI and Voice. Tracing `AudioNode.connect` showed every source going through its bus into a cycle: Master's output gain node was connected to another bus's input, that bus back into Master, and nothing reached `ctx.destination` except the position worklets. Web Audio renders a cycle without a `DelayNode` as silence.

The Web side keeps its own bus list (`GodotAudio.Bus` in `index.js`). `Bus.addAt(atPos)` appends the bus and, when `atPos` differs from its new index, calls `Bus.move(from, atPos)`, which does `buses.splice(toIndex - 1, 0, bus)`. A position the engine does not pass as the plain new index (for example -1 for "at the end") inserts the new bus in front of the last one, so the JS indices stop matching the engine's. Later `set_bus_send` calls by index then wire the wrong buses, including Master (index 0 in JS is no longer Master).

**해결:** Put the buses in `res://default_bus_layout.tres` (the default value of `audio/buses/default_bus_layout`). The layout is applied with a bus count, which the Web side builds by appending in order, so the indices match. Measured on the same page after the change: every source path ends at `AudioDestination`, output peak 0.95-1.14. Keep any runtime `add_bus` as a fallback only when `get_bus_index(name) == -1`. To check a Web build, wrap `AudioNode.prototype.connect` in an init script and walk the graph from each `AudioBufferSourceNode`; on a Mac reached over ssh, launch Chromium with `--disable-audio-output`, or `AudioContext.currentTime` stays at 0.005 and nothing renders (GDT-097 for the other hooks).

## GDT-259 — Android: `DisplayServer.screen_get_dpi()` is the panel's real density (560 on a Pixel 7 Pro), so `px * 160 / dpi` gives dp; a GL Compatibility farm scene held 60 fps at `scaling_3d_scale` 0.70

`측정 2026-10-05 · Godot 4.7.2-stable · prebuilt release export (gradle_build=false), screen/immersive_mode=true · Pixel 7 Pro (Android 17, 3120 × 1440, wm density 560)`

**증상:** a UI that lays out by the screen's height in dp (phone layout below 700 dp) needs the Android density. GDT-242 found that `DisplayServer.screen_get_scale()` reports 2.40 on this phone where the density is 3.5, so it cannot be used for that.

Printed from the game on the phone: `window (3120.0, 1440.0) dpi 560`. `screen_get_dpi()` matches `wm density` exactly, and the window was the whole panel from the first frame (immersive preset, no `window_set_mode` call; see GDT-201). With `dpr = screen_get_dpi() / 160.0` the short side is 1440 / 3.5 = 411 dp, the same value Chrome reports for this phone. Laying out 480 logical px of height (`content_scale_factor` = 1440 / 480 = 3.0) put 15 px body text at 45 physical px, about 12.9 dp.

Frame rate in the same build, read from `Engine.get_frames_per_second()` every 5 s: with the 3D capped at about 2.2 Mpx (`scaling_3d_scale = sqrt(2.2e6 / (3120 * 1440))` = 0.70; 2D at full resolution) the title, the farmhouse interior (122–130 draw calls) and the outdoor farm map (148 draw calls, MSAA 2×, 4096 shadow atlas) all read 58–60 fps. Changing maps showed one sample of 1 fps (the map build stalls the frame) and one of 40 on the first interior frame.

**해결:** on `OS.has_feature("mobile")` take the density from `screen_get_dpi() / 160.0`, not from `screen_get_scale()`. For a light GL Compatibility scene, a 2.2 Mpx 3D budget is enough for 60 fps on this phone; GDT-242's heavier scene needed about 1.2 Mpx.

## GDT-260 — Android: a preset with `gradle_build/use_gradle_build=false` ignores `custom_theme_attributes` and `screen/background_color` silently; `themes.xml` is not even rewritten

`측정 2026-10-05 · Godot 4.7.2-stable · Android export (debug) · Samsung Galaxy S24+ (SM-S926U) · adb screenrecord`

**증상:** after adding the GDT-244 keys (`"[splash]android:windowSplashScreenBackground": "#FFFFFF"`, `"[splash]windowSplashScreenAnimatedIcon": "@android:color/transparent"`, `screen/background_color=Color(1, 1, 1, 1)`) to every Android preset, the debug APK still opened on the dark system splash with the launcher icon, then a black frame, then white. The export printed no warning and exited 0. `android/build/res/values/themes.xml` kept its old mtime and contents (`@mipmap/icon_background`, `@drawable/splash_icon`, `windowBackground #000000`).

The debug preset had `gradle_build/use_gradle_build=false`: it repackages the prebuilt APK template, whose theme is compiled in. The theme options exist only for gradle builds, and the editor shows them on a non-gradle preset without complaint.

**해결:** judge the launch on a gradle preset. Flipping `use_gradle_build=true` for one export regenerated `themes.xml` (`windowSplashScreenBackground #FFFFFF`, transparent icon, `windowBackground #ffffff`), and a cold start recorded at 4 fps went home screen → white → the game's own first frame, with no icon and no dark frame. The gradle debug APK was 92 MB against 32 MB for the template build. Related: GDT-243, GDT-244.

## GDT-261 — GDT-104's U+2060 WORD JOINER has no glyph in Noto Sans KR or Jua: it draws as nothing, but a `Font.has_char()` glyph-coverage test reports it missing

`측정 2026-10-05 · Godot 4.7.2-stable · TextServerAdvanced · windowed macOS run (M1) · Noto Sans KR and Jua subsets (fontTools)`

**증상:** after inserting U+2060 between Hangul syllables (GDT-104) in an autowrapped `Label`, a headless UI test that walks every visible label and checks `font.has_char(ch)` for each character failed with `glyph '⁠' in '돌⁠파⁠는…'`. The bundled Korean faces do not map the code point: fontTools `getBestCmap()` has no 0x2060 in Noto Sans KR (a subset that keeps U+2000–U+206F) nor in Jua.

On screen nothing is wrong. A windowed capture of the same label (Noto Sans KR 600, 26 px, 330 px wide) showed no tofu box and no gap, and the line broke at a space ("돌파는 돌파! 다음엔 더 | 멋지게 가 봐요.") where the label without joiners had split "멋지 | 게". HarfBuzz treats U+2060 as default-ignorable and hides it whether or not the font has a glyph.

**해결:** keep the joiners; exempt default-ignorable code points (at least U+2060, and U+200B if the font lacks it) from glyph-coverage checks instead of adding a glyph to the font. Related: GDT-104, GDT-186.

## GDT-262 — Capturing a one-shot pose (attack at 0.12 s, die at 0.35 s) in a windowed `--script` render: step `_process` and `AnimationPlayer.advance()` by hand, then disable processing

`측정 2026-10-05 · Godot 4.7.2-stable · GL Compatibility (OpenGL 4.1 Metal, Apple M1) · windowed --script contact sheet`

**증상:** A lineup that calls `play("attack")` and saves the viewport a few frames later shows every
actor at a different, random point of its one-shot (frame timing varies with shader compiles), and
code-driven poses (procedural rigs posed in `_process`) drift between the call and the capture.

Deterministic recipe, verified on 13 contact sheets of 8 poses each (rigged and procedural actors):
add the node, call `play()` / state setters, then advance it yourself at a fixed step and freeze it:
`for i in round(seconds * 60): tick(node, 1.0 / 60.0)` where `tick` calls `n._process(dt)` on the node
and every descendant that has it, and `ap.advance(dt)` on every `AnimationPlayer` whose `active` is
true; then `node.process_mode = Node.PROCESS_MODE_DISABLED`. The engine renders the frozen pose; the
skinned meshes still update (Skeleton3D skinning is not tied to the node's process mode).

Related: `AnimationPlayer.active = false` (AnimationMixer) keeps the last pose and leaves bones set by
`Skeleton3D.set_bone_pose_rotation()` / `set_bone_pose_scale()` alone, so a rig can hold a hand-made
pose (folded wings of a sleeping bat) while its clip is off. Setting `active = true` again resumes the
clip, but bones the clip has no track for (here scale) keep the manual value: reset them with
`Skeleton3D.reset_bone_poses()` first.

**해결:** Use the manual step + `PROCESS_MODE_DISABLED` recipe for any pose-specific capture; reset
manual bone poses before reactivating an AnimationPlayer.

---

## GDT-263 — Web export Sample playback: `get_playback_position()` trails the audible position by about 1 s for the whole life of a playback, and two players' reports can differ by 75 ms under load; players started in the same frame start at the same AudioContext time

`측정 2026-10-05 · Godot 4.7.2-stable Web export (no threads, default Sample playback) · headless Brave 1.96 (SwiftShader, --disable-audio-output) on the M1 Air under load average 50-95`

**증상:** layered music on the Web (a percussion stem that must stay within 30 ms of its track). Starting the stem mid-track at the music's `get_playback_position()` puts it about a second behind (GDT-256 saw 0.85 s). Re-aligning from the reported positions made it worse: a stem placed from the game clock landed 85 ms off, and a "correction" computed from the two players' reported positions moved it to +40 ms.

Read from the exported `index.js` and `index.audio.position.worklet.js`, and measured by wrapping `AudioBufferSourceNode.prototype.start` in an init script (it records `ctx.currentTime` and the offset of every start):

- Every `play()` creates a `SampleNode` whose position worklet gets `reset.setValueAtTime(1, now)` and `setValueAtTime(0, now + 1)`. For that first second the reported position is the start offset; afterwards it counts from zero. So the report trails the audible position by about 1 s until the next `play()`/`seek()`. Two players started together both trail by the same amount, so their difference is still meaningful.
- Reports arrive by `postMessage` from the audio thread. Two players started in the same frame (identical start time and offset) read 3.392 s and 3.467 s at the same moment once, under load. A drift check built on reported positions on the Web needs a tolerance above 75 ms.
- `start()` is called in a microtask after `await audioPositionWorkletPromise`, which runs at the end of the frame's JS task. Players that `play()` in the same frame start at the same `ctx.currentTime` (recorded 4.21333 s and 4.21333 s, same offset). Audible error: 0.00 ms in every one of 5 runs.
- `register_stream_as_sample()` always builds a 2-channel buffer (`numberOfChannels = 2` is hard-coded in `godot_audio_sample_register_stream`). A mono OGG costs the same Web memory as stereo. Shipping a stem as mono only shrinks the download.
- Hand looping per GDT-256 (loop off; on `finished`, `play()` the music and its stems in one frame) worked: restarts at the same context time and offset, with gaps of 69-141 ms between the end and the restart (6 loops). The engine's own loop restart on an unlayered track measured 32-123 ms (3 loops) under the same load.

**해결:** On the Web, start a stem only in the frame its music starts or restarts (`play()` both, same offset), and never place it from a reported position or from the game clock. If the stem arrives late (download), let it join at the next hand-looped restart. Natively, positions are exact, and `seek(music.get_playback_position())` re-aligns a stem (GDT-265). Related: GDT-097, GDT-256.

## GDT-264 — Web export Sample playback: a looping sample that was started with `play(from)` or `seek()` loops back to that offset, not to 0

`측정 2026-10-05 · Godot 4.7.2-stable Web export (no threads, default Sample playback) · headless Brave 1.96`

**증상:** `SampleNode._restart()` (the `ended` handler for `loopMode` `forward`) calls `this._source.start(this.startTime, this.offset + pauseTime)`. `this.offset` is the offset the node was created with, meaning the `from` of `play(from)` or the target of `seek()`. A 60 s looping track that was `seek(58.0)`'d restarted at 58.0 s: the recorded `start()` calls show offset 58.0 twice, 2.04 s apart. It then loops the last 2 s forever. Natively the same stream loops back to `loop_offset`.

**해결:** On the Web, do not `seek()` or `play(from > 0)` a stream that relies on its own loop flag. Either always start loops from 0, or loop by hand: loop flag off, and `play()` again on `finished` (GDT-256).

## GDT-265 — Comparing two `AudioStreamPlayer` positions natively shows one mix buffer (11.6 ms) of phantom drift unless read under `AudioServer.lock()`

`측정 2026-10-05 · Godot 4.7.2-stable, --headless (Dummy audio driver, 44.1 kHz) on the M1 Air`

**증상:** a music track and its stem were started in the same frame and kept in step by a drift check, `layer.get_playback_position() - music.get_playback_position()`. Read every frame, it reported up to 11.6 ms of drift (512 frames, one mix buffer) in 290 samples, although both play from the same mixer. The mixer thread had updated one playback and not yet the other.

Also measured in the same run: under the headless Dummy driver the positions do advance in real time (0.003 s to 1.025 s in 1.2 s). Natively, `seek(music.get_playback_position())` on the stem re-aligned an injected 203 ms offset to 2.9 ms. Two OGGs with the same sample count, both `loop = true`, stayed at 0.0 ms across the loop point.

**해결:** Wrap the two reads in `AudioServer.lock()` / `AudioServer.unlock()`. With the lock the same check read 0.0 ms over 285 frames. One check per second is cheap enough.

## GDT-266 — GDScript 4: `bool(null)` is a runtime error ("Nonexistent 'bool' constructor"), so `bool(settings.get(key))` on a key that was never written breaks the function; a method named `_set` is a parse error because it overrides `Object._set`

`측정 2026-10-05 · Godot 4.7.2 · headless and windowed`

**증상:** `if not bool(Settings.get_value("ui/seen_" + id)):` for a key with no default returned `null`, and every call printed `SCRIPT ERROR: Invalid call. Nonexistent 'bool' constructor.` and abandoned the rest of the function. Here that was the duel screen's `open()`, so the screen opened half set up. In a separate case, a preview script declared `func _set(fields: Dictionary) -> void:` and failed to parse with `The function signature doesn't match the parent. Parent signature is "_set(StringName, Variant) -> bool"`.

**해결:** compare instead of converting: `get(key) != true`, or give the key a default. Do not name a helper `_set`, `_get`, `_init`, `_notification`, `_get_property_list` or another `Object` virtual. Separately, in a draw callback, draw only on the canvas item that is drawing: a helper that draws on a sibling `Control` while the HUD's `draw` signal runs prints `ERROR: Drawing is only allowed inside this node's _draw()...`, and a test gate that greps `^ERROR:` fails while every check passes. Pass the target canvas item into shared draw helpers.

## GDT-267 — Balance a timing-based combat system with bots on a hand-driven clock: a game-time override plus `advance(ms)` runs a minute-long duel in milliseconds, and bot archetypes (skilled, average, masher) turn "too easy" into numbers a test can fail on

`측정 2026-10-05 · Godot 4.7.2 headless · Air (M1)`

**증상:** a parry/timing duel felt too easy, and nobody could say by how much. Real-time end-to-end runs take minutes per fight, and their timing depends on frame jitter.

**해결:** route every game-time read through one `now_ms()` that returns `base + manual_ms` when a test sets `manual_ms >= 0`. Add `advance(ms)`: drain the queued actions, then step the clock in tick-sized increments, calling `_process(0)` and draining again each step. Add a `debug_duel(kind, case)` that skips range and story checks. Give each fight a fresh state node with gear and level set directly; 12 runs × 3 bots × 34 enemies finished in about a minute.

Bots read the state's true blow time (that stands in for the player reading the telegraph) and add N(0, σ) timing error: skilled σ = 50 ms, average σ = 120 ms. The masher presses attack whenever ready and never guards. Assert targets: how many enemy attacks a fight lasts for the skilled bot, the average bot's win rate, the masher's win rate on late bosses, and HP lost by mashing against timing.

The first table exposed three exploits that play-testing had hidden:
- a masher randomly lands one strike per cycle in the "red" window, so penalising only early strikes is not enough; spoil the whole cycle after an early strike;
- a "slow" part effect applied on every jab froze the enemy's meter;
- "pull the meter forward on a jab" capped at 97 % moved an already-due blow later, so rapid jabs held it off for ever.

## GDT-268 — A logo drawn from SVG at run time: `Image.load_svg_from_string` works in the Web (nothreads) template; size it from `get_screen_transform()`, which warns inside a SubViewport

`측정 2026-10-05 · Godot 4.7.2-stable · Web export (nothreads, debug) in Brave 1.96 at DPR 2 and 3.5 · native macOS (Android not yet looked at on a device)`

**증상:** a studio logo shipped as a PNG looked soft on a 3.5x phone and stair-stepped on a desktop that drew it at a quarter of its size. An imported `.svg` is a fixed-size texture too, and the raw `.svg` file is not exported for loading at run time.

Keeping the SVG as a GDScript string constant and rasterising it on layout gives a texture of exactly the pixels it covers: `image.load_svg_from_string(svg, pixels / view_width)`, then `image.generate_mipmaps()` (for a scale-in entrance) and `ImageTexture.create_from_image(image)`. It returned `OK` and drew sharp at 547 px in the Web export at DPR 3.5 and at 300 px at DPR 2, so the official web template carries ThorVG. A 20 KB SVG with clip paths, an even-odd frame and a linear gradient rendered the same as in the editor. The pixel count is `size.x * get_viewport().get_screen_transform().get_scale().x` under `canvas_items` stretch; inside a `SubViewport` used for a capture, that call prints *SubViewport is not a child of a SubViewportContainer. get_screen_transform doesn't return the actual screen position*, so use 1.0 there (`viewport is Window`).

**해결:** store the art as a generated constant (a build script writes both the `.svg` files and the `.gd`), rasterise on `resized`, and only re-rasterise when the pixel count changes. For per-letter animation of a wordmark, rasterise the whole word once and draw each letter with `draw_texture_rect_region` from its own horizontal slice; the letters' ink spans do not overlap, so no slice takes a neighbour's edge. Related: GDT-246.

## GDT-269 — Exponential fog tuned on a landscape preview washes a board out on the phone-portrait camera, which sits farther back

`측정 2026-10-05 · Godot 4.7.2 · Compatibility (GL) · Environment fog (exponential) with aerial perspective 0.35`

**증상:** a floating board got per-map themes (fog colour and density among them). Landscape previews (960 × 560, camera fitted to the board) looked right at `fog_density` 0.006–0.011 with a light lilac or pale-blue `fog_light_color`. In the match on a 390 × 844 portrait view the same board was nearly white: the portrait camera fits the board's width, so it stands about twice as far away, and exponential fog grows with distance. A bright fog colour made it worse than the original warm, darker one at the same density.

**해결:** check every theme in a portrait view, not only the preview. Here densities of 0.0035–0.005 with darker fog colours (`6f5f9a` instead of `b9a8e0`) kept both views readable. A coloured light rig has the same trap: a red sun and red fill on a volcano map turned every element-coloured tile orange; a near-white sun with a cool, weak fill kept the tiles readable and the lava still glowing.

## GDT-270 — A modal UI that eats key events with `set_input_as_handled()` in `_input` can still see a held key: poll `Input.is_action_pressed()` for "hold to fast-forward"

`측정 2026-10-05 · Godot 4.7.2-stable · headless SceneTree test on the Air (M1)`

**증상:** a credits screen wanted "hold confirm to fast-forward" while its UI root turns key events into press-only commands in `_input()` and marks every key event handled, so the game never sees them. Nothing reported the release, and an `_unhandled_input` handler never got the events at all.

The `Input` singleton's action state is updated before the event is dispatched to the viewport, so marking the event handled does not touch it. In a test, `Input.parse_input_event()` of an E press plus `Input.flush_buffered_events()` (GDT-089) kept `Input.is_action_pressed("interact")` true in the screen's `_process` while the UI root consumed the event; the roll moved more than 3× as far in 0.5 s as without the hold, and dropped back to normal speed within 0.4 s of the release event.

**해결:** start the hold from the UI's own press command (so a key still held from before the modal opened does not count), then poll `Input.is_action_pressed()` for every action that means confirm each frame and end the hold when none is down. Touch holds need their own flag from `gui_input` (both the touch and its emulated mouse event arrive, GDT-030; setting the same flag from both is harmless).

## GDT-271 — Windowed `--script` capture on a heavily loaded host saves the same stale frame for several shots in a row, with no error in the log

`측정 2026-10-05 · Godot 4.7.2-stable · GL Compatibility (OpenGL 4.1 Metal, Apple M1 Air) · load average 60–125 from other sessions`

**증상:** a capture harness that switches maps, waits 50–120 frames and saves `root.get_texture().get_image()` produced byte-identical PNGs for the first four shots of a batch (`md5` equal): all four showed the title screen with the map half-drawn behind it, although each shot had entered a different map and the log printed `CAPTURED` for each with no `SCRIPT ERROR`. In another batch the last shot was an exact copy of the one before it (wrong room, wrong boss name). The same shots captured one at a time a few minutes later were correct. Frame counting in `_process` keeps going while the window's presented image does not change, so "wait N frames" is not proof that a new frame was drawn.

**해결:** after a batch, compare the hashes of consecutive shots (`md5 -q *.png`) and recapture any duplicates on their own, or run fewer shots per process when the host is busy. Do not trust a capture batch from a loaded machine without that check. Related: GDT-262.

## GDT-272 — Godot 4.7 iOS export on a personal (free) Apple team fails with "Your team has no devices"; build the Xcode project it leaves behind against the USB device instead
`측정 2026-10-05 · Godot 4.7.2 · Xcode 27.0 · iPad mini 5 (iPadOS 26.3.1) · personal team, 7-day profiles`

**증상:** `godot --headless --export-debug iOS out.ipa` with `application/app_store_team_id` and `export_method_debug=1` writes the Xcode project, then its archive step stops with
`error: Communication with Apple failed: Your team has no devices from which to generate a provisioning profile.` and
`No profiles for '<bundle id>' were found`, then `ERROR: Project export for preset "iOS" failed.` The iPad was plugged in and `devicectl list devices` showed it `available (paired)`. Godot archives for a generic destination, so Xcode never registers the connected device to the team.

**해결:** keep the `<name>.xcodeproj` the failed export wrote next to the .ipa path and build it yourself for the device:
`xcodebuild -project <name>.xcodeproj -scheme <name> -configuration Debug -destination id=<UDID> -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=<team> CODE_SIGN_STYLE=Automatic build`
→ `BUILD SUCCEEDED`, the device is registered, and `xcrun devicectl device install app --device <UDID> <derivedData>/Build/Products/Debug-iphoneos/<name>.app` installs it.
The first launch on that device still fails with `FBSOpenApplicationErrorDomain error 3`, "profile has not been explicitly trusted by the user", and the iPad shows "신뢰하지 않는 개발자". Trust is a tap on the device (Settings > General > VPN & Device Management > the Apple Development certificate > Trust); no `devicectl` command does it, and launching Settings with `--payload-url 'prefs:root=General&path=ManagedConfigurationList'` only lands under the untrusted-developer alert. Trust is per developer certificate, so one tap covers every app signed with it on that device.

## GDT-273 — iOS export: with `boot_splash/show_image=false` the launch screen still shows Godot's logo and "Game engine"; set the preset's `storyboard/*` images, and uninstall before judging (iOS caches it)

`측정 2026-10-05 · Godot 4.7.2-stable · iOS export (debug, Xcode 27) · iPad mini 5, iPadOS 26.3.1 · devicectl screenshots every ~0.55 s`

**증상:** a project with `boot_splash/show_image=false` and a white `boot_splash/bg_color`, so its Android and web starts are plain white, opened on the iPad with the Godot robot and the words *Game engine* centred on white for about four seconds while the engine loaded, before the game's own studio ident. The exported `Launch Screen.storyboard` takes `SplashImage` from `Images.xcassets`, and with no image configured the export fills it with Godot's default splash.

**해결:** in the iOS preset set `storyboard/custom_image@2x` and `storyboard/custom_image@3x` to a transparent PNG (4×4 is enough), `storyboard/use_custom_bg_color=true` and `storyboard/custom_bg_color` to the first frame's colour. The exported `SplashImage.imageset` then holds that PNG and the launch is white → ident. iOS keeps the old launch screen of an installed app, so `xcrun devicectl device uninstall app` before installing the new build. Related: GDT-244 (the Android side of the same white start).

## GDT-274 — Godot 4.7 on iPadOS: a number pad opened by a LineEdit floats over the UI and is gone for good once code moves focus to the next LineEdit; draw your own keypad
`측정 2026-10-05 · Godot 4.7.2 · iPad mini 5 (iPadOS 26.3.1) · landscape · LineEdit.virtual_keyboard_type = KEYBOARD_TYPE_NUMBER`

**증상:** a date form of three LineEdits (year, month, day) moved focus with `next.grab_focus()` from `text_changed` once the year had 4 digits. On the iPad the number pad did not dock at the bottom: it floated as a small panel in the top-left corner over the title. After the 4th year digit the pad disappeared and did not come back, so the month could not be typed and the form could not be finished. The same build on Android (Pixel 7 Pro) kept its keyboard across the focus move. Which call loses the keyboard (focus exit hide vs. focus enter show) was not isolated.

**해결:** on touch devices set `LineEdit.virtual_keyboard_enabled = false` and draw a 3 x 4 keypad of Buttons with `focus_mode = FOCUS_NONE` (so a key press does not take focus from the field). Append the digit to the focused field yourself and call your `text_changed` handler, because setting `text` from code does not emit `text_changed`. Make the last key "Next", turning into "Confirm" on the last field. On a Pixel 7 Pro, `adb shell input tap` on the keys typed 1990-07-15, deleted, advanced focus and submitted. The system keyboard no longer appears on iOS or Android.

## GDT-275 — Once a device is registered to the personal team (GDT-272's xcodebuild), a plain headless iOS export writes a working .ipa for any new bundle id

`측정 2026-10-05 · Godot 4.7.2 · Xcode 27.0 · iPad mini 5 · personal team UXJJ94BPC2`

**증상:** a second project (new bundle id `com.mnori.monsterworld.dev`, never built before) was exported with `godot --headless --export-debug iOS build/ios/<name>.ipa`, `application/app_store_team_id` set and `export_method_debug=1`. Unlike GDT-272 the export exited 0 and wrote the .ipa and .xcarchive; Xcode generated the new App ID's profile on its own because the iPad had been registered to the team by an earlier `-allowProvisioningDeviceRegistration` build of another project.

**해결:** `xcrun devicectl device install app --device <UDID> <name>.ipa` then `xcrun devicectl device process launch --device <UDID> <bundle id>` launched it with no trust prompt (the developer certificate was already trusted on that iPad). `idevicescreenshot` cannot capture it ("Could not start screenshotr service") because the developer disk image is not mounted; check the app is alive with `xcrun devicectl device info processes --device <UDID>` instead. Related: GDT-272.

## GDT-276 — macOS with a 1× monitor beside 2× (Retina) screens: the Godot window on the 1× monitor is in 2× pixels, yet `screen_get_scale()` returns 1.0

`측정 2026-10-05 · Godot 4.7.2-stable · gl_compatibility · macOS 27 · M1 Max with a 4K portrait screen at 2×, the built-in Liquid Retina XDR at 2×, and a Dell S2721DS 2560 × 1440 at 1×`

**증상:** a game that scaled its UI from the window's pixel size (`factor = clamp(min(w / 1440, h / 900), 0.9, 1.35)`) showed tiny text when maximized on the Dell. Measured with a `--script` that maximized the window on each screen:
- Dell (screen 2): `screen_get_usable_rect` = 5120 × 2820, `screen_get_scale` = **1.0**, maximized `window_get_size()` and the framebuffer (`get_texture().get_image()`) = **5120 × 2756**. macOS reports that window as 2560 × 1410 points.
- Built-in Retina (screen 1): usable 3456 × 2168, scale 2.0, maximized window 3456 × 2104.
- `screen_get_size(2)` = 5120 × 2880 and the screen positions are in the same doubled units. Godot uses the highest scale of all screens for every screen's coordinates.

So `window size / screen_get_scale()` does not give points on the 1× monitor: the window is 2× too large, and a capped UI factor leaves the layout 3793 units wide.

**해결:** scale the UI in proportion to the window (`factor = min(w / 1440, h / 900)` with no low upper cap, then lay out at `size / factor`). That gives the same 1440 × 900-shaped layout on every screen, whatever unit the window reports. Do not rely on `screen_get_scale()` to convert to points on a mixed-DPI desktop. The 1× monitor also renders 4× the pixels it shows (14 MP for a 2560 × 1440 panel). Related: GDT-090.

## GDT-277 — Drag-to-scroll that also starts on buttons (the fix for GDT-204): watch the touch in `_input`, and let a release that ended a scroll reach the button but do nothing

`측정 2026-10-05 · Godot 4.7.2-stable · headless SceneTree test with injected `InputEventScreenTouch` / `InputEventScreenDrag` (emulate_mouse_from_touch on) · Air (M1)`

**증상:** a page taller than a phone screen had to scroll under a finger. Most of its surface is tiles and buttons, and a `ScrollContainer` does not pan when the drag starts on one of them (GDT-204).

**해결:** do the scrolling yourself in `_input()` of the screen that owns the page. `_input` sees the `InputEventScreenTouch` / `InputEventScreenDrag` before the GUI gets the emulated mouse events for the same finger. Once the drag passes a small threshold (here 12 px of the scaled page, mostly vertical), mark the touch as a scroll with a global flag and move the page by the drag's delta. Keep a velocity from the last drag steps and let it decay for a glide (`v *= exp(-dt * 3.5)`), and drop it if the finger rested more than 90 ms before lifting. Do not swallow the emulated mouse press or release. Make every control under the finger act on the **release** for touch (the emulated mouse events carry `device == InputEvent.DEVICE_ID_EMULATION`, GDT-030) and skip the action when the flag is set. A real mouse keeps acting on press. Clear the flag on the next touch press. Give pressable controls a `cancel_press()` (spring back the scale, put a slider back to its value at the press) and call it on the subtree when the scroll starts. Turn off focus-on-hover (`NOTIFICATION_MOUSE_ENTER`) on touch, or the emulated motion moves the focus along the drag path.

Measured: a 260 px drag that started on a tool tile scrolled the page and left the selection as it was. A drag that started on an equip button scrolled and equipped nothing. A tap on the same tile or button selected or equipped it. A 9 px wobble during a tap stayed a tap. A 300 px flick kept moving the page after the lift. Keyboard focus was scrolled into view separately: after each focus move, compare the focused control's rect with the clip and tween the scroll.

## GDT-278 — Binding `JOY_BUTTON_A` / `JOY_BUTTON_B` into `ui_accept` / `ui_cancel` at run time makes a focused `Button` press on A, and B arrives in `_unhandled_input` past it (extends GDT-132)

`측정 2026-10-05 · Godot 4.7.2-stable · windowed --script test with InputEventJoypadButton (device 0) parsed into Input · Air (M1)`

**증상:** with Godot 4.7's defaults a gamepad moves the focus (the d-pad and left stick are in `ui_up/down/left/right`) but A and B do nothing (GDT-132), so a menu built from ordinary `Button`s cannot be confirmed or left with a pad.

At start, `InputMap.action_add_event("ui_accept", e)` with `e = InputEventJoypadButton.new()`, `e.button_index = JOY_BUTTON_A`, **`e.device = -1`** (all pads), and the same for `JOY_BUTTON_B` into `ui_cancel`. Then an A press and release from pad 0 presses the focused `Button` (`pressed` emitted on the release, `button_down` on the press, like Enter). B is not used by a focused `Button`: it reaches `_unhandled_input` as `event.is_action_pressed("ui_cancel")`, the same as Esc, so one handler serves both. Custom actions for Start, LB/RB and Y were added the same way (`InputMap.add_action` first). Buttons created with `focus_mode = FOCUS_NONE` (common for mouse-first UIs) need `FOCUS_ALL` while a pad drives.

**해결:** bind A/B at run time as above, and give focus only to the controls of the topmost card or screen while the pad drives (set `FOCUS_ALL` on them and `FOCUS_NONE` on every other visible control, remembering each one's original mode). Measured in one run: A opened the map, a stage card and a match from focused buttons, B closed the card and the map with the focus restored to the button that opened them, a held d-pad repeated through `InputEventAction` presses (GDT-182), and a mouse motion of more than 3 px returned every control to its original mode with no focus left. `Control.get_global_rect()` includes the control's `scale`, so a focus ring drawn in a separate `CanvasLayer` stays on panels scaled to fit a short screen.

## GDT-279 — Web export: the scripted gamepad of GDT-248 also works when installed after the engine has booted, without an init script or a click

`측정 2026-10-05 · Godot 4.7.2-stable Web export (debug) · Brave 1.96 headless=new via raw CDP · Air (M1) · 1280×720, 844×390 and 390×844`

**증상:** GDT-248 installs the fake pad with Playwright's `page.addInitScript` and clicks the page before `gamepadconnected`. A raw-CDP check (`Runtime.evaluate` only) has no init-script helper and no reason to click.

After the game's first screen was up, one `Runtime.evaluate` that assigned `navigator.getGamepads = () => [pad, null, null, null]` and dispatched `new Event('gamepadconnected')` with `e.gamepad = pad` was enough: the engine's polling read `pad.buttons[i] = {pressed, touched, value}` changes (standard index 0 → `JOY_BUTTON_A`, 1 → B, 9 → Start, 12–15 → d-pad) in all three window sizes. A press held 110 ms followed by 260 ms released was seen exactly once per press, at a machine load of 2.3–4.9 per core.

**해결:** for a CDP-only check, install the pad late in one evaluate and replace the whole button object on each change. Related: GDT-248, GDT-278.

## GDT-280 — A Nakama realtime client in pure GDScript (no nakama-godot): HTTPRequest + WebSocketPeer polled in `_process`, a duck-typed socket var so unit tests inject a fake

`측정 2026-10-05 · Godot 4.7.2-stable headless (macOS arm64) · Nakama 3.40.0 JS runtime · ~760 lines`

**증상:** a native build needed the same behaviour as a hand-written browser client (device auth, REST RPC, `match_join`, op codes, reconnect with backoff), and nakama-godot brings its own adapter whose HTTP path can freeze a frame (GDT-022) and whose joins have no deadline (GDT-025).

The port that passed 135 checks (unit + two clients against a real Nakama, 4 runs, 0 failures):
- **Promises:** a small `RefCounted` with `signal done`, `resolve()`/`reject()` and `func wait(): if not finished: await done`. Coroutines `await waiter.wait()`; `_process` rejects waiters past their deadline. Signal emission resumes the awaiting coroutine synchronously, so a `disconnect()` that rejects pending waiters runs the cancelled branches before it returns — give every connect a generation number and check it after each `await`.
- **HTTP:** one `HTTPRequest` child per call with `timeout`; `cancel_request()` emits nothing, so reject the waiter yourself. A port nobody listens on gives `RESULT_CANT_CONNECT` at once; a local `TCPServer.listen()` that never accepts gives `RESULT_TIMEOUT` — both make offline failure tests.
- **Wire:** Nakama's JSON socket sends `op_code` as a string and `data` as standard base64; `Marshalls.utf8_to_base64(JSON.stringify(payload))` for `match_data_send`. JSON numbers come back as floats, so `Number.isInteger`-style checks must accept integral floats and convert with `int()`. Pre-check base64 with a regex before `Marshalls.base64_to_raw` to keep junk frames quiet. In `RegEx`, use `\z` rather than `$` to match JS anchors (PCRE `$` also matches before a final `\n`).
- **Close:** `close()` finishes in later `poll()`s (GDT-194): keep closed peers in a retiring list polled until `STATE_CLOSED`, or the `match_leave` queued before `close()` never leaves. Real-server check: the other player saw the leave.
- **Tests:** declare the socket as an untyped `var _socket: Variant` and the test can drop in a `RefCounted` with `poll/get_ready_state/get_available_packet_count/get_packet/send_text/close`, then put the client in the connected state and feed envelopes — throttle, heartbeat, `match_lost` and backoff cases run in ~3 s with no server.
- Measured: op 2 at 18–20 messages per second headless against a 20 Hz match loop.

## GDT-281 — `export_filter="all_resources"` does pack `.json` files: a 4.7.2 macOS `--export-pack` listed a JSON that no include filter named

`측정 2026-10-05 · Godot 4.7.2-stable, godot --headless --export-pack macOS (Air, M1)`

**증상:** a desktop build reads `res://native/audio/manifest.json` at run time, and it was unclear whether a preset with `export_filter="all_resources"` and no matching `include_filter` ships it (GDT-216 says it does not, from a build that was never run).

Measured: the macOS preset had `include_filter="assets/characters3d/projection.json"` only. The pack's file table (`strings probe.pck`, between `shaders/wind.gdshader` and the next binary block) still listed `tools/roster_projection.json`, while the `.py` files in the same `tools/` folder were absent. In Godot 4 `JSON` is a resource type, so `all_resources` picks `.json` up like any other resource.

**해결:** no include filter is needed for `.json` under `all_resources`. Read it with `FileAccess.get_file_as_string("res://…json")`, or `load()` it and use `(res as JSON).data`. To check a pack, run `--export-pack <preset> out.pck` (no export templates needed) and grep the path without `res://` in `strings out.pck`; a path inside a script literal carries `res://`, a file-table entry does not.

## GDT-282 — Pre-render a WebAudio synth for a native Godot build: capture OfflineAudioContext buffers by subclassing, loop files as "second loop of two", and test the Vorbis loop seam with `AudioStreamPlayback.mix_audio()`

`측정 2026-10-05 · Godot 4.7.2-stable --headless (Dummy driver) · Brave 1.96 headless (Playwright 1.63) · oggenc (libvorbis) -q 5`

**증상:** a game's music and effects exist only as a procedural WebAudio engine; the desktop build needs files, and tempo changes (hurry-up x1.25) must not change pitch, so `pitch_scale` is out for music.

What worked (24 loop files, 9 jingles, 81 effects, 9.74 MiB at -q 5, 58 checks passing):
- **Capture without editing the engine:** before loading it, replace `window.OfflineAudioContext` with `class extends Base { startRendering() { return super.startRendering().then(b => (window.__last = b, b)); } }`. An engine that resolves the constructor at render time then hands every buffer over. Move it to Node as base64 of an interleaved `Float32Array` (tens of MB per call were fine).
- **Seamless loops with reverb and echo:** render from beat 0 for two loop lengths and keep only `[L, 2L)`. The tails of the loop's end are then already inside its start. Measured seam step in the WAV: 0.0000-0.0112 against a 99th-percentile neighbour step of 0.009-0.078.
- **Tempo variants:** one file per (bpm x rate) the game can send; variants with the same product (96 x1.25 = 120 x1) render bit-identically, so alias them (3 of 27 files saved). Switch variants by crossfading 60 ms to the new file at `beat / (beats / loop_seconds)`.
- **Vorbis keeps the loop:** after oggenc -q 5, `stream.get_length()` matched the WAV frame count within 2 ms and the decoded wrap stayed sample-aligned (located shift 0 or +1 frame).
- **Seam test in Godot:** `var pb := stream.instantiate_playback(); pb.start(len - 0.02); var buf: PackedVector2Array = pb.mix_audio(1.0, 1764)` decodes across the loop point headless (`loop = true`). Locate the wrap by matching the first 64 frames of `start(0.0)`, then compare the step at the wrap with the 99th percentile of neighbouring steps. Worst file: 0.39x of p99.
- Effects rendered at v=1 through the engine's own limiter were limited separately from the music; one `AudioEffectHardLimiter` on Master stands in for the shared web limiter.

**해결:** keep the browser engine as the single source and render it; do not port a synth. Render on a host with a browser, encode anywhere, write minimal `.ogg.import` sidecars with `loop=true` for loops (GDT-120), and set `AudioStreamOggVorbis.loop` at run time as well.

## GDT-283 — A GDScript `_get_minimum_size()` override on a Button subclass is ignored; push the size into `custom_minimum_size`

`측정 2026-10-05 · Godot 4.7.2-stable (macOS, Compatibility renderer)`

**증상:** a custom button (`extends Button`, flat, its icon and label drawn by a child HBoxContainer) collapses to a few pixels in an HBoxContainer: a 6 px tall sliver with the label spilling out. The script's `func _get_minimum_size() -> Vector2` returns the right size and is never called.

The virtual `_get_minimum_size()` is only consulted by `Control::get_minimum_size()`. `Button` (like other native controls with their own sizing) overrides `get_minimum_size()` in C++ from its text, icon and stylebox, so with empty text and `StyleBoxEmpty` its minimum is near zero whatever the script says. `Container` subclasses written in GDScript are not affected: there `_get_minimum_size()` works.

A second trap in the same setup: the child box's minimum size changes (text set later) do not reach the button, because Button is not a Container.

**해결:** compute the size yourself and set `custom_minimum_size = Vector2(content.get_combined_minimum_size().x + padding, height)`; call it from `content.minimum_size_changed` and after every text change. Keep any caller-imposed width in a separate variable and take the max, or the next refresh overwrites it.

## GDT-284 — Containers reset their children's rotation and scale; wrap a tilted child in a one-child Container

`측정 2026-10-05 · Godot 4.7.2-stable`

**증상:** a badge or logo given `rotation_degrees = -3` inside an HBox/VBox (or a PanelContainer) shows upright. Scale tweens on the same child snap back when the container re-sorts.

`Container.fit_child_in_rect()` sets the child's rotation to 0 and scale to 1 as well as its rect, on every sort (resize, child added, minimum size changed).

**해결:** put the tilted node inside a tiny `Container` subclass whose `NOTIFICATION_SORT_CHILDREN` calls `fit_child_in_rect(child, Rect2(Vector2.ZERO, size))` and *then* sets `child.pivot_offset = size * 0.5` and `child.rotation_degrees`; return the child's combined minimum size from `_get_minimum_size()`. Short scale "bump" tweens are fine as long as nothing re-sorts mid-tween.

## GDT-285 — Per-pixel hash noise in world shaders costs 5–7 ms a frame on an M1; a baked 256² noise texture removes it

`측정 2026-10-05 · Godot 4.7.2-stable · Compatibility renderer · MacBook Air M1, 1440 × 900 window at 2x`

**증상:** a stylised 3D scene whose ground, model and water shaders build their detail from `fract(sin(dot(p, …)) * 43758.5)` value noise (several octaves of fbm plus a 3 × 3 Voronoi for cobbles and leaf clumps) runs at 28–33 ms a frame natively and 23–33 fps in the browser. Halving `scaling_3d_scale` saves about 10 ms, so the frame is fragment-bound, not vertex- or draw-call-bound (120–160 draw calls).

Replacing the procedural functions with reads from one tileable RGBA texture (R value noise, G distance to the nearest Voronoi point, B 4-octave fbm, A Voronoi edge distance, 256 × 256, mipmapped, bound once as a `global uniform sampler2D` in `[shader_globals]`) gave, on the same scenes:

| scene | hash noise | baked texture |
|---|---|---|
| forest | 32.9 ms | 27.8 ms |
| farm | 27.7 ms | 21.5 ms |
| town | 28.1 ms | 23.7 ms |

The same build in headless Brave 1.96 on that Air then measured 54–61 fps at 1440 × 900 (from 23–38). Mipmaps also stop distant noise from shimmering.

Two related costs measured in the same pass: a full-screen `hint_screen_texture` post pass (9-tap blur and vignette on a camera quad) cost 7–9 ms; the directional shadow pass cost 4–8 ms, mostly from props far from the player, cut by turning off `cast_shadow` for scenery beyond the playable map.

**해결:** bake the noise once (numpy, a few lines; keep the lattice periodic so it tiles) and sample it at the frequency the old function had (`texture(noise_tex, p / 16.0)` for a 16-cell texture). Prefer UI-layer gradients over screen-texture post passes for vignettes.

## GDT-286 — Check what VoiceOver reads in a Godot macOS app without any Accessibility permission: dump NSAccessibility in-process from a class-less GDExtension

`측정 2026-10-05 · Godot 4.7.2-stable (editor binary and exported app), AccessKit driver · macOS on M1 test host over ssh, console locked`

**증상:** reading another app's accessibility tree needs the caller to be trusted (System Events from ssh sees 0 windows; Terminal waits on a prompt; OPS-363 for VoiceOver itself on a locked console), so a remote session cannot confirm what VoiceOver will say.

What worked:
- A GDExtension with no classes: the entry symbol only fills `GDExtensionInitialization` (`minimum_initialization_level = 2`, `initialize`/`deinitialize` callbacks) and returns 1. At level 2 it `dispatch_after`s an Objective-C walk of `[NSApp windows]` → `accessibilityChildren` (role, `accessibilityTitle`, `accessibilityValue`, frame) and `[NSApp accessibilityFocusedUIElement]` to a file every 2 s. Built with `xcrun --sdk macosx clang -dynamiclib -fobjc-arc -arch arm64 -framework Cocoa`, a 4-line `.gdextension` (`entry_symbol`, `compatibility_minimum`, `macos = "res://…dylib"`) and one `--import`. In-process calls need no TCC trust.
- Run with `godot --accessibility always`. On a locked console the window is never focused and the focused element stays empty until `DisplayServer.accessibility_set_window_focused(DisplayServer.MAIN_WINDOW_ID, true)`.
- Result on a Godot UI: a focused `Button` is `AXButton` whose `accessibilityTitle` is `accessibility_name` (or its text); `HSlider` → `AXSlider`; a `toggle_mode` Button → `AXCheckBox`; `Label` → `AXStaticText` with the text as value. That is what VoiceOver speaks on focus.

Traps it found:
- `AudioStreamPlayer` nodes under a `CanvasLayer` appear as empty `AXGroup`s titled with the node name (`Sfx0`…); 3D nodes and players under a `Node3D` do not. Parent audio nodes outside UI layers.
- Stacked Labels used for one visual (outline layer, fill layer) are each a separate `AXStaticText`: a two-letter logo read as six. Draw decorative layers with `draw_string`/`draw_string_outline` and leave one Label (alpha 0 is fine) for the name.
- The root group's `accessibilityChildren` kept only the controls visible at start (6), while controls shown later (menu after a "press any key" gate, modal sheets) were still reported correctly as the focused element with that group as parent. `queue_accessibility_update()` on every node and hiding/showing the UI root did not change the list. Focus-follow reading works; VoiceOver's free cursor browsing (VO+arrows) may not reach later-shown controls in 4.7.2.

**해결:** keep the probe as a test-only tool outside the shipped project (copy it into a scratch copy's `game/`), drive focus from a `--script` tour, and compare the dumped focused titles with the names the UI sets. Example: KIDS repo `tests/a11y-probe/probe.m` + `game/tests/native_a11y_tour.gd`.

## GDT-287 — Switching a Label to `AUTOWRAP_WORD` does not stop Korean breaking between syllables, and an autowrapping Label in a shrink-centred PanelContainer collapses to one glyph per line

`측정 2026-10-05 · Godot 4.7.2-stable · gl_compatibility · Noto Sans KR · 390 × 844 layout`

**증상:** a centred prompt "영지 명령 · 내 영지를 고르세요" in a 230 px pill wrapped as "영지 명령 · 내 영지를 고" / "르세요". Moving from `AUTOWRAP_WORD_SMART` to `AUTOWRAP_WORD` kept the same break. The cause is the syllable-level break from GDT-104, and the autowrap mode does not change it. `Font.get_multiline_string_size(..., TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)` measures the same breaks.

A second trap showed up in the same pass. An autowrapping Label inside a `PanelContainer` with `SIZE_SHRINK_CENTER` gets a minimum width of about one glyph. The pill then drew "예상: 점령" as a tall column of single syllables.

**해결:** use GDT-104's WORD JOINER for prose. For a short UI line, keep it on one line when it fits; otherwise replace your own separator with a newline (`text.replace(" · ", "\n")`) and size the panel from `get_string_size` of each line. Turn autowrap off on short status pills.

## GDT-288 — `Dictionary.merge(data)` keeps the existing value on a key clash, so an event payload's `"kind"` is silently dropped under the envelope's `"kind"`

`측정 2026-10-08 · Godot 4.7.2-stable · GDScript`

**증상:** a simulation built events as `var event = {"id": n, "kind": event_type}` then `event.merge(data)`. An item pickup sent `{"kind": "P", "pos": ...}` as its data. Every consumer that read `event["kind"]` for the item got `"item"` (the event type) instead. The pickup popup fell through its `match` and showed the word "item" for months. No error or warning is printed.

`merge(dictionary, overwrite := false)` only adds keys the target lacks. A payload key equal to an envelope key (`kind`, `id`, `type`) loses without a sound.

**해결:** never reuse envelope key names inside payloads (here the payload key became `"item"`). If the payload must win, call `merge(data, true)`, but then a payload can overwrite the event type. A one-line check in the event helper catches the clash early: `assert(not data.has("kind"))`.

## GDT-289 — Web export sample playback honours `pitch_scale`: it becomes the `AudioBufferSourceNode.playbackRate` (pitch and length change together)

`측정 2026-10-08 · Godot 4.7.2-stable Web export (nothreads template), Brave 1.96 headless on an M1 MacBook Air`

**증상:** none; the question is whether a semitone ladder of `pitch_scale` on short effects (chain reactions, streaks) works on the Web, where `audio/general/default_playback_type.web` is Sample and bus effects are not applied to samples (GDT-097).

It works. The engine JS (`GodotAudio.SampleNode` in the exported `index.js`) receives the player's `pitch_scale` as the `pitchScale` start option of `godot_audio_sample_start`, and `_syncPlaybackRate()` sets `source.playbackRate.value = playbackRate (1) * pitchScale` before `start()`. A later change of `pitch_scale` on a playing player goes through `godot_audio_sample_update_pitch_scale` to the same place.

Measured with an `addInitScript` hook on `AudioBufferSourceNode.prototype.start` that records `this.playbackRate.value` and the `ended` time, for `AudioStreamPlayer2D` voices with `pitch_scale` set before `play()`: 9 of 9 sources started at exactly the requested rate (1.0, 1.0595, 1.5, 2.0, 1.1225, 0.75; jittered 0.9911 and 1.0141 where the game asked for 1.0). A 0.26 s buffer played 0.299 / 0.272 / 0.229 / 0.165 s at rates 1 / 1.0595 / 1.5 / 2 (the `ended` event arrives about 35-40 ms late on the main thread, so the steps, not the absolute times, are the signal).

As with `playbackRate` everywhere in WebAudio, this is resampling: a sound pitched up is also shorter. A timed sound (one whose end must land on a beat or a reveal) must not be pitched or jittered.

**해결:** set `pitch_scale` on the voice before `play()`; nothing Web-specific is needed. Also: a probe scene under a folder listed in the export preset's `exclude_filter` exports fine and then fails at boot with `Cannot open file 'res://…/probe.tscn'` and `Failed loading scene`; drop that folder from the filter in the sandbox copy that builds the probe.

## GDT-290 — A windowed capture script that waits N frames misses tween-driven moments on a loaded host: at load average 100 an M1 Air rendered one frame per 180–600 ms

`측정 2026-10-08 · Godot 4.7.2-stable, gl_compatibility, windowed capture on an M1 MacBook Air shared by several sessions`

**증상:** a screenshot harness (a `SceneTree` script that counts `_process` frames, triggers an effect N frames before saving `root.get_texture().get_image()`) showed nothing for an 0.8 s tween (a chest trembling while light leaks out). The same harness showed particle effects and simulation results fine. The log timestamps explained it: 36 frames took 6.6 s, so the tween had finished long before the capture. Under the same load the next run took 1.3 s for those frames. Frame counts are not time; tweens, timers and `Time`-driven shaders run on real time, while physics-driven game state (60 Hz steps) and particles advance per frame.

**해결:** stamp the trigger with `Time.get_ticks_msec()` and capture when the elapsed real time reaches the moment you want (set the frame counter to 0 then, not 1, or the countdown never reaches the capture branch). For a still of a short real-time effect, call it with a much longer duration in the harness (6 s instead of 0.8 s) and capture at the fraction you want; the image no longer depends on the frame rate. Print the timestamps of the trigger and the capture so a reader can see the real gap.

## GDT-291 — Web export art fetched with `HTTPRequest` fails with `Result 13` (TIMEOUT) when the shared test Mac sits at load average ~70; the same build passes at ~50, so check `uptime` before calling it a regression

`측정 2026-10-08 · Godot 4.7.2-stable web export (Compatibility), Brave 1.96 (Chromium 154) driven by Playwright on an M1 MacBook Air shared by several sessions, art served by vite preview`

**증상:** a browser test that fails on any console warning failed twice in a row with exactly four lines, `WARNING: art failed: arcana/pierrot.webp (HTTP 0 / result 13)` and three more (the first textures the stage asks for at setup). The stage loads art with one `HTTPRequest` per file and `timeout = 25.0`; `13` is `HTTPRequest.RESULT_TIMEOUT`. `uptime` on the host read load averages 68–71 during both runs. The previous build of the same project passed the same spec at load ~51, and so did the new build when rerun at ~50 (42.8 s). Nothing in the change touched art loading. On a saturated M1 the page's main thread (Godot's loop and the fetches it polls) and the node preview server both stall long enough that 25 s is not enough for the first burst of parallel requests.

**해결:** when a web-export test fails only on `art failed … result 13` (or other `HTTPRequest` timeouts), run `uptime` on the host first. Above ~60, rerun when it drops instead of debugging the change; to prove the point, run the same spec on the pre-change tree under the same load. Report which load each run saw.

## GDT-292 — A test bot that budgets a fight in frames (`t += 1.0 / 60.0` per `process_frame`) loses game time to every `Engine.time_scale` hit-stop; count `dt * Engine.time_scale` instead

`측정 2026-10-08 · Godot 4.7.2-stable, windowed SceneTree bot on an M1 MacBook Air shared by several sessions (load average 86–104)`

**증상:** a mine-boss playtest bot gives each boss a budget of 180 "seconds" by adding `1.0 / 60.0` per awaited `process_frame`. After the game gained hit-stops (`Engine.time_scale = 0.05` for 35 ms of wall time on a sword hit, 75 ms on a crit, 50 ms on a kill, restored by a node that reads `Time.get_ticks_msec()`), one boss with many minions (803 strikes, 129 dodge rolls in the fight) was left at 94 of 360 HP when the budget ran out (no run of the bot without hit-stops was made on that day to compare). On a loaded host one frame takes far longer than a hit-stop, so every hit-stop scales one whole frame's delta by 0.05: the frame is counted in the budget but the world barely moves.

**해결:** advance the bot's clock by game time, `t += dt * Engine.time_scale`, so a held world does not spend the budget. With that change the same boss went down at 117.2 game-seconds and all six bosses passed (`PLAY_MINES 0 failures`). The same applies to anything a test waits on by counting frames while the game uses time-scale effects (slow motion, hit-stop); wall-clock waits (`create_timer(s, true, false, true)`) are not affected by the scale.

## GDT-293 — `tween_property(node, "rotation:y", atan2(d.x, d.z), t)` spins the long way: an NPC set to face west (yaw 3π/2) turned a full circle to face a player on its left

`측정 2026-10-08 · Godot 4.7.2-stable · GDScript Tween`

**증상:** talking to an NPC made it spin almost 360° before facing the player (owner's report: "아빠가 이유없이 한바퀴 돕니다"). The NPC's model yaw was set from an 8-way facing (`f * PI / 4`, so west is 4.71 rad); `atan2` returns -π..π (-1.57 for the same direction). A Tween interpolates the raw numbers, 4.71 → -1.57: 6.28 rad, one full turn. `lerp_angle` handles the wrap, but `tween_property` on a rotation property does not.

**해결:** tween to the nearest equivalent angle: `var want := model.rotation.y + wrapf(target - model.rotation.y, -PI, PI)`, then tween to `want`. Same for any angle you tween (rotation.x/z, a camera yaw). Per-frame code can keep using `lerp_angle`.
