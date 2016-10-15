//
//  HueBridge.swift
//  lazerbeamz
//
//  Created by kyb on 14/10/2016.
//  Copyright © 2016 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation

struct Lazerbeamz {
    struct Light {
        var id: Int = -1
        var name: String = "Unknown"
        var model: String  = "Unknown"
        var manufacturer: String  = "Unknown"

        fileprivate var bridge: Bridge = Bridge()
        
//        fileprivate struct State {
//            var bri: Int = 0
//            var hue: Int = 0
//            var sat: Int = 0
//            var on: Bool = false
//        }
        
        func updateState() {
//            self.state = Lazerbeamz.stateForLight(bridge: self.bridge, lightID: self.id)
        }
        
        var brightness: Int {
            set {
                Lazerbeamz.setBrightness(bridge: self.bridge, lightID: self.id, brightness: newValue)
            }
            get {
                updateState()
                return -1
            }
        }
        
        var hue: Int {
            set {
                Lazerbeamz.setHue(bridge: self.bridge, lightID: self.id, hue: newValue)
            }
            get {
                updateState()
                return -1
            }
        }
        
        var saturation: Int {
            set {
                Lazerbeamz.setSaturation(bridge: self.bridge, lightID: self.id, saturation: newValue)
            }
            get {
                updateState()
                return -1
            }
        }
        
    }
    
    struct Bridge {
        struct Config {
            var ip: String = "10.0.0.4"
            var key: String = "2c94da63e6702cf1c368f5b30235a47"
            var transitionTime: Int = 15
            var blockingNetworkCalls: Bool = true
            var verbose: Bool = false
        }
        
        var cfg: Config = Config()
        
        fileprivate var baseURL: String {
            get {
                return "http://\(self.cfg.ip)/api/\(self.cfg.key)"
            }
        }
        
        var lights: [Int : Light] {
            set {
                
            }
            get {
                let arr = Lazerbeamz.enumerateConnectedLights(bridge: self)
                var ret: [Int : Light] = [:]
                for l in arr {
                    ret[l.id] = l
                }
                return ret
            }
        }
        
        func setBrightness(brightness: Int) {
            Lazerbeamz.setBrightness(bridge: self, lightID: 0, brightness: brightness)
        }
        
        func setHue(hue: Int) {
            Lazerbeamz.setHue(bridge: self, lightID: 0, hue: hue)
        }
        
        func setSaturation(saturation: Int) {
            Lazerbeamz.setSaturation(bridge: self, lightID: 0, saturation: saturation)
        }
    }
}


extension Lazerbeamz {
    fileprivate static func enumerateConnectedLights(bridge: Bridge) -> [Light] {
        let url = bridge.baseURL + "/lights"
        var ret: [Light] = []
        
        do {
            let dict = try get(url: url)
            var curID: Int = 1
            for (key, l) in dict {
                var light = Light()
                light.bridge = bridge
                light.id = Int(key)!
                light.name = l["name"] as! String
                light.model = l["modelid"] as! String
                light.manufacturer = l["manufacturername"] as! String
                
//                let state = l["state"] as! Dictionary<String, AnyObject>
//                
//                light.state.bri = state["bri"] as! Int
//                light.state.hue = state["hue"] as! Int
//                light.state.sat = state["sat"] as! Int
//                light.state.on = state["on"] as! Bool
                ret.append(light)
                
                curID += 1
            }
            
            return ret
        } catch {
            print("Net Error: \(error)")
            return []
        }
    }
}

extension Lazerbeamz {
    private static func setParameterToValue(bridge: Bridge, lightID: Int, parameterName: String, parameterValue: Int) {
        let payload = [parameterName : parameterValue,
                       "transitiontime" : bridge.cfg.transitionTime]
        let url = bridge.baseURL + actionPathForLight(lightID: lightID)
        put(url: url, payload: payload)
    }
    
    fileprivate static func setHue(bridge: Bridge, lightID: Int, hue: Int) {
        let val = min(max(0, hue), 0xffff)
        setParameterToValue(bridge: bridge,
                            lightID: lightID,
                            parameterName: "hue",
                            parameterValue: val)
    }
    
    fileprivate static func setBrightness(bridge: Bridge, lightID: Int, brightness: Int) {
        let val = min(max(0, brightness), 255)
        setParameterToValue(bridge: bridge,
                            lightID: lightID,
                            parameterName: "bri",
                            parameterValue: val)
    }
    
    fileprivate static func setSaturation(bridge: Bridge, lightID: Int, saturation: Int) {
        let val = min(max(0, saturation), 255)
        setParameterToValue(bridge: bridge,
                            lightID: lightID,
                            parameterName: "sat",
                            parameterValue: val)
    }
    
    
}


////MARK: - Networking
extension Lazerbeamz {
    enum NetError : Error {
        case UrlFormatError
        case NoAnswer
    }
    
    fileprivate static func actionPathForLight(lightID: Int) -> String {
        if lightID == 0 {
            return "/groups/\(lightID)/action"
        } else {
            return "/lights/\(lightID)/state"
        }
    }
    
    fileprivate static func put(url: String, payload: [String:Int]) {
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

