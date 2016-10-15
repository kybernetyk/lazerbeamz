//
//  HueBridge.swift
//  lazerbeamz
//
//  Created by kyb on 14/10/2016.
//  Copyright © 2016 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation

//MARK: - High Level Hue Abstraction
struct Lazerbeamz {
    struct Light {
        var id: Int = -1
        var name: String = "Unknown"
        var model: String  = "Unknown"
        var manufacturer: String  = "Unknown"
        
        struct State {
            var bri: Int = 0
            var hue: Int = 0
            var sat: Int = 0
            var on: Bool = false
        }
        
        var state: State = State()
    }
    
    struct Bridge {
        struct Config {
            var ipOrHostname: String = "10.0.0.4"
            var apiKey: String = "2c94da63e6702cf1c368f5b30235a47"
            var transitionTime: Int = 15
            var blockingNetworkCalls: Bool = true
            var verbose: Bool = false
        }
        
        var cfg: Config = Config()
        
        func enumerateConnectedLights() -> [Light] {
            return Lazerbeamz.enumerateConnectedLights(bridgeAddress: self.cfg.ipOrHostname,
                                                       apiKey: self.cfg.apiKey)
        }
        
        /* following operations will apply to specified light only */
        func turnOn(light: Int) {
            Lazerbeamz.setOn(bridgeAddress: self.cfg.ipOrHostname,
                             apiKey: self.cfg.apiKey,
                             lightID: light,
                             on: true,
                             transitionTime: 0)
        }
        
        func turnOff(light: Int) {
            Lazerbeamz.setOn(bridgeAddress: self.cfg.ipOrHostname,
                             apiKey: self.cfg.apiKey,
                             lightID: light,
                             on: false,
                             transitionTime: 0)
        }
        
        func setBrightness(light: Int, brightness: Int) {
            Lazerbeamz.setBrightness(bridgeAddress: self.cfg.ipOrHostname,
                                     apiKey: self.cfg.apiKey,
                                     lightID: light,
                                     brightness: brightness,
                                     transitionTime: cfg.transitionTime)
        }
        
        func setHue(light: Int, hue: Int) {
            Lazerbeamz.setHue(bridgeAddress: self.cfg.ipOrHostname,
                              apiKey: self.cfg.apiKey,
                              lightID: light,
                              hue: hue,
                              transitionTime: cfg.transitionTime)
        }
        
        func setSaturation(light: Int, saturation: Int) {
            Lazerbeamz.setSaturation(bridgeAddress: self.cfg.ipOrHostname,
                                     apiKey: self.cfg.apiKey,
                                     lightID: light,
                                     saturation: saturation,
                                     transitionTime: cfg.transitionTime)
        }
        
        /* following operations will apply to all connected lights */
        func turnOn() {
            self.turnOn(light: 0)
        }
        
        func turnOff() {
            self.turnOff(light: 0)
        }
        
        func setBrightness(brightness: Int) {
            self.setBrightness(light: 0,
                               brightness: brightness)
        }
        
        func setHue(hue: Int) {
            self.setHue(light: 0,
                        hue: hue)
        }
        
        func setSaturation(saturation: Int) {
            self.setSaturation(light: 0,
                               saturation: saturation)
        }
        
    }
}

//MARK: - Low Level Hue Access
extension Lazerbeamz {
    fileprivate static func baseUrlForBridge(bridgeAddress: String, apiKey: String) -> String {
        return "http://\(bridgeAddress)/api/\(apiKey)"
    }
    
    private static func sendToBridge(bridgeAddress: String, apiKey: String, lightID: Int, payload: [String : Any]) {
        let baseURL = baseUrlForBridge(bridgeAddress: bridgeAddress, apiKey: apiKey)
        let endpoint = lightID == 0 ? "/groups/\(lightID)/action" : "/lights/\(lightID)/state"
        let url = baseURL + endpoint
        put(url: url, payload: payload)
    }
    
    fileprivate static func setHue(bridgeAddress: String, apiKey: String, lightID: Int, hue: Int, transitionTime: Int) {
        let val = min(max(0, hue), 0xffff)
        
        sendToBridge(bridgeAddress: bridgeAddress,
                     apiKey: apiKey,
                     lightID: lightID,
                     payload: ["hue" : val,
                               "transitiontime" : transitionTime])
    }
    
    fileprivate static func setBrightness(bridgeAddress: String, apiKey: String, lightID: Int, brightness: Int, transitionTime: Int) {
        let val = min(max(0, brightness), 255)
        sendToBridge(bridgeAddress: bridgeAddress,
                     apiKey: apiKey,
                     lightID: lightID,
                     payload: ["bri" : val,
                               "transitiontime" : transitionTime])
    }
    
    fileprivate static func setSaturation(bridgeAddress: String, apiKey: String, lightID: Int, saturation: Int, transitionTime: Int) {
        let val = min(max(0, saturation), 255)
        sendToBridge(bridgeAddress: bridgeAddress,
                     apiKey: apiKey,
                     lightID: lightID,
                     payload: ["sat" : val,
                               "transitiontime" : transitionTime])
    }
    
    fileprivate static func setOn(bridgeAddress: String, apiKey: String, lightID: Int, on: Bool, transitionTime: Int) {
        sendToBridge(bridgeAddress: bridgeAddress,
                     apiKey: apiKey,
                     lightID: lightID,
                     payload: ["on" : on,
                               "transitiontime" : transitionTime])
    }
}

extension Lazerbeamz {
    fileprivate static func enumerateConnectedLights(bridgeAddress: String, apiKey: String) -> [Light] {
        let baseURL = baseUrlForBridge(bridgeAddress: bridgeAddress, apiKey: apiKey)
        let url = baseURL + "/lights"
        var ret: [Light] = []
        
        //create our special "all lights" light
        //this is maily so that a) the user knows that sending
        //messages to light 0 will affect all connected lights
        //and be to fit into Hue's 1-based indexing scheme for
        //light ids
        do {
            var light = Light()
            light.id = 0
            light.name = "All Lights Group."
            light.model = "generilight"
            light.manufacturer = "ACME"
            ret.append(light)
        }
        
        do {
            let dict = try get(url: url)
            for (key, l) in dict {
                var light = Light()
                light.id = Int(key)!
                light.name = l["name"] as! String
                light.model = l["modelid"] as! String
                light.manufacturer = l["manufacturername"] as! String
                
                let state = l["state"] as! Dictionary<String, AnyObject>
                
                light.state.bri = state["bri"] as! Int
                light.state.hue = state["hue"] as! Int
                light.state.sat = state["sat"] as! Int
                light.state.on = state["on"] as! Bool
                ret.append(light)
            }
            
            return ret.sorted(by: {$0.id < $1.id})
        } catch {
            print("Net Error: \(error)")
            return ret
        }
    }
}

//MARK: - HTTP Networking
extension Lazerbeamz {
    enum NetError : Error {
        case UrlFormatError
        case NoAnswer
    }
    
    fileprivate static func put(url: String, payload: [String:Any]) {
        guard let pls = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("json fuckup bro")
            return
        }
        
        guard let url = URL(string: url) else {
            return
        }
        let req = NSMutableURLRequest(url: url)
        req.httpMethod = "PUT"
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        req.httpBody = pls
        
        //let's turn this request into blocking so our prog doesn't get terminated
        //before we get the network answer
        let sem = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: req as URLRequest) { (data, response, error) in
            sem.signal()
            
        }
        task.resume()
        sem.wait()
    }
    
    fileprivate static func get(url: String) throws -> Dictionary<String, AnyObject> {
        guard let url = URL(string: url) else {
            throw NetError.UrlFormatError
        }
        
        let req = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        var responseData: Data? = nil
        
        let sem = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: req as URLRequest) { (data, response, error) in
            if let data = data /*, let s = String(data: data, encoding: .utf8)*/ {
                responseData = data
            }
            sem.signal()
        }
        task.resume()
        sem.wait()
        
        if let data = responseData {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, AnyObject> {
                return dict
            }
            
            throw NetError.NoAnswer
        } else {
            throw NetError.NoAnswer
        }
    }
}

