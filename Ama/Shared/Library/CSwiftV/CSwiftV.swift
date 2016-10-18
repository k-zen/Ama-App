import Foundation

class CSwiftV {
    
    // MARK: Properties
    let columnCount: Int
    let headers: [String]
    let keyedRows: [[String : String]]?
    let rows: [[String]]
    
    init(String string: String, headers:[String]?, separator:String)
    {
        let lines: [String] = includeQuotedStringInFields(
            Fields: string.splitOnNewLine().filter { (includeElement: String) -> Bool in
                return !includeElement.isEmpty;
            },
            quotedString: "\r\n")
        
        var parsedLines = lines.map { (transform: String) -> [String] in
            let commaSanitized = includeQuotedStringInFields(Fields: transform.components(separatedBy: separator), quotedString: separator)
                .map {
                    (input: String) -> String in
                    return sanitizedStringMap(String: input) }
                .map {
                    (input: String) -> String in
                    return input.replacingOccurrences(of: "\"\"", with: "\"", options: String.CompareOptions.literal) }
            
            return commaSanitized;
        }
        
        let tempHeaders : [String]
        
        if let unwrappedHeaders = headers {
            tempHeaders = unwrappedHeaders
        }
        else {
            tempHeaders = parsedLines[0]
            parsedLines.remove(at: 0)
        }
        
        rows = parsedLines
        columnCount = tempHeaders.count
        
        let keysAndRows = rows.map { (field: [String]) -> [String : String] in
            var row = [String : String]()
            
            for (index, value) in field.enumerated() {
                row[tempHeaders[index]] = value
            }
            
            return row
        }
        
        self.keyedRows = keysAndRows
        self.headers = tempHeaders
    }
    
    convenience init(String string: String)
    {
        self.init(String: string, headers: nil, separator: ",")
    }
    
    convenience init(String string: String, separator: String)
    {
        self.init(String: string, headers: nil, separator: separator)
    }
    
    convenience init(String string: String, headers: [String]?)
    {
        self.init(String: string, headers: headers, separator: ",")
    }
}

func includeQuotedStringInFields(Fields fields: [String], quotedString :String) -> [String]
{
    var mergedField = ""
    var newArray = [String]()
    
    for field in fields {
        mergedField += field
        if (mergedField.components(separatedBy: "\"").count%2 != 1) {
            mergedField += quotedString
            continue
        }
        newArray.append(mergedField);
        mergedField = ""
    }
    
    return newArray;
}

func sanitizedStringMap(String string :String) -> String
{
    let startsWithQuote: Bool = string.hasPrefix("\"")
    let endsWithQuote: Bool = string.hasSuffix("\"")
    
    if (startsWithQuote && endsWithQuote) {
        let startIndex = string.index(string.startIndex, offsetBy: 1)
        let endIndex = string.index(string.endIndex, offsetBy: -1)
        let range = startIndex ..< endIndex
        let sanitizedField: String = string.substring(with: range)
        
        return sanitizedField
    }
    else {
        return string;
    }
}
