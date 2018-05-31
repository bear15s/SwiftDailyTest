//
//  DemoPhotosVC.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/5/8.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import UIKit

class DemoPhotosVC:UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    
    var assetGroup:KLAssetsGroup?
    var photoAssets = Array<KLAsset>()
    var photoListView:UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupUI();
        self.loadAlbumAssets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI(){
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: self.view.bounds.size.width / 4, height: self.view.bounds.size.width / 4)
        let photoListView = UICollectionView.init(frame: self.view.bounds, collectionViewLayout: layout)
        self.view.addSubview(photoListView)
        self.photoListView = photoListView
        photoListView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        photoListView.delegate = self
        photoListView.dataSource = self
        photoListView.register(DemoPhotoListCell.classForCoder(), forCellWithReuseIdentifier: "photoCell")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! DemoPhotoListCell
        let asset = self.photoAssets[indexPath.item]
        asset.requestThumbnailImage(size: CGSize(width: self.view.bounds.size.width / 4, height: self.view.bounds.size.width / 4), completion: { (resultImg, info) in
            cell.imageView.image = resultImg
        }) { (progress, error, stop, info) in
            
        }
        return cell
    }
    
    func loadAlbumAssets(){
        if let group = assetGroup {
            group.enumerateAssets(albumSortType: .Reverse, { (resultAsset) in
                if let asset = resultAsset {
                    self.photoAssets.append(asset)
                } else{
                    self.photoListView?.reloadData()
                }
            })
        }
    }
}
