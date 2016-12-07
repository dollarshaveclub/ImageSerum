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
    func containsImageForURL(_ URL: URL) -> Bool
    func imageForURL(_ URL: URL) -> Data?
    func cacheImageFromURL(_ URL: URL, at fileURL: URL)
    func cacheImage(_ URL: URL, data: Data)
}

/**
 Cache for image assets. Stores images on disk in the temp directory.
 */
class DiskImageCache: ImageCache {
    static let CacheSubdirectory = "com.dollarshaveclub.imageserum"
    
    func containsImageForURL(_ URL: Foundation.URL) -> Bool {
        guard let hash = hashForURL(URL) else {
            return false
        }
        
        guard let path = filePathForImage(hash) else {
            return false
        }
        
        return FileManager.default.fileExists(atPath: path.absoluteString)
    }
    
    func imageForURL(_ URL: Foundation.URL) -> Data? {
        guard let hash = hashForURL(URL) else {
            return nil
        }
        
        guard let path = filePathForImage(hash) else {
            return nil
        }
        
        return FileManager.default.contents(atPath: path.absoluteString)
    }
    
    func cacheImageFromURL(_ URL: Foundation.URL, at fileURL: Foundation.URL) {
        guard let hash = hashForURL(URL) else {
            return
        }
        
        guard let path = filePathForImage(hash) else {
            return
        }
        
        do {
            try FileManager.default.moveItem(at: fileURL, to: path)
        } catch {
            
        }
    }
    
    func cacheImage(_ URL: Foundation.URL, data: Data) {
        guard let hash = hashForURL(URL) else {
            return
        }
        
        guard let path = filePathForImage(hash) else {
            return
        }
        
        do {
            try data.write(to: path, options: [])
        } catch {
            
        }
    }
    
    func hashForURL(_ URL: Foundation.URL) -> String? {
        guard let data = URL.absoluteString.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        CC_MD5((data as NSData).bytes, CC_LONG(data.count), &digest)
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
    
    func filePathForImage(_ byHash: String) -> URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        let dataPath = URL(fileURLWithPath: path).appendingPathComponent(DiskImageCache.CacheSubdirectory)
        return dataPath
    }
}
