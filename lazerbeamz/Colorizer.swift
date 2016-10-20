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
        //1. try to retrieve from db
//        do {
//            if let cols = try self.database.read(filename: path) {
//                return cols
//            }
//        } catch {
//            print(error)
//        }
//        
        /*
            note: we can't just forward try here because even if the db fails we want to return a calculated ColorSet
        */
        
        //2. if not found caluclate
        let cols = try calculateColorSetForFile(file: path)
//        do {
//            try self.database.insert(filename: path, colorset: cols)
//        } catch {
//            print(error)
//        }
//        
        return cols
    }
    
    func currentWallpaperPath() throws -> String {
        guard let fn =  SLColorArt.currentDesktopWallpaperPath() else {
            throw ColorizerError.NoWallpaperFound
        }
        return fn
    }
    
    init() {
//        try? self.database.open(filename: "colors.sqlite")
    }
    
//    fileprivate var database = ColorDB()
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
}
