//
//  KLAssetsManager.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/4/27.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import Foundation
import Photos
import AssetsLibrary

enum KLAuthorizationStaus {
    case NotUsingPhotoKit,// 对于iOS7及以下不支持PhotoKit的系统，没有所谓的“授权状态”，所以定义一个特定的status用于表示这种情况
         NotDetermined,// 还不确定有没有授权
         Authorized,// 已经授权
         NotAuthorized // 手动禁止了授权
}

//typealias KLWriteAssetCompleteClosure = (kLAsset:KLAsset,error:NSError?)->Void

enum KLAlbumContentType {
    case All,Photo,Video,Audio
}

class KLAssetsManager:NSObject {
    typealias KLWriteAssetCompleteCourse = (_ asset:KLAsset?,_ error:Error?)->()
    static let sharedInstance = KLAssetsManager()
    var usePhotoKit:Bool = false
    var alAssetsLibrary:ALAssetsLibrary?
    lazy var phCachingImageManager:PHCachingImageManager = PHCachingImageManager()
    private override init() {
        if(!usePhotoKit){
            self.alAssetsLibrary = ALAssetsLibrary.init()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//获取Asset
extension KLAssetsManager {
    func enumerateAllAlbums(contentType:KLAlbumContentType,showEmptyAlbum:Bool,showSmartAlbumIfSupport:Bool,usingBlock:@escaping (_ resultAssetsGroup:KLAssetsGroup?)->Void){
        if self.usePhotoKit {
            let tempAlbumsArray = PHPhotoLibrary.fetchAllAlbums(contentType: contentType,showEmptyAlbum: showEmptyAlbum,showSmartAlbum: showSmartAlbumIfSupport)
            let phFetchOptions = PHPhotoLibrary.createFetchOptions(albumContentType: contentType)
            for i in 0..<tempAlbumsArray.count {
                let phAssetCollection = tempAlbumsArray[i]
                let assetsGroup = KLAssetsGroup.init(phAssetCollection: phAssetCollection, fetchAssetsOptions: phFetchOptions)
                usingBlock(assetsGroup)
            }
            /**
             *  所有结果遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举相册结束的标记。
             *  该处理方式也是参照系统 ALAssetsLibrary enumerateGroupsWithTypes 枚举结束的处理。
             */
            usingBlock(nil)
        } else {
            if let alAssetsLibrary = self.alAssetsLibrary {
                alAssetsLibrary.emumerateAllAlbum(albumContentType: contentType, enumeration: { (group) in
                    if let resultGroup = group {
                        let assetsGroup = KLAssetsGroup.init(alAssetGroup: resultGroup)
                        usingBlock(assetsGroup)
                    }else{
                        usingBlock(nil)
                    }
                })
            }
        }
    }
    
    func enumerateAllAlbums(contentType:KLAlbumContentType,_ enumerationClosure:@escaping(_ resultAssetsGroup:KLAssetsGroup?)->Void){
        self.enumerateAllAlbums(contentType: contentType, showEmptyAlbum: false, showSmartAlbumIfSupport: true, usingBlock: enumerationClosure)
    }
    
    func saveImage(imageRef:CGImage,albumAssetsGroup:KLAssetsGroup,orientation:UIImageOrientation,completeClosure:@escaping KLWriteAssetCompleteCourse){
        if self.usePhotoKit {
            if let albumPhAssetCollection = albumAssetsGroup.phAssetCollection{
                PHPhotoLibrary.shared().addImageToAlbum(imageRef: imageRef, albumAssetCollection: albumPhAssetCollection, oritentation: orientation, completionHander: { (success, creationDate, error) in
                    if success {
                        let fetchOptions = PHFetchOptions.init()
                        fetchOptions.predicate = NSPredicate.init(format: "createDate = %@",creationDate! as CVarArg)
                        let fetchResult = PHAsset.fetchAssets(in: albumPhAssetCollection, options: fetchOptions)
                        if let phAsset = fetchResult.lastObject {
                            let klAsset = KLAsset.init(aPhAsset: phAsset)
                            completeClosure(klAsset,error)
                        }
                        
                    }else {
                        print("get phasset of image error:\(String(describing: error))")
                    }
                })
            }
        } else {
            if let assetGroup = albumAssetsGroup.alAssetGroup,let alAssetLibrary = self.alAssetsLibrary{
                alAssetLibrary.writeImageToSavedPhotosAlbum(imageRef: imageRef, albumAssetsGroup: assetGroup, orientation: orientation, completionClosure: { (assetURL, error) in
                    if let url = assetURL {
                        alAssetLibrary.asset(for:   url, resultBlock: { (alAsset) in
                            if let alAsset = alAsset {
                                let resultAsset = KLAsset.init(aALAsset: alAsset)
                                completeClosure(resultAsset,error)
                            }
                        }, failureBlock: { (error) in
                             print("get alasset of image error:\(String(describing: error))")
                             completeClosure(nil,error)
                        })
                    }
                })
            }
        }
    }
    
    func saveImage(imagePathURL:URL,albumAssetsGroup:KLAssetsGroup,completeClosure:@escaping KLWriteAssetCompleteCourse){
        if self.usePhotoKit {
            if let albumPhAssetCollection = albumAssetsGroup.phAssetCollection{
                PHPhotoLibrary.shared().addImageToAlbum(imagePathURL: imagePathURL, albumAssetCollection: albumPhAssetCollection, completeHandler: { (success, creationDate, error) in
                    if success {
                        let fetchOptions = PHFetchOptions.init()
                        fetchOptions.predicate = NSPredicate.init(format: "createDate = %@",creationDate! as CVarArg)
                        let fetchResult = PHAsset.fetchAssets(in: albumPhAssetCollection, options: fetchOptions)
                        if let phAsset = fetchResult.lastObject {
                            let klAsset = KLAsset.init(aPhAsset: phAsset)
                            completeClosure(klAsset,error)
                        }
                    }else {
                        print("get phasset of image error:\(String(describing: error))")
                        completeClosure(nil,error)
                    }
                })
            }
        }else {
            if let assetGroup = albumAssetsGroup.alAssetGroup,let alAsssetLibrary = self.alAssetsLibrary{
                alAsssetLibrary.writeImageAtPathToSavedPhotosAlbum(imagePathURL: imagePathURL, ablumAssetsGroup: assetGroup, completionClosure: { (assetURL, error) in
                    alAsssetLibrary.asset(for: assetURL, resultBlock: { (alasset) in
                        if let alasset = alasset {
                            let klAsset = KLAsset.init(aALAsset: alasset)
                            completeClosure(klAsset, error);
                        }
                    }, failureBlock: { (error) in
                        print("Get ALAsset of image error : \(String(describing: error))")
                        completeClosure(nil, error);
                    })
                })
            }
        }
    }
    
    func saveVideo(videoPathURL:URL,albumAssetsGroup:KLAssetsGroup,completeClosure:@escaping KLWriteAssetCompleteCourse){
        if self.usePhotoKit {
            if  let albumPhAssetCollection = albumAssetsGroup.phAssetCollection{
                PHPhotoLibrary.shared().addVideoToAlbum(videoPathURL: videoPathURL, albumAssetCollection: albumPhAssetCollection, completionHandler: { (success, creationDate, error) in
                    if success {
                        let fetchOptions = PHFetchOptions.init()
                        fetchOptions.predicate = NSPredicate.init(format: "createDate = %@",creationDate! as CVarArg)
                        let fetchResult = PHAsset.fetchAssets(in: albumPhAssetCollection, options: fetchOptions)
                        if let phAsset = fetchResult.lastObject {
                            let klAsset = KLAsset.init(aPhAsset: phAsset)
                            completeClosure(klAsset,error)
                        }
                    }else {
                        print("get phasset of image error:\(String(describing: error))")
                        completeClosure(nil,error)
                    }
                })
            }
        } else {
            if let alAsssetLibrary = self.alAssetsLibrary{
                alAsssetLibrary.writeVideoAtPath(toSavedPhotosAlbum: videoPathURL, completionBlock: { (assetURL, error) in
                    alAsssetLibrary.asset(for: assetURL, resultBlock: { (alasset) in
                        if let alasset = alasset {
                            let klAsset = KLAsset.init(aALAsset: alasset)
                            completeClosure(klAsset, error);
                        }
                    }, failureBlock: { (error) in
                        print("Get ALAsset of image error : \(String(describing: error))")
                        completeClosure(nil, error);
                    })
                })
            }
        }
    }
    
    func refreshAssetsLibrary(){
        self.alAssetsLibrary = ALAssetsLibrary.init()
    }
}

//权限认证
extension KLAssetsManager {
    class func authorizationStatus() -> KLAuthorizationStaus{
        var status:KLAuthorizationStaus?
        
        if self.sharedInstance.usePhotoKit {
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            if authorizationStatus == PHAuthorizationStatus.restricted ||  authorizationStatus == PHAuthorizationStatus.denied{
                status = KLAuthorizationStaus.NotAuthorized
            } else if authorizationStatus == PHAuthorizationStatus.notDetermined{
                status = KLAuthorizationStaus.NotDetermined
            } else {
                status = KLAuthorizationStaus.Authorized
            }
        }else {
            let authorizationStatus = ALAssetsLibrary.authorizationStatus()
            if authorizationStatus == ALAuthorizationStatus.restricted || authorizationStatus == ALAuthorizationStatus.denied{
                status = KLAuthorizationStaus.NotAuthorized
            }else if authorizationStatus == ALAuthorizationStatus.notDetermined{
                status = KLAuthorizationStaus.NotDetermined
            }else {
                status = KLAuthorizationStaus.Authorized
            }
        }
        return status!
    }
    
    class func requestAuthorization(hander:@escaping (_ status:KLAuthorizationStaus)->()){
        if self.sharedInstance.usePhotoKit {
            PHPhotoLibrary.requestAuthorization({(phStatus) in
                let authorizationStatus = phStatus
                var status:KLAuthorizationStaus?
                if authorizationStatus == PHAuthorizationStatus.restricted ||  authorizationStatus == PHAuthorizationStatus.denied{
                    status = KLAuthorizationStaus.NotAuthorized
                } else if authorizationStatus == PHAuthorizationStatus.notDetermined{
                    status = KLAuthorizationStaus.NotDetermined
                } else {
                    status = KLAuthorizationStaus.Authorized
                }
                
                hander(status!)
            })
        } else {
            self.sharedInstance.alAssetsLibrary?.enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: nil, failureBlock: nil)
            hander(KLAuthorizationStaus.NotUsingPhotoKit)
        }
    }
}

extension PHPhotoLibrary {
    class func fetchAllAlbums(contentType:KLAlbumContentType,showEmptyAlbum:Bool,showSmartAlbum:Bool)->[PHAssetCollection]{
        var tempAlbumsArray = Array<PHAssetCollection>()
        // 创建一个 PHFetchOptions，用于 对资源的排序和类型进行控制
        let fetchOptions = PHPhotoLibrary.createFetchOptions(albumContentType: contentType)
        var fetchResult:PHFetchResult<PHAssetCollection>?
        if showSmartAlbum {
            // 允许显示系统的“智能相册”
            // 获取保存了所有“智能相册”的 PHFetchResult
            fetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.any, options: nil)
        } else {
            // 不允许显示系统的智能相册，但由于在 PhotoKit 中，“相机胶卷”也属于“智能相册”，因此这里从“智能相册”中单独获取到“相机胶卷”
            fetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary, options: nil)
        }
        var resultCount:Int = 0
        
        if let fetchResultCheck = fetchResult {
            resultCount = fetchResultCheck.count
        }
        
        for i in 0..<resultCount {
            if let resultCollection = fetchResult{
                let collection = resultCollection[i]
                assert(collection.isKind(of: PHAssetCollection.classForCoder()), "Fetch collection not PHCollection \(collection)")
                let currentFetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0，只有资源数量大于 0 的相册才会作为有效的相册显示
                if currentFetchResult.count > 0 || showSmartAlbum {
                    if collection.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumUserLibrary {
                        tempAlbumsArray.insert(collection, at: 0)
                    } else {
                        tempAlbumsArray.append(collection)
                    }
                }
            }
        }
        
        //获取所有用户自己建立的相册
        let topLeveluserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        for i in 0..<topLeveluserCollections.count {
            let collection = topLeveluserCollections[i] as! PHAssetCollection
            assert(collection.isKind(of: PHAssetCollection.classForCoder()), "topLeveluserCollections not PHCollection \(collection)")
            if showSmartAlbum {
                // 允许显示空相册，直接保存相册到结果数组中
                tempAlbumsArray.append(collection)
            } else {
                let fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                 // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0
                if fetchResult.count > 0 {
                    tempAlbumsArray.append(collection)
                }
            }
        }
        
        let macCollections = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumSyncedAlbum, options: nil)
        // 获取从 macOS 设备同步过来的相册，同步过来的相册不允许删除照片，因此不会为空
        for i in 0..<macCollections.count {
            let collection = macCollections[i]
            assert(collection.isKind(of: PHAssetCollection.classForCoder()), "macCollections not PHCollection \(collection)")
            tempAlbumsArray.append(collection)
        }
        return tempAlbumsArray
    }
    
    class func createFetchOptions(albumContentType:KLAlbumContentType)->PHFetchOptions{
         // 根据输入的内容类型过滤相册内的资源
        let fetchOptions:PHFetchOptions = PHFetchOptions.init()
        switch albumContentType {
        case KLAlbumContentType.Photo:
            
            fetchOptions.predicate = NSPredicate.init(format: "mediaType = %d",PHAssetMediaType.image.rawValue)
            break
        case KLAlbumContentType.Video:
            fetchOptions.predicate = NSPredicate.init(format: "mediaType = %d",PHAssetMediaType.video.rawValue)
            break
        case KLAlbumContentType.Audio:
            fetchOptions.predicate = NSPredicate.init(format: "mediaType = %d",PHAssetMediaType.audio.rawValue)
            break
        default:
            break
        }
        return fetchOptions
    }
    
    class func fetchLatestAsset(assetCollection:PHAssetCollection)->PHAsset?{
        let fetchOptions = PHFetchOptions.init()
         // 按时间的先后对 PHAssetCollection 内的资源进行排序，最新的资源排在数组最后面
        fetchOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
         // 获取 PHAssetCollection 内最后一个资源，即最新的资源
        let latestAsset = fetchResult.lastObject
        return latestAsset
    }
    
    func addImageToAlbum(imageRef:CGImage,albumAssetCollection:PHAssetCollection,oritentation:UIImageOrientation,completionHander:@escaping(_ success:Bool,_ creationDate:Date?,_ error:Error?)->()){
        let targetImage = UIImage.init(cgImage: imageRef, scale: UIScreen.main.scale, orientation: oritentation)
        PHPhotoLibrary.shared().addImageToAlbum(image: targetImage, imagePathURL: nil, albumAssetCollection: albumAssetCollection, completionHander: completionHander)
    }
    
    func addImageToAlbum(imagePathURL:URL,albumAssetCollection:PHAssetCollection,completeHandler:@escaping (_ success:Bool,_ creationDate:Date?,_ error:Error?)->Void){
        PHPhotoLibrary.shared().addImageToAlbum(image: nil, imagePathURL: imagePathURL, albumAssetCollection: albumAssetCollection, completionHander: completeHandler)
    }
    
    func addImageToAlbum(image:UIImage?,imagePathURL:URL?,albumAssetCollection:PHAssetCollection,completionHander:@escaping(_ success:Bool,_ creationDate:Date?,_ error:Error?)->()){
        var tempCreationDate:Date?
        self.performChanges({
            // 创建一个以图片生成新的 PHAsset，这时图片已经被添加到“相机胶卷”
            var assetChangeRequest:PHAssetChangeRequest?
            
            if let paramImage = image  {
                assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: paramImage)
            }
            if let paramImagePath = imagePathURL {
                assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: paramImagePath)
            }
            guard let finalRequest = assetChangeRequest else {
                print("Creating asset with empty data")
                return;
            }
            finalRequest.creationDate = Date.init()
            tempCreationDate = finalRequest.creationDate
            if albumAssetCollection.assetCollectionType == PHAssetCollectionType.album {
                // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
                // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
                if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest.init(for: albumAssetCollection){
                /**
                 *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
                 *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
                 */
                    let arr = [finalRequest.placeholderForCreatedAsset]
                    assetCollectionChangeRequest.addAssets(arr as NSFastEnumeration)
                }
            }
            
        }) { (success, error) in
            if !success {
                print("Creating asset of image error \(String(describing: error))")
            }
            DispatchQueue.main.async {
                guard let tempCreationDate = tempCreationDate else {
                   completionHander(false,nil,error)
                   return
                }
                // 若创建时间为 nil，则说明 performChanges 中传入的资源为空，因此需要同时判断 performChanges 是否执行成功以及资源是否有创建时间。
                completionHander(success,tempCreationDate,error)
            }
        }
    }
    
    func addVideoToAlbum(videoPathURL:URL,albumAssetCollection:PHAssetCollection,completionHandler:@escaping (_ success:Bool,_ creationDate:Date?,_ error:Error?)->Void){
        var creationDate:Date?
        self.performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoPathURL)
            assetChangeRequest?.creationDate = Date.init()
            creationDate = assetChangeRequest?.creationDate
            if albumAssetCollection.assetCollectionType == PHAssetCollectionType.album {
                // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
                // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest.init(for: albumAssetCollection)
                /**
                 *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
                 *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
                 */
                if let assetChangeRequest = assetChangeRequest{
                    var arr:NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                    assetCollectionChangeRequest?.addAssets(arr)
                }
            }
        }) { (success, error) in
            if !success {
                print("creating asset of video error \(error)")
            }
            DispatchQueue.main.async {
                completionHandler(success,creationDate,error)
            }
        }
    }
    
  
    
}

extension ALAssetsLibrary {
    func emumerateAllAlbum(albumContentType:KLAlbumContentType,enumeration:@escaping ALAssetsLibraryGroupResultBlock){
        self.enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: { (group, stop) in
            guard let resultGroup = group else {
                enumeration(nil)
                return
            }
            switch albumContentType {
                case KLAlbumContentType.Photo:
                    resultGroup.setAssetsFilter(ALAssetsFilter.allPhotos())
                    break
                case KLAlbumContentType.Video:
                    resultGroup.setAssetsFilter(ALAssetsFilter.allVideos())
                    break
                default:
                    break
            }
            if resultGroup.numberOfAssets() > 0{
                enumeration(resultGroup)
            }
        }) { (error) in
            print("Asset group not found!error:\(String(describing: error))")
        }
    }
    
    func writeImageToSavedPhotosAlbum(imageRef:CGImage,albumAssetsGroup:ALAssetsGroup,orientation:UIImageOrientation,completionClosure:@escaping ALAssetsLibraryWriteImageCompletionBlock) {
        // 调用系统的添加照片的接口，把图片保存到相机胶卷，从而生成一个图片的 ALAsset
        self.writeImageToSavedPhotosAlbum(imageRef: imageRef, albumAssetsGroup: albumAssetsGroup, orientation: orientation) { (url, error) in
            guard let judgeError = error else{
                self.addAsset(assetURL: url!, albumAssetsGroup: albumAssetsGroup, completeClosure: { (error) in
                    completionClosure(url,nil)
                })
                return
            }
            completionClosure(url,judgeError)
        }
    }
    
    func writeImageAtPathToSavedPhotosAlbum(imagePathURL:URL,ablumAssetsGroup:ALAssetsGroup,completionClosure:@escaping ALAssetsLibraryWriteImageCompletionBlock){
        do {
            let imageData = try Data.init(contentsOf: imagePathURL)
            self.writeImageData(toSavedPhotosAlbum: imageData, metadata: nil, completionBlock: { (url, error) in
                guard let checkError = error else {
                    self.addAsset(assetURL: imagePathURL, albumAssetsGroup: ablumAssetsGroup, completeClosure: { (error) in
                        completionClosure(url,error)
                    })
                    return
                }
                completionClosure(url,checkError)
            })
            
        }catch {
            print("imageData init error \(error)")
        }
    }
    
    func addAsset(assetURL:URL,albumAssetsGroup:ALAssetsGroup,completeClosure:@escaping ALAssetsLibraryAccessFailureBlock) {
        self.asset(for: assetURL, resultBlock: { (asset) in
            albumAssetsGroup.add(asset)
        }) { (error) in
            completeClosure(error)
        }
    }
}

