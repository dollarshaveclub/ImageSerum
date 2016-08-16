//
//  ImageCache.swift
//  ImageSerum
//
//  Created by David Peredo on 8/11/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import Foundation
import CommonCrypto

protocol ImageCache {
    func imageForURL(URL: String) -> NSData?
}

/**
 Cache for image assets. Stores images on disk in the temp directory.
 */
class DiskImageCache: ImageCache {
    static let CacheSubdirectory = "com.dollarshaveclub.imageserum"
    
    func imageForURL(URL: String) -> NSData? {
        guard let hash = hashForURL(URL) else {
            return nil
        }
        
        guard let path = filePathForImage(hash) else {
            return nil
        }
        
        return NSFileManager.defaultManager().contentsAtPath(path)
    }
    
    func hashForURL(URL: String) -> String? {
        guard let data = URL.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        
        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        
        CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
    
    func filePathForImage(byHash: String) -> String? {
        guard let path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
            return nil
        }
        
        let dataPath = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(DiskImageCache.CacheSubdirectory)
        return dataPath.absoluteString
    }
}