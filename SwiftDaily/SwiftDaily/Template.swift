//
//  Template.swift
//  SwiftDaily
//
//  Created by zbmy on 2018/4/25.
//  Copyright © 2018年 HakoWaii. All rights reserved.
//

import UIKit
import HandyJSON

struct ElementCount:HandyJSON {
    var image:Int?
    var text:Int?
}

struct ElementMaker:HandyJSON {
    var top:Float?
    var left:Float?
    var width:Float?
    var height:Float?
}

struct ElementPoint:HandyJSON {
    var top:Float?
    var left:Float?
}

struct ElementCrop:HandyJSON {
    var top:Float?
    var left:Float?
    var width:Float?
    var height:Float?
}

struct ElementClip:HandyJSON {
    var start:Float?
    var duration:Float?
}

struct MusicSource:HandyJSON{
    var name:String?
}

struct ScreenLayer:HandyJSON {
    var top:Float = 0.0
    var left:Float = 0.0
    var width:Float = 0.0
    var height:Float = 0.0
    var image:String?
    var opacity:Float = 0.0
    var name:String?
    var index:Int = 0
}

class ScreenElement:HandyJSON {
    var default_text:String?
    var id:String?
    var max_length:Int?
    var type:String?
    var name:String?
    var value:String?
    var duration:Float?
    var no_audio:Bool?
    var video_width:Float?
    var video_height:Float?
    var image_width:Float?
    var image_height:Float?
    var mark:ElementMaker?
    var clip:ElementClip?
    var point:ElementPoint?
    var source:MusicSource?
    var top:Float = 0.0
    var left:Float = 0.0
    var width:Float = 0.0
    var height:Float = 0.0
    var cover:String?
    
     required init() {}
}


class TemplateScreen:HandyJSON {
    var layers:[ScreenLayer]?
    var id:String?
    var image:String?
    var video:String?
    var elements:[ScreenElement]?
    var maker:ElementMaker?
     required init() {}
}

class Template:HandyJSON{
    var tpl_description:String?
    var elements:ElementCount?
    var title:String?
    var id:String?
    var video_uuid:String?
    var image:String?
    var video:String?
    var audio:String?
    var price:Float?
    var original_price:Float?
    var price_info:String?
    var price_type:String?
    var duration:Int?
    var video_width:Float = 0.0
    var video_height:Float = 0.0
    var tags:[String]?
    var screens:[TemplateScreen]?
    var remove_audio:Bool = false
    var remove_watermark:Bool = false
    var template_cover:String?
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        
        mapper <<<
           self.id <-- "uuid"
        
        mapper <<<
            self.tpl_description <-- "template_description"
        
    }
}
