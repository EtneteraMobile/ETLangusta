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

typealias Localizations = [String: [String: String]]

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

    private let userDefaults = UserDefaults(suiteName: "LangustaUserDefaults")! // swiftlint:disable:this force_unwrapping
    private let versionKeyUD = "langusta.data.version"
    private let localizationsKeyUD = "langusta.data.localizations"

    private var localizations: Localizations!
    private var config: Config

    // MARK: - Initialization

    public init(config: Config) {
        self.config = config
        setupWith(config: config)
    }

    private func setupWith(config: Config) {
        // LOCAL DATA
        let localData = config.dataProvider.getLocalData()

        guard let localLangustaData = decodeLangustaData(from: localData) else {
            preconditionFailure("Can't get langustaData from local data")
        }

        // Already saved version is greater than version of local data
        if let localSavedVersion = loadLocalVersion(), localSavedVersion > localLangustaData.version {
            if let savedLocalizations = loadLocalSavedLocalizations() {
                localizations = savedLocalizations
            }

        // There isn't saved version yet or version is smaller than version of local data
        } else {
            // Save localizations and version from local data
            save(localLangustaData)
            localizations = localLangustaData.localizations
        }

        // REMOTE DATA
        config.dataProvider.loadData { [weak self] (remoteData) in
            guard let wSelf = self else { return }
            print("✅ Remote data loaded")
            // If version of remote data is greater than local data, save it
            if let remoteLangustaData = wSelf.decodeLangustaData(from: remoteData), remoteLangustaData.version > localLangustaData.version {
                wSelf.save(remoteLangustaData)
                wSelf.localizations = remoteLangustaData.localizations
            } else {
                // Do nothing
                // Use local data
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

    // MARK: - Private

    private func loadLocalVersion() -> String? {
        return userDefaults.string(forKey: versionKeyUD)
    }

    private func loadLocalSavedLocalizations() -> Localizations? {
        return userDefaults.object(forKey: localizationsKeyUD) as? Localizations
    }

    private func save(_ langustaData: LangustaData) {
        userDefaults.set(langustaData.version, forKey: versionKeyUD)
        userDefaults.set(langustaData.localizations, forKey: localizationsKeyUD)
    }

    private func decodeLangustaData(from data: Data?) -> LangustaData? {
        guard let data = data else {
            return nil
        }
        let langustaData = try? JSONDecoder().decode(LangustaData.self, from: data)
        return langustaData
    }
}
