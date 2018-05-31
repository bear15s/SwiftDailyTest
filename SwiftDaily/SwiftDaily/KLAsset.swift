//
//  KLAsset.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/4/27.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import Foundation
import MobileCoreServices
import AssetsLibrary
import Photos

enum KLAssetType {
    case  Unknow,                              // 未知类型的 Asset
          Image,                               // 图片类型的 Asset
          Video,                               // 视频类型的 Asset
          Audio,    // 音频类型的 Asset，仅被 PhotoKit 支持，因此只适用于 iOS 8.0
          LivePhoto// Live Photo 类型的 Asset，仅被 PhotoKit 支持，因此只适用于 iOS 9.1
}

enum KLDownloadStatus {
    case  Succeed,     // 下载成功或资源本来已经在本地
          Downloading, // 下载中
          Canceled,    // 取消下载
          Failed      // 下载失败
}

struct KLAssetConstants {
    static let kAssetInfoImageData = "imageData"
    static let kAssetInfoOriginInfo = "originInfo"
    static let kAssetInfoDataUTI = "dataUTI"
    static let kAssetInfoOrientation = "orientation"
    static let kAssetInfoSize = "size"
}

class KLAsset : NSObject {
    /// 从 iCloud 下载资源大图的状态
    var requestID:String?
    /// 从 iCloud 请求获得资源的大图的请求 ID
    var downloadStatus:KLDownloadStatus?
    /// 从 iCloud 请求获得资源的进度
    var downloadProgress:Double{
        get { return self.downloadProgress }
        set(newProgress){
            self.downloadProgress = newProgress
            self.downloadStatus = KLDownloadStatus.Downloading
        }
    }
    var assetType:KLAssetType?
    var userPhotoKit:Bool = {
        return KLAssetsManager.sharedInstance.usePhotoKit
    }()
    var alAsset:ALAsset?
    var phAsset:PHAsset?
    var alAssetRepresentation:ALAssetRepresentation?
    var phAssetInfo:Dictionary<String, Any>?
    var imageSize:Float = 0.0
    var assetIdentityHash:String?
    
    public init(aPhAsset:PHAsset){
        self.phAsset = aPhAsset
        self.userPhotoKit = true
        switch aPhAsset.mediaType {
        case .image:
            self.assetType = KLAssetType.Image
            break
        case .audio:
            self.assetType = KLAssetType.Audio
            break
        case .video:
            self.assetType = KLAssetType.Video
            break
        default:
            self.assetType = KLAssetType.Unknow
            break
        }
    }
    
    public init(aALAsset:ALAsset){
        self.alAsset = aALAsset
        self.alAssetRepresentation = alAsset?.defaultRepresentation()
        self.userPhotoKit = false
        let propertyType:String = aALAsset.value(forProperty: ALAssetPropertyType) as! String
        if propertyType == ALAssetTypePhoto{
            self.assetType = KLAssetType.Image
        } else if propertyType == ALAssetTypeVideo{
            self.assetType = KLAssetType.Video
        } else {
            self.assetType = KLAssetType.Unknow
        }
    }
   
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    func originImage() -> UIImage? {
        var resultImg:UIImage?
        if self.userPhotoKit {
            let phImageRequestOptions = PHImageRequestOptions.init()
            phImageRequestOptions.isSynchronous = true
            KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: self.phAsset!, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: phImageRequestOptions, resultHandler: { (resultImage, info) in
                resultImg = resultImage
            })
        } else {
            if var fullResolutionImageRef = self.alAssetRepresentation?.fullScreenImage().takeUnretainedValue(){
                // 通过 fullResolutionImage 获取到的的高清图实际上并不带上在照片应用中使用“编辑”处理的效果，需要额外在 AlAssetRepresentation 中获取这些信息
                if let adjustment:String = self.alAssetRepresentation?.metadata()["adjustmentXMP"] as? String,let xmpData = adjustment.data(using: String.Encoding.utf8){
                    var tempImage = CIImage.init(cgImage: fullResolutionImageRef)
                    var error:NSError?
                    let filterArray:[CIFilter] =  CIFilter.filterArray(fromSerializedXMP: xmpData, inputImageExtent: tempImage.extent, error: &error)
                    let content = CIContext.init(options: nil)
                    for filter in filterArray {
                        filter.setValue(tempImage, forKey: kCIInputImageKey)
                        tempImage = filter.outputImage!
                    }
                    fullResolutionImageRef = content.createCGImage(tempImage, from: tempImage.extent)!
                    
                    print("error = \(error)")
                    
                }
                let imageOrientation:UIImageOrientation = UIImageOrientation(rawValue: self.alAssetRepresentation!.orientation().rawValue)!
                resultImg = UIImage.init(cgImage: fullResolutionImageRef, scale: CGFloat(self.alAssetRepresentation!.scale()), orientation: imageOrientation)
                
            }
        }
        return resultImg
    }
    
    func thumbnailImage(size:CGSize) -> UIImage?{
        var resultImage:UIImage?
        if self.userPhotoKit {
            let phImageRequestOptions = PHImageRequestOptions.init()
            phImageRequestOptions.resizeMode = .exact
            // 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
            if let phAsset = self.phAsset {
                KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale), contentMode: PHImageContentMode.aspectFill, options: phImageRequestOptions, resultHandler: { (result, info) in
                    resultImage = result
                })
            }
        } else {
            if let thumbnailImageRef = self.alAsset?.thumbnail().takeUnretainedValue(){
                resultImage = UIImage.init(cgImage: thumbnailImageRef)
            }
        }
        return resultImage
    }
    
    func previewImage()->UIImage?{
        var resultImage:UIImage?
        if self.userPhotoKit {
            let imageRequestOptions = PHImageRequestOptions.init()
            imageRequestOptions.isSynchronous = true
            if let phAsset = self.phAsset {
                KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), contentMode: .aspectFill, options: imageRequestOptions, resultHandler: { (result, info) in
                    resultImage = result
                })
            }
        }else {
            if let fullScreenImageRef = self.alAssetRepresentation?.fullScreenImage().takeUnretainedValue(){
                resultImage = UIImage.init(cgImage: fullScreenImageRef)
            }
        }
        return resultImage
    }
    
    func requestOriginImage(completion:@escaping (_ result:UIImage?,_ info:Dictionary
        <String,Any>?)-> Void,progressHander:@escaping PHAssetImageProgressHandler)->Int32{
        var id:Int32 = 0
        if(self.userPhotoKit){
            if let phAsset = self.phAsset {
                let imageRequestOption = PHImageRequestOptions.init()
                imageRequestOption.isNetworkAccessAllowed = true
                imageRequestOption.progressHandler = progressHander
                id  = KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: imageRequestOption, resultHandler: { (result, info) in
                    completion(result,info as? Dictionary<String, Any>)
                })
            }
        }else{
            completion(self.originImage(),nil)
            id = 0
        }
        return id
    }
    
    func requestThumbnailImage(size:CGSize,completion:@escaping (_ result:UIImage?,_ info:Dictionary
        <String,Any>?)-> Void,progressHander:@escaping PHAssetImageProgressHandler)->Int32{
        var id:Int32 = 0
        if(self.userPhotoKit){
            if let phAsset = self.phAsset {
                let imageRequestOption = PHImageRequestOptions.init()
                imageRequestOption.resizeMode = .fast
                imageRequestOption.progressHandler = progressHander
                id  = KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale), contentMode: .aspectFill, options: imageRequestOption, resultHandler: { (result, info) in
                    completion(result,info as? Dictionary<String, Any>)
                })
            }
        }else{
            completion(self.thumbnailImage(size: size),nil)
            id = 0
        }
        return id
    }
    
    func requestPreviewImage(completion:@escaping (_ result:UIImage?,_ info:Dictionary
        <String,Any>?)-> Void,progressHander:@escaping PHAssetImageProgressHandler)->Int32{
        var id:Int32 = 0
        if(self.userPhotoKit){
            if let phAsset = self.phAsset {
                let imageRequestOption = PHImageRequestOptions.init()
                imageRequestOption.isNetworkAccessAllowed = true
                imageRequestOption.progressHandler = progressHander
                id  = KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), contentMode: .aspectFill, options: imageRequestOption, resultHandler: { (result, info) in
                    completion(result,info as? Dictionary<String, Any>)
                })
            }
        }else{
            completion(self.previewImage(),nil)
            id = 0
        }
        return id
    }
    
    @objc func requestLivePhoto(completion:@escaping (_ result:PHLivePhoto?,_ info: [AnyHashable : Any]?)-> Void,progressHander:@escaping PHAssetImageProgressHandler)->Int32{
        var id:Int32 = 0
        if self.userPhotoKit && PHCachingImageManager.classForCoder().instancesRespond(to: #selector(requestLivePhoto(completion:progressHander:))){
            if let phAsset = self.phAsset {
                let livePhotoRequestOptions = PHLivePhotoRequestOptions.init()
                livePhotoRequestOptions.isNetworkAccessAllowed  = true
                livePhotoRequestOptions.progressHandler = progressHander
                id = KLAssetsManager.sharedInstance.phCachingImageManager.requestLivePhoto(for: phAsset, targetSize: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), contentMode: .default, options: livePhotoRequestOptions, resultHandler: { (livePhoto, info) in
                    completion(livePhoto,info)
                })
            }
        }else {
            id = 0
        }
        return id
    }
    
    @objc func requestPlayerItem(completion:@escaping (_ playerItem:AVPlayerItem?,_ info:[AnyHashable:Any]?)->Void,phProgressHandler:@escaping PHAssetVideoProgressHandler)->Int32{
        var id:Int32 = 0
        if self.userPhotoKit && PHCachingImageManager.classForCoder().instancesRespond(to: #selector(requestPlayerItem(completion:phProgressHandler:))){
            let videoRequestOptions = PHVideoRequestOptions.init()
            videoRequestOptions.isNetworkAccessAllowed = true
            videoRequestOptions.progressHandler = phProgressHandler
            if let phAsset = self.phAsset {
                id = KLAssetsManager.sharedInstance.phCachingImageManager.requestPlayerItem(forVideo: phAsset, options: videoRequestOptions, resultHandler: { (playerItem, info) in
                    completion(playerItem,info)
                })
            }
        }else {
            if let url = self.alAssetRepresentation?.url() {
                let playerItem = AVPlayerItem.init(url: url)
                completion(playerItem,nil)
            }
        }
        return id
    }
    
    func requestImageData(completeClosure:@escaping (_ imageData:Data?,_ info:[String:Any]?,_ isGif:Bool)->Void){
        if self.assetType != KLAssetType.Image && self.assetType != KLAssetType.LivePhoto {
            completeClosure(nil,nil,false)
            return
        }
        
        if self.userPhotoKit {
            if self.phAssetInfo != nil{
                 // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
                weak var weakSelf = self
                self.requestPhAssetInfo({ (phAssetInfo) in
                    weakSelf?.phAssetInfo = phAssetInfo
//                    if completeClosure != nil {
                        weakSelf?.phAssetInfo = phAssetInfo
                    if let dataUTI:String = weakSelf?.phAssetInfo!["dataUTI"] as? String,let originInfo:[String:Any] = weakSelf?.phAssetInfo!["originInfo"] as? [String : Any],let infoImageData:Data = weakSelf?.phAssetInfo!["imageData"] as? Data{
                            let typeGIF:String = kUTTypeGIF as String
                            let isGIF:Bool = dataUTI == typeGIF
                            DispatchQueue.main.async {
                                completeClosure(infoImageData,originInfo,isGIF)
                            }
                    }
//                    }
                })
            }else {
                self.assetSize({ (size) in
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
                    var error:NSError?
//                 // 获取 NSData 数据
                    if let bytes = self.alAssetRepresentation?.getBytes(buffer, fromOffset: 0, length: Int(size), error: &error){
                        let imageData = Data.init(bytes: buffer, count: bytes)
                        free(buffer)
                         // 判断是否为 GIF 图
                        let gifRepresentation = self.alAsset?.representation(forUTI: kUTTypeGIF as String)
                        if gifRepresentation != nil {
                            completeClosure(imageData,nil,true)
                        } else{
                            completeClosure(imageData,nil,false)
                        }
                    }
                })
            }
        }
    }
    
    func imageOrientation()->UIImageOrientation{
        var orientation:UIImageOrientation = UIImageOrientation.up
        if self.assetType == KLAssetType.Image || self.assetType == KLAssetType.LivePhoto{
            if self.userPhotoKit{
                  // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
                self.requestPhAssetInfo(synchronous: true, { (phAssetInfo) in
                    self.phAssetInfo = phAssetInfo
                })
                // 从 PhAssetInfo 中获取 UIImageOrientation 对应的字段
                if let assetOrientation = self.phAssetInfo!["orientation"] as? UIImageOrientation{
                    orientation = assetOrientation
                }
            }else{
                if let alAssetOrientation:ALAssetOrientation = self.alAsset?.value(forProperty: "ALAssetPropertyOrientation") as! ALAssetOrientation{
                    orientation = UIImageOrientation(rawValue: alAssetOrientation.rawValue)!
                }
            }
        }
        return orientation
    }
    
    func assetIdentity()->String{
        if self.assetIdentityHash != nil {
            return self.assetIdentityHash!
        }
        var identity:String?
        if self.userPhotoKit {
            identity = self.phAsset?.localIdentifier
        }else {
            identity = self.alAssetRepresentation?.url().absoluteString
        }
        self.assetIdentityHash = identity?.MD5()
        return self.assetIdentityHash!
    }
    
    func requestPhAssetInfo(_ complete: @escaping (_ phAssetInfo:[String:Any]?)->Void){
        if self.phAsset == nil {
            complete(nil)
            return
        }
        if self.assetType == KLAssetType.Video {
            KLAssetsManager.sharedInstance.phCachingImageManager.requestAVAsset(forVideo: self.phAsset!, options: nil, resultHandler: { (resultAsset, audioMix, info) in
                if (resultAsset?.isKind(of: AVURLAsset.classForCoder()))! {
                    var tempInfo = [String:Any]()
                    if info != nil {
                        tempInfo.updateValue(tempInfo, forKey: "originInfo")
                    }
                    let urlAsset = resultAsset as! AVURLAsset
                    var urlSet:Set<URLResourceKey> = Set()
                    urlSet.insert(URLResourceKey.init(kCFURLFileSizeKey as String))
                    do {
                        let values:URLResourceValues =  try urlAsset.url.resourceValues(forKeys: urlSet)
                        if let size = values.fileSize {
                            tempInfo.updateValue(size, forKey: KLAssetConstants.kAssetInfoSize)
                            complete(tempInfo)
                        }
                    }catch{
                        print("error = \(error)")
                    }
                }
            })
        }
    }
    
    func requestPhAssetInfo(synchronous:Bool,_ completeClosure:((_ phAssetInfo:[String:Any]?)->Void)?){
        let imageRequestOptions = PHImageRequestOptions.init()
        imageRequestOptions.isSynchronous = synchronous
        imageRequestOptions.isNetworkAccessAllowed = true
        if let phAsset = self.phAsset {
            KLAssetsManager.sharedInstance.phCachingImageManager.requestImageData(for: phAsset, options: imageRequestOptions, resultHandler: { (imageData, dataUTI, orientation, info) in
                if let info = info,let imageData = imageData,let dataUTI = dataUTI{
                    var tempInfo = [String:Any]()
                    tempInfo.updateValue(imageData, forKey: KLAssetConstants.kAssetInfoImageData)
                    tempInfo.updateValue(imageData.count, forKey: KLAssetConstants.kAssetInfoSize)
                    tempInfo.updateValue(info, forKey: KLAssetConstants.kAssetInfoOriginInfo)
                    tempInfo.updateValue(dataUTI, forKey: KLAssetConstants.kAssetInfoDataUTI)
                    tempInfo.updateValue(orientation, forKey: KLAssetConstants.kAssetInfoOrientation)
                    if let complete = completeClosure {
                        complete(tempInfo)
                    }
                }
            })
        }
    }
    
    func updateDownloadStatus(downloadProgress:Double){
        self.downloadProgress = downloadProgress
        self.downloadStatus = KLDownloadStatus.Downloading
    }
    
    func assetSize(_ getSize :@escaping (_ size:Int64)->Void){
        if self.userPhotoKit {
            if let phAssetInfo = self.phAssetInfo {
                // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
                if let infoSize = phAssetInfo["size"] as? Int64{
                    DispatchQueue.main.async {
                        getSize(infoSize)
                    }
                }
            }else {
                self.requestPhAssetInfo({ (info) in
                    self.phAssetInfo = info
                    if let infoSet = info,let infoSize = infoSet["size"] as? Int64{
                        DispatchQueue.main.async {
                            getSize(infoSize)
                        }
                    }
                })
            }
        }else {
            DispatchQueue.main.async {
                getSize((self.alAssetRepresentation?.size())!)
            }
        }
    }
}

extension Int
{
    func hexedString() -> String
    {
        return NSString(format:"%02x", self) as String
    }
}

extension NSData
{
    func hexedString() -> String
    {
        var string = String()
        let unsafePointer = bytes.assumingMemoryBound(to: UInt8.self)
        for i in UnsafeBufferPointer<UInt8>(start:unsafePointer, count: length)
        {
            string += Int(i).hexedString()
        }
        return string
    }
    func MD5() -> NSData
    {
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        let unsafePointer = result.mutableBytes.assumingMemoryBound(to: UInt8.self)
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(unsafePointer))
        return NSData(data: result as Data)
    }
}

extension String
{
    func MD5() -> String
    {
        let data = (self as NSString).data(using: String.Encoding.utf8.rawValue)! as NSData
        return data.MD5().hexedString()
    }
}  
