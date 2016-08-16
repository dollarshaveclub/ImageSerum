//
//  PriorityQueueTests.swift
//  ImageSerum
//
//  Created by David Peredo on 8/15/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import XCTest
import ImageSerum

class PriorityQueueTests: XCTestCase {
    
    var queue: HeapPriorityQueue!
    
    override func setUp() {
        super.setUp()

        queue = HeapPriorityQueue()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInsert() {
        queue.insert("a", priority: 1)
        XCTAssertEqual(queue.peakMax(), "a")
        
        queue.insert("b", priority: 100)
        XCTAssertEqual(queue.peakMax(), "b")
        
        queue.insert("c", priority: 50)
        XCTAssertEqual(queue.peakMax(), "b")
    }
    
    func testPopMax() {
        queue.insert("a", priority: 1)
        queue.insert("b", priority: 100)
        queue.insert("c", priority: 50)
        
        XCTAssertEqual(queue.popMax(), "b")
        XCTAssertEqual(queue.popMax(), "c")
        XCTAssertEqual(queue.popMax(), "a")
    }
    
    func testInsertPerformance() {
        // Seed random to keep the numbers the same on each test.
        srand(UInt32(0))
        self.measureBlock {
            for _ in 0..<1000 {
                let num = Int(rand())
                self.queue.insert("number", priority: num)
            }
        }
    }
}
