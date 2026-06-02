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
        HEEditImageViewController.showImageEditor(
            parent: self,
            image: currentImage,
            delegate: self
        )
    }

    @objc private func didTapPicker() {
        let picker = HEImagePicker()
        picker.pickerDelegate = self
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

    func imagePickerDidCancel(_ picker: HEImagePicker) {
        picker.dismiss(animated: true)
        statusLabel.text = "사진 선택을 취소했습니다."
    }
}
