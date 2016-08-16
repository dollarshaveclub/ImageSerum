//
//  PriorityQueue.swift
//  ImageSerum
//
//  Created by David Peredo on 8/11/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import Foundation

class QueueNode {
    let val: String
    let priority: Int
    
    init(val: String, priority: Int) {
        self.val = val
        self.priority = priority
    }
}

func < (left: QueueNode, right: QueueNode) -> Bool {
    return left.priority < right.priority
}

func <= (left: QueueNode, right: QueueNode) -> Bool {
    return left.priority <= right.priority
}

func > (left: QueueNode, right: QueueNode) -> Bool {
    return left.priority > right.priority
}

func >= (left: QueueNode, right: QueueNode) -> Bool {
    return left.priority >= right.priority
}

func == (left: QueueNode, right: QueueNode) -> Bool {
    return left.priority == right.priority
}

protocol PriorityQueue {
    func insert(val: String, priority: Int)
    func popMax() -> String?
    func peakMax() -> String?
}

class HeapPriorityQueue: PriorityQueue {
    var heap: [QueueNode]
    
    public init() {
        self.heap = [QueueNode]()
    }
    
    func insert(val: String, priority: Int) {
        let node = QueueNode(val: val, priority: priority)
        heap.append(node)
        
        var highestPos = heap.count - 1
        while highestPos > 0 {
            let parentPos = Int(floor(Double(highestPos) / 2))
            if heap[parentPos].priority < heap[highestPos].priority {
                swap(parentPos, highestPos)
                highestPos = parentPos
            } else {
                return
            }
                
        }
    }
    
    func popMax() -> String? {
        guard heap.count > 0 else {
            return nil
        }
        
        swap(0, heap.count - 1)
        let val = removeEnd()
        
        heapify(0)
        
        return val
    }
    
    func peakMax() -> String? {
        return heap.first?.val
    }
    
    func heapify(pos: Int) {
        let leftPos = pos * 2
        let rightPos = leftPos + 1
        var largestPos = pos
        
        if leftPos < heap.count && heap[leftPos] > heap[largestPos] {
            largestPos = leftPos
        }
        if rightPos < heap.count && heap[rightPos] > heap[largestPos] {
            largestPos = rightPos
        }
        
        if largestPos != pos {
            swap(pos, largestPos)
            
            // TODO: make non-recursive
            heapify(largestPos)
        }
    }
    
    func swap(firstPos: Int, _ secondPos: Int) {
        let first = heap[firstPos]
        heap[firstPos] = heap[secondPos]
        heap[secondPos] = first
    }
    
    func removeEnd() -> String? {
        guard heap.count > 0 else {
            return nil
        }
        return heap.removeLast().val
    }
}