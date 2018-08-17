//
//  LangustaData.swift
//  ETLangusta-iOS
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

struct LangustaData: Decodable {
    var version: String
    var languages: [Language]

    private enum CodingKeys: String, CodingKey {
        case version
        case languages = "localizations"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)

        let data = try container.decode([String: Language].self, forKey: .languages)
        languages = []
        for item in data {
            let language = Language(name: item.key, commonContent: item.value.commonContent, iosContent: item.value.iosContent)
            languages.append(language)
        }
    }
}

struct Language: Decodable {
    var name: String?
    var commonContent: [String: String]
    var iosContent: [String: String]

    private enum CodingKeys: String, CodingKey {
        case name
        case commonContent = "_"
        case iosContent = "ios"
    }
}
