//
//  Langusta+Language.swift
//  ETLangusta
//
//  Created by Petr Urban on 23/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

public extension Langusta {
    
    public enum Language {
        // TODO: add languages
        case en
        case cs
        case sk
        case pl
        case ro
        case custom(code: String)

        public var code: String {
            switch self {
            case .en:
                return "en"
            case .cs:
                return "cs"
            case .sk:
                return "sk"
            case .custom(let code):
                return code
            case .pl:
                return "pl"
            case .ro:
                return "ro"
            }
        }
    }
}
