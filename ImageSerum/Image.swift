//
//  Image.swift
//  ImageSerum
//
//  Created by Michael Mork on 8/22/16.
//  Copyright © 2016 Dollar Shave Club. All rights reserved.
//

import Foundation
import UIKit

struct ImageFrame {
    
    //the frame of this image
    var frame: CGRect
    
    //should the we canvas be cleared before drawing this image?
    //dispose == YES don't draw anything but this image. NO means to draw the previous frames.
    var dispose: Bool
    
    //should only the last drawing rect have transparent pixels or solid background?
    //Blend == YES means it should be transparent and NO means the background color.
    var blend: Bool
    
    //how long should this image frame be display (in milliseconds)?
    var displayDuration: NSInteger
    
    //the image object to display for this frame
    var image: UIImage
    
    init(frame: CGRect, image: UIImage, dispose: Bool, blend: Bool, duration: NSInteger) {
        self.frame = frame
        self.image = image
        self.dispose = dispose
        self.blend = blend
        self.displayDuration = duration
    }
}

import CoreGraphics
import ImageIO
import MobileCoreServices

class Image: NSObject {
    
    typealias ImageDecodeProgress = (progress: Float)->()
    typealias ImageDecodeFinished = ()->()
    
    var size: CGSize
    var frames: [ImageFrame]?
    var backgroundColor: UIColor
    var isDecoded: Bool = false
    var decodeProgress: ImageDecodeProgress?
    var decodeCompletion: ImageDecodeFinished?
    var hasAlpha: Bool = false
    
    static func isValidImage(data: NSData) -> Bool {
        if WebPGetInfo(UnsafePointer<UInt8>(data.bytes), data.length, nil, nil) == 1 {
            return true // valid webP image
        }
        if let ref = CGImageSourceCreateWithData(data, nil) {
            var isImage = false
            if let imageSourceContainerType = CGImageSourceGetType(ref) {
                isImage = UTTypeConformsTo(imageSourceContainerType, kUTTypeImage)
            }
            return isImage
        }
        return false
    }
    
    convenience init(data: NSData) {
        self.init()
        decode(data)
        isDecoded = frames?.count > 0
    }
    
    convenience init(data: NSData, completion: ()->()) {
        self.init()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
            self?.decode(data)
            dispatch_async(dispatch_get_main_queue(), { 
                self?.isDecoded = self?.frames?.count > 0
                if self?.isDecoded == true {
                    completion()
                    guard let finished = self?.decodeCompletion else {return}
                    finished()
                }

            })
        }
    }
    
    convenience init(image: UIImage) {
        self.init()
        size = image.size
        frames = [ImageFrame(frame: CGRect(origin: CGPointZero, size: image.size), image: image, dispose: true, blend: false, duration: 0)]
        backgroundColor = UIColor.clearColor()
        isDecoded = true
    }
    
    override init() {
        size = CGSize()
        backgroundColor = UIColor.blackColor()
        super.init()
    }
    
    func decode(data: NSData) {
        hasAlpha = true
        let scale = UIScreen.mainScreen().scale
        let bytes: UnsafePointer<UInt8> = UnsafePointer<UInt8>(data.bytes)
        
        if WebPGetInfo(bytes, data.length, nil, nil) != 0 {
            decodeWebPData(data, scale: scale)
        } else {
            let ref = CGImageSourceCreateWithData(data, nil)
            if let goodRef = ref as CGImageSource? {
                guard let imageSourceContainerType = CGImageSourceGetType(goodRef) as CFString? else {
                    return
                }
                
                if UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF) {
                    decodeGif(goodRef, data: data, scale: scale)
                    hasAlpha = false
                } else if UTTypeConformsTo(imageSourceContainerType, kUTTypeImage) {
                    if let image = UIImage(data: data, scale: scale) as UIImage? {
                        size = image.size
                        frames = [ImageFrame(frame: CGRect(origin: CGPointZero, size: size), image: image, dispose: true, blend: false, duration: 0)]
                        updateProgress(1.0)
                    }
                } else {
                    //failed to decode.
                }
            }
        }
    }
    
    func decodeGif(ref: CGImageSource, data: NSData, scale: CGFloat) {
        var largestWidth: Int = 0
        var largestHeight: Int = 0
        
        let frameCount = CGImageSourceGetCount(ref)
        
        let progressOffset = 1/frameCount
        var progress = 0
        
        var frames = [ImageFrame]()
        
        for i in 0..<frameCount {
            if let imageRef = CGImageSourceCreateImageAtIndex(ref, i, nil) {
                let image = UIImage(CGImage: imageRef)
                if let frameProps = CGImageSourceCopyPropertiesAtIndex(ref, i, nil) as NSDictionary?,
                   let height = frameProps.objectForKey(kCGImagePropertyPixelHeight)?.integerValue,
                   let width = frameProps.objectForKey(kCGImagePropertyPixelWidth)?.integerValue//[kCGImagePropertyPixelWidth]?.integerValue
                {
                    let frame = CGRect(origin: CGPointZero, size: CGSize(width: CGFloat(width)/scale, height: CGFloat(height)/scale))
                    if Int(frame.size.height) > largestHeight {
                        largestHeight = Int(frame.size.height)
                        largestWidth = Int(frame.size.width)
                    }
                    
                    let gifProps = frameProps.objectForKey(kCGImagePropertyGIFDictionary)
                    
                    var duration: CGFloat = 0.1
                    
                    if let delayTime = gifProps?.objectForKey(kCGImagePropertyGIFUnclampedDelayTime) ?? gifProps?.objectForKey(kCGImagePropertyGIFDelayTime) {
                        duration = CGFloat(delayTime.floatValue ?? 0.1)
                    }
                    
                    duration = duration * 1000.0 // convert centisecond -> millisecond
                    
                    let newFrame = ImageFrame(frame: frame, image: image, dispose: true, blend: false, duration: Int(duration))
                    frames.append(newFrame)
                    progress += progressOffset
                    updateProgress(Float(progress))
                }
            }
            
            size = CGSize(width: largestWidth, height: largestHeight)
            self.frames = frames
            
        }
    }
    
    func decodeWebPData(data: NSData, scale: CGFloat) {
        var imageFrames = [ImageFrame]()
        var webPData = WebPData(bytes: UnsafePointer<UInt8>(data.bytes), size: data.length)
        // setup the demux we need for animated webp images.
        let demux = WebPDemux(&webPData)
        
        let canvasWidth = CGFloat(WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH))/scale
        let canvasHeight = CGFloat(WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT))/scale
        let frameCount = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT)
        let backgroundColor = WebPDemuxGetI(demux, WEBP_FF_BACKGROUND_COLOR)
        
        let b = (backgroundColor >> 24) & 0xff
        let g = (backgroundColor >> 16) & 0xff
        let r = (backgroundColor >> 8) & 0xff
        let a = backgroundColor & 0xff
        self.backgroundColor = UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a))
        self.size = CGSize(width: canvasWidth, height: canvasHeight)
        
        var config = WebPDecoderConfig()
        WebPInitDecoderConfig(&config)
        config.options.use_threads = 1
        let progressOffset: CGFloat = 1/CGFloat(frameCount)
        var progress: CGFloat = 0.0
        
        var iterator = WebPIterator()
        WebPDemuxGetFrame(demux, 1, &iterator)
        if iterator.num_frames > 0 {
        
                repeat {
                    let webPData = iterator.fragment
                    if let image = createImage(webPData.bytes, size: webPData.size, config: &config, scale: scale) {
                        imageFrames.append(ImageFrame(frame: CGRect(origin: CGPointZero, size: image.size), image: image, dispose: true, blend: false, duration: 0))
                        var duration = iterator.duration
                        if duration <= 0 {
                            duration = 100
                        }
                        
                        let blend = iterator.blend_method == WEBP_MUX_BLEND
                        let dispose = iterator.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND
                        let frame = CGRect(x: CGFloat(iterator.x_offset)/scale, y: CGFloat(iterator.y_offset)/scale, width: CGFloat(iterator.width)/scale, height: CGFloat(iterator.height)/scale)
                        
                        imageFrames.append(ImageFrame(frame: frame, image: image, dispose: dispose, blend: blend, duration: Int(duration)))
                        progress += progressOffset
                        updateProgress(Float(progress))
                    }
                } while (WebPDemuxNextFrame(&iterator) == 1)
            
        } else {
            if let image = createImage(UnsafePointer<UInt8>(data.bytes), size: webPData.size, config: &config, scale: scale) {
                imageFrames.append(ImageFrame(frame: CGRect(origin: CGPointZero, size: image.size), image: image, dispose: true, blend: false, duration: 0))
                
                progress += progressOffset
                updateProgress(Float(progress))
            }
        }
        
        self.frames = imageFrames
    }

    func updateProgress(progress: Float) {
        
        guard let decodeProgress = decodeProgress else {return}
        var progress = progress
        if progress > 1.0 {
            progress = 1.0
        } else if progress < 0.0 {
            progress = 0.0
        }
        
        dispatch_async(dispatch_get_main_queue()) { 
            decodeProgress(progress: progress)
        }
    }
    
    func createImage(bytes: UnsafePointer<UInt8>, size: size_t, config: UnsafeMutablePointer<WebPDecoderConfig>, scale: CGFloat) -> UIImage? {
        
        if VP8StatusCode(WebPDecode(bytes, size, config).rawValue) != VP8_STATUS_OK {
            return nil
        }
        
        var height: Int32 = 0
        var width: Int32 = 0
        let data = WebPDecodeRGBA(bytes, size, &width, &height)
        var config = config
        let provider = CGDataProviderCreateWithData(&config, data, Int(width*height*4), nil)//(&config, data, width * height * 4, free_image_data)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.ByteOrderDefault//: CGBitmapInfo = [.ByteOrderDefault, .AlphaInfoMask] // < -- 0_- latest fix.
        guard let imageRef = CGImageCreate(Int(width), Int(height), 8, 32, 4*Int(width), colorSpace,
                                           bitmapInfo, provider, nil, true, .RenderingIntentDefault) else {
                                            return nil
        }
        let image = UIImage(CGImage: imageRef, scale: scale, orientation: .Up)
        WebPFreeDecBuffer(&config.memory.output);

        return image
    }
}
