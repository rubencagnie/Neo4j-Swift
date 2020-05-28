import Foundation
#if os(Linux)
import NIOSSL
#endif

public class UnsecureCertificateValidator: CertificateValidatorProtocol {

    public init(hostname: String, port: UInt) {
        self.hostname = hostname
        self.port = port

        self.trustedCertificates = []
    }

    public let hostname: String

    public let port: UInt

    #if os(Linux)
    public let trustedCertificates: [NIOSSLCertificateSource]
    #else
    public let trustedCertificates: [SecCertificate]
    #endif

    public func shouldTrustCertificate(withSHA1: String) -> Bool {
        return true
    }

    public func didTrustCertificate(withSHA1: String) {
    }

}

#if os(Linux)
#else

public class TrustRootOnlyCertificateValidator: CertificateValidatorProtocol {

    public init(hostname: String, port: UInt) {
        self.hostname = hostname
        self.port = port
        self.trustedCertificates = []
    }

    public let hostname: String

    public let port: UInt

    public let trustedCertificates: [SecCertificate]

    public func shouldTrustCertificate(withSHA1: String) -> Bool {
        return false
    }

    public func didTrustCertificate(withSHA1: String) {
    }

}

public class TrustSpecificOrRootCertificateValidator: CertificateValidatorProtocol {

    public init(hostname: String, port: UInt, trustedCertificate: SecCertificate) {
        self.hostname = hostname
        self.port = port
        self.trustedCertificates = [trustedCertificate]
    }

    public init(hostname: String, port: UInt, trustedCertificates: [SecCertificate]) {
        self.hostname = hostname
        self.port = port
        self.trustedCertificates = trustedCertificates
    }

    public init(hostname: String, port: UInt, trustedCertificateAtPath path: String) {
        self.hostname = hostname
        self.port = port

        let data: Data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let cert = SecCertificateCreateWithData(nil, data as CFData)
        if let cert = cert {
            self.trustedCertificates = [cert]
        } else {
            print("Bolt: Path '\(path)' did not contain a valid certificate, continuing without")
            self.trustedCertificates = []
        }
    }

    public let hostname: String

    public let port: UInt

    public let trustedCertificates: [SecCertificate]

    public func shouldTrustCertificate(withSHA1: String) -> Bool {
        return false
    }

    public func didTrustCertificate(withSHA1: String) {
    }
}

public class StoreCertSignaturesInFileCertificateValidator: CertificateValidatorProtocol {

    public init(hostname: String, port: UInt, filePath path: String) {
        self.hostname = hostname
        self.port = port
        self.trustedCertificates = []
        self.filePath = path
    }

    lazy var fileManager = FileManager.default

    public let hostname: String

    public let port: UInt

    public let trustedCertificates: [SecCertificate]

    public let filePath: String

    public func shouldTrustCertificate(withSHA1 testSHA1: String) -> Bool {

        let keysForHosts = readKeysForHosts()
        let key = "\(self.hostname):\(self.port)"

        if let trueSHA1 = keysForHosts[key] {
            return trueSHA1 == testSHA1
        }

        trustSHA1(key: key, testSHA1)

        return true
    }

    public func didTrustCertificate(withSHA1 testSHA1: String) {

        let keysForHosts = readKeysForHosts()
        let key = "\(self.hostname):\(self.port)"

        if keysForHosts[key] != nil {
            return
        }

        trustSHA1(key: key, testSHA1)
    }

    private func readKeysForHosts() -> [String: String] {
        var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        var keysForHosts: [String: String] = [:] //Our data
        if let plistXML = FileManager.default.contents(atPath: self.filePath) {
            do {//convert the data to a dictionary and handle errors.
                keysForHosts = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListForamt) as? [String: String] ?? [:]

            } catch {
                print("Error reading plist: \(error), format: \(propertyListForamt)")
            }
        }

        return keysForHosts
    }

    private func trustSHA1(key: String, _ SHA1: String) {
        var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.

        var keysForHosts: [String: String] = self.readKeysForHosts()

        if fileManager.fileExists(atPath: self.filePath) {
            let plistXML = fileManager.contents(atPath: self.filePath)!
            do {//convert the data to a dictionary and handle errors.
                keysForHosts = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListForamt) as! [String: String]

            } catch {
                print("Error reading plist: \(error), format: \(propertyListForamt)")
            }
        }

        keysForHosts[key] = SHA1
        if let data = try? PropertyListSerialization.data(fromPropertyList: keysForHosts, format: propertyListForamt, options: 0) {
            let url = URL(fileURLWithPath: self.filePath)
            try? data.write(to: url)
        }
    }

}
#endif
