import Foundation
import UIKit

class AKWSUtils {
    static func makeRESTRequest(
        controller: UIViewController?,
        endpoint: String,
        httpMethod: String,
        headerValues: Dictionary<String, String>,
        bodyValue: String,
        showDebugInfo: Bool,
        isJSONResponse: Bool,
        completionTask: @escaping (Any) -> Void,
        failureTask: @escaping (Int, String?) -> Void) {
        // Make the call synchronously, but with a small timeout.
        var request = URLRequest(url: NSURL(string: endpoint)! as URL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10.0)
        // HTTP Method:
        request.httpMethod = httpMethod
        // Header:
        for (key, value) in headerValues {
            request.setValue(value, forHTTPHeaderField: key)
            if showDebugInfo {
                NSLog("=> HEADER ==> %@ : %@", key, value)
            }
        }
        // Body:
        request.httpBody = bodyValue.data(using: String.Encoding.utf8)
        if showDebugInfo {
            NSLog("=> BODY ==> %@", bodyValue)
        }
        // Completion Block:
        let completionBlock: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) -> Void in
            if error != nil {
                failureTask(ErrorCodes.ConnectionToBackEndError.rawValue, error!.localizedDescription.capitalized)
            }
            else {
                if (response?.isKind(of: HTTPURLResponse.self))! {
                    // Check the response.
                    let httpResponse = response as! HTTPURLResponse;
                    if isJSONResponse {
                        // Only JSON responses are allowed. (Check MIMEType!)
                        if httpResponse.mimeType?.compare("application/json", options: String.CompareOptions.caseInsensitive) == ComparisonResult.orderedSame {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                                switch httpResponse.statusCode {
                                case 200 ... 299:  // If it's any of 2XX is valid, let it through.
                                    completionTask(json) // Execute the completion task block!
                                    break
                                default:
                                    failureTask(httpResponse.statusCode, nil)
                                    break
                                }
                            }
                            catch {
                                failureTask(ErrorCodes.JSONProcessingError.rawValue, nil)
                            }
                        }
                        else {
                            failureTask(ErrorCodes.InvalidMIMEType.rawValue, nil)
                        }
                        
                        if showDebugInfo {
                            NSLog("=> RESPONSE HTTP *Status Code* ==> %ld", Int64(httpResponse.statusCode))
                            NSLog("=> RESPONSE HTTP *Headers* ==>\n%@", httpResponse.allHeaderFields)
                            NSLog("=> RESPONSE *Body* ==>\n%@", String(data: data!, encoding: String.Encoding.utf8)!)
                        }
                    }
                    else {
                        let str = String(data: data!, encoding: String.Encoding.utf8)
                        switch httpResponse.statusCode {
                        case 200 ... 299:  // If it's any of 2XX is valid, let it through.
                            completionTask(str ?? "") // Execute the completion task block!
                            break
                        default:
                            failureTask(httpResponse.statusCode, nil)
                            break
                        }
                    }
                }
            }
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: completionBlock)
        if showDebugInfo {
            NSLog("=> REQUEST ==> %@", request.description)
        }
        task.resume()
    }
}
