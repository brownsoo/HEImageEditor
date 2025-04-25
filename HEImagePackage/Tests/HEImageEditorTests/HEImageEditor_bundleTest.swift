//
//  HEImageEditor_bundleTest.swift
//
//
//  Created by 브라운수 on 7/11/24.
//


import XCTest
@testable import HEImageEditor

final class HEImageEditor_bundleTest: XCTestCase {
    func testBundleString() {
        let string = Bundle.heLocalizedString("confirm")
        XCTAssertEqual(string, "확인")
        
    }
    
    func testSpmModule() {
        
        XCTAssertNotNil(Bundle.spm_module)
    }
}
