//
//  main.swift
//  lazerbeamz
//
//  control hue lights from your terminal
//
//  Created by kyb on 14/10/2016.
//  Copyright © 2016 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation
import Cocoa

var bridge = Lazerbeamz.Bridge()
print(bridge.enumerateConnectedLights())

bridge.turnOn()
//bridge.turnOn(light: 1)
bridge.setSaturation(saturation: 255)
bridge.setBrightness(brightness: 0)

func updateColors() {
    let cols = SLColorArt.withDesktopWallpaper()!
    
    func fobbleLight(light: Int, color: NSColor) {
        let h = Int(color.hueComponent * 0xffff) + 0x1000
        let b = Int(color.brightnessComponent * 100)
//        let s = Int(color.saturationComponent * 0xff)
        
        bridge.setHue(light: light, hue: h)
        bridge.setBrightness(light: light, brightness: b)
        bridge.setSaturation(light: light, saturation: 0xff)
    }
    
    if let col = cols.primaryColor {
        fobbleLight(light: 1, color: col)
    }
    
    if let col = cols.secondaryColor {
        fobbleLight(light: 2, color: col)
    }
    
    //if let col = cols.detailColor {
    //    fobbleLight(light: 3, color: col)
    //}
    
    if let col = cols.detailColor {
        fobbleLight(light: 4, color: col)
    }
    
    if let col = cols.backgroundColor {
        fobbleLight(light: 5, color: col)
    }
}

var currentWallpaper = ""

while true {
    let wp = SLColorArt.currentDesktopWallpaperPath()
    if wp != currentWallpaper {
        print("wallpaper changed to: \(wp)")
        currentWallpaper = wp!
        updateColors();
    }
    sleep(1)
}

//while true {
//    bridge.setBrightness(brightness: 255)
//    sleep(1)
//    bridge.setHue(hue: Int(arc4random_uniform(0xffff)))
//    sleep(1)
//    bridge.setBrightness(brightness: 0)
//    sleep(1)
//    bridge.setHue(hue: Int(0xffff))
//    sleep(1)
//}
