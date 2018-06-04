//
//  DemoAlbumVC.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/5/8.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

class DemoAlbumVC :UIViewController,UITableViewDelegate,UITableViewDataSource {
   
    var albumsArray:Array = [KLAssetsGroup]()
    var albumListView:UITableView?
    var currentAlbum:KLAssetsGroup?
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        let cancelBtn = UIButton.init()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: cancelBtn)
        cancelBtn.backgroundColor = UIColor.blue
        cancelBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        cancelBtn.titleLabel?.text = "Back"
        cancelBtn.rx.tap.subscribe(
            onNext:{ [weak self] in
                self?.dismiss(animated: true, completion: nil)
                print("back tap")
            }
        ).disposed(by: disposeBag)
//
        
//
        
        self.setupUI();
        self.requestAlbumData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI(){
        let albumListView = UITableView.init(frame: self.view.bounds, style: UITableViewStyle.plain)
        albumListView.delegate = self
        albumListView.dataSource = self
        self.albumListView = albumListView
        self.view.addSubview(albumListView)
        albumListView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
        }
        albumListView.tableFooterView = UIView.init()
        albumListView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "albumCell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albumsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath)
        let assetGroup = self.albumsArray[indexPath.row]
        cell.imageView?.image = assetGroup.posterImage(size: CGSize(width: 64, height: 64))
        cell.textLabel?.text = assetGroup.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let demoPhotoVC = DemoPhotosVC.init()
        self.currentAlbum = self.albumsArray[indexPath.row]
        demoPhotoVC.assetGroup = self.currentAlbum
        self.navigationController?.pushViewController(demoPhotoVC, animated: true)
    }
    
    func requestAlbumData(){
        KLAssetsManager.sharedInstance.usePhotoKit = false
        KLAssetsManager.sharedInstance.enumerateAllAlbums(contentType: KLAlbumContentType.Photo, showEmptyAlbum: false, showSmartAlbumIfSupport: false) { (group) in
            if let assetGroup = group {
                print("group info = \(assetGroup)")
                self.albumsArray.append(assetGroup)
            } else {
                self.albumListView!.reloadData()
                print("finish")
            }
        }
    }
}
