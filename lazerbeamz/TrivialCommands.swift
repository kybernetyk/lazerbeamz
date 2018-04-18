//
//  LazerBri.swift
//  lazerbeamz
//
//  Created by kyb on 18.04.18.
//  Copyright © 2018 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation

class CmdBri : Command {
    func exec(args: [String], bridge: Lazerbeamz.Bridge) -> Bool {
        if args.count == 2 {
            if let val = Int(args[1]) {
                bridge.setBrightness(brightness: val)
                return true
            }
            return false
        }
        if args.count == 3 {
            if let light = Int(args[1]), let val = Int(args[2]) {
                bridge.setBrightness(light: light, brightness: val)
                return true
            }
            return false
        }
        return false
    }

    var triggerWords: [String] {
        return ["bri"]
    }

    var helpString: String {
        return "bri [lightnum] <brigthness (0-255)>"
    }
}


class CmdHue : Command {
    func exec(args: [String], bridge: Lazerbeamz.Bridge) -> Bool {
        if args.count == 2 {
            if let val = Int(args[1]) {
                bridge.setHue(hue: val)
                return true
            }
            return false
        }
        if args.count == 3 {
            if let light = Int(args[1]), let val = Int(args[2]) {
                bridge.setHue(light: light, hue: val)
                return true
            }
            return false
        }
        return false
    }

    var triggerWords: [String] {
        return ["hue"]
    }

    var helpString: String {
        return "hue [lightnum] <hue (0-65280)>"
    }
}


class CmdSat : Command {
    func exec(args: [String], bridge: Lazerbeamz.Bridge) -> Bool {
        if args.count == 2 {
            if let val = Int(args[1]) {
                bridge.setSaturation(saturation: val)
                return true
            }
            return false
        }
        if args.count == 3 {
            if let light = Int(args[1]), let val = Int(args[2]) {
                bridge.setSaturation(light: light, saturation: val)
                return true
            }
            return false
        }
        return false
    }

    var triggerWords: [String] {
        return ["sat"]
    }

    var helpString: String {
        return "sat [lightnum] <sat (0-255)>"
    }
}


class CmdOnOff : Command {
    func exec(args: [String], bridge: Lazerbeamz.Bridge) -> Bool {
        if args.count == 1 {
            let toggle = args[0]
            switch toggle {
            case "on":
                bridge.turnOn()
                return true
            case "off":
                bridge.turnOff()
                return true
            default:
                return false
            }
        }
        if args.count == 2 {
            let toggle = args[0]
            if let lightnum = Int(args[1]) {
                switch toggle {
                case "on":
                    bridge.turnOn(light: lightnum)
                    return true
                case "off":
                    bridge.turnOff(light: lightnum)
                    return true
                default:
                    return false
                }
            }
            return false
        }
        return false
    }

    var triggerWords: [String] {
        return ["on", "off"]
    }

    var helpString: String {
        return "on || off [lightnum]"
    }
}
