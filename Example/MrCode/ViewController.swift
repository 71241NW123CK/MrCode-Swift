//
//  ViewController.swift
//  MrCode
//
//  Created by Ryan Hiroaki Tsukamoto on 01/08/2018.
//  Copyright (c) 2018 Ryan Hiroaki Tsukamoto. All rights reserved.
//

import UIKit
import MrCode

class ViewController: UIViewController {
    @IBOutlet weak var mrCodeScanner: MrCodeScanner!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let plugin = MrCodeScanner.Plugin(
            supportedFormats: .all,
            predicate: nil,
            mrCodeFoundCompletion: { mrCode in
                self.label.text = "\(mrCode.format): \(mrCode.value)"
                self.label.isHidden = false
            },
            mrCodeLostCompletion: {
                self.label.isHidden = true
            }
        )
        mrCodeScanner.pluginChain.append(plugin)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mrCodeScanner.viewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        mrCodeScanner.viewWillDisappear()
        super.viewWillDisappear(animated)
    }
}
