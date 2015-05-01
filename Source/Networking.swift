import Foundation
import UIKit
import NSObject_HYPTesting

class Networking {
  private let baseURL: NSString
  private var stubbedResponses: [String : [String : AnyObject]]

  private static let stubsInstance = Networking(baseURL: "")

  init(baseURL: String) {
    self.baseURL = baseURL
    self.stubbedResponses = [String : [String : AnyObject]]()
  }

  func GET(path: String, completion: (JSON: [String : AnyObject]?, error: NSError?) -> ()) {
    let url = String(format: "%@%@", self.baseURL, path)
    let request = NSURLRequest(URL: NSURL(string: url)!)

    if NSObject.isUnitTesting() {
      let responses = Networking.stubsInstance.stubbedResponses
      if let response: [String : AnyObject] = responses[path] {
        completion(JSON: response, error: nil)
      } else {
        var error: NSError?
        var response: NSURLResponse?
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error) {
          let result = data.toJSON()
          completion(JSON: result.JSON, error: result.error)
        } else {
          completion(JSON: nil, error: error)
        }
      }
    } else {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = true

      let queue = NSOperationQueue()
      NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response, data, error) -> Void in
        dispatch_async(dispatch_get_main_queue(), {
          UIApplication.sharedApplication().networkActivityIndicatorVisible = false

          if let response = response, data = data {
            let result = data.toJSON()

            if let JSON = result.JSON {
              completion(JSON: result.JSON, error: error)
            } else {
              completion(JSON: nil, error: error)
            }
          } else {
            completion(JSON: nil, error: error)
          }
        })
      })
    }
  }

  class func stubGET(path: String, response: [String : AnyObject]) {
    stubsInstance.stubbedResponses[path] = response
  }
}

extension NSData {
  func toJSON() -> (JSON: [String : AnyObject]?, error: NSError?) {
    var error: NSError?
    let JSON = NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions.MutableContainers, error: &error) as? [String : AnyObject]

    return (JSON, error)
  }
}