//
//  HEImageEditor_bundleTest.swift
//
//
//  Created by 브라운수 on 7/11/24.
//


import XCTest
@testable import HEImageEditor

final class HEImageEditor_bundleTest: XCTestCase {
    // 리소스 번들이 연결되어 로컬라이즈 키가 해석되는지 검증.
    // 시스템 로케일(AppleLanguages)에 의존하지 않도록 특정 언어 문자열을 하드코딩하지 않는다.
    func testBundleString() {
        let string = Bundle.heLocalizedString("confirm")
        XCTAssertFalse(string.isEmpty)
        XCTAssertNotEqual(string, "confirm", "로컬라이즈 누락(키 그대로 반환)")
    }

    func testSpmModule() {
        XCTAssertNotNil(Bundle.spm_module)
    }
}
