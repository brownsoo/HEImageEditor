# HEImageEditor 사용자 테스트 케이스 (Manual QA)

> 대상: `Sources/HEImageEditor`
> 자동화하기 어려운 편집 UI / 제스처 / 이미지 처리 플로우를 실제 기기·시뮬레이터에서 수동 검증하기 위한 시나리오 목록.
> 형식: **Given(전제) → When(동작) → Then(기대결과)**

---

## 1. 편집기 진입 / 페이징

### TC-NAV-01 단일 이미지 진입
- Given: `imageStore`에 이미지 1장
- When: `HEImageEditorViewController`를 표시
- Then: 이미지가 화면에 맞게(scaleAspectFit) 표시되고 상단 인덱스가 `1 / 1`

### TC-NAV-02 다중 이미지 페이징
- Given: 이미지 3장
- When: 좌우로 스와이프
- Then: 페이징 단위로 이동하고 인덱스 라벨이 `2 / 3` 등으로 갱신된다

### TC-NAV-03 initialIndex 진입
- Given: `initialIndex = 2`, 이미지 5장
- When: 진입
- Then: 3번째 이미지로 스크롤된 상태로 시작

### TC-NAV-04 취소
- When: 좌상단 취소 버튼 탭
- Then: `didCancelEditImages` 호출 후 화면 pop/dismiss

### TC-NAV-05 완료
- When: 우상단 완료 버튼 탭
- Then: `didFinishEditImages` 호출

---

## 2. 도구 노출 (tools)

### TC-TOOL-01 기본 도구 노출
- Given: 기본 설정
- Then: 하단 툴바에 텍스트/스티커/자르기/필터/모자이크/색감/그리기 노출

### TC-TOOL-02 이미지 스티커 트레이 미설정
- Given: `tools`에 `.imageSticker` 포함하지만 `imageStickerTray == nil`
- Then: 스티커 도구가 자동으로 숨겨진다(런타임 제거)

### TC-TOOL-03 도구 커스터마이즈
- Given: `config.editImageTools([.clip, .filter])`
- Then: 지정한 두 도구만 노출

---

## 3. 자르기 / 회전 (Clip)

### TC-CLIP-01 비율 적용
- When: 자르기 진입 → 1:1 / 3:4 / 16:9 등 선택
- Then: 크롭 프레임이 해당 비율로 고정

### TC-CLIP-02 원본 비율
- When: `original` 선택
- Then: 원본 비율로 크롭 영역 복원

### TC-CLIP-03 자유 비율 (custom)
- When: `custom` 선택 후 핸들 드래그
- Then: 자유롭게 크롭 영역 조정 가능

### TC-CLIP-04 동그랗게 (circle)
- When: `circle` 선택
- Then: 1:1로 고정되고 원형 마스크로 표시

### TC-CLIP-05 회전
- When: 회전 버튼/슬라이더로 각도 변경
- Then: 이미지가 해당 각도(라디안 변환)로 회전

### TC-CLIP-06 상태 보전 경고 (allowClipWithoutKeepingState)
- Given: 스티커/텍스트가 이미 적용됨, `allowClipWithoutKeepingState = false` 흐름
- When: 자르기/회전 시도
- Then: `alert_clipping_without_state` 경고가 노출되고, 진행 시 이전 스티커/텍스트는 수정 불가 상태로 합쳐진다

---

## 4. 필터 (Filter)

### TC-FILTER-01 필터 목록
- When: 필터 진입
- Then: Normal 포함 16종 필터 썸네일 노출

### TC-FILTER-02 필터 적용
- When: Sepia / Noir / Clarendon 등 선택
- Then: 미리보기에 즉시 반영

### TC-FILTER-03 Normal 복원
- When: Normal 선택
- Then: 원본(필터 미적용)으로 복원

---

## 5. 색감 조정 (Adjust)

### TC-ADJ-01 밝기/대비/채도 슬라이더
- When: 각 슬라이더 조정
- Then: 밝기(-1~1), 대비, 채도가 실시간 반영

### TC-ADJ-02 0 값 햅틱 피드백
- Given: `impactFeedbackWhenAdjustSliderValueIsZero = true`
- When: 슬라이더가 정확히 0(기본값)을 지날 때
- Then: 임팩트 햅틱이 발생

### TC-ADJ-03 전부 0이면 변화 없음
- Given: brightness/contrast/saturation 모두 0
- Then: 결과 이미지가 원본과 동일(`allValueIsZero`)

---

## 6. 그리기 (Draw)

### TC-DRAW-01 펜 그리기
- When: 그리기 진입 후 손가락으로 드로잉
- Then: 부드러운(Catmull-Rom 보간) 선이 그려진다

### TC-DRAW-02 색상 선택
- When: 색상 팔레트에서 색 변경
- Then: 이후 그리는 선에 색상 반영(기본 색상 빨강 계열)

### TC-DRAW-03 되돌리기 / 다시실행
- Given: `actionManagerAllowToStore = true`
- When: undo/redo
- Then: 그리기 동작이 히스토리 단위로 취소·복구

---

## 7. 모자이크 (Mosaic)

### TC-MOSAIC-01 모자이크 칠하기
- When: 모자이크 진입 후 영역을 문지름
- Then: 해당 경로 영역이 모자이크 처리

### TC-MOSAIC-02 모자이크 스티커
- Given: 스티커 트레이에 모자이크 항목
- When: 모자이크 스티커 선택
- Then: `hasMosaicSticker` 동작과 함께 적용

---

## 8. 이미지 스티커 (Image Sticker)

### TC-ISTK-01 스티커 추가
- Given: `stickerDataSource` 설정
- When: 트레이에서 스티커 선택
- Then: 캔버스 중앙에 스티커 추가, 핀치/회전/이동 제스처 동작

### TC-ISTK-02 최대 개수 초과
- Given: `maxImageStickersCount = 50`, 50개 추가됨
- When: 51번째 추가 시도
- Then: `cannotAttachMoreImageStickers` → `cannot_more_image_stickers` 경고

### TC-ISTK-03 얼굴 AI 스티커
- Given: faceAI 스티커
- When: 얼굴 검출 후 자동 배치(`aiStickerScale = 2.4` 적용)
- Then: 검출된 얼굴 위치에 스케일 적용되어 배치

### TC-ISTK-04 스티커 탭하여 재편집
- When: 이미 배치된 이미지 스티커 탭(반경 내 히트 테스트)
- Then: 해당 스티커 편집 모드로 진입

### TC-ISTK-05 스티커 삭제
- When: 스티커를 휴지통(ashbin) 영역으로 드래그
- Then: 휴지통이 강조색으로 바뀌고 드롭 시 삭제

---

## 9. 텍스트 스티커 (Text Sticker)

### TC-TXT-01 텍스트 입력
- When: 텍스트 도구 진입 후 입력
- Then: 입력한 텍스트가 스티커로 추가됨

### TC-TXT-02 글자 수 제한
- Given: `maxTextLength = 60`
- When: 60자 초과 입력 시도
- Then: 초과 입력 차단

### TC-TXT-03 줄바꿈 제한
- Given: `textStickerCanLineBreak = true`, `textStickerMaximumLines = 4`
- Then: 최대 4줄, 줄당 글자수/너비 제한 적용

### TC-TXT-04 색상 / 배경
- When: 글자색·배경색 선택
- Then: 텍스트 색상과 채움(`textStickerFillStyle`) 반영

### TC-TXT-05 최대 개수 초과
- Given: `maxTextStickersCount = 50`
- When: 초과 추가 시도
- Then: `cannot_more_text_stickers` 경고

### TC-TXT-06 텍스트 스티커 재편집
- When: 배치된 텍스트 스티커 탭
- Then: 입력 화면으로 재진입하여 수정

---

## 10. 원본 초기화 (Reset)

### TC-RESET-01 초기화 토스트 노출
- Given: 현재 이미지가 편집됨(`editImageURL != nil`)
- Then: "원본으로 초기화" 토스트 버튼이 활성 상태로 노출

### TC-RESET-02 미편집 이미지
- Given: 편집 이력 없는 이미지
- Then: 초기화 버튼이 비활성(disabled)

### TC-RESET-03 초기화 확인 콜백
- When: 초기화 버튼 탭
- Then: `confirmingResetEditImage`로 확인을 받고, 승인 시 `resetToOrigin()`으로 원본 복원 + 셀 리로드

---

## 11. 편집 결과 저장 / 캐시

### TC-SAVE-01 편집 확정
- When: 편집 모드에서 확인(done)
- Then: 결과 이미지가 edit/thumbnail 캐시에 저장되고 페이지 셀이 갱신

### TC-SAVE-02 fatten(병합) 처리
- Given: 자르기/회전 없이 편집 누적
- Then: 중간 병합본(fatten)이 생성되어 다음 편집의 베이스로 사용

### TC-SAVE-03 상태 미보전 자르기
- Given: `allowClipWithoutKeepingState` 경로
- When: 자르기만 확정
- Then: `didClipWithoutKeepingState`로 fatten 캐시만 갱신

---

## 12. 표현 / 회전 / 로케일

### TC-UI-01 세로 고정
- Given: `supportedInterfaceOrientations = .portrait`
- When: 기기 가로 회전
- Then: 세로 고정 유지(회전 시 레이아웃 재계산)

### TC-UI-02 다크 배경
- Then: 편집 화면 배경이 검정으로 일관 표시

### TC-UI-03 로케일
- Given: 기기 언어 한국어/영어
- Then: 도구 라벨/버튼/경고 문구가 해당 언어로 표시 (ko/en `HEImageEditorLocalizable.strings`)

---

## 회귀 체크리스트 (Smoke)
- [ ] 단일/다중 이미지 진입 및 페이징
- [ ] 자르기 비율 4종 + 회전 + 상태보전 경고
- [ ] 필터 적용/복원
- [ ] 색감 3종 슬라이더 + 0값 처리
- [ ] 그리기 + undo/redo
- [ ] 모자이크 칠하기
- [ ] 이미지/텍스트 스티커 추가·재편집·삭제·개수 제한
- [ ] 원본 초기화(확인 콜백)
- [ ] 편집 확정 후 결과 반영
- [ ] 취소/완료 델리게이트
- [ ] 다크 배경 / 한·영 로케일
