//
//  TestColllectionViewCell.swift
//  SwiftDemo1
//
//  Created by zbmy on 2018/4/23.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher


protocol TestColllectionViewCellDelegate:NSObjectProtocol {
    func heightForViewExceptImage(collectionViewCell:TestColllectionViewCell,height:CGFloat) -> Void
}

class TestColllectionViewCell :UICollectionViewCell{
    var extendHeight:CGFloat = 0
    weak var delegate:TestColllectionViewCellDelegate?
    public lazy var coverView = { () -> UIImageView in
        let imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    public lazy var titleLabel = { () -> UILabel in
        let label = UILabel.init()
        label.numberOfLines = 2
//        label.font = UIFont.init
        return label
    }()
    
    var template:Template? = nil{
        willSet {
            
        }
        didSet {
            self.titleLabel.text = self.template?.title
            let height = (Float)(self.bounds.width) / ((self.template?.video_width)! / (self.template?.video_height)!)
            self.coverView.snp.updateConstraints { (make) in
                make.height.equalTo(height)
            }
            if let url = URL(string: (self.template?.image!)!) {
                self.coverView.kf.setImage(with: url)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(code:) has not been implemented")
    }
    
}

//ui构建
extension TestColllectionViewCell {
    func setupUI()  {
        self.contentView.backgroundColor = self.getRandomColor()
        //        self.coverView.backgroundColor = self.getRandomColor()
        self.contentView.addSubview(coverView)
        coverView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self.contentView)
            make.height.equalTo(50)
        }
        
        self.contentView.addSubview(self.titleLabel)
        
        let titleHeight:CGFloat = 13.0
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(8);
            make.width.equalTo(105.5);
            make.top.equalTo(self.coverView.snp.bottom);
            make.height.equalTo(titleHeight);
        }
       // MARK: - 说明文字,带分割线
        self.extendHeight += titleHeight
        assert(self.delegate == nil, "没有设置代理")
        self.delegate?.heightForViewExceptImage(collectionViewCell: self, height: self.extendHeight)
    }
}

//随机颜色
extension TestColllectionViewCell {
    func getRandomColor() -> UIColor{
        let red = CGFloat(arc4random()%256)/255.0
        let green = CGFloat(arc4random()%256)/255.0
        let blue = CGFloat(arc4random()%256)/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

