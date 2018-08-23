//
//  LanguastaType.swift
//  ETLangusta
//
//  Created by Petr Urban on 23/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

protocol LangustaType {
    func fetch()
    func change(_ language: Langusta.Language)
    func loca(for key: String) -> String
    func loca(for key: String, with argument: String) -> String
    func loca(for key: String, with arguments: [String]) -> String

    var onUpdate: Event { get }
    var onLocalizationFailure: ((_ message: String) -> Void)? { get set }
}
