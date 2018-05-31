//
//  DemoPhotoListCell.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/5/8.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import UIKit

class DemoPhotoListCell :UICollectionViewCell{
    
    public lazy var imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(code:) has not been implemented")
    }
    
    func setupUI() -> Void {
        self.contentView.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
    }
    
    
}
