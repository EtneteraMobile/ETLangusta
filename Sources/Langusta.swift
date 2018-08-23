//
//  Langusta.swift
//  Etnetera a.s.
//
//  Created by Ondřej Korol on 17/08/2018.
//  Copyright © 2018 Etnetera a.s.. All rights reserved.
//

import Foundation

public class Langusta: LangustaType {

    // MARK: Public

    typealias Localizations = [String: [String: String]]
    private typealias LanguageCode = String

    public func change(_ language: Language) {
        config.defaultLanguage = language
        onUpdate.trigger()
    }

    public var onUpdate = Event()
    public var onLocalizationFailure: ((_ message: String) -> Void)?

    public class Config {

        var defaultLanguage: Language

        let platform: Platform
        let supportedLaguages: [Language]
        let dataProvider: DataProviderType
        let fetchOnInit: Bool

        public init(platform: Platform = .iOS, supportedLaguages: [Language], defaultLanguage: Language, dataProvider: DataProviderType, fetchOnInit: Bool = false) {
            let supportedLangCodes = supportedLaguages.map { $0.code }
            guard supportedLangCodes.contains(defaultLanguage.code) else {
                preconditionFailure("default language is not in supported languages")
            }

            self.platform = platform
            self.supportedLaguages = supportedLaguages
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

    private static func getLanguageCodes(for languages: [Language]) -> [LanguageCode] {
        return languages.map {
            $0.code
        }
    }

    // MARK: Private

    private let userDefaults = UserDefaults(suiteName: "LangustaUserDefaults")! // swiftlint:disable:this force_unwrapping
    private let versionKeyUD = "langusta.data.version"
    private let localizationsKeyUD = "langusta.data.localizations"

    private var localizations: Localizations!
    private var config: Config

    private var valuePolicy: ValuePolicy = .exceptionIfMissing

    enum ValuePolicy {
        case noException
        case exceptionIfMissing
    }

    // MARK: - Initialization

    public init(config: Config) {
        self.config = config

        setupLocalizations()
        if config.fetchOnInit {
            fetch()
        }
    }

    // MARK: - Methods

    // MARK: Public

    public func loca(for key: String) -> String {
        return localize(key)
    }

    public func loca(for key: String, with argument: String) -> String {
        return String(format: localize(key), argument)
    }

    public func loca(for key: String, with arguments: [String]) -> String {
        return String(format: localize(key), arguments: arguments)
    }

    // MARK: Private

    private func localize(_ key: String) -> String {
        guard let language = localizations[config.defaultLanguage.code] else {
            let error = LangustaError.languageNotFound(config.defaultLanguage.code)
            if valuePolicy == .exceptionIfMissing {
                preconditionFailure(error.localizedDescription)
            } else {
                onLocalizationFailure?(error.localizedDescription)
                return "*\(key)*"
            }
        }

        guard let value = language[key] else {
            let error = LangustaError.keyNotFound(key, config.defaultLanguage.code)
            if valuePolicy == .exceptionIfMissing {
                preconditionFailure(error.localizedDescription)
            } else {
                onLocalizationFailure?(error.localizedDescription)
                return "*\(key)*"
            }
        }

        return value
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
                    wSelf.localizations = wSelf.localizations.merging(remoteLangustaData.localizations, uniquingKeysWith: { (_, last) in last })
                }
            } else {
                // Do nothing
                // Use local data
            }

            DispatchQueue.main.async {
                wSelf.onUpdate.trigger()
            }
        }
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
