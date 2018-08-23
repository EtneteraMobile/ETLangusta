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

    var langusta: Langusta?

    let localizedLabel = UILabel()
    let localizedLabel2 = UILabel()
    let localizedLabel3 = UILabel()
    let button = UIButton()

    override func loadView() {
        super.loadView()

        setupViews()

        let dataProvider = DataProvider(backupFile: "dummy", url: URL(string: "https://raw.githubusercontent.com/EtneteraMobile/ETLangusta/feature/InitialConfig/ETLangustaExample/remote.json")!) // swiftlint:disable:this force_unwrapping
        let config = Langusta.Config(supportedLaguages: [.cs, .en, .custom(code: "esperanto")], defaultLanguage: .cs, dataProvider: dataProvider)
        langusta = Langusta(config: config)
        langusta?.fetch()

        langusta?.onUpdate.observe(on: self) { [unowned self] in
            self.updateLocalizations()
        }

        langusta?.onUpdate.trigger()
    }

    private func updateLocalizations() {
        localizedLabel.text = langusta?.loca(for: "k1", with: ["Pivo", "Rum"])
        localizedLabel2.text = langusta?.loca(for: "k2")
        localizedLabel3.text = langusta?.loca(for: "k3")
        button.setTitle("Change language", for: .normal)
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

        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.topAnchor.constraint(equalTo: localizedLabel3.bottomAnchor, constant: 20).isActive = true

        button.backgroundColor = .gray
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.black, for: .highlighted)
        button.layer.cornerRadius = 25

        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)
    }

    @objc private func onButtonTap() {
        let optionMenu = UIAlertController(title: nil, message: "Choose Language", preferredStyle: .actionSheet)
        let cs = UIAlertAction(title: "Cesky", style: .default) { [unowned self] _ in
            self.langusta?.change(.cs)
        }
        let sk = UIAlertAction(title: "English", style: .default) { [unowned self] _ in
            self.langusta?.change(.en)
        }
        let pl = UIAlertAction(title: "Esperanto", style: .default) { [unowned self] _ in
            self.langusta?.change(.custom(code: "esperanto"))
        }
        let esperanto = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancelled")
        }

        optionMenu.addAction(cs)
        optionMenu.addAction(sk)
        optionMenu.addAction(pl)
        optionMenu.addAction(esperanto)

        self.present(optionMenu, animated: true, completion: nil)
    }
}
