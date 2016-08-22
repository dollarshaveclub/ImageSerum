//
//  QueueTests.swift
//  ImageSerum
//
//  Created by David Peredo on 8/16/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import XCTest


class DownloadQueueTests: XCTestCase {
    let URLOne = NSURL(string: "http://one")!
    let URLTwo = NSURL(string: "http://two")!
    let URLThree = NSURL(string: "http://three")!
    
    var queue: DownloadQueue!

    override func setUp() {
        super.setUp()

        queue = DownloadQueue()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testAppend() {
        queue.queue(URLOne)
        queue.queue(URLTwo)
        queue.queue(URLThree)
        
        XCTAssertEqual(queue.toArray(), [URLOne, URLTwo, URLThree])
    }
    
    func testPop() {
        queue.queue(URLOne)
        queue.queue(URLTwo)
        queue.queue(URLThree)
        
        XCTAssertEqual(queue.pop(), URLOne)
        XCTAssertEqual(queue.pop(), URLTwo)
        XCTAssertEqual(queue.pop(), URLThree)
        XCTAssertNil(queue.pop())
    }
    
    func testPopNil() {
        XCTAssertNil(queue.pop())
    }
    
    func testRemove() {
        queue.queue(URLOne)
        queue.queue(URLTwo)
        queue.queue(URLThree)
        
        queue.removeDownload(URLTwo)
        
        XCTAssertEqual(queue.toArray(), [URLOne, URLThree])
    }
    
    func testRemoveNil() {
        queue.queue(URLOne)
        queue.queue(URLTwo)
        
        queue.removeDownload(URLThree)
        XCTAssertEqual(queue.toArray(), [URLOne, URLTwo])
    }
    
    func testContainsURL() {
        queue.queue(URLOne)
        queue.queue(URLTwo)
        queue.queue(URLThree)
        
        XCTAssertTrue(queue.contains(URLTwo))
    }
    
    func testDoesNotContainsURL() {
        queue.queue(URLOne)
        queue.queue(URLThree)
        
        XCTAssertFalse(queue.contains(URLTwo))
    }
}
