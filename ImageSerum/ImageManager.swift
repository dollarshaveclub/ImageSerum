//
//  File.swift
//  ImageSerum
//
//  Created by David Peredo on 8/11/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import UIKit

public enum ImagePriority: Int {
    case low = 10
    case medium = 50
    case high = 100
}

open class ImageManager: DownloadManagerDelegate {
    static let sharedManager = ImageManager(imageCache: DiskImageCache(), downloadManager: DownloadManager.sharedManager)

    public typealias ImageCompletion = ((_ image: UIImage?, _ error: NSError?) -> Void)
    
    let cache: ImageCache
    let downloadManager: DownloadManager
    let dispatchQueue: DispatchQueue
    var completionCallbacksForURL = [URL: [ImageCompletion]]()
    
    init(imageCache: ImageCache, downloadManager: DownloadManager) {
        self.cache = imageCache
        self.downloadManager = downloadManager
        self.dispatchQueue = DispatchQueue(label: "com.dollarshaveclub.imageserum.imagemanager", attributes: [])
    }
    
    open func preloadImage(byURL URL: Foundation.URL, priority: ImagePriority = .low) {
        dispatchQueue.async(flags: .barrier, execute: { [weak self] in
            guard let manager = self else {
                return
            }
            
            if !manager.cache.containsImageForURL(URL) {
                manager.downloadManager.fetchImageToDisk(URL)
            }
        }) 
    }
    
    open func getImage(byURL URL: Foundation.URL, completion: @escaping ImageCompletion) {
        // TODO:
        // Check for cache for data, if so decode and return
        // If cache miss, queue for download with high priority (or bump
        // existing queue item to high priority) and store callback
        // This call should be done async with a barrier or lock on the queue
        // and the cache to ensure that there isn't race conditions.
        dispatchQueue.async(flags: .barrier, execute: { [weak self] in
            guard let manager = self else {
                return
            }
            
            if let cachedData = manager.cache.imageForURL(URL) {
                // TODO: decode image and notify callback
            } else {
                manager.addCompletionCallback(URL, completion: completion)
                manager.downloadManager.fetchImage(URL)
            }
        }) 
    }
    
    func addCompletionCallback(_ URL: Foundation.URL, completion: @escaping ImageCompletion) {
        if var completions = completionCallbacksForURL[URL] {
            completions.append(completion)
        } else {
            completionCallbacksForURL[URL] = [completion]
        }
    }
    
    func completeCallbacks(_ URL: Foundation.URL, image: UIImage?, error: NSError?) {
        if let callbacks = completionCallbacksForURL[URL] {
            for callback in callbacks {
                callback(image, error)
            }
        }
    }
    
    // MARK: DownloadManagerDelegate
    
    func downloadManagerFinishedDownloading(_ URL: Foundation.URL, data: Data) {
        dispatchQueue.sync(flags: .barrier, execute: { [weak self] in
            guard let manager = self else{
                return
            }
            
            manager.cache.cacheImage(URL, data: data)
            
            // TODO: schedule decode and notify callbacks
        }) 
    }
    
    func downloadManagerFinishedDownloadingToDisk(_ URL: Foundation.URL, fileURL: Foundation.URL) {
        dispatchQueue.sync(flags: .barrier, execute: { [weak self] in
            guard let manager = self else{
                return
            }
            
            manager.cache.cacheImageFromURL(URL, at: fileURL)
        }) 
    }
    
    func downloadManagerFailedDownloading(_ URL: Foundation.URL, error: Error) {
        dispatchQueue.sync(flags: .barrier, execute: {
            // TODO: notify callbacks of failed download
        }) 
    }
}
