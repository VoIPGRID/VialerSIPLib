//
//  VSLSetupCodecsViewController.swift
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

import Foundation

class VSLSetupCodecsViewController: UITableViewController {
    
    var selectedCodecs = [String]()
    var avialableCodecs = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        avialableCodecs = (VSLCodecs.codecsArray() as? Array)! as [String];
        selectedCodecs = UserDefaults.standard.stringArray(forKey: "selectedCodecs") ?? [String]()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VSLCodecs.numberOfCodecs();
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "codec", for: indexPath)
        let codec = VSLCodecs.codecString(with: indexPath.row)!
        cell.textLabel?.text = codec
        
        let codecIndex = findCodecInSelectedCodecs(codec)
        if codecIndex > -1 {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let codec = VSLCodecs.codecString(with: indexPath.row)!
        let codecIndex = findCodecInSelectedCodecs(codec)
        let accessoryType = tableView.cellForRow(at: indexPath)?.accessoryType;
        
        if (codecIndex == -1 && accessoryType != .checkmark){
            selectedCodecs.append(codec)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        } else if (codecIndex > -1 && accessoryType == .checkmark) {
            selectedCodecs.remove(at: codecIndex)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        let codec = VSLCodecs.codecString(with: indexPath.row)!
        let codecIndex = findCodecInSelectedCodecs(codec)
        if (codecIndex > -1){
            selectedCodecs.remove(at: codecIndex)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
//        if selectedCodecs.count > 0 {
            UserDefaults.standard.set(selectedCodecs, forKey: "selectedCodecs")
            UserDefaults.standard.synchronize()
//        }
    }
    
    fileprivate func findCodecInSelectedCodecs(_ codecToFind: String) -> Int {
        for (index, codec) in selectedCodecs.enumerated() {
            if (codec == codecToFind) {
                return index
            }
        }
        return -1
    }
    
}
