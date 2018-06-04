//
//  ViewController.swift
//  SwiftDaily
//
//  Created by zbmy on 2018/5/31.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import UIKit
import Alamofire
import RxCocoa
import RxSwift

typealias JSON = Any

enum CustomNSError{
    case convertJSONError
}



class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,MyWaterFallFlowDelegate,TestColllectionViewCellDelegate {
    
    var extraHeight:Float = 18
    var albumArray = Array<KLAssetsGroup>()
    var template_array = Array<Template>()
    var collectionView:UICollectionView?
    
    
    //RxSwift 关于JSON转模型的尝试  配合HandyJSON
    var disposeBag = DisposeBag()
    var templateJSON:Single<[Template]> = Single.create { single -> Disposable in
        let header:Dictionary = ["x-api-version":"7","Content-Type":"application/json"]
        Alamofire.request("http://testappapi.rabbitpre.com/market/esee/template/recommend_list?page=1&page_size=20",method: .get,headers: header).validate().responseJSON { (res) in
            
            guard let resData = res.data,let jsonStr:String = String.init(data: resData, encoding: .utf8) else{
                single(SingleEvent.error(res.error!))
                return
            }
            
            guard let templates:[Template] = [Template].deserialize(from: jsonStr, designatedPath: "result.list") as? [Template] else {
                return;
            }
            
            single(SingleEvent.success(templates))
           
        }
        return Disposables.create{
           
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupUI();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        self.title = "Swift瀑布流demo"
        
        let waterfall = MyWaterFallFlow.init()
        waterfall.columnCount = 2.0
        waterfall.delegate = self
        
        let collectionView = UICollectionView.init(frame: self.view.bounds, collectionViewLayout: waterfall)
        self.collectionView = collectionView
        collectionView.register(TestColllectionViewCell.classForCoder(), forCellWithReuseIdentifier: "colCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
//        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
//        collectionView.rx.itemSelected.map { [weak self] indexPath in
//            
//        }
//        
        
        
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets.init(top: 64, left: 0, bottom: 0, right: 0))
        }
        
  
        self.requestData()
        //        self.requestAlbumData()
    }
    
    func requestAlbumData(){
        KLAssetsManager.sharedInstance.enumerateAllAlbums(contentType: KLAlbumContentType.Photo) { (group) in
            if let assetGroup = group {
                print("group info = \(assetGroup)")
                self.albumArray.append(assetGroup)
            } else {
                print("finish")
            }
        }
    }
    
    
    func requestData (){
        
        templateJSON.subscribe(
            onSuccess:{ [weak self] templatesArr in
                self?.template_array = templatesArr
                self?.collectionView?.reloadData()
            },
            onError:{ error in
                print("Error : \(error)")
            }
        ).disposed(by: disposeBag)
        
//
//        templateJSON .subscribe(onNext: { [weak self] tplArr in
//            print("取得 json 成功: \(tplArr)")
//            self?.template_array = tplArr
//        }, onError: { error in
//            print("取得 json 失败 Error: \(error.localizedDescription)")
//        }, onCompleted: { [weak self] in
//            self?.collectionView?.reloadData()
//            print("取得 json 任务成功完成")
//        })
//        .disposed(by: disposeBag)
    }
    
    
    func heightForViewExceptImage(collectionViewCell: TestColllectionViewCell, height: CGFloat) {
        if height > 0 {
            self.extraHeight = Float(height)
        }
    }
    
    func heightForCellWidth(flowLayout: MyWaterFallFlow, cellWidth: CGFloat, indexPath: IndexPath) -> CGFloat {
        if(self.template_array.count == 0){
            return 0
        }
        let template:Template = self.template_array[indexPath.item]
        
        let height = (CGFloat)(template.video_height / template.video_width) * cellWidth + (CGFloat)(self.extraHeight)
        return height
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //collectionView delegate & dataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.template_array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell:TestColllectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "colCell", for: indexPath) as!TestColllectionViewCell
        collectionViewCell.template = self.template_array[indexPath.item]
        collectionViewCell.delegate = self
        return collectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        NSLog("didSelect collectionViewCell at \(indexPath.row)");
        let demoAlbumVC = DemoAlbumVC.init()
        let navVC = UINavigationController.init(rootViewController: demoAlbumVC)
        self.present(navVC, animated: true) {
            
        }
    }
}

extension ViewController {
    
}

