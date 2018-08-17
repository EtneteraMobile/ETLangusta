//
//  LangustaError.swift
//  ETLangusta
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

enum LangustaError: Error, LocalizedError {
    case missingURL
    case invalidJson
    case languageNotFound(String)
    case keyNotFound(String, String)

    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "🦀 URL for remote fetch is missing"
        case .invalidJson:
            return "🦀 Can't get langusta data from JSON file"
        case .languageNotFound(let language):
            return "🦀 Language '\(language)' wasn't found"
        case .keyNotFound(let key, let language):
            return "🦀 Localization for given key '\(key)' wasn't found in '\(language)' language"
        }
    }
}
