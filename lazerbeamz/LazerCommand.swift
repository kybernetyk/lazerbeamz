//
//  LazerPlugin.swift
//  lazerbeamz
//
//  Created by kyb on 18.04.18.
//  Copyright © 2018 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation

protocol Command {
    func exec(args: [String], bridge: Lazerbeamz.Bridge) -> Bool
    var triggerWords: [String] { get }
    var helpString: String { get }

    func canHandle(args: [String]) -> Bool
}

extension Command {
    func canHandle(args: [String]) -> Bool {
        let tw = self.triggerWords.map { $0.lowercased() }
        let args = args.map { $0.lowercased() }

        if let verb = args.first {
            return tw.contains(verb)
        }

        return false
    }
}
