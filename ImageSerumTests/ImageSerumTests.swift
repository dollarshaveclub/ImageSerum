//
//  ImageSerumTests.swift
//  ImageSerumTests
//
//  Created by David Peredo on 8/9/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import XCTest

class ImageSerumTests: XCTestCase {
    
    
    static func webPData() -> NSData? {
        guard let path = NSBundle.init(forClass: ImageSerumTests.self).pathForResource("2_IntroToLoop", ofType: "webp") else {return nil}
        return NSData(contentsOfFile: path)
    }
    
    static func gifData() -> NSData? {
        guard let path = NSBundle.init(forClass: ImageSerumTests.self).pathForResource("2_IntroToLoop", ofType: "gif") else {return nil}
        return NSData(contentsOfFile: path)
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValidGifDoesNotReportAlpha() {
        guard let data = ImageSerumTests.gifData() else { assert(true, "testData is invalid")
            return }
        let image = Image()//data: data)
        assert(!image.hasAlpha, "image should have an alpha unless a gif has been loaded")
        image.decode(data)
        assert(!image.hasAlpha, "image with decoded gif data reports !hasAlpha")
    }
    
    
    func testIsValidImage() {
        guard let data = ImageSerumTests.webPData() else { assert(true, "testData is invalid")
            return }
        assert(Image.isValidImage(data) == true, "valid image data not read as valid")
    }
    
    func testFramesExistsAfterDecode() {
        guard let data = ImageSerumTests.webPData() else { assert(true, "testData is invalid")
            return }
        let image = Image(data: data)
        
        //frames load with valid data
        assert(image.frames?.count > 0, "Image failed WebP decode")
    }
    
    func testIsDecodedWhenDecoded() {
        //decode finish
        guard let data = ImageSerumTests.webPData() else { assert(true, "testData is invalid")
            return }
        let image = Image()
        assert(image.isDecoded == false, "image is decoded when initialized with no data")
        image.decodeCompletion = {
            assert(image.isDecoded, "image not decoded when finishedDecode is called")
        }
        
        image.decode(data)
    }

    func testDecodeProgress() {
        //decode progress
        guard let data = ImageSerumTests.webPData() else { assert(true, "testData is invalid")
            return }
        let image = Image(data: data)
        image.decodeProgress = { progressFloat in assert(progressFloat > 0.0, "decodeProgress should not be below 0") }
    }
    
}
