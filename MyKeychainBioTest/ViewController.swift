//
//  ViewController.swift
//  MyKeychainBioTest
//
//  Created by sungbin on 2020/03/11.
//  Copyright © 2020 coinplug.dave. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //암복호화 클래스변수
    var privateKey : SecKey!
    var cipherText : CFData!
    //바이오인증 인스턴스
    let bio = MyBioAuthentication.shared
    
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
            var isBio = false
            isBio = UserDefaults.standard.value(forKey: "isBio") as! Bool
            if isBio {
                var bioSuccess : Bool! = false
                let semaphore = DispatchSemaphore(value: 0)
                bio.myBio { (result,error) in
                    bioSuccess = result
                    let errorText = error ?? "Decrypt: 바이오 인증 성공 확인"
                    print(errorText)
                    semaphore.signal()
                }
                semaphore.wait()
                if bioSuccess {
                    let result = try MySecureEnclave.shared.decrypt(privateKey: self.privateKey, cipherText: cipherText)
                    textOutput.text = String(decoding: result as Data, as: UTF8.self)
                }
            } else {
                let result = try MySecureEnclave.shared.decrypt(privateKey: self.privateKey, cipherText: cipherText)
                textOutput.text = String(decoding: result as Data, as: UTF8.self)
            }
            
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

