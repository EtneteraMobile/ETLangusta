//
//  DataProvider.swift
//  ETLangusta
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

public protocol DataProviderType {
    func getLocalData() -> Data
    func loadData(completion: @escaping ((Data?) -> Void))
    func loadData(platform: String?, language: String?, currentVersion: String?, completion: @escaping ((Data?) -> Void))
}

public class DataProvider: DataProviderType {

    let backupFile: String
    let url: URL?

    public init(backupFile: String, url: URL?) {
        self.backupFile = backupFile
        self.url = url
    }

    public func getLocalData() -> Data {
        return getJsonFromMainBundle(with: backupFile)

    }

    public func loadData(completion: @escaping ((Data?) -> Void)) {
        guard let url = url else {
            print("Url is nil, can't fetch remote data")
            completion(nil)
            return
        }
        fetchLocalizationJSON(from: url) { (data) in
            completion(data)
        }
    }

    public func loadData(platform: String?, language: String?, currentVersion: String?, completion: @escaping ((Data?) -> Void)) {
        guard let url = url else {
            print("Url is nil, can't fetch remote data")
            completion(nil)
            return
        }
        fetchLocalizationJSON(platform: platform, language: language, currentVersion: currentVersion, from: url) { (data) in
            completion(data)
        }
    }

    // MARK: Fetching and decoding JSON

    private func fetchLocalizationJSON(platform: String?, language: String?, currentVersion: String?, from url: URL, completion: @escaping ((Data?) -> Void)) {
        var components = URLComponents(string: url.absoluteString)! // swiftlint:disable:this force_unwrapping

        var queryItems: [URLQueryItem] = []

        if let platform = platform {
            queryItems.append(URLQueryItem(name: "platform", value: platform))
        }

        if let language = language {
            queryItems.append(URLQueryItem(name: "language", value: language))
        }

        if let currentVersion = currentVersion {
            queryItems.append(URLQueryItem(name: "version", value: currentVersion))
        }

        components.queryItems = queryItems
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")

        let request = URLRequest(url: components.url!) // swiftlint:disable:this force_unwrapping

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            completion(data)
        }
        print("Sending: \(task.currentRequest)")
        task.resume()
    }

    private func fetchLocalizationJSON(from url: URL, completion: @escaping ((Data?) -> Void)) {

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                print("✅ Fetched Data from remote url.")
                completion(data)

            } else if let error = error {
                print("Error while fetching localization JSON :\(error)")
                completion(nil)
            }
        }

        task.resume()
    }

    // MARK: - Helper methods

    // Temporary function - get local JSON File
    private func getJsonFromMainBundle(with filename: String) -> Data {
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                return data
            } catch {
                preconditionFailure("🦀 Can't make data from \(filename).json")
            }
        }
        preconditionFailure("🦀 Can't find \(filename).json in main bundle")
    }

}
