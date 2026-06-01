# HEImagePicker 사용자 테스트 케이스 (Manual QA)

> 대상: `Sources/HEImagePicker`
> 자동화하기 어려운 UI / 권한 / 미디어 플로우를 실제 기기·시뮬레이터에서 수동 검증하기 위한 시나리오 목록.
> 형식: **Given(전제) → When(동작) → Then(기대결과)**

---

## 1. 권한 (Permission)

### TC-PERM-01 사진 라이브러리 최초 접근 (notDetermined)
- Given: 앱이 사진 권한을 한 번도 요청하지 않은 상태
- When: 피커를 연다
- Then: 시스템 권한 팝업이 표시되고, **허용** 시 라이브러리 썸네일이 로드된다

### TC-PERM-02 사진 권한 거부 (denied)
- Given: 사진 권한이 거부됨
- When: 피커를 연다
- Then: `PermissionDeniedPopup`(설정 이동 안내)이 표시되고, **취소** 시 콜백이 차단된다

### TC-PERM-03 제한된 접근 (limited, iOS 14+)
- Given: "선택한 사진만 허용" 상태
- When: 피커를 연다
- Then: 허용된 일부 사진만 노출되고 정상 동작한다 (`limited` → 접근 허용으로 처리)

### TC-PERM-04 카메라 권한 거부
- Given: 카메라 권한 거부됨
- When: 카메라(사진/동영상 촬영) 소스를 선택
- Then: 카메라 권한 거부 팝업이 표시된다

### TC-PERM-05 카메라 미지원 기기
- Given: 카메라가 없는 환경(일부 시뮬레이터)
- When: 카메라 소스 선택
- Then: `_noSupportCameraDevice`("카메라가 지원되지 않습니다.") 안내 노출

---

## 2. 라이브러리 선택 (Library)

### TC-LIB-01 빈 라이브러리
- Given: 사진이 0장
- When: 피커를 연다
- Then: `_photos_empty_messge`("사진이 없습니다.")가 표시되고 `imagePickerHaveNoItems` 델리게이트가 호출된다

### TC-LIB-02 단일 선택 (maxNumberOfItems = 1)
- Given: `library.maxNumberOfItems = 1`
- When: 사진 한 장을 탭
- Then: 선택 즉시 미리보기에 반영, 다른 사진을 탭하면 이전 선택이 교체된다

### TC-LIB-03 단일 탭 선택 동작 (addToSelectionBySigleTouch)
- Given: `addToSelectionBySigleTouch = true`
- When: 썸네일을 한 번 탭
- Then: 즉시 선택 토글된다

### TC-LIB-04 다중 선택 활성화
- Given: `maxNumberOfItems > 1`
- When: 다중 선택 토글 ON 후 여러 장 선택
- Then: 선택 순서대로 번호가 표시되고 `didToggleMultipleSelectionEnabled(true)` 호출

### TC-LIB-05 최대 개수 초과
- Given: `maxNumberOfItems = 3`, 이미 3장 선택
- When: 4번째 사진 선택 시도
- Then: `limitExceededOnSelectItemType` 호출 → `_warningItemsLimit`("최대 3개 까지 선택할 수 있습니다.") 노출, 선택 거부

### TC-LIB-06 shouldAddToSelection 차단
- Given: 델리게이트가 특정 항목에 대해 `false` 반환
- When: 해당 항목 선택 시도
- Then: 선택되지 않는다

### TC-LIB-07 선택 없이 첨부 (allowPickWithoutSelection)
- Given: `allowPickWithoutSelection = true`, 아무 것도 명시 선택하지 않음
- When: 첨부/완료를 누름
- Then: 현재 미리보기에 표시된 미디어가 결과로 추출된다

### TC-LIB-08 미리선택 항목 (preselectedItems)
- Given: `library.preselectedItems`에 항목 지정
- When: 피커를 연다
- Then: 해당 항목들이 이미 선택된 상태로 표시된다

---

## 3. 미디어 타입 제한

### TC-TYPE-01 사진 전용
- Given: `library.mediaType = .photo`
- Then: 동영상은 목록에 보이지 않거나 선택 불가

### TC-TYPE-02 동영상 선택 제한 메시지
- Given: 사진만 선택 가능한 설정
- When: 동영상 선택 시도
- Then: `cannotSelectItemType(.video)` → `_only_image_selectable`("이미지만 선택 가능합니다.")

### TC-TYPE-03 단일 타입 강제 (shouldSelectSingleType)
- Given: `shouldSelectSingleType = true`, 첫 선택이 사진
- When: 이후 동영상 선택 시도
- Then: 첫 타입(사진)만 허용, 동영상 선택 차단

---

## 4. 미리보기 / 줌 / 크롭

### TC-PREV-01 줌 가능 미리보기
- Given: `allowZoomablePreview = true`
- When: 미리보기에서 핀치 줌
- Then: 확대/축소가 동작한다

### TC-PREV-02 채움 vs 맞춤 (priviewScaleFit)
- Given: `priviewScaleFit = true`
- Then: 미리보기 영역을 이미지가 가득 채운다 / `false` 면 전체가 보이도록 맞춤

### TC-PREV-03 정사각 크롭 (onlySquare)
- Given: `library.onlySquare = true`
- Then: 크롭 영역이 정사각으로 고정된다

### TC-PREV-04 팬 제스처로 미리보기 접기/펼치기
- Given: 미리보기 + 컬렉션 뷰 화면
- When: 위/아래로 드래그 (`HEPanGestureHelper`)
- Then: 미리보기 박스가 부드럽게 접히고 펼쳐진다 (튕김 없이 원위치 복귀)

---

## 5. 카메라 촬영 (Capture)

### TC-CAM-01 사진 촬영 후 정사각
- Given: `onlySquareImagesFromCamera = true`
- When: 사진 촬영
- Then: 결과 이미지가 정사각으로 출력된다

### TC-CAM-02 앨범 저장 여부
- Given: `shouldSaveNewPicturesToAlbum = true`
- When: 사진 촬영 완료
- Then: 지정 앨범(`albumName` 기본 "하이클래스")에 저장된다
- And: `false` 이면 저장하지 않고 `didCaptureItem`만 호출된다

---

## 6. 동영상 (Video)

### TC-VID-01 라이브러리 길이 제한
- Given: `video.limitVideoTimeLImit = true`, `libraryTimeLimit = 60`
- When: 60초 초과 동영상 선택
- Then: `_videoTooLong` 안내, 선택/트리밍 유도

### TC-VID-02 용량 제한
- Given: `video.maxVideoFileSize = 500MB`
- When: 초과 동영상 선택
- Then: `_videoTooHeavy`("...MB 이하인 동영상을 선택해주세요.") 노출

### TC-VID-03 트리머 표시
- Given: `showsVideoTrimmer = true`
- When: 동영상 선택
- Then: 트리머 단계가 표시되고 `trimmerMin/MaxDuration` 범위로 제한된다

### TC-VID-04 자동 트리밍
- Given: `automaticTrimToTrimmerMaxDuration = true`
- When: 트리머를 건너뜀
- Then: `trimmerMaxDuration`(기본 60초)로 자동 트리밍된다

### TC-VID-05 압축 비활성화
- Given: `video.disableCompressing = true`
- Then: 원본 URL/asset 그대로 사용, 압축 미수행

---

## 7. 편집 연동 (Edit)

### TC-EDIT-01 편집 버튼 노출
- Given: `useEditPhoto = true`
- When: 미리보기에서 편집 버튼 탭
- Then: `didSelectToEditItem(item, inItems:)` 델리게이트 호출

### TC-EDIT-02 편집 캡션 표시
- Given: `editImageStore`에 편집된 이미지(editImageURL 존재)
- Then: 해당 항목에 `_edited`("편집 적용") 캡션이 표시된다

### TC-EDIT-03 편집 대상 없음
- Given: 선택/미리보기 항목이 없음
- When: 편집 시도
- Then: `_noSelectionToEdit`("편집할 대상을 찾지 못했습니다.") 노출

---

## 8. 결과 추출 (extractSelectedMedia)

### TC-EXT-01 단일 사진 결과
- When: 사진 한 장 선택 후 완료
- Then: `didSelectItems`로 `.photo` 1건 전달, `editImageStore`는 단일 항목으로 정리됨

### TC-EXT-02 다중 결과 순서 유지
- Given: 다중 선택 3건(사진/동영상 혼합)
- When: 완료
- Then: 선택한 순서대로 결과 배열이 정렬되어 전달된다

### TC-EXT-03 처리 중 인디케이터
- When: 추출 진행 중
- Then: `exportLoadingView`(`_processing` "처리중...")가 표시되고 완료 후 숨겨진다

---

## 9. 취소 / 상태 복원

### TC-CANCEL-01 취소 시 초기 상태 복원
- Given: 피커 진입 시점의 `editImageStore` 스냅샷(`initiailHEImages`)
- When: 취소
- Then: 스토어가 진입 시점 상태로 복원되고 `imagePickerDidCancel` 호출

### TC-CANCEL-02 취소 버튼 숨김
- Given: `hidesCancelButton = true`
- Then: 내비게이션 바에 취소 버튼이 표시되지 않는다

---

## 10. 앨범 목록 (Albums)

### TC-ALBUM-01 앨범 전환
- When: 상단 앨범 타이틀(▼) 탭 → 다른 앨범 선택
- Then: 선택 앨범의 사진으로 컬렉션이 갱신된다

### TC-ALBUM-02 라이브러리 변경 감지 (PHPhotoLibraryChangeObserver)
- Given: 피커가 열린 상태
- When: 사진 앱에서 사진 추가/삭제
- Then: 컬렉션이 갱신되거나 `_library_changed_alert` 안내가 노출된다

---

## 11. 표현/접근성/회전

### TC-UI-01 다크모드
- When: 라이트/다크 모드 전환
- Then: 배경/텍스트 색상(`offWhiteOrBlack`, `ypLabel`)이 모드에 맞게 적용

### TC-UI-02 세로 고정
- Given: `supportedInterfaceOrientations = .portrait`
- When: 기기를 가로로 회전
- Then: 화면이 세로로 고정 유지

### TC-UI-03 로케일
- Given: 기기 언어 한국어/영어
- Then: 모든 문구가 해당 언어로 표시 (ko/en `HEImagePickerLocalizable.strings`)

### TC-UI-04 iPad 너비
- Given: iPad에서 `HEImagePickerConfiguration.widthOniPad > 0`
- Then: `screenWidth`가 지정 너비를 사용해 레이아웃이 계산된다

---

## 회귀 체크리스트 (Smoke)
- [ ] 권한 허용 → 사진 선택 → 완료까지 정상
- [ ] 다중 선택 + 최대 개수 초과 경고
- [ ] 동영상 선택 → 트리밍 → 완료
- [ ] 카메라 촬영 → 앨범 저장
- [ ] 편집 진입/복귀 후 캡션 표시
- [ ] 취소 시 상태 복원
- [ ] 다크모드 / 한·영 로케일
