//
//  DownloadManager.swift
//  ImageSerum
//
//  Created by David Peredo on 8/16/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import Foundation

let DownloadManagerErrorDomain = "com.dollarshaveclub.imageserum.downloadmanager"

let DownloadManagerErrorCodeDataFailed = 100

protocol DownloadManagerDelegate: class {
    func downloadManagerFinishedDownloading(URL: NSURL, data: NSData)
    func downloadManagerFinishedDownloadingToDisk(URL: NSURL, fileURL: NSURL)
    func downloadManagerFailedDownloading(URL: NSURL, error: NSError)
}

class DownloadManager: NSObject, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    static let sharedManager = DownloadManager(backgroundQueue: DownloadQueue(), priorityQueue: DownloadQueue())
    
    let backgroundQueue: DownloadQueueProtocol
    let priorityQueue: DownloadQueueProtocol
    let session: NSURLSession
    
    weak var delegate: DownloadManagerDelegate?
    
    var currentlyDownloading: Set<NSURL>
    var backgroundDispatchQueue: dispatch_queue_t
    var priorityDispatchQueue: dispatch_queue_t
    var maxBackgroundDownloads = 2
    var maxPriorityDownloads = 2
    
    var concurrentBackgroundDownloads = 0
    var concurrentPriorityDownloads = 0
    
    init(backgroundQueue: DownloadQueueProtocol, priorityQueue: DownloadQueueProtocol) {
        self.backgroundDispatchQueue = dispatch_queue_create("com.dollarshaveclub.imageserum.background-dispatch-queue", DISPATCH_QUEUE_CONCURRENT)
        self.priorityDispatchQueue = dispatch_queue_create("com.dollarshaveclub.imageserum.priority-dispatch-queue", DISPATCH_QUEUE_CONCURRENT)
        self.currentlyDownloading = Set<NSURL>()
        self.backgroundQueue = backgroundQueue
        self.priorityQueue = priorityQueue
        self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    func fetchImageToDisk(URL: NSURL) {
        dispatch_barrier_async(backgroundDispatchQueue) { [weak self] in
            guard let manager = self else {
                return
            }
            
            if !manager.backgroundQueue.contains(URL) && !manager.priorityQueue.contains(URL) && !manager.currentlyDownloading.contains(URL) {
                manager.backgroundQueue.queue(URL)
            }
            
            manager.processBackgroundQueue()
        }
    }
    
    func fetchImage(URL: NSURL) {
        dispatch_barrier_async(backgroundDispatchQueue) { [weak self] in
            guard let manager = self else {
                return
            }
            
            if !manager.backgroundQueue.contains(URL) {
                manager.backgroundQueue.removeDownload(URL)
            }
            
            if !manager.priorityQueue.contains(URL) && !manager.currentlyDownloading.contains(URL) {
                manager.backgroundQueue.removeDownload(URL)
                manager.priorityQueue.queue(URL)
            }
        }
    }
    
    func processBackgroundQueue()  {
        if concurrentBackgroundDownloads < maxBackgroundDownloads {
            if let nextURL = backgroundQueue.pop() {
                concurrentBackgroundDownloads += 1
                
                let task = session.downloadTaskWithURL(nextURL)
                task.resume()
            }
        }
    }
    
    func processPriorityQueue() {
        if concurrentPriorityDownloads < maxPriorityDownloads {
            if let nextURL = priorityQueue.pop() {
                concurrentPriorityDownloads += 1
                
                let task = session.dataTaskWithURL(nextURL, completionHandler: { [weak self] (data, response, error) in
                    guard let manager = self else {
                        return
                    }
                    
                    dispatch_barrier_async(manager.priorityDispatchQueue) { [weak self] in
                        guard let manager = self else {
                            return
                        }
                        
                        if let data = data where error == nil {
                            manager.delegate?.downloadManagerFinishedDownloading(nextURL, data: data)
                        } else {
                            if let error = error {
                                manager.delegate?.downloadManagerFailedDownloading(nextURL, error: error)
                            } else {
                                let error = NSError(domain: DownloadManagerErrorDomain, code: DownloadManagerErrorCodeDataFailed, userInfo: nil)
                                manager.delegate?.downloadManagerFailedDownloading(nextURL, error: error)
                            }
                        }
                        
                        manager.concurrentPriorityDownloads -= 1
                        manager.processPriorityQueue()
                    }
                })
                task.resume()
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let URL = downloadTask.originalRequest?.URL else {
            return
        }
        
        dispatch_barrier_async(backgroundDispatchQueue) { [weak self] in
            guard let manager = self else {
                return
            }
            
            manager.delegate?.downloadManagerFinishedDownloadingToDisk(URL, fileURL: location)
            
            manager.concurrentBackgroundDownloads -= 1
            manager.processBackgroundQueue()
        }
    }
}