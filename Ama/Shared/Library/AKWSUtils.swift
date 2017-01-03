import Foundation
import TSMessages
import UIKit

class AKWSUtils
{
    /// This method makes an asynchronous request to a REST web service and
    /// executes a given success closure if success or a failed closure if failed.
    ///
    /// - Parameter endpoint:      The endpoint to connect to.
    /// - Parameter httpMethod     The HTTP method to execute.
    /// - Parameter headerValues   A dictionary containing all header options.
    /// - Parameter bodyValue      The HTTP payload.
    /// - Parameter completionTask A Block with the task to perform after the request.
    /// - Parameter failureTask    A Block with the task to perform if failure.
    static func makeRESTRequest(
        controller: UIViewController,
        endpoint: String,
        httpMethod: String,
        headerValues: Dictionary<String, String>,
        bodyValue: String,
        completionTask: @escaping (Any) -> Void,
        failureTask: (Void) -> Void)
    {
        // Make the call synchronously, but with a small timeout.
        var request = URLRequest(url: NSURL(string: endpoint) as! URL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10.0)
        // HTTP Method:
        request.httpMethod = httpMethod
        // Header:
        for (key, value) in headerValues {
            request.setValue(value, forHTTPHeaderField: key)
            NSLog("=> HEADER ==> %@ : %@", key, value)
        }
        // Body:
        request.httpBody = bodyValue.data(using: String.Encoding.utf8)
        // Completion Block:
        let completionBlock: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) -> Void in
            if error != nil {
                GlobalFunctions.AKPresentTopMessage(controller, type: TSMessageNotificationType.error, message: error!.localizedDescription.capitalized)
            }
            else {
                if (response?.isKind(of: HTTPURLResponse.self))! {
                    // Check the response.
                    let httpResponse = response as! HTTPURLResponse;
                    // Only JSON responses are allowed. (Check MIMEType!)
                    if httpResponse.mimeType?.compare("application/json") == ComparisonResult.orderedSame {
                        do {
                            let jsonDocument = try JSONSerialization.jsonObject(with: data!)
                            switch httpResponse.statusCode {
                            case 200 ... 299:  // If it's any of 2XX is valid, let it through.
                                completionTask(jsonDocument) // Execute the completion task block!
                                break
                            default:
                                GlobalFunctions.AKPresentTopMessage(controller, type: TSMessageNotificationType.error, message: String(format: "%d: Error genérico.", httpResponse.statusCode))
                                break
                            }
                        }
                        catch {
                            GlobalFunctions.AKPresentTopMessage(controller, type: TSMessageNotificationType.error, message: "Error procesando respuesta. Reportando...")
                            return
                        }
                    }
                    else {
                        GlobalFunctions.AKPresentTopMessage(controller, type: TSMessageNotificationType.error, message: "El servicio devolvió una respuesta inválida. Reportando...")
                        NSLog("=> EL SERVICIO DEVOLVIO UNA RESPUESTA INVÁLIDA. REPORTANDO...")
                    }
                    
                    NSLog("=> RESPONSE HTTP *Status Code* ==> %ld\n", Int64(httpResponse.statusCode))
                    NSLog("=> RESPONSE HTTP *Headers* ==>\n%@\n", httpResponse.allHeaderFields)
                    NSLog("=> RESPONSE *Body* ==>\n%@\n", String(data: data!, encoding: String.Encoding.utf8)!)
                }
            }
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: completionBlock)
        NSLog("=> REQUEST ==> %@", request.description)
        task.resume() // Make the request.
    }
}
