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
bridge.setSaturation(saturation: 255)
bridge.setBrightness(brightness: 0)
bridge.turnOff(light: 3) //annoying light is annoying

func updateColors() {
    let cols = SLColorArt.withDesktopWallpaper()!
    
    //saturation and brightness are tricky to get right for a dark room
    //some colors just don't translate well to lighting and we could 
    //be sitting in low saturated (= white) colors all time
    //the same with brightness. let's cap it at 100.
    func fobbleLight(light: Int, color: NSColor) {
        let h = Int(color.hueComponent * 0xffff) + 3655
        let b = Int(color.brightnessComponent * 127)
        let s = 100 + Int(color.saturationComponent * 150)
        
        print("light \(light) => h: \(h), s: \(s), b: \(b)")
        
        bridge.setHue(light: light, hue: h)
        bridge.setBrightness(light: light, brightness: b)
        bridge.setSaturation(light: light, saturation: s)
    }

    //these lighting layout is hardcoded for my office.
    //change according to yours
    if let col = cols.primaryColor {
        fobbleLight(light: 1, color: col)
    }
    
    if let col = cols.secondaryColor {
        fobbleLight(light: 2, color: col)
    }
    
    //that lamp is annoying no matter what color it has :/
    //if let col = cols.detailColor {
    //    fobbleLight(light: 3, color: col)
    //}
    
    if let col = cols.detailColor {
        fobbleLight(light: 4, color: col)
    } else {
        print("could not get detail color. attemping primary color.")
        if let col = cols.primaryColor {
            fobbleLight(light: 4, color: col)
        }
    }
    
    if let col = cols.backgroundColor {
        fobbleLight(light: 5, color: col)
    } else {
        print("could not get background color. attemping secondary color.")
        if let col = cols.primaryColor {
            fobbleLight(light: 5, color: col)
        }
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

//an annoying randomized loop
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
