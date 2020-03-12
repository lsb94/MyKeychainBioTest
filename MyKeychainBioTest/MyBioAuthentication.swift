//
//  MyBioAuthentication.swift
//  MyKeychainBioTest
//
//  Created by sungbin on 2020/03/12.
//  Copyright © 2020 coinplug.dave. All rights reserved.
//

import Foundation
import LocalAuthentication
import UIKit



typealias bioResult = (Bool, String?) -> Void

@available(iOS 11.0, *)
class MyBioAuthentication {
    let authContext = LAContext()
    
    init() {
    }
    
    static let shared = MyBioAuthentication()
    
    func myBio(onCompletion: @escaping(bioResult)) {
        var error : NSError?
        var description : String?
        
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch authContext.biometryType {
            case .faceID:
                description = "계정 정보를 열람하기 위해서 Face ID로 인증 합니다."
                break
            case .touchID:
                description = "계정 정보를 열람하기 위해서 Touch ID로 인증 사용합니다."
                break
            case .none:
                description = "이부분이 어디서 걸릴까."
                break
            @unknown default:
                print("********** BIO SWITCH: UNKNWON ERROR **********")
                onCompletion(false,"Unknwon Error")
                return
            }
            guard let desc = description else {
                print("********** BIO : Description is Nil **********")
                onCompletion(false,nil)
                return
            }
            authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: desc) { (success, error) in
                if success {
                    print("인증결과: 바이오 인증 성공")
                    onCompletion(true, nil)
                } else {
                    print("인증결과: 바이오 인증 실패")
                    if let error = error {
                        print("인증결과: \(error.localizedDescription)")
                    }
                    onCompletion(false, error?.localizedDescription)
                }
            }
        } else {
            // Touch ID・Face ID를 사용할 수없는 경우
            let errorDescription = error?.userInfo["NSLocalizedDescription"] ?? ""
            print(errorDescription)
            description = "계정 정보를 열람하기 위해서는 로그인하십시오."
            
            let alertController = UIAlertController(title: "Authentication Required", message: description, preferredStyle: .alert)
            weak var textPassword: UITextField!
            alertController.addTextField(configurationHandler: { textField in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
                textPassword = textField
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Login", style: .destructive, handler: { action in
                if textPassword.text == "coinplug" {
                    print("패스워드 인증 성공")
                    onCompletion(true, nil)
                } else {
                    print("패스워드 인증 실패")
//                    onCompletion(false, "패스워드가 틀립니다")
                }
            }))
            guard var topViewController =  UIApplication.shared.keyWindow?.rootViewController else {
                print("topview : nil")
                return
            }
            while topViewController.presentedViewController != nil {
                topViewController = topViewController.presentedViewController!
            }
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
