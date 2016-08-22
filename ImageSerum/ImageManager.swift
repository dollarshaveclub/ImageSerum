//
//  File.swift
//  ImageSerum
//
//  Created by David Peredo on 8/11/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import UIKit

public enum ImagePriority: Int {
    case Low = 10
    case Medium = 50
    case High = 100
}

public class ImageManager: DownloadManagerDelegate {
    static let sharedManager = ImageManager(imageCache: DiskImageCache(), downloadManager: DownloadManager.sharedManager)

    public typealias ImageCompletion = ((image: UIImage?, error: NSError?) -> Void)
    
    let cache: ImageCache
    let downloadManager: DownloadManager
    let dispatchQueue: dispatch_queue_t
    var completionCallbacksForURL = [NSURL: [ImageCompletion]]()
    
    init(imageCache: ImageCache, downloadManager: DownloadManager) {
        self.cache = imageCache
        self.downloadManager = downloadManager
        self.dispatchQueue = dispatch_queue_create("com.dollarshaveclub.imageserum.imagemanager", DISPATCH_QUEUE_SERIAL)
    }
    
    public func preloadImage(byURL URL: NSURL, priority: ImagePriority = .Low) {
        dispatch_barrier_async(dispatchQueue) { [weak self] in
            guard let manager = self else {
                return
            }
            
            if !manager.cache.containsImageForURL(URL) {
                manager.downloadManager.fetchImageToDisk(URL)
            }
        }
    }
    
    public func getImage(byURL URL: NSURL, completion: ImageCompletion) {
        // TODO:
        // Check for cache for data, if so decode and return
        // If cache miss, queue for download with high priority (or bump
        // existing queue item to high priority) and store callback
        // This call should be done async with a barrier or lock on the queue
        // and the cache to ensure that there isn't race conditions.
        dispatch_barrier_async(dispatchQueue) { [weak self] in
            guard let manager = self else {
                return
            }
            
            if let cachedData = manager.cache.imageForURL(URL) {
                // TODO: decode image and notify callback
            } else {
                manager.addCompletionCallback(URL, completion: completion)
                manager.downloadManager.fetchImage(URL)
            }
        }
    }
    
    func addCompletionCallback(URL: NSURL, completion: ImageCompletion) {
        if var completions = completionCallbacksForURL[URL] {
            completions.append(completion)
        } else {
            completionCallbacksForURL[URL] = [completion]
        }
    }
    
    func completeCallbacks(URL: NSURL, image: UIImage?, error: NSError?) {
        if let callbacks = completionCallbacksForURL[URL] {
            for callback in callbacks {
                callback(image: image, error: error)
            }
        }
    }
    
    // MARK: DownloadManagerDelegate
    
    func downloadManagerFinishedDownloading(URL: NSURL, data: NSData) {
        dispatch_barrier_sync(dispatchQueue) { [weak self] in
            guard let manager = self else{
                return
            }
            
            manager.cache.cacheImage(URL, data: data)
            
            // TODO: schedule decode and notify callbacks
        }
    }
    
    func downloadManagerFinishedDownloadingToDisk(URL: NSURL, fileURL: NSURL) {
        dispatch_barrier_sync(dispatchQueue) { [weak self] in
            guard let manager = self else{
                return
            }
            
            manager.cache.cacheImageFromURL(URL, at: fileURL)
        }
    }
    
    func downloadManagerFailedDownloading(URL: NSURL, error: NSError) {
        dispatch_barrier_sync(dispatchQueue) {
            // TODO: notify callbacks of failed download
        }
    }
}