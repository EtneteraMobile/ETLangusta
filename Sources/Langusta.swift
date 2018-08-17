//
//  Langusta.swift
//  Etnetera a.s.
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s.. All rights reserved.
//

import Foundation

protocol DataProviderType {

    func loadData(completion: ((Data?) -> Void))
}

class RemoteDataProvider: DataProviderType {

    let url: URL

    init(url: URL) {
        self.url = url
    }

    func loadData(completion: ((Data?) -> Void)) {
        fetchLocalizationJSON(from: url) { (data) in
            completion(data)
        }
    }

    // MARK: Fetching and decoding JSON

    private func fetchLocalizationJSON(from url: URL, completion: ((Data?) -> Void)) {
        let jsonFile = loadJson(filename: "dummy")!
        completion(jsonFile)

        // TODO: - Send task to fetch json from server
        //        let task = URLSession.shared.dataTask(with: url) { data, _, error in
        //            if let data = data {
        //                print("✅ Fetched Data from remote url.")
        //
        //
        //            } else if let error = error {
        //
        //            }
        //        }.resume()
    }

    // MARK: - Helper methods

    // TODO: [Oko] - Get rid of this after remote returns correct json file
    // Temporary function - get local JSON File
    private func loadJson(filename fileName: String) -> Data? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                return data
            } catch {
                print("\(error)")
            }
        }
        return nil
    }

}

public class Langusta {

    public class Config {
        var platform: Platform = .iOS // required
        var multiLanguage: Bool = true
        var defaultLanguage: String
        var updateOnInit: Bool = true

        var dataProvider: DataProviderType

        init(platform: Platform = .iOS, defaultLanguage: String, dataProvider: DataProviderType) {
            self.platform = platform
            self.defaultLanguage = defaultLanguage
            self.dataProvider = dataProvider
        }

        enum Platform: String {
            case universal = "_"
            case iOS = "ios"
            case android = "an"
        }
    }

    // MARK: Public

    // MARK: Private
    private let fileManager = FileManager.default
    private let bundleName = Bundle.main.bundleIdentifier! //swiftlint:disable:this force_unwrapping
    private lazy var bundlePath: URL = {
        let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!) //swiftlint:disable:this force_unwrapping
      print("\n [Document's directory:] \(documents.absoluteString)\n")

        let bundlePath = documents.appendingPathComponent(bundleName, isDirectory: true)
        return bundlePath
    }()

    // MARK: - Initialization

   public init(config: Config) {
        setupWith(config: config)
    }

   private func setupWith(config: Config) {

    config.dataProvider.loadData { (data) in

        // Get LangustaData (languages) from JSON
        getLangustaData(from: data) { (langustaData) in

            // Make strings in ("Key" = "Value") format
            guard let langustaData = langustaData else { fatalError() }
            guard let strings = makeLocalizationStrings(from: langustaData) else { fatalError() }

            // Make "language".strings files and return where it is (Bundle)
            guard let bundle = updateLocalizationFileAndGetHisBundle(with: strings) else { fatalError() }

            // Use this bundle with NSLocalized

        }
    }

    // TODO: Error - use backup bundle

    }

    private func getLangustaData(from data: Data?, completion: ((LangustaData?) -> Void)) {
        guard let data = data else {
            return
        }
        let langustaData = try? JSONDecoder().decode(LangustaData.self, from: data)
        completion(langustaData)
    }

    // MARK: Creating localization files

    private func makeLocalizationStrings(from data: LangustaData) -> [String]? {
        var localizationStrings: [String] = []

        // TODO: remove only czech language, make it generic
        for language in data.languages where language.name == "cs" {
            var commonPlatformContent = language.commonContent
            commonPlatformContent.update(with: language.iosContent)

            /// Create rows in correct format
            let commonContent = commonPlatformContent.compactMap { key, value in
                "\"\(key)\" = \"\(value)\";\n"
            }
            localizationStrings += commonContent

            return localizationStrings
        }
        return nil
    }

    // Creates localization file with given strings in documents directory and returns Bundle in which we can find it
    // Path: Documents/*bundlePath*/*language*.lproj/*language*.strings
    // http://alejandromp.com/blog/2017/6/24/loading-translations-dynamically-generating-localized-string-runtime/
    private func updateLocalizationFileAndGetHisBundle(with content: [String]) -> Bundle? {
        do {
            if fileManager.fileExists(atPath: bundlePath.path) == false {
                try fileManager.createDirectory(at: bundlePath, withIntermediateDirectories: true, attributes: nil)
            }
            // TODO: Make it generic
            let langPath = bundlePath.appendingPathComponent("cs.lproj", isDirectory: true)
            if fileManager.fileExists(atPath: langPath.path) == false {
                try fileManager.createDirectory(at: langPath, withIntermediateDirectories: true, attributes: nil)
            }
            // TODO: Make it generic
            let filePath = langPath.appendingPathComponent("cs.strings")

            let data = content.joined().data(using: .utf32)
            fileManager.createFile(atPath: filePath.path, contents: data, attributes: nil)

            guard let bundle = Bundle(url: bundlePath) else {
                fatalError()//LangustaError.bundleError
            }
            return bundle
        } catch {
           print("\(error)")
            return nil
        }
    }

    /// In case of an error while fetching and creating new localization file.
    /// Checks if there is previously saved file. If true - returns it, otherwise return main bundle where is default file
    func loadBackupBundle() -> Bundle {
        let langPath = bundlePath.appendingPathComponent("cs.lproj", isDirectory: true)
        let filePath = langPath.appendingPathComponent("cs.strings")

        if fileManager.fileExists(atPath: filePath.path), let bundle = Bundle(url: bundlePath) {
            return bundle
        } else {
            return Bundle.main
        }
    }
}

extension Dictionary {

    mutating func update(with otherDictionary: Dictionary) {
        for (key, value) in otherDictionary {
            self.updateValue(value, forKey: key)
        }
    }
}
