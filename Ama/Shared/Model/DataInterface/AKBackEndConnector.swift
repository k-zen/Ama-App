import Foundation
import UIKit

class AKBackEndConnector {
    static func obtainSessionToken(controller: UIViewController?,
                                   user: String,
                                   pass: String,
                                   showDebugInfo: Bool = false,
                                   completionTask: @escaping (String) -> Void,
                                   failureTask: @escaping (Int, String?) -> Void) {
        if showDebugInfo {
            NSLog("=> INFO: MAKING SESSION TOKEN AUTHORISATION REQUEST...")
        }
        
        // Make the call synchronously, but with a small timeout.
        var tokenRequest = URLRequest(
            url: NSURL(
                string: String(
                    format: "%@/oauth/token?grant_type=password&username=%@&password=%@",
                    GlobalConstants.AKAmaServerAddress,
                    user,
                    pass
            ))! as URL,
            cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy,
            timeoutInterval: 10.0
        )
        // HTTP Method:
        tokenRequest.httpMethod = "POST"
        // Header:
        tokenRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        tokenRequest.setValue(String(format: "Basic %@", "Ama@admin:amaPass2017".toBase64()), forHTTPHeaderField: "Authorization")
        // Body:
        tokenRequest.httpBody = "".data(using: String.Encoding.utf8)
        // Completion Block:
        let completionBlock: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) -> Void in
            if error != nil {
                failureTask(ErrorCodes.ConnectionToBackEndError.rawValue, error!.localizedDescription.capitalized)
            }
            else {
                if (response?.isKind(of: HTTPURLResponse.self))! {
                    // Check the response.
                    let httpResponse = response as! HTTPURLResponse;
                    // Only JSON responses are allowed. (Check MIMEType!)
                    if httpResponse.mimeType?.compare("application/json", options: String.CompareOptions.caseInsensitive) == ComparisonResult.orderedSame {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            switch httpResponse.statusCode {
                            case 200 ... 299:  // If it's any of 2XX is valid, let it through.
                                
                                if let dictionary = json as? JSONObject {
                                    if let sessionToken = dictionary["access_token"] as? String {
                                        completionTask(sessionToken) // Execute the completion task block!
                                    }
                                }
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
                        NSLog("=> SESSION TOKEN: RESPONSE HTTP *Status Code* ==> %ld", Int64(httpResponse.statusCode))
                        NSLog("=> SESSION TOKEN: RESPONSE HTTP *Headers* ==>\n%@", httpResponse.allHeaderFields)
                        NSLog("=> SESSION TOKEN: RESPONSE *Body* ==>\n%@", String(data: data!, encoding: String.Encoding.utf8)!)
                    }
                }
            }
        }
        
        let tokenSession = URLSession.shared
        let tokenTask = tokenSession.dataTask(with: tokenRequest, completionHandler: completionBlock)
        if showDebugInfo {
            NSLog("=> SESSION TOKEN: REQUEST ==> %@", tokenRequest.description)
        }
        tokenTask.resume()
    }
}
