import Foundation
import UIKit

class AKWSUtils
{
    /// This method makes an asynchronous request to a REST web service and
    /// executes a given success closure if success or a failed closure if failed.
    ///
    /// - Parameter endpoint:       The endpoint to connect to.
    /// - Parameter httpMethod:     The HTTP method to execute.
    /// - Parameter headerValues:   A dictionary containing all header options.
    /// - Parameter bodyValue:      The HTTP payload.
    /// - Parameter showDebugInfo:  Show extra information.
    /// - Parameter isJSONResponse: If the response from the server is JSON or just a string.
    /// - Parameter completionTask: A Block with the task to perform after the request.
    /// - Parameter failureTask:    A Block with the task to perform if failure.
    static func makeRESTRequest(
        controller: UIViewController,
        endpoint: String,
        httpMethod: String,
        headerValues: Dictionary<String, String>,
        bodyValue: String,
        showDebugInfo: Bool = false,
        isJSONResponse: Bool = true,
        completionTask: @escaping (Any) -> Void,
        failureTask: @escaping (Int, String?) -> Void)
    {
        // Make the call synchronously, but with a small timeout.
        var request = URLRequest(url: NSURL(string: endpoint) as! URL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10.0)
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
                            NSLog("=> RESPONSE HTTP *Status Code* ==> %ld\n", Int64(httpResponse.statusCode))
                            NSLog("=> RESPONSE HTTP *Headers* ==>\n%@\n", httpResponse.allHeaderFields)
                            NSLog("=> RESPONSE *Body* ==>\n%@\n", String(data: data!, encoding: String.Encoding.utf8)!)
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
