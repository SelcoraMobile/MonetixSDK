//
//  MonetixSDKTests.swift
//  MonetixSDK
//
//  Copyright © 2024 SelcoraMobile. All rights reserved.
//

import XCTest
@testable import MonetixSDK

final class MonetixSDKTests: XCTestCase {

    func testVersion() {
        XCTAssertEqual(MonetixSDK.version, "1.0.0")
    }
}
