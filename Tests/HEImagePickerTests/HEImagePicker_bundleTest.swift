//
//  HEImagePicker_bundleTest.swift
//
//
//  Created by 브라운수 on 7/11/24.
//

import XCTest
@testable import HEImagePicker

final class HEImagePicker_bundleTest: XCTestCase {
    func testBundleString() {
        let string = pickerLocalized("_confirm")
        XCTAssertEqual(string, "확인")
        
    }
    
    func testPickerConfig() {
        let string = PickerConfig.wordings.attach
        XCTAssertEqual(string, "추가하기")
    }
}
