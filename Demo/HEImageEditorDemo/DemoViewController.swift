//
//  DemoViewController.swift
//  HEImageEditorDemo
//
//  두 가지 핵심 기능을 시뮬레이터에서 바로 확인할 수 있는 데모 화면입니다.
//   1. 샘플 이미지 편집  (HEEditImageViewController.showImageEditor)
//   2. 사진 피커 열기      (HEImagePicker)
//

import UIKit
import HECommon
import HEImageEditor
import HEImagePicker

final class DemoViewController: UIViewController {

    // MARK: - UI

    private let previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = UIColor.secondarySystemBackground
        iv.layer.cornerRadius = 12
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let statusLabel: UILabel = {
        let lb = UILabel()
        lb.text = "샘플 이미지를 편집하거나 사진 피커를 열어보세요."
        lb.font = .systemFont(ofSize: 14)
        lb.textColor = .secondaryLabel
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()

    /// 편집 진입에 사용할 현재 이미지(편집 결과로 갱신됨)
    private lazy var currentImage: UIImage = Self.makeSampleImage()

    /// 이미지 스티커용 이모지 데이터 소스.
    /// 트레이 뷰가 `dataSource` 를 weak 로 참조하므로 화면이 강하게 보유한다.
    private let emojiStickerDataSource = EmojiStickerDataSource()

    /// 피커에서 "사진 편집"으로 에디터를 띄운 경우의 피커 참조.
    /// 편집 완료 시 결과를 이 피커의 편집 저장소에 반영하기 위해 사용한다.
    private weak var pickerForEditing: HEImagePicker?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HEImageEditor Demo"
        view.backgroundColor = .systemBackground
        setupUI()
        previewImageView.image = currentImage
    }

    private func setupUI() {
        let editButton = makeButton(title: "샘플 이미지 편집", action: #selector(didTapEdit))
        let pickerButton = makeButton(title: "사진 피커 열기", action: #selector(didTapPicker))

        let buttonStack = UIStackView(arrangedSubviews: [editButton, pickerButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(previewImageView)
        view.addSubview(statusLabel)
        view.addSubview(buttonStack)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 24),
            previewImageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            previewImageView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor),

            statusLabel.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),

            buttonStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -32),
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc private func didTapEdit() {
        configureAllEditTools()
        HEEditImageViewController.showImageEditor(
            parent: self,
            image: currentImage,
            delegate: self,
            topToolViewBuilder: Self.makeTopBarBuilder()
        )
    }

    /// 툴이 선택되지 않은 평상시 상단 바.
    ///
    /// 빌더를 넘기지 않으면 에디터 레벨 상단 바가 없어, 툴(Clip/Sticker/Text 등)을
    /// 선택했을 때 나타나는 편집용 X/체크 버튼만 보인다. 이 빌더는 평상시에
    /// 에디터 전체를 취소(`cancel()`)/완료(`done()`)하는 버튼을 노출한다.
    private static func makeTopBarBuilder() -> HEEditImageTopToolViewBuilder {
        { editView in
            let topBar = HETopBarView()
            topBar.backgroundColor = .black
            topBar.addLeadingView(makeBarButton(title: "취소", weight: .regular) { [weak editView] in
                editView?.cancel()
            })
            topBar.addTrailingView(makeBarButton(title: "완료", weight: .semibold) { [weak editView] in
                editView?.done()
            })
            return (topBar, topBarHeight)
        }
    }

    /// 상단 바 높이. 라이브러리의 `HETopBarView.contentHeight`(internal)와 동일한 값.
    private static let topBarHeight: CGFloat = 48

    private static func makeBarButton(
        title: String,
        weight: UIFont.Weight,
        action: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: weight)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.addAction(.init(handler: { _ in action() }), for: .touchUpInside)
        return button
    }

    /// 데모에서 모든 EditTool 을 사용하도록 에디터를 설정한다.
    ///
    /// `imageSticker` 는 `imageStickerTray` 가 없으면 에디터가 자동으로 제거하므로,
    /// 이모지 스티커 트레이를 함께 주입한다.
    private func configureAllEditTools() {
        let config = HEImageEditorConfiguration.default()
        config.tools = [.draw, .clip, .imageSticker, .textSticker, .mosaicDraw, .filter, .adjust]

        let stickerTray = HEImageStickerTrayView()
        stickerTray.dataSource = emojiStickerDataSource
        config.imageStickerTray = stickerTray

        // Clip / ImageSticker 의 X·체크 버튼이 에디터 전체를 종료하지 않고
        // 해당 툴의 적용/취소만 수행하도록 한다.
        // 에디터 전체의 취소/완료는 상단 바(makeTopBarBuilder)가 담당한다.
        config.actionDoneEditorWhenImageStickerEditingConfirm = false
    }

    @objc private func didTapPicker() {
        let picker = HEImagePicker()
        picker.pickerDelegate = self
        // 사진 피커는 전체 화면으로 표시한다. (네비게이션 바가 상태바 영역까지 정상 확보)
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    // MARK: - Sample image

    /// 외부 에셋 없이 코드로 그라데이션 샘플 이미지를 생성합니다.
    private static func makeSampleImage() -> UIImage {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let colors = [
                UIColor.systemIndigo.cgColor,
                UIColor.systemTeal.cgColor,
            ] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            let text = "HEImageEditor"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .heavy),
                .foregroundColor: UIColor.white,
            ]
            let attributed = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributed.size()
            attributed.draw(at: CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            ))
        }
    }
}

// MARK: - HEEditImageViewDelegate

extension DemoViewController: HEEditImageViewDelegate {

    func didFinishEditImage(
        _ editView: HEEditImageView,
        resultImage: UIImage,
        editId: String?,
        editModel: HEEditState?
    ) {
        currentImage = resultImage
        previewImageView.image = resultImage
        statusLabel.text = "편집을 완료했습니다."

        // 피커에서 진입한 편집이면, 편집본을 저장하고 피커를 갱신한다.
        // (편집 이미지 표시 + 썸네일 "편집" 캡션은 피커 기본 델리게이트가 처리)
        if let picker = pickerForEditing, let editId,
           let hei = picker.editImageStore.getHEImage(forAssetIdentifier: editId)
            ?? picker.editImageStore.getHEImage(forId: editId) {
            pickerForEditing = nil
            Task { @MainActor in
                _ = try? await picker.editImageStore.cacheEditImage(uiImage: resultImage, forHei: hei)
                picker.reload()
            }
        }
    }

    func didClipWithoutKeepingState(
        _ editView: HEEditImageView,
        resultImage: UIImage,
        editId: String?
    ) {
        currentImage = resultImage
        previewImageView.image = resultImage
        statusLabel.text = "이미지를 잘랐습니다."
    }

    func cancelledEditImage(_ editView: HEEditImageView) {
        pickerForEditing = nil
        statusLabel.text = "편집을 취소했습니다."
    }

    func cannotAttachMoreImageStickers(_ editView: HEEditImageView) {
        statusLabel.text = "이미지 스티커를 더 추가할 수 없습니다."
    }

    func cannotAttachMoreTextStickers(_ editView: HEEditImageView) {
        statusLabel.text = "텍스트 스티커를 더 추가할 수 없습니다."
    }
}

// MARK: - HEImagePickerDelegate

extension DemoViewController: HEImagePickerDelegate {

    func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem]) {
        picker.dismiss(animated: true)
        statusLabel.text = "사진 \(items.count)개를 선택했습니다."

        guard let first = items.photoItems.first else { return }

        // 원본 사진 디코딩은 비용이 크므로 백그라운드에서 수행하고 UI는 메인에서 갱신한다.
        let path = first.url.path
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let image = UIImage(contentsOfFile: path) else { return }
            DispatchQueue.main.async {
                self?.currentImage = image
                self?.previewImageView.image = image
            }
        }
    }

    /// 피커의 "사진 편집" 선택 → 해당 사진을 이미지 에디터로 연결한다.
    func imagePicker(
        _ picker: HEImagePicker,
        didSelectToEditItem item: HEMediaItem,
        inItems items: [HEMediaItem]
    ) {
        guard case let .photo(photo) = item else {
            statusLabel.text = "이미지만 편집할 수 있습니다."
            return
        }

        // 편집 결과를 다시 찾을 수 있도록 에셋 식별자를 editId 로 사용한다.
        let editId = photo.asset?.localIdentifier ?? photo.identifier
        // 피커의 편집 저장소에 해당 사진의 HEImage 가 없으면 등록한다.
        if picker.editImageStore.getHEImage(forAssetIdentifier: editId) == nil {
            picker.editImageStore.addHEImage(
                HEImage(id: editId, origin: photo.url, phAsset: photo.asset)
            )
        }
        pickerForEditing = picker

        // 원본 사진 디코딩은 비용이 크므로 백그라운드에서 수행하고 UI는 메인에서 갱신한다.
        let path = photo.url.path
        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak picker] in
            guard let image = UIImage(contentsOfFile: path) else { return }
            DispatchQueue.main.async {
                guard let self, let picker else { return }
                self.currentImage = image
                self.configureAllEditTools()
                // 피커 위에 에디터를 띄운다. 편집 완료는 didFinishEditImage 에서 처리된다.
                HEEditImageViewController.showImageEditor(
                    parent: picker,
                    image: image,
                    editId: editId,
                    delegate: self,
                    topToolViewBuilder: Self.makeTopBarBuilder()
                )
            }
        }
    }

    func imagePickerDidCancel(_ picker: HEImagePicker) {
        picker.dismiss(animated: true)
        statusLabel.text = "사진 선택을 취소했습니다."
    }
}
