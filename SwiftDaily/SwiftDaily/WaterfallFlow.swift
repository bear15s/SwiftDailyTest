//
//  WaterfallFlow.swift
//  SwiftDemo1
//
//  Created by 梁家伟 on 2018/4/25.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import UIKit


protocol MyWaterFallFlowDelegate:NSObjectProtocol {
    func heightForCellWidth(flowLayout:MyWaterFallFlow,cellWidth:CGFloat,indexPath:IndexPath) -> CGFloat
}

class MyWaterFallFlow : UICollectionViewFlowLayout{
    open var columnCount:CGFloat = 2.0
    weak var delegate:MyWaterFallFlowDelegate?
    var cellWidth:CGFloat = 0
    var attrsArrM:[UICollectionViewLayoutAttributes]?
    lazy var eachColHeightM:Array<Any> = {
        var colHeightM = Array<Any>()
        //初始化默认值
        for i in 0...Int(self.columnCount){
            colHeightM.append(self.sectionInset.top)
        }
        return colHeightM
    }()
    var headerView:UICollectionReusableView?
    
    override func prepare() {
        super.prepare()
        //    W 是整个屏幕的宽度screen-左边距和右边距 =列数-1 * 内边距 / 列数
        self.cellWidth = ((self.collectionView?.bounds.size.width)! - self.sectionInset.left - self.sectionInset.right - (self.columnCount - 1) * self.minimumInteritemSpacing)/self.columnCount
        self.attributes()
    }
    
    //重新记录cell的attrs
    func attributes(){
//        self.attrsArrM.removeAll()
        var attributesArray = [UICollectionViewLayoutAttributes]()
        let itemCount:Int = self.collectionView!.numberOfItems(inSection: 0)
        for i in 0..<itemCount{
            let indexPath:IndexPath = IndexPath.init(item: i, section: 0)
            let attr:UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes.init(forCellWith:indexPath)
            assert(self.delegate != nil, "没有设置代理")
            //    H 则是根据后台给予的高度宽度做宽高比例 实现公式  H = W * imageH / imageW
            let cellHeight:CGFloat = self.delegate!.heightForCellWidth(flowLayout: self, cellWidth:self.cellWidth, indexPath: indexPath)
            //    Y  找到高度最小的那一列去遍历 高度最小的就是目标 赋值
            let minCol:Int = self.minHeightCol()
//            let col:Int = i % (Int)(self.columnCount)
            let cellY:CGFloat = self.eachColHeightM[minCol] as! CGFloat + self.minimumLineSpacing
            //    X 第0列-> 左边距+0倍的(宽+内边距) 第1列-> 左边距+1倍的(宽+内边距) 以此类推
            let cellX:CGFloat = self.sectionInset.left + (self.cellWidth + self.minimumInteritemSpacing) * (CGFloat)(minCol)
            //更新每列的高度
            self.eachColHeightM[minCol] = cellY + cellHeight
            attr.frame = CGRect(x: cellX, y: cellY, width:self.cellWidth, height: cellHeight)
            attributesArray.append(attr)
        }
        self.attrsArrM = attributesArray
    }
    
    //变更可滑动区域的大小
    override var collectionViewContentSize: CGSize{
        get {
            guard let maxColHeight:CGFloat = self.eachColHeightM[self.maxHeightCol()] as? CGFloat else {
                return CGSize(width:(self.collectionView?.bounds.size.width)!, height:(self.headerView?.bounds.size.height)! + self.minimumLineSpacing)
            }
            
            if(self.attrsArrM?.count == 0){
                return CGSize.zero
            }
            
            guard let headerHeight = self.headerView?.bounds.size.height else {
                return CGSize(width: (self.collectionView?.bounds.size.width)!, height:maxColHeight + self.minimumLineSpacing)
            }
            
            return CGSize(width: (self.collectionView?.bounds.size.width)!, height:maxColHeight+headerHeight + self.minimumLineSpacing)
        }
        set (newHeight){
            self.collectionViewContentSize = newHeight
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        print("\(String(describing: self.attrsArrM))")
        return self.attrsArrM
    }
    
    
    //cell最高的那一列
    func maxHeightCol() -> Int{
        var maxH:CGFloat = 0
        var maxCol:Int = 0
        for i in 0..<(Int)(self.columnCount) {
            let currentH:CGFloat = self.eachColHeightM[i] as! CGFloat
            if(maxH < currentH){
                maxH = currentH
                maxCol = i
            }
        }
        return maxCol
    }
    
     //cell最矮的那一列
    func minHeightCol() -> Int {
        var minH:CGFloat = CGFloat(MAXFLOAT)
        var minCol:Int = 0
        for i in 0..<Int(self.columnCount) {
            let currentH:CGFloat = self.eachColHeightM[i] as! CGFloat
            if(minH > currentH){
                minH = currentH
                minCol = i
            }
        }
        return minCol
    }
    

    
}
