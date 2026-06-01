//
//  EditorActionManagerTests.swift
//  HEImageEditorTests
//
//  정적 검사: HEEditActionManager 의 undo/redo/store 히스토리 로직.
//

import XCTest
@testable import HEImageEditor

private final class SpyActionDelegate: HEEditActionManagerDelegate {
    var updateCount = 0
    var lastActions: [HEEditAction] = []
    var lastRedoActions: [HEEditAction] = []
    var undone: [HEEditAction] = []
    var redone: [HEEditAction] = []

    func editActionManager(_ manager: HEEditActionManager, didUpdateActions actions: [HEEditAction], redoActions: [HEEditAction]) {
        updateCount += 1
        lastActions = actions
        lastRedoActions = redoActions
    }
    func editActionManager(_ manager: HEEditActionManager, undoAction action: HEEditAction) {
        undone.append(action)
    }
    func editActionManager(_ manager: HEEditActionManager, redoAction action: HEEditAction) {
        redone.append(action)
    }
}

// 전역 싱글톤 설정을 변경하므로 @MainActor 로 직렬화하여 병렬 실행 간섭을 막는다.
@MainActor
final class EditorActionManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        HEImageEditorConfiguration.resetConfiguration()
        HEImageEditorConfiguration.default().actionManagerAllowToStore = true
    }

    override func tearDown() {
        HEImageEditorConfiguration.resetConfiguration()
        super.tearDown()
    }

    private func filterAction(_ f: HEFilter) -> HEEditAction {
        .filter(oldFilter: nil, newFilter: f)
    }

    func testStoreAppendsActionAndNotifiesDelegate() {
        let manager = HEEditActionManager()
        let spy = SpyActionDelegate()
        manager.delegate = spy

        manager.storeAction(filterAction(.sepia))

        XCTAssertEqual(manager.actions.count, 1)
        XCTAssertEqual(manager.redoActions.count, 1)
        XCTAssertEqual(spy.updateCount, 1)
        XCTAssertEqual(spy.lastActions.count, 1)
    }

    func testStoreIsSkippedWhenDisabled() {
        HEImageEditorConfiguration.default().actionManagerAllowToStore = false
        let manager = HEEditActionManager()
        manager.storeAction(filterAction(.mono))
        XCTAssertTrue(manager.actions.isEmpty)
    }

    func testUndoPopsLastAndNotifiesDelegate() {
        let manager = HEEditActionManager()
        let spy = SpyActionDelegate()
        manager.delegate = spy
        manager.storeAction(filterAction(.sepia))
        manager.storeAction(filterAction(.mono))

        manager.undoAction()

        XCTAssertEqual(manager.actions.count, 1)
        XCTAssertEqual(manager.redoActions.count, 2) // redo 스택은 유지
        XCTAssertEqual(spy.undone.count, 1)
    }

    func testUndoOnEmptyIsNoop() {
        let manager = HEEditActionManager()
        let spy = SpyActionDelegate()
        manager.delegate = spy
        manager.undoAction()
        XCTAssertTrue(spy.undone.isEmpty)
    }

    func testRedoReappliesUndoneAction() {
        let manager = HEEditActionManager()
        let spy = SpyActionDelegate()
        manager.delegate = spy
        manager.storeAction(filterAction(.sepia))
        manager.storeAction(filterAction(.mono))
        manager.undoAction()

        manager.redoAction()

        XCTAssertEqual(manager.actions.count, 2)
        XCTAssertEqual(spy.redone.count, 1)
    }

    func testRedoAtHeadIsNoop() {
        let manager = HEEditActionManager()
        let spy = SpyActionDelegate()
        manager.delegate = spy
        manager.storeAction(filterAction(.sepia))

        manager.redoAction() // 더 이상 redo 할 것이 없음

        XCTAssertEqual(manager.actions.count, 1)
        XCTAssertTrue(spy.redone.isEmpty)
    }

    func testInitWithActionsSeedsBothStacks() {
        let seeded = [filterAction(.sepia), filterAction(.mono)]
        let manager = HEEditActionManager(actions: seeded)
        XCTAssertEqual(manager.actions.count, 2)
        XCTAssertEqual(manager.redoActions.count, 2)
    }
}
