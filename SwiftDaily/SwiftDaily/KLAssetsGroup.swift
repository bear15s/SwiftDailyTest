//
//  KLAssetGroup.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/4/27.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos

enum kLAlbumSortType {
    case  Positive,   // 日期最新的内容排在后面
          Reverse  // 日期最新的内容排在前面
}

class KLAssetsGroup:NSObject{
    var alAssetGroup:ALAssetsGroup?
    var phAssetCollection:PHAssetCollection?
    var phFetchResult:PHFetchResult<AnyObject>?
    var usePhotoKit:Bool = {
        return KLAssetsManager.sharedInstance.usePhotoKit
    }()
    var numberOfAsset:Int{
        if self.usePhotoKit {
            if let fetResultCount = self.phFetchResult?.count {
                return fetResultCount
            }else {
                return 0
            }
        }else {
            if let fetResultCount = self.alAssetGroup?.numberOfAssets(){
                return fetResultCount
            }else {
                return 0
            }
        }
    }
    
    var name:String {
        var resultName:String?
        if self.usePhotoKit {
            resultName = self.phAssetCollection?.localizedTitle
        } else {
            resultName = self.alAssetGroup?.value(forProperty: ALAssetsGroupPropertyName) as! String
        }
        return NSLocalizedString(resultName!, comment: resultName!)
    }
    
    init(alAssetGroup:ALAssetsGroup){
        super.init()
        self.alAssetGroup = alAssetGroup
    }
    
    init(phAssetCollection:PHAssetCollection,fetchAssetsOptions:PHFetchOptions?){
        super.init()
        if let fetchAssetsOptions = fetchAssetsOptions {
            let phFetchResult = PHAsset.fetchAssets(in: phAssetCollection, options: fetchAssetsOptions)
            self.phFetchResult = phFetchResult as? PHFetchResult<AnyObject>
        }
        self.phAssetCollection = phAssetCollection
        self.usePhotoKit = true
    }
    
    convenience init(phAssetCollection:PHAssetCollection) {
        self.init(phAssetCollection: phAssetCollection, fetchAssetsOptions: nil)
    }
    
    func posterImage(size:CGSize)->UIImage?{
        var resultImage:UIImage?
        if self.usePhotoKit {
            if let fetchResult = self.phFetchResult{
                let count = fetchResult.count
                if count > 0 {
                    let asset:PHAsset = fetchResult[count-1] as! PHAsset
                    let phImageRequestOptions = PHImageRequestOptions.init()
                    phImageRequestOptions.isSynchronous = true
                    phImageRequestOptions.resizeMode = .exact
                    // targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
                    KLAssetsManager.sharedInstance.phCachingImageManager.requestImage(for: asset, targetSize: CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale), contentMode: .aspectFill, options: phImageRequestOptions, resultHandler: { (resultImg, info) in
                        resultImage = resultImg
                    })
                }
            }
        } else {
           
            if let alAssetGroup = self.alAssetGroup{
                let postImageRef:CGImage = alAssetGroup.posterImage().takeUnretainedValue()
                resultImage = UIImage.init(cgImage: postImageRef)
            }
        }
        return resultImage
    }
    
    func enumerateAssets(albumSortType:kLAlbumSortType,_ enumerationClosure:@escaping (_ resultAsset:KLAsset?)->Void){
        if self.usePhotoKit {
            if let fetchResult = self.phFetchResult {
                let resultCount = fetchResult.count
                if albumSortType == .Reverse {
                    for i in (0..<resultCount).reversed() {
                        let phAsset = fetchResult[i] as! PHAsset
                        let kLAsset = KLAsset.init(aPhAsset: phAsset)
                        enumerationClosure(kLAsset)
                    }
                } else {
                    for i in 0..<resultCount {
                        let phAsset = fetchResult[i] as! PHAsset
                        let kLAsset = KLAsset.init(aPhAsset: phAsset)
                        enumerationClosure(kLAsset)
                    }
                }
                /**
                 *  For 循环遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举资源结束的标记。
                 *  该处理方式也是参照系统 ALAssetGroup 枚举结束的处理。
                 */
                enumerationClosure(nil)
            }
        }else {
            var enumerationOptions:NSEnumerationOptions?
            if albumSortType == .Reverse {
                enumerationOptions = NSEnumerationOptions.reverse
            } else {
                enumerationOptions = NSEnumerationOptions.concurrent
            }
            if let assetsGroup = self.alAssetGroup {
                assetsGroup.enumerateAssets(options: enumerationOptions!, using: { (result, index, stop) in
                    if let resultAsset = result {
                        let asset = KLAsset.init(aALAsset: resultAsset)
                        enumerationClosure(asset)
                    } else {
                        enumerationClosure(nil)
                    }
                })
            }
        }
    }
    
    func enumerateAssets(_ usingBlock:@escaping (_ resultAsset:KLAsset?)->Void){
        self.enumerateAssets(albumSortType: .Positive, usingBlock)
    }
}
