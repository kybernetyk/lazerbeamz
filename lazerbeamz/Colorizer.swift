//
//  Colorizer.swift
//  lazerbeamz
//
//  Created by kyb on 20/10/2016.
//  Copyright © 2016 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation
typealias Color = (hue: Float, saturation: Float, brightness: Float)

struct ColorSet {
    var primary: Color = (0, 0, 0)
    var secondary: Color  = (0, 0, 0)
    var detail: Color  = (0, 0, 0)
    var background: Color  = (0, 0, 0)
}


class Colorizer {
    enum ColorizerError : Error {
        case NoWallpaperFound
        case FileNotFound(path: String)
    }
    
    func colorForCurrentWallpaper() throws -> ColorSet {
        let path = try self.currentWallpaperPath()
        
        //2. if not found caluclate
        let cols = try calculateColorSetForFile(file: path)
        return cols
    }
    
    func currentWallpaperPath() throws -> String {
        guard let fn =  SLColorArt.currentDesktopWallpaperPath() else {
            throw ColorizerError.NoWallpaperFound
        }
        return fn
    }
    
    func colorForMainScreen() throws -> ColorSet {
        let cols = try self.calculateColorSetForScreen()
        return cols
    }
    
    func colorsForMainScreen() throws -> [ColorSet] {
        let cols = try self.calculateColorSetsForScreen()
        return cols
    }

}

fileprivate extension Colorizer {
    func calculateColorSetForFile(file: String) throws -> ColorSet {        
        guard let cols = SLColorArt.init(forImageAtPath: file) else {
            throw ColorizerError.FileNotFound(path: file)
        }
        
        var colset: ColorSet = ColorSet()
        
        if let c = cols.primaryColor {
            colset.primary = Color(hue: Float(c.hueComponent),
                                   saturation: Float(c.saturationComponent),
                                   brightness: Float(c.brightnessComponent))
        }
        
        if let c = cols.secondaryColor {
            colset.secondary = Color(hue: Float(c.hueComponent),
                                     saturation: Float(c.saturationComponent),
                                     brightness: Float(c.brightnessComponent))
        }
        
        if let c = cols.detailColor {
            colset.detail = Color(hue: Float(c.hueComponent),
                                  saturation: Float(c.saturationComponent),
                                  brightness: Float(c.brightnessComponent))
        } else {
            colset.detail = colset.primary
        }
        
        if let c = cols.backgroundColor {
            colset.background = Color(hue: Float(c.hueComponent),
                                      saturation: Float(c.saturationComponent),
                                      brightness: Float(c.brightnessComponent))
        } else {
            colset.background = colset.primary
        }
        
        
        return colset;
      }
    
    func calculateColorSetForScreen() throws -> ColorSet {
//        guard let cols = SLColorArt.init(forImageAtPath: file) else {
//            throw ColorizerError.FileNotFound(path: file)
//        }
        
        guard let cols = SLColorArt.forMainScreen() else {
            throw ColorizerError.NoWallpaperFound
        }
        
        var colset: ColorSet = ColorSet()
        
        if let c = cols.primaryColor {
            colset.primary = Color(hue: Float(c.hueComponent),
                                   saturation: Float(c.saturationComponent),
                                   brightness: Float(c.brightnessComponent))
        }
        
        if let c = cols.secondaryColor {
            colset.secondary = Color(hue: Float(c.hueComponent),
                                     saturation: Float(c.saturationComponent),
                                     brightness: Float(c.brightnessComponent))
        }
        
        if let c = cols.detailColor {
            colset.detail = Color(hue: Float(c.hueComponent),
                                  saturation: Float(c.saturationComponent),
                                  brightness: Float(c.brightnessComponent))
        } else {
            colset.detail = colset.primary
        }
        
        if let c = cols.backgroundColor {
            colset.background = Color(hue: Float(c.hueComponent),
                                      saturation: Float(c.saturationComponent),
                                      brightness: Float(c.brightnessComponent))
        } else {
            colset.background = colset.primary
        }
        
        
        return colset;
    }

    func calculateColorSetsForScreen() throws -> [ColorSet] {
        //        guard let cols = SLColorArt.init(forImageAtPath: file) else {
        //            throw ColorizerError.FileNotFound(path: file)
        //        }
        
        guard let cols = SLColorArt.colorArtsForMainScreen() else {
            throw ColorizerError.NoWallpaperFound
        }
        
        var ret: [ColorSet] = []
        
        for originset in cols {
            var colset: ColorSet = ColorSet()
            
            if let c = originset.primaryColor {
                colset.primary = Color(hue: Float(c.hueComponent),
                                       saturation: Float(c.saturationComponent),
                                       brightness: Float(c.brightnessComponent))
            }
            
            if let c = originset.secondaryColor {
                colset.secondary = Color(hue: Float(c.hueComponent),
                                         saturation: Float(c.saturationComponent),
                                         brightness: Float(c.brightnessComponent))
            }
            
            if let c = originset.detailColor {
                colset.detail = Color(hue: Float(c.hueComponent),
                                      saturation: Float(c.saturationComponent),
                                      brightness: Float(c.brightnessComponent))
            } else {
                colset.detail = colset.primary
            }
            
            if let c = originset.backgroundColor {
                colset.background = Color(hue: Float(c.hueComponent),
                                          saturation: Float(c.saturationComponent),
                                          brightness: Float(c.brightnessComponent))
            } else {
                colset.background = colset.primary
            }
            
            ret.append(colset)
        }
        
        return ret;
    }

}
