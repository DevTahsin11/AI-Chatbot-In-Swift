//
//  AppConfig.swift
//  Tech.AI
//
//  Created by Tahsin Ahmed  on 1/3/26.
//

import Foundation

struct AppConfig {
    static var openAIAPIKey: String {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let key = plist["API_KEY"] as? String else {
            fatalError("Missing API_KEY in Secrets.plist")
        }
        return key
    }
}
