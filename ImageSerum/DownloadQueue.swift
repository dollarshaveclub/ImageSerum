//
//  Queue.swift
//  ImageSerum
//
//  Created by David Peredo on 8/16/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import Foundation

protocol DownloadQueueProtocol {
    func queue(URL: NSURL)
    func pop() -> NSURL?
    func removeDownload(URL: NSURL)
    func contains(URL: NSURL) -> Bool
}

class DownloadQueueNode {
    var val: NSURL
    var before: DownloadQueueNode?
    var after: DownloadQueueNode?
    
    init(val: NSURL) {
        self.val = val
    }
}

class DownloadQueue: DownloadQueueProtocol {
    var head: DownloadQueueNode?
    var tail: DownloadQueueNode?
    var nodesByURL: [NSURL: DownloadQueueNode]
    
    init() {
        self.nodesByURL = [NSURL: DownloadQueueNode]()
    }
    
    func queue(URL: NSURL) {
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
    
    func pop() -> NSURL? {
        guard let elem = head else {
            return nil
        }
        
        head = elem.after
        
        if let after = elem.after {
            after.before = nil
        }
        
        nodesByURL.removeValueForKey(elem.val)
        
        return elem.val
    }
    
    func removeDownload(URL: NSURL) {
        if let node = nodesByURL.removeValueForKey(URL) {
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
    
    func contains(URL: NSURL) -> Bool {
        return nodesByURL[URL] != nil
    }
    
    func toArray() -> [NSURL] {
        var current = head
        
        var elements = [NSURL]()
        while current != nil {
            elements.append(current!.val)
            current = current!.after
        }
        
        return elements
    }
}