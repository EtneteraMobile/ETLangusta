//
//  Langusta.swift
//  Etnetera a.s.
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s.. All rights reserved.
//

import Foundation

protocol LangustaType {
    func fetch()
    func change(_ language: Langusta.Language)
    func loca(for key: String) -> String
    var onUpdate: (() -> Void)? { get set }
}

public class Langusta: LangustaType {

    public typealias Localizations = [String: [String: String]]
    public typealias LanguageCode = String

    public func change(_ language: Language) {
        config.defaultLanguage = language
        onUpdate?()
    }
    
    public var onUpdate: (() -> Void)? // TODO: future event (ETBinding)

    public class Config {
        var platform: Platform = .iOS // require
        var supportedLaguages: [Language]
        var defaultLanguage: Language
        var dataProvider: DataProviderType
        var fetchOnInit: Bool

        public init(platform: Platform = .iOS, supportedLaguages: [Language], defaultLanguage: Language, dataProvider: DataProviderType, fetchOnInit: Bool = false) {
            self.platform = platform
            self.supportedLaguages = supportedLaguages
            guard Langusta.getLanguageCodes(for: supportedLaguages).contains(defaultLanguage.code) else {
                preconditionFailure("default language is not in supported languages")
            }
            self.defaultLanguage = defaultLanguage
            self.dataProvider = dataProvider
            self.fetchOnInit = fetchOnInit
        }

        public enum Platform: String {
            case universal = "_"
            case iOS = "ios"
            case android = "an"
        }
    }

    public static func getLanguageCodes(for languages: [Language]) -> [LanguageCode] {
        return languages.map {
            $0.code
        }
    }

    // MARK: Public

    public enum Language {
        // TODO: add languages 
        case en
        case cs
        case sk
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
            }
        }
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

        setupLocalizations()
        if config.fetchOnInit {
            fetch()
        }
    }

    private func setupLocalizations() {
        let localData = config.dataProvider.getLocalData()

        guard let localLangustaData = decodeLangustaData(from: localData) else {
            preconditionFailure("Can't get langustaData from local data")
        }

        config.supportedLaguages.forEach { (language) in
            guard localLangustaData.localizations[language.code] != nil else {
                preconditionFailure("Supported language: \(language) not found in backup .json")
            }
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
    }

    public func fetch() {
        config.dataProvider.loadData { [weak self] (remoteData) in
            guard let wSelf = self else {
                return
            }

            if let remoteLangustaData = wSelf.decodeLangustaData(from: remoteData) {

                // If version of remote data is greater than local data, save it
                if let localSavedVersion = wSelf.loadLocalVersion(), remoteLangustaData.version > localSavedVersion {
                    wSelf.save(remoteLangustaData)
                    wSelf.localizations = remoteLangustaData.localizations
                }
            } else {
                // Do nothing
                // Use local data
            }

            DispatchQueue.main.async {
                wSelf.onUpdate?() // TODO!!!
            }
        }
    }

    // MARK: - Public

    public func loca(for key: String) -> String {
        guard let language = localizations[config.defaultLanguage.code] else {
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
