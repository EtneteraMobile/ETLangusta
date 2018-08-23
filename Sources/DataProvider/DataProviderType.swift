//
//  DataProviderType.swift
//  ETLangusta
//
//  Created by Petr Urban on 23/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

public protocol DataProviderType {

    /// Synchronously returns JSON in defined format as Data
    ///
    /// - Returns: JSON as Data
    func getLocalData() -> Data

    /// Asynchronously loads JSON in defined format
    ///
    /// - Parameter completion: JSON in defined format as Data - should be called from background thread
    func loadData(completion: @escaping ((Data?) -> Void))


    /// Asynchronously loads JSON in defined format
    ///
    /// - Parameters:
    ///   - platform: String - platform code like (an, ios)
    ///   - language: String - language code like (cs, en, sk, ...)
    ///   - currentVersion: String - version (higher is newer)
    ///   - completion: JSON in defined format as Data - should be called from background thread
    func loadData(platform: String?, language: String?, currentVersion: String?, completion: @escaping ((Data?) -> Void))
}
