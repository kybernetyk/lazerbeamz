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

enum Mode {
    case Help
    case Wallpaper
    case WallpaperContrast
    case Live
    case DumpState
    case Command
}

var mode = Mode.Command

if CommandLine.arguments.contains("--live") {
    mode = .Live
}

if CommandLine.arguments.contains("--wallpaper") {
    mode = .Wallpaper
}

if CommandLine.arguments.contains("--wallpapercon") {
    mode = .WallpaperContrast
}

if CommandLine.arguments.contains("--dump") {
    mode = .DumpState
}

if CommandLine.arguments.contains("--help") {
    mode = .Help
}


var commands: [Command] = []
var bridge = Lazerbeamz.Bridge()
let colorizer = Colorizer()

func updateLive2() {
    var colors: [ColorSet] = []
    
    do {
        colors = try colorizer.colorsForMainScreen()
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
        let s = Int(color.saturation * 255)
        
        print("light \(light) => h: \(h), s: \(s), b: \(b)")
        bridge.setHSV(light: light, hue: h, sat: s, bri: b)

        //        bridge.setHue(light: light, hue: h)
        //        bridge.setBrightness(light: light, brightness: b)
        //        bridge.setSaturation(light: light, saturation: s)
    }
    
    //these lighting layout is hardcoded for my office.
    //change according to yours
    fobbleLight(light: 1, color: colors[0].primary)
    //    fobbleLight(light: 4, color: colors[1].primary)
    fobbleLight(light: 2, color: colors[2].primary)
    fobbleLight(light: 5, color: colors[3].primary)
    
}

//ghetto ambilight (which doesn't work too well because of the high hue latency)
func doLiveMode() {
    func updateLive(prevColors: ColorSet) -> ColorSet {
        var colors = ColorSet()
        var prevColors = prevColors
        
        do {
            colors = try colorizer.dominantColorForMainScreen()
        } catch {
            print(error)
            return prevColors
        }

        
        
        //saturation and brightness are tricky to get right for a dark room
        //some colors just don't translate well to lighting and we could
        //be sitting in low saturated (= white) colors all time
        //the same with brightness. let's cap it at 100.
        func fobbleLight(light: Int, color: Color) {
            let h = Int(color.hue * 0xffff) + 3655
            let b = Int(color.brightness * 127)
            let s = Int(color.saturation * 255)
            
            print("light \(light) => h: \(h), s: \(s), b: \(b)")

            bridge.setHSV(light: light, hue: h, sat: s, bri: b)
            
            //            bridge.setHue(light: light, hue: h)
            //            bridge.setBrightness(light: light, brightness: b)
            //            bridge.setSaturation(light: light, saturation: s)
        }

        func fobbleLights(color: Color) {
            let h = Int(color.hue * 0xffff) + 3655
            let b = Int(color.brightness * 127)
            let s = Int(color.saturation * 255)

            print("all lights => h: \(h), s: \(s), b: \(b)")
            bridge.setHSV(light: 0, hue: h, sat: s, bri: b)
        }
        
        //these lighting layout is hardcoded for my office.
        //change according to yours
        if prevColors.primary != colors.primary {
            fobbleLight(light: 1, color: colors.primary)
            fobbleLight(light: 2, color: colors.primary)
            fobbleLight(light: 3, color: colors.primary)
            fobbleLight(light: 4, color: colors.primary)
            fobbleLight(light: 5, color: colors.primary)

//            fobbleLights(color: colors.primary)
            prevColors.primary = colors.primary
        }
//        if prevColors.secondary != colors.secondary {
//            fobbleLight(light: 2, color: colors.secondary)
//            prevColors.secondary = colors.secondary
//        }
////        if prevColors.detail != colors.detail {
////            fobbleLight(light: 4, color: colors.detail)
////            prevColors.detail = colors.detail
////        }
//        if prevColors.background != colors.background {
//            fobbleLight(light: 5, color: colors.background)
//            prevColors.background = colors.background
//        }

/*
        if prevColors.secondary != colors.secondary {
            fobbleLight(light: 2, color: colors.secondary)
            //            fobbleLight(light: 2, color: colors.primary)
            //            fobbleLight(light: 5, color: colors.primary)

            prevColors.secondary = colors.secondary
        }
        if prevColors.detail != colors.detail {
            fobbleLight(light: 5, color: colors.detail)
            prevColors.detail = colors.detail
        }
        //        if prevColors.detail != colors.detail {
        //            fobbleLight(light: 4, color: colors.detail)
        //            prevColors.detail = colors.detail
        //        }
        if prevColors.background != colors.background {
            fobbleLight(light: 1, color: colors.background)
            prevColors.background = colors.background
        }
*/

        return prevColors
    }

    bridge.turnOn()
    bridge.setSaturation(saturation: 255)
    bridge.setBrightness(brightness: 0)
    bridge.turnOff(light: 3) //annoying light is annoying

    bridge.cfg.transitionTime = 5
    var prevColors = ColorSet()
    
    while true {
        autoreleasepool {
            prevColors = updateLive(prevColors: prevColors);
        }
        usleep(250 * 1000)
    }
}

//sets the light colors to match current wallpaper colors
func doWallpaperMode() {
    func updateWallpaper() {
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
            bridge.setHSV(light: light, hue: h, sat: s, bri: b)
            //
            //            bridge.setHue(light: light, hue: h)
            //            bridge.setBrightness(light: light, brightness: b)
            //            bridge.setSaturation(light: light, saturation: s)
        }
        
        //these lighting layout is hardcoded for my office.
        //change according to yours
        fobbleLight(light: 1, color: colors.primary)
        fobbleLight(light: 2, color: colors.secondary)
        fobbleLight(light: 3, color: colors.background)
        //        fobbleLight(light: 4, color: colors.detail)
        fobbleLight(light: 5, color: colors.background)
    }
    

    bridge.turnOn()
    bridge.setSaturation(saturation: 255)
    bridge.setBrightness(brightness: 0)
    //bridge.turnOff(light: 3) //annoying light is annoying

    var currentWallpaper = ""
    while true {
        autoreleasepool {
            do {
                let wp = try colorizer.currentWallpaperPath()
                if wp != currentWallpaper {
                    print("wallpaper changed to: \(wp)")
                    currentWallpaper = wp
                    updateWallpaper();
                }
            } catch {
                print(error)
            }
            usleep(50 * 1000)
        }
    }
}

//sets the light colors to match current wallpaper colors (rotated by 180 deg on the H axis)
func doWallpaperContrastMode() {
    func updateWallpaper() {
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
            var roth = color.hue + 0.5
            if roth > 1.0 {
                roth = roth - 1.0
            }
            let h = Int(roth * 0xffff) + 3655
            let b = Int(color.brightness * 127)
            let s = 100 + Int(color.saturation * 155)
            
            print("light \(light) => h: \(h), s: \(s), b: \(b)")
            bridge.setHSV(light: light, hue: h, sat: s, bri: b)

            //            bridge.setHue(light: light, hue: h)
            //            bridge.setBrightness(light: light, brightness: b)
            //            bridge.setSaturation(light: light, saturation: s)
        }
        
        //these lighting layout is hardcoded for my office.
        //change according to yours
        fobbleLight(light: 1, color: colors.primary)
        fobbleLight(light: 2, color: colors.secondary)
        fobbleLight(light: 3, color: colors.background)
        fobbleLight(light: 4, color: colors.detail)
        fobbleLight(light: 5, color: colors.background)
    }
    
    
    bridge.turnOn()
    bridge.setSaturation(saturation: 255)
    bridge.setBrightness(brightness: 0)
    //bridge.turnOff(light: 3) //annoying light is annoying
    
    var currentWallpaper = ""
    while true {
        autoreleasepool {
            do {
                let wp = try colorizer.currentWallpaperPath()
                if wp != currentWallpaper {
                    print("wallpaper changed to: \(wp)")
                    currentWallpaper = wp
                    updateWallpaper();
                }
            } catch {
                print(error)
            }
            usleep(50 * 1000)
        }
    }
}


//this will generate a shell script so you
//can restore the current light state later
func doDumpMode() {
    print("#!/bin/sh")
    print("#  script generated")
    print("#    on \(Date())")
    print("#    by \(NSUserName())")
    print("")
    
    let lights = bridge.enumerateConnectedLights()
    for l in lights {
        if l.id == 0 {
            continue
        }
        print("#Light id \(l.id) - \(l.manufacturer) - \(l.model) - \(l.name)")
        if l.state.on {
            print("light_on \(l.id)")
        } else {
            print("light_off \(l.id)")
        }
        print("light_hue \(l.id) \(l.state.hue)")
        print("light_sat \(l.id) \(l.state.sat)")
        print("light_bri \(l.id) \(l.state.bri)")
        print("")
    }
}

func doHelpMode() {
    print("syntax: lazerbeamz <mode_switch || command>")
    print("valid mode switches:")
    print("  --wallpaper")
    print("    set light colors to current desktop wallpaper colors")
    print("  --wallpapercon")
    print("    set light colors to constrast current desktop wallpaper colors")
    print("  --live")
    print("    poor man's ambilight")
    print("  --dump")
    print("    dump script that saves current light state")
    print("  --help")
    print("    help")
    print("  commands:")
    for cmd in commands {
        print("    \(cmd.helpString)")
    }
}

func doMode(mode: Mode) {
    switch mode {
    case .Live: doLiveMode()
    case .Wallpaper: doWallpaperMode()
    case .WallpaperContrast: doWallpaperContrastMode()
    case .DumpState: doDumpMode()
    case .Command: doCommandMode()
    default: doHelpMode()
    }
}


func doCommandMode() {
    var args = CommandLine.arguments
    args.removeFirst()
    args = args.map { $0.lowercased() }

    for cmd in commands {
        if cmd.canHandle(args: args) {
            if (!cmd.exec(args: args, bridge: bridge)) {
                print(cmd.helpString)
            }
            return
        }
    }
    doMode(mode: .Help)
}

func registerCommands() {
    commands.append(CmdBri())
    commands.append(CmdHue())
    commands.append(CmdSat())
    commands.append(CmdOnOff())
}

registerCommands()
doMode(mode: mode)
