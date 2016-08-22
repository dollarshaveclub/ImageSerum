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
    func containsImageForURL(URL: NSURL) -> Bool
    func imageForURL(URL: NSURL) -> NSData?
    func cacheImageFromURL(URL: NSURL, at fileURL: NSURL)
    func cacheImage(URL: NSURL, data: NSData)
}

/**
 Cache for image assets. Stores images on disk in the temp directory.
 */
class DiskImageCache: ImageCache {
    static let CacheSubdirectory = "com.dollarshaveclub.imageserum"
    
    func containsImageForURL(URL: NSURL) -> Bool {
        guard let hash = hashForURL(URL) else {
            return false
        }
        
        guard let path = filePathForImage(hash) else {
            return false
        }
        
        return NSFileManager.defaultManager().fileExistsAtPath(path.absoluteString)
    }
    
    func imageForURL(URL: NSURL) -> NSData? {
        guard let hash = hashForURL(URL) else {
            return nil
        }
        
        guard let path = filePathForImage(hash) else {
            return nil
        }
        
        return NSFileManager.defaultManager().contentsAtPath(path.absoluteString)
    }
    
    func cacheImageFromURL(URL: NSURL, at fileURL: NSURL) {
        guard let hash = hashForURL(URL) else {
            return
        }
        
        guard let path = filePathForImage(hash) else {
            return
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(fileURL, toURL: path)
        } catch {
            
        }
    }
    
    func cacheImage(URL: NSURL, data: NSData) {
        guard let hash = hashForURL(URL) else {
            return
        }
        
        guard let path = filePathForImage(hash) else {
            return
        }
        
        do {
            try data.writeToURL(path, options: [])
        } catch {
            
        }
    }
    
    func hashForURL(URL: NSURL) -> String? {
        guard let data = URL.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
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
    
    func filePathForImage(byHash: String) -> NSURL? {
        guard let path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
            return nil
        }
        
        let dataPath = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(DiskImageCache.CacheSubdirectory)
        return dataPath
    }
}