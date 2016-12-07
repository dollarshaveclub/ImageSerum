//
//  Queue.swift
//  ImageSerum
//
//  Created by David Peredo on 8/16/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import Foundation

protocol DownloadQueueProtocol {
    func queue(_ URL: URL)
    func pop() -> URL?
    func removeDownload(_ URL: URL)
    func contains(_ URL: URL) -> Bool
}

class DownloadQueueNode {
    var val: URL
    var before: DownloadQueueNode?
    var after: DownloadQueueNode?
    
    init(val: URL) {
        self.val = val
    }
}

class DownloadQueue: DownloadQueueProtocol {
    var head: DownloadQueueNode?
    var tail: DownloadQueueNode?
    var nodesByURL: [URL: DownloadQueueNode]
    
    init() {
        self.nodesByURL = [URL: DownloadQueueNode]()
    }
    
    func queue(_ URL: Foundation.URL) {
        if nodesByURL[URL] == nil {
            let node = DownloadQueueNode(val: URL)
            
            nodesByURL[URL] = node
            
            if tail == nil {
                tail = node
                head = node
            } else {
                tail!.after = node
                node.before = tail
                tail = node
            }
        }
    }
    
    func pop() -> URL? {
        guard let elem = head else {
            return nil
        }
        
        head = elem.after
        
        if let after = elem.after {
            after.before = nil
        }
        
        nodesByURL.removeValue(forKey: elem.val)
        
        return elem.val
    }
    
    func removeDownload(_ URL: Foundation.URL) {
        if let node = nodesByURL.removeValue(forKey: URL) {
            if head === node {
                head = node.after
            }
            
            if let before = node.before {
                before.after = node.after
            }
            
            if let after = node.before {
                after.before = node.before
            }
            
            if tail === node {
                tail = node.before
            }
        }
    }
    
    func contains(_ URL: Foundation.URL) -> Bool {
        return nodesByURL[URL] != nil
    }
    
    func toArray() -> [URL] {
        var current = head
        
        var elements = [URL]()
        while current != nil {
            elements.append(current!.val)
            current = current!.after
        }
        
        return elements
    }
}
