//
//  ViewController.swift
//  MyKeychainBioTest
//
//  Created by sungbin on 2020/03/11.
//  Copyright © 2020 coinplug.dave. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var privateKey : SecKey!
    var cipherText : CFData!
    
    @IBAction func buttonBio(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "isBio")
        UserDefaults.standard.set(true, forKey: "isBio")
    }
    @IBAction func buttonPasscode(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "isBio")
        UserDefaults.standard.set(false, forKey: "isBio")
    }
    @IBAction func buttonKeyGeneration(_ sender: Any) {
        do {
            try MySecureEnclave.shared.createSecKey()
        } catch{print(error)}
    }
    @IBAction func buttonKeyLoad(_ sender: Any) {
        do {
            self.privateKey = try MySecureEnclave.shared.loadSecKey()
        } catch{print(error)}
    }
    @IBAction func buttonEncrypt(_ sender: Any) {
        do {
            guard let text = textInput.text.data(using: .utf8) else {
                print("!! malformatted input !!")
                return
            }
            self.cipherText = try MySecureEnclave.shared.encrypt(privateKey: self.privateKey!, target: text )
            textOutput.text = String(decoding: self.cipherText as Data, as: UTF8.self)
        } catch{print(error)}
    }
    @IBAction func buttonDecrypt(_ sender: Any) {
        do {
            let result = try MySecureEnclave.shared.decrypt(privateKey: self.privateKey, cipherText: cipherText)
            textOutput.text = String(decoding: result as Data, as: UTF8.self)
        } catch{print(error)}
    }
    @IBOutlet weak var textInput: UITextView!
    @IBOutlet weak var textOutput: UITextView!
    
    
    
    
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UserDefaults.standard.set(false, forKey: "isBio")
    }


}

