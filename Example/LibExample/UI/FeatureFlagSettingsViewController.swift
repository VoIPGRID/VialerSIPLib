//
//  FeatureFlagSettingsViewController.swift
//  LibExample
//
//  Created by Manuel on 18/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

class FeatureFlagSettingsViewController: MessageViewController {
    private var allFlags: [FeatureFlagModel] = []
    @IBOutlet weak var featureFlagTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        featureFlagTableView.dataSource = self
        featureFlagTableView.delegate = self
        featureFlagTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FlagCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        responseHandler?.handle(msg: .feature(.flag(.useCase(.getAllFlags))))
    }
    
    override func handle(msg: Message) {
        super.handle(msg: msg)
        if case .feature(.flag(.useCase(.allFlags(let flags)))) = msg { allFlags = flags }
    }
}

extension FeatureFlagSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allFlags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlagCell", for: indexPath)
        let flag = allFlags[indexPath.row]
        cell.textLabel?.text = flag.title
        cell.textLabel?.textColor = flag.isActivated ? UIColor.black : UIColor.gray
        return cell
    }
}
