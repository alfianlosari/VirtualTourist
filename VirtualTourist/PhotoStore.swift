//
//  PhotoStore.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 27/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import Foundation

typealias GetPhotoResponseCompletionHandler = (_ photos: [FlickrPhoto]?, _ error: Error?) -> Void

struct FlickrPhotoStore {
    
    static private let flickrApiKey = "f38f23a178a9bf6f083ae37ccd2f99bc"
    static private let flickrSecretKey = "cbf94c0d46db14e5"
    static private let flickrBaseURL = "https://api.flickr.com/services/rest"
    
    static func searchPhotos(lat: Double, lon: Double, completionHandler: @escaping GetPhotoResponseCompletionHandler) {
        var url = URL(string: flickrBaseURL)!
        let URLParams = [
            "method": "flickr.photos.search",
            "api_key": flickrApiKey,
            "lon": "\(lon)",
            "format": "json",
            "per_page": "100",
            "lat": "\(lat)",
            "nojsoncallback": "1"
            ]
        
        url = url.appendingQueryParameters(URLParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async { completionHandler(nil, error) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 else {
                let error = NSError(domain: "Search Photo", code: 0, userInfo: [NSLocalizedDescriptionKey: "Search Photo Failed."])
                DispatchQueue.main.async { completionHandler(nil, error) }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                let stat = json["stat"] as! String
                guard stat == "ok" else {
                    let message = json["message"] as? String ?? "Search Photo Failed"
                    let error = NSError(domain: "Search Photo", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                    DispatchQueue.main.async { completionHandler(nil, error) }
                    return
                }
                
                let photosDict = json["photos"] as! [String: Any]
                let photosArray = photosDict["photo"] as! [[String: Any]]
                let photos = photosArray.map { FlickrPhoto(json: $0) }.flatMap { $0 }
                
                DispatchQueue.main.async { completionHandler(photos, nil)}
                
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    
    static func getPhoto(urlText: String, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let url = URL(string: urlText) else {
            let error = NSError(domain: "Get Photo", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            DispatchQueue.main.async { completionHandler(nil, error) }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async { completionHandler(nil, error) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 else {
                let error = NSError(domain: "Get Photo", code: 0, userInfo: [NSLocalizedDescriptionKey: "Get Photo Failed."])
                DispatchQueue.main.async { completionHandler(nil, error) }
                return
            }
            
            DispatchQueue.main.async { completionHandler(data, nil) }
        }
        
        task.resume()
    }
    
}
