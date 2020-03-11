//
//  MyBioAuth.swift
//  MyKeychainBioTest
//
//  Created by sungbin on 2020/03/12.
//  Copyright © 2020 coinplug.dave. All rights reserved.
//

import Foundation
// 키 태그
let tag = "com.dave.web3Wallet.mySecKey".data(using: .utf8)!
//암복호 알고리즘 EC 256비트
let cryptoAlgo: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM


class MySecureEnclave {
    init (){}
    static var shared = MySecureEnclave()
    
    /**개인키 생성 및 저장 함수
     */
    func createSecKey() throws {
        print("개인키 생성 및 저장 시작...")
        var error: Unmanaged<CFError>?
        
        //액세스 컨트롤러
        let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                     kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                     [.userPresence, .privateKeyUsage],
                                                     nil)!
        
        //개인키 생성
        let attributes : [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC ,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access ] ]
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        let key = privateKey
        
        //키체인 특정 태그의 키 모두삭제 (키 중복 등록 방지)
        let deletequery: [String: Any] = [ kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: tag]
        SecItemDelete(deletequery as CFDictionary)
        
        //키체인 특정 태그에 개인키 등록
        let addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecValueRef as String: key]
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { throw  SecureKeyError.keyStore }
        print("개인키 생성 및 저장 완료")
    }
    
    /**개인키 로드하여
     개인키를 반환
     */
    func loadSecKey() throws -> SecKey{
        
        let getquery : [String: Any] = [kSecClass as String: kSecClassKey,
                                        kSecAttrApplicationTag as String: tag,
                                        kSecReturnRef as String: true ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else { throw SecureKeyError.keyLoad }
        let privateKey = item as! SecKey
        
        print("개인키 불러오기 완료")
        return privateKey
    }
    
    /**비밀키와 평문을 받아
     암호화 하여
     암호문을 유저디폴트에 저장
     */
    func encrypt(privateKey: SecKey, target: Data) throws {
        print("암호화 시작...")
        //공개키 추출
        guard let publickey = SecKeyCopyPublicKey(privateKey) else{throw SecureKeyError.publicKeyDeriveError}
        
        //공개키와 암호화알고리즘 간 호환성 검사
        guard SecKeyIsAlgorithmSupported(publickey, .encrypt, cryptoAlgo) else { throw SecureKeyError.encryptionCompatibility}
        
        //평문 생성
//        guard let plainText = "this is message".data(using: .utf8) else {
//            throw SecureKeyError.encryption
//        }
        let plainText = target
        print("\(String(decoding: plainText, as: UTF8.self)) << target text")

        //암호문 생성 및 유저디폴트에 저장
        var error: Unmanaged<CFError>?
        guard let cipherText = SecKeyCreateEncryptedData(publickey, cryptoAlgo, plainText as CFData, &error) else {
            throw error!.takeRetainedValue() as Error }
        UserDefaults.standard.set(cipherText, forKey: "testing.cipher")
        print("암호화 완료")
    }
    
    /**비밀키를 받아
     복호화를 하여
     평문을 반환
     */
    func decrypt(privateKey: SecKey) throws -> CFData {
        //개인키와 복호화알고리즘 간 호환성 검사
        print ("복호화 시작...")
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, cryptoAlgo) else { throw SecureKeyError.encryptionCompatibility}
        
        let loaded = UserDefaults.standard.value(forKey: "testing.cipher") as! CFData
        
        var error: Unmanaged<CFError>?
        guard let plainText = SecKeyCreateDecryptedData(privateKey, cryptoAlgo, loaded, &error) else{
            throw error!.takeRetainedValue() as Error }
        
        print ("복호화 완료")
        return plainText
    }
    
    enum SecureKeyError: Error {
        case keyStore
        case keyLoad
        case publicKeyDeriveError
        case encryptionCompatibility
        case encryptionSize
        case encryption
        case decryptionCompatibility
        case decryptionSize
        case decryption
    }
}
