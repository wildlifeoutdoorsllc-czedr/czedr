//
//  CzedrAesGcmBridge.swift
//  Czedr — AES-256-GCM via CryptoKit (matches server wire format)
//

import Foundation
import CryptoKit

@objc public final class CzedrAesGcmBridge: NSObject {
    @objc(encryptPlain:key:iv:tag:error:)
    public static func encrypt(
        plain: Data,
        key: Data,
        iv: Data,
        tag: UnsafeMutablePointer<UInt8>,
        outError: NSErrorPointer
    ) -> Data? {
        guard key.count == 32, iv.count == 12 else {
            outError?.pointee = NSError(
                domain: "CzedrAesGcmBridge",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid key or IV length"]
            )
            return nil
        }
        do {
            let symKey = SymmetricKey(data: key)
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealed = try AES.GCM.seal(plain, using: symKey, nonce: nonce)
            let tagData = sealed.tag
            tagData.withUnsafeBytes { buf in
                guard let src = buf.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                tag.assign(from: src, count: 16)
            }
            return Data(sealed.ciphertext)
        } catch let err as NSError {
            outError?.pointee = err
            return nil
        } catch let err {
            outError?.pointee = NSError(
                domain: "CzedrAesGcmBridge",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: err.localizedDescription]
            )
            return nil
        }
    }
}
