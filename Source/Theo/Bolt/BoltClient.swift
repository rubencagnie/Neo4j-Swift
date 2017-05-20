import Foundation
import PackStream
import Bolt

#if os(Linux)
import Dispatch
#endif
    
public struct QueryWithParameters {
    let query: String
    let parameters: Dictionary<String,Any>
}

public class Transaction {
    
    var succeed: Bool
    
    public init() {
        succeed = true
    }
    
    public func markAsFailed() {
        succeed = false
    }
}

typealias BoltRequest = Bolt.Request

open class BoltClient {
    
    private let hostname: String
    private let port: Int
    private let username: String
    private let password: String
    private let encrypted: Bool
    private let connection: Connection
    
    private var currentTransaction: Transaction?
    
    required public init(hostname: String = "localhost", port: Int = 7687, username: String = "neo4j", password: String = "neo4j", encrypted: Bool = true) throws {

        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.encrypted = encrypted
        
        let settings = ConnectionSettings(username: username, password: password, userAgent: "Theo 3.1a1")
        
        let generator = SSLKeyGeneratorConfig(
            signingRequestFileName: "csr.csr",
            countryName: "DK",
            stateOrProvinceName: "Esbjerg",
            localityName: "",
            organizationName: "Theo",
            orgUnitName: "",
            commonName: "",
            emailAddress: "",
            companyName: "")
        
        let sslConfig = SSLConfiguration(
            temporarySSLKeyPath: "/tmp/boltTestKeys",
            certificatePKCS12FileName: "cert.pfx",
            certificatePKCS12Password: "1234",
            keyFileName: "key.pem",
            certificatePEMFilename: "cert.pem",
            generator: generator)
        
        let configuration = EncryptedSocket.defaultConfiguration(
            sslConfig: sslConfig,
            allowHostToBeSelfSigned: true)
        
        let socket = try EncryptedSocket(
            hostname: hostname,
            port: port,
            configuration: configuration)
        
        self.connection = Connection(
            socket: socket,
            settings: settings)
    }
    
    public func connect(completionBlock: ((Bool) -> ())? = nil) throws {
        
        if let completionBlock = completionBlock {
            try self.connection.connect { (success) in
                completionBlock(success)
            }
        }
        
        else {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            try self.connection.connect { (success) in
                dispatchGroup.leave()
            }
            dispatchGroup.wait()
        }

    }
    
    
    private func pullSynchronouslyAndIgnore() throws {
        let dispatchGroup = DispatchGroup()
        let pullRequest = BoltRequest.pullAll()
        dispatchGroup.enter()
        try self.connection.request(pullRequest) { (success, response) in
            
            dispatchGroup.leave()
        }
        dispatchGroup.wait()

    }

    public func pullAll(completionBlock: (Bool, [Response]) -> ()) throws {
        let pullRequest = BoltRequest.pullAll()
        try self.connection.request(pullRequest) { (success, response) in
            completionBlock(success, response)
        }
        
    }

    public func executeAsTransaction(bookmark: String? = nil, transactionBlock: @escaping (_ tx: Transaction) throws -> ()) throws {
        
        let transaction = Transaction()
        currentTransaction = transaction
        
        let beginRequest = BoltRequest.run(statement: "BEGIN", parameters: Map(dictionary: [:]))
        
        let transactionGroup = DispatchGroup()
        transactionGroup.enter()
        
        try connection.request(beginRequest) { (success, response) in
            if success {
                
                try pullSynchronouslyAndIgnore()

                try transactionBlock(transaction)
                if transaction.succeed {
                    let commitRequest = BoltRequest.run(statement: "COMMIT", parameters: Map(dictionary: [:]))
                    try connection.request(commitRequest) { (success, response) in
                        try pullSynchronouslyAndIgnore()
                        if !success {
                            print("Error committing transaction: \(response)")
                        }
                        self.currentTransaction = nil
                        transactionGroup.leave()
                    }
                } else {
                    
                    let rollbackRequest = BoltRequest.run(statement: "ROLLBACK", parameters: Map(dictionary: [:]))
                    try connection.request(rollbackRequest) { (success, response) in
                        try pullSynchronouslyAndIgnore()
                        if !success {
                            print("Error rolling back transaction: \(response)")
                        }
                        self.currentTransaction = nil
                        transactionGroup.leave()
                    }
                }
                

            } else {
                print("Error beginning transaction: \(response)")
                transactionGroup.leave()
            }
        }
        
        transactionGroup.wait()
        
        
    }
    
    public func executeTransaction(parameteredQueries: [QueryWithParameters], completionBlock: ClientProtocol.TheoCypherQueryCompletionBlock? = nil) -> Void {
        
    }
    
    public func executeCypher(_ query: String, params: Dictionary<String,PackProtocol>? = nil, completionBlock: ((Bool) -> ())? = nil) throws -> Void {
        
        let cypherRequest = BoltRequest.run(statement: query, parameters: Map(dictionary: params ?? [:]))
        
        if let completionBlock = completionBlock {
            try connection.request(cypherRequest) { (success, response) in
                completionBlock(success)
            }
        }
        
        else { // synchronous request
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            try connection.request(cypherRequest) { (success, response) in
                if success == true {
                    let pullRequest = BoltRequest.pullAll()
                    try self.connection.request(pullRequest) { (success, response) in
                        
                        if let currentTransaction = self.currentTransaction,
                           success == false {
                            currentTransaction.markAsFailed()
                        }
                        
                        dispatchGroup.leave()
                    }
                    
                } else {
                    if let currentTransaction = self.currentTransaction {
                        currentTransaction.markAsFailed()
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.wait()
            
        }
        
        
    }
    
    public func getBookmark() -> String? {
        return connection.currentTransactionBookmark
    }
    
}
