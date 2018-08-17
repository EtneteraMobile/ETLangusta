//
//  ViewController.swift
//  ETLangustaExample
//
//  Created by Petr Urban on 17/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import UIKit
import ETLangusta

class ViewController: UIViewController {

    let localizedLabel = UILabel()
    let localizedLabel2 = UILabel()
    let localizedLabel3 = UILabel()

    override func loadView() {
        super.loadView()

        setupViews()

        let url = URL(string: "https://api.myjson.com/bins/npnl0")
        let dataProvider = DataProvider(backupFile: "dummy", url: url!) // swiftlint:disable:this force_unwrapping
        let config = Langusta.Config(defaultLanguage: "cs", dataProvider: dataProvider)
        let langusta = Langusta(config: config)

        localizedLabel.text = langusta.loca(for: "k1")
        localizedLabel2.text = "loca2"
        localizedLabel3.text = langusta.loca(for: "k3")
    }

    private func setupViews() {
        view.addSubview(localizedLabel)
        localizedLabel.translatesAutoresizingMaskIntoConstraints = false
        localizedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        localizedLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        localizedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true

        view.addSubview(localizedLabel2)
        localizedLabel2.translatesAutoresizingMaskIntoConstraints = false
        localizedLabel2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        localizedLabel2.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        localizedLabel2.topAnchor.constraint(equalTo: localizedLabel.bottomAnchor, constant: 24).isActive = true

        view.addSubview(localizedLabel3)
        localizedLabel3.translatesAutoresizingMaskIntoConstraints = false
        localizedLabel3.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        localizedLabel3.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        localizedLabel3.topAnchor.constraint(equalTo: localizedLabel2.bottomAnchor, constant: 24).isActive = true
    }
}
