//
//  StorageService.swift
//  Finance
//
//  Created by Andrii Zuiok on 15.06.2020.
//  Copyright © 2020 Andrii Zuiok. All rights reserved.
//

import Foundation
import Combine

//MARK: -STORAGE ERROR
enum StorageError: Swift.Error {
        case fileAlreadyExists
        case invalidDirectory
        case writtingFailed
        case fileNotExists
        case readingFailed
        case deletingFiled
        case undefinedError
        
        var errorDescription: String? {
            switch self {
            case .fileAlreadyExists:
                return "File already exists"
            case .invalidDirectory:
                return "Invalid directory"
            case .writtingFailed:
                return "Writing failed"
            case .fileNotExists:
                return "File not exists"
            case .readingFailed:
                return "Reading failed"
            case .deletingFiled:
                return "Deleting error"
            case .undefinedError:
                return "Undefined error"
            }
            
            
        }
    }
    

    
//MARK: - StorageService
enum StorageService {

//MARK: - URL
    
    //MARK: DOCUMENT DIRECTORY URL
    static func makeDocumentDirectoryURL(forFileNamed fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        //debugPrint(url)
        return url.appendingPathComponent(fileName)
    }
    
    //MARK: BANDLE URL (only for presentation)
    static func makeMainBandleURL(forFileNamed fileName: String) -> URL? {
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            return URL(fileURLWithPath: path)
        } else {return nil}
    }
    
    static func makeBandleURL(forJSONNamed fileName: String) -> URL? {
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            return URL(fileURLWithPath: path)
        } else {return nil}
    }
    
    static func makeBandleURL(forXMLNamed fileName: String) -> URL? {
        if let path = Bundle.main.path(forResource: fileName, ofType: "xml") {
            return URL(fileURLWithPath: path)
        } else {return nil}
    }
    
    
//MARK: - STORING TO DISC
    static func storeData<T: Codable>(_ data: T, url: URL) throws {
        //debugPrint("store to \(url)")
        
        do {
            let encoder = JSONEncoder()
            //encoder.dataEncodingStrategy = .deferredToData
            let data = try encoder.encode(data)
            
            do {
                try data.write(to: url)
            } catch {
                //debugPrint(error)
                //throw error
                throw StorageError.writtingFailed

            }
        } catch {
            //debugPrint(error)
            throw error as? EncodingError ?? error
        }
        
    }
    
    
//MARK: - FETCHING FROM DISC

    static func readData<T: Codable>(from url: URL, decodableType: T.Type, completion: @escaping (_ object: T)->()) throws {

        guard FileManager.default.fileExists(atPath: url.path) else {
            //debugPrint("fileExists ERROR!!!")
            //debugPrint(url)
            throw StorageError.fileNotExists
        }
        
        guard let data = try? Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe) else {
            //debugPrint("data ERROR!!!")

            throw StorageError.readingFailed
        }
        
        do {
            let decoded = try JSONDecoder().decode(decodableType, from: data)
            completion(decoded)
        } catch {
            //debugPrint("decoding ERROR!!!")

            throw error as? DecodingError ?? error
        }
    }
    
    static func readXML(url: URL, completion: @escaping (_ rss: [RSSItem])->()) {
        do {
            let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe)
            let parser = XmlRssParser()
            let rssItems = parser.parsedItemsFromData(data)
            completion(rssItems)
        } catch {
            //debugPrint("xml reading ERROR!!!")
        }
    }
    
    static func makeStoreQuery(XML: String, completion: @escaping (_ data: Data)->()) {
        
        if let path = Bundle.main.path(forResource: XML, ofType: "xml") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: Data.ReadingOptions.mappedIfSafe)
                completion(data)
            } catch {
                //debugPrint("xml file ERROR!!!")
            }
        }
    }
    
    
//MARK: - REMOVE FROM DISC

    static func clearAllFiles() {

        //debugPrint("CLEARING")

        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            try fileManager.removeItem(at: myDocuments)
        } catch {
            //debugPrint("CLEARING ERROR")
            return
        }
    }

    static func getSymbolsFiles() -> [String] {

        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            
            let names = directoryContents.map{ $0.deletingPathExtension().lastPathComponent }
            return names

        } catch {
            //debugPrint(error)
            return []
        }
        
    }
    
    static func removeFile(name: String) throws {
        if let filePath = StorageService.makeDocumentDirectoryURL(forFileNamed: name)?.path {
            
            do {
                let fileManager = FileManager.default
                
                guard FileManager.default.fileExists(atPath: filePath) else {
                    throw StorageError.fileNotExists
                }
                
                do {
                    try fileManager.removeItem(atPath: filePath)
                } catch {
                    throw StorageError.deletingFiled
                }
            } catch  {
                throw StorageError.undefinedError
            }
        }
    }
    
    
}
