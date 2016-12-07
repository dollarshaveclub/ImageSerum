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
    func downloadManagerFinishedDownloading(_ URL: URL, data: Data)
    func downloadManagerFinishedDownloadingToDisk(_ URL: URL, fileURL: URL)
    func downloadManagerFailedDownloading(_ URL: URL, error: Error)
}

class DownloadManager: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {
    static let sharedManager = DownloadManager(backgroundQueue: DownloadQueue(), priorityQueue: DownloadQueue())
    
    let backgroundQueue: DownloadQueueProtocol
    let priorityQueue: DownloadQueueProtocol
    let session: Foundation.URLSession
    
    weak var delegate: DownloadManagerDelegate?
    
    var currentlyDownloading: Set<URL>
    var dispatchQueue: DispatchQueue
    var maxBackgroundDownloads = 2
    var maxPriorityDownloads = 2
    
    var concurrentBackgroundDownloads = 0
    var concurrentPriorityDownloads = 0
    
    init(backgroundQueue: DownloadQueueProtocol, priorityQueue: DownloadQueueProtocol) {
        self.dispatchQueue = DispatchQueue(label: "com.dollarshaveclub.imageserum.priority-dispatch-queue", attributes: [])
        self.currentlyDownloading = Set<URL>()
        self.backgroundQueue = backgroundQueue
        self.priorityQueue = priorityQueue
        self.session = Foundation.URLSession(configuration: URLSessionConfiguration.default)
    }
    
    func fetchImageToDisk(_ URL: Foundation.URL) {
        dispatchQueue.async { [weak self] in
            guard let manager = self else {
                return
            }
            
            if !manager.backgroundQueue.contains(URL) && !manager.priorityQueue.contains(URL) && !manager.currentlyDownloading.contains(URL) {
                manager.backgroundQueue.queue(URL)
            }
            
            manager.processBackgroundQueue()
        }
    }
    
    func fetchImage(_ URL: Foundation.URL) {
        dispatchQueue.async { [weak self] in
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
                
                let task = session.downloadTask(with: nextURL)
                task.resume()
            }
        }
    }
    
    func processPriorityQueue() {
        if concurrentPriorityDownloads < maxPriorityDownloads {
            if let nextURL = priorityQueue.pop() {
                concurrentPriorityDownloads += 1
                
                let task = session.dataTask(with: nextURL, completionHandler: { [weak self] (data, response, error) in
                    guard let manager = self else {
                        return
                    }
                    
                    manager.dispatchQueue.async { [weak self] in
                        guard let manager = self else {
                            return
                        }
                        
                        if let data = data, error == nil {
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
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let URL = downloadTask.originalRequest?.url else {
            return
        }
        
        dispatchQueue.async { [weak self] in
            guard let manager = self else {
                return
            }
            
            manager.delegate?.downloadManagerFinishedDownloadingToDisk(URL, fileURL: location)
            
            manager.concurrentBackgroundDownloads -= 1
            manager.processBackgroundQueue()
        }
    }
}
