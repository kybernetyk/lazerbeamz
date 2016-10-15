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

var bridge = Lazerbeamz.Bridge()
var lights = bridge.lights
print(lights)

bridge.lights[5]!.saturation = 255

//////
while true {
    bridge.setBrightness(brightness: 255)
    sleep(1)
    bridge.setHue(hue: Int(arc4random_uniform(0xffff)))
    sleep(1)
    bridge.setBrightness(brightness: 0)
    sleep(1)
    bridge.setHue(hue: Int(0xffff))
    sleep(1)
}
