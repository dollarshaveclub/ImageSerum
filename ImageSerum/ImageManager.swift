//
//  File.swift
//  ImageSerum
//
//  Created by David Peredo on 8/11/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import UIKit

public enum ImageManagerError: ErrorType {
    
}

public enum ImagePriority: Int {
    case Low = 10
    case Medium = 50
    case High = 100
}

public class ImageManager {
    static let sharedManager = ImageManager(priorityQueue: HeapPriorityQueue(), imageCache: DiskImageCache())

    public typealias ImageCompletion = ((image: UIImage?, error: ImageManagerError?) -> Void)
    
    let queue: PriorityQueue
    let cache: ImageCache
    
    var completionHolder = [String: [ImageCompletion]]()
    
    init(priorityQueue: PriorityQueue, imageCache: ImageCache) {
        self.queue = priorityQueue
        self.cache = imageCache
    }
    
    public func preloadImage(byURL URL: String, priority: ImagePriority = .Low) {
        queue.insert(URL, priority: priority.rawValue)
    }
    
    public func getImage(byURL URL: String, completion: ImageCompletion) {
        // TODO:
        // Check for cache for data, if so decode and return
        // If cache miss, queue for download with high priority (or bump
        // existing queue item to high priority) and store callback
        // This call should be done async with a barrier or lock on the queue
        // and the cache to ensure that there isn't race conditions.
        if let cachedData = cache.imageForURL(URL) {
            // TODO: Decode image
        } else {
            addCompletionCallback(URL, completion: completion)
            queue.insert(URL, priority: ImagePriority.High.rawValue)
        }
    }
    
    func addCompletionCallback(URL: String, completion: ImageCompletion) {
        if var completions = completionHolder[URL] {
            completions.append(completion)
        } else {
            completionHolder[URL] = [completion]
        }
    }
}