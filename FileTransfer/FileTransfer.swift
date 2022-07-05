//
//  FileTransfer.swift
//  FileTransfer
//
//  Created by Swaminathan on 09/05/22.
//

import Foundation
import Alamofire

public class FileTransfer {
    
    public static var shared = FileTransfer()
    
    var session = AF
    
    
    @discardableResult
    /// Entry point to initiate a download request
    /// - Parameters:
    ///   - src: the src URL of the file
    ///   - destination: the destination URL to which the file needs to be downloaded
    ///   - options: Any addotional options (like headers)
    ///   - downloadProgress: The progress block during download
    ///   - response: The response block once the download is completed
    /// - Returns: The DownloadRequest task
    public func download(at src: String, to destination: String, options: [String:Any], downloadProgress: ((Progress) -> ())?,  response: @escaping (_ data: Data?, _ error: NSError?) -> ()) -> DownloadRequest {
        
        var headers: HTTPHeaders?
        if let headersDict = options["headers"] as? [String:String] {
            headers = HTTPHeaders(headersDict)
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        if options["background"] as? Bool == true {
            backgroundTask =  UIApplication.shared.beginBackgroundTask {
                backgroundTask = .invalid
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
        }
        
        return sendDownloadRequest(src: src, destination: destination, headers: headers,downloadProgress: downloadProgress, completion: { responseData in
            UIApplication.shared.endBackgroundTask(backgroundTask)
            switch responseData.result {
            case .success(let data):
                response(data, nil)
            case .failure(let error):
                response(nil, error as NSError)
            }
        })
    }
    
    /// Sends the download request based on the arguments
    /// - Parameters:
    ///   - src: the src URL of the file
    ///   - destination: the destination URL to which the file needs to be downloaded
    ///   - headers: Headers for the request
    ///   - downloadProgress: The progress block during download
    ///   - completion: Completion handler once the download is completed
    /// - Returns: The DownloadRequest task
    private func sendDownloadRequest(src: String, destination: String, headers: HTTPHeaders?, downloadProgress: ((Progress) -> ())?, completion: @escaping (AFDownloadResponse<Data>) -> ()) -> DownloadRequest {
        
        let request = session.download(src, headers: headers, to:  { (_, _) -> (destinationURL: URL, options: DownloadRequest.Options) in
            // Copy the downloaded file from temporary directory to the destination file path provided
            let destinationUrl = URL(fileURLWithPath: destination.replacingOccurrences(of: "file://", with: ""))
            
            return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
        })
        
            .downloadProgress { (progress) in
                // Notify progress
                downloadProgress?(progress)
            }
        
            .responseData(completionHandler: { response in
                completion(response)
            })
        return request
    }
}
