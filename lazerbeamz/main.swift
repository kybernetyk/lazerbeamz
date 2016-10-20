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

let colorizer = Colorizer()

func updateLights() {
    var colors = ColorSet()
    
    do {
        colors = try colorizer.colorForCurrentWallpaper()
    } catch {
        print(error)
        return
    }
    
    //saturation and brightness are tricky to get right for a dark room
    //some colors just don't translate well to lighting and we could
    //be sitting in low saturated (= white) colors all time
    //the same with brightness. let's cap it at 100.
    func fobbleLight(light: Int, color: Color) {
        let h = Int(color.hue * 0xffff) + 3655
        let b = Int(color.brightness * 127)
        let s = 100 + Int(color.saturation * 155)
        
        print("light \(light) => h: \(h), s: \(s), b: \(b)")
        
        bridge.setHue(light: light, hue: h)
        bridge.setBrightness(light: light, brightness: b)
        bridge.setSaturation(light: light, saturation: s)
    }
    
    //these lighting layout is hardcoded for my office.
    //change according to yours
    fobbleLight(light: 1, color: colors.primary)
    fobbleLight(light: 2, color: colors.secondary)
    fobbleLight(light: 4, color: colors.detail)
    fobbleLight(light: 5, color: colors.background)
}

var currentWallpaper = ""

while true {
    do {
        let wp = try colorizer.currentWallpaperPath()
        if wp != currentWallpaper {
            print("wallpaper changed to: \(wp)")
            currentWallpaper = wp
            updateLights();
        }
    } catch {
        print(error)
    }
    sleep(1)
}
