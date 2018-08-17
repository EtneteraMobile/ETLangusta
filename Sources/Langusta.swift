//
//  Langusta.swift
//  Etnetera a.s.
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s.. All rights reserved.
//

import Foundation

protocol LangustaType {
    func update()
//    func change(_ language: Language)
    func loca(for key: String) -> String
}

public class Langusta {

    public typealias LanguageCode = String

    public class Config {
        var platform: Platform = .iOS // require
        var supportedLaguages: [LanguageCode]
        var defaultLanguage: LanguageCode
        var dataProvider: DataProviderType

        public init(platform: Platform = .iOS, supportedLaguages: [LanguageCode], defaultLanguage: String, dataProvider: DataProviderType) {
            self.platform = platform
            self.supportedLaguages = supportedLaguages
            guard supportedLaguages.contains(defaultLanguage) else {
                preconditionFailure("default language is not in supported languages")
            }
            self.defaultLanguage = defaultLanguage
            self.dataProvider = dataProvider
        }

        public enum Platform: String {
            case universal = "_"
            case iOS = "ios"
            case android = "an"
        }
    }

    public static func getLanguageCodes(for languages: [Language]) -> [LanguageCode] {
        return languages.map {
            $0.rawValue
        }
    }

    // MARK: Public

    public enum Language: String {
        case en
        case cs
        case sk
        // TODO: more
    }

    // MARK: Private

    private var localizations: [String: [String: String] ]!
    private var config: Config

    // MARK: - Initialization

   public init(config: Config) {
    self.config = config
        setupWith(config: config)
    }

   private func setupWith(config: Config) {
        // LOCAL DATA
        let localData = config.dataProvider.getLocalData()

        guard let localLangustaData = getLangustaData(from: localData) else {
            preconditionFailure("Can't get langustaData from local data")
        }

        let userDefaults = UserDefaults.standard // TODO: custom UD
        if let localSavedVersion = userDefaults.string(forKey: "langusta-data-version"), localSavedVersion > localLangustaData.version {

            // Nepřepisuj verzi, načti localizations
            // do nothing
            // TODO: nacist do localizations z filu? ()
        } else {

            // Vytvoř localizations
            // Přenačíst lokální data
            userDefaults.set(localLangustaData.version, forKey: "langusta-data-version")
            localizations = localLangustaData.localizations
            // TODO: ulozit localizations do filu
        }

        // REMOTE DATA
        config.dataProvider.loadData { [weak self] (remoteData) in
            guard let wSelf = self else { return }
             print("✅ Remote data loaded")

            // JSON

            if let remoteLangustaData = wSelf.getLangustaData(from: remoteData), remoteLangustaData.version > localLangustaData.version {
                wSelf.localizations = remoteLangustaData.localizations
            }
        }

    }

    // MARK: - Public

    public func loca(for key: String) -> String {
        guard let language = localizations[config.defaultLanguage] else {
            preconditionFailure("Language does not exist")
        }

        guard let value = language[key] else {
            preconditionFailure("Value does not exist for given key")
        }
        return value
    }

    private func getLangustaData(from data: Data?) -> LangustaData? {
        guard let data = data else {
            return nil
        }
        let langustaData = try? JSONDecoder().decode(LangustaData.self, from: data)
        return langustaData
    }

    // MARK: - Private

    // MARK: Creating localization files

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

    private let fileManager = FileManager.default
    private let bundleName = Bundle.main.bundleIdentifier! //swiftlint:disable:this force_unwrapping
    private lazy var bundlePath: URL = {
        let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!) //swiftlint:disable:this force_unwrapping
        print("\n [Document's directory:] \(documents.absoluteString)\n")

        let bundlePath = documents.appendingPathComponent(bundleName, isDirectory: true)
        return bundlePath
    }()

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
