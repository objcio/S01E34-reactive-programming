//
//  Networking.swift
//  ReactiveUIExample
//
//  Created by Florian Kugler on 24-01-2017.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import RxSwift

typealias JSONDictionary = [String: Any]


struct Resource<A> {
    let url: URL
    let parse: (Data) -> A?
}

extension Resource {
    init(url: URL, parseJSON: @escaping (Any) -> A?) {
        self.url = url
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            return json.flatMap(parseJSON)
        }
    }
}


enum Result<A> {
    case success(A)
    case error(Error)
    
    init(_ value: A?, or error: Error) {
        if let value = value {
            self = .success(value)
        } else {
            self = .error(error)
        }
    }
}

extension Result {
    func map<B>(_ transform: (A) -> B) -> Result<B> {
        switch self {
        case .success(let value): return .success(transform(value))
        case .error(let error): return .error(error)
        }
    }
}

func vat(country: String) -> Resource<Double> {
    let url = URL(string: "http://localhost:8000/\(country).json")!
    return Resource(url: url) { (json: Any) in
        return (json as? [String:Double])?["vat"]
    }
}



extension String: Error { }

final class Webservice {
    let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    
    func load<A>(_ resource: Resource<A>, completion: @escaping (Result<A>) -> ()) {
        session.dataTask(with: resource.url, completionHandler: { data, _, _ in
            guard let data = data else {
                completion(.error("No data"))
                return
            }
            completion(Result(resource.parse(data), or: "Couldn't parse data"))
        }).resume()
    }
}
