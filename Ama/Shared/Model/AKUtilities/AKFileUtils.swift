import Foundation

enum FileIOError: Error {
    case notSerializableObject(String)
    case fileCreationError(String)
    case fileWriteError(String)
}

class AKFileUtils {
    static func openFileArchive(
        _ fileName: String,
        location: FileManager.SearchPathDirectory,
        shouldCreate: Bool) throws -> String? {
        let fm: FileManager = FileManager()
        let appSupportDir: URL = try fm.url(for: location,
                                            in: FileManager.SearchPathDomainMask.userDomainMask,
                                            appropriateFor: nil,
                                            create: true
        )
        
        if fm.fileExists(atPath: appSupportDir.appendingPathComponent(fileName).path) {
            return appSupportDir.appendingPathComponent(fileName).path
        }
        else {
            if shouldCreate {
                NSLog("=> FILE *%@* DOES NOT EXISTS! CREATING...", fileName)
                guard fm.createFile(atPath: appSupportDir.appendingPathComponent(fileName).path, contents: nil, attributes: nil) else {
                    throw FileIOError.fileCreationError("File cannot be created.")
                }
                
                return appSupportDir.appendingPathComponent(fileName).path
            }
            else {
                throw FileIOError.fileCreationError("No file to open.")
            }
        }
    }
    
    static func write(_ fileName: String, newData: AnyObject) throws {
        let fileName = String(format: "%@.%@.%@", fileName, Func.AKAppVersion(), Func.AKAppBuild())
        
        guard newData is NSCoding else { throw FileIOError.notSerializableObject("Object not serializable.") }
        
        do {
            NSLog("=> WRITING DATA...")
            
            let path = try AKFileUtils.openFileArchive(fileName, location: FileManager.SearchPathDirectory.applicationSupportDirectory, shouldCreate: true)
            guard NSKeyedArchiver.archiveRootObject(newData, toFile: path!) else {
                throw FileIOError.fileWriteError("Error writing data to file.")
            }
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
    }
    
    static func read(_ fileName: String) throws -> AKMasterFile {
        let fileName = String(format: "%@.%@.%@", fileName, Func.AKAppVersion(), Func.AKAppBuild())
        
        do {
            NSLog("=> READING DATA...")
            
            let path = try AKFileUtils.openFileArchive(fileName, location: FileManager.SearchPathDirectory.applicationSupportDirectory, shouldCreate: false)
            if let object = NSKeyedUnarchiver.unarchiveObject(withFile: path!) {
                return object as! AKMasterFile
            }
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
        
        return AKMasterFile()
    }
}

extension AKStreamReader : Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}

class AKStreamReader {
    let encoding : String.Encoding
    let chunkSize : Int
    var fileHandle : FileHandle!
    let delimData : Data
    var buffer : Data
    var atEof : Bool
    
    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) {
        guard let fileHandle = FileHandle(forReadingAtPath: path), let delimData = delimiter.data(using: encoding) else {
            return nil
        }
        
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }
    
    deinit {
        self.close()
    }
    
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        while !atEof {
            if let range = buffer.range(of: delimData) {
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                buffer.removeSubrange(0..<range.upperBound)
                
                return line
            }
            
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            }
            else {
                atEof = true
                if buffer.count > 0 {
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    
                    return line
                }
            }
        }
        
        return nil
    }
    
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }
    
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}
