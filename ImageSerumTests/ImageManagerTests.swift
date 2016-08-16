//
//  ImageManagerTests.swift
//  ImageSerum
//
//  Created by David Peredo on 8/16/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import XCTest
import ImageSerum

class MockPriorityQueue: PriorityQueue {
    func insert(val: String, priority: Int) {

    }
    
    func popMax() -> String? {
        return nil
    }
    
    func peakMax() -> String? {
        return nil
    }
}

class MockCache: ImageCache {
    func imageForURL(URL: String) -> NSData? {
        return nil
    }
}

class ImageManagerTests: XCTestCase {
    
    var imageManager: ImageManager!
    
    override func setUp() {
        super.setUp()
        
        imageManager = ImageManager(priorityQueue: MockPriorityQueue(), imageCache: MockCache())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
