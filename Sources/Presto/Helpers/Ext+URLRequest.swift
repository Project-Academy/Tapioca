//
//  Ext+URLRequest.swift
//  Presto
//
//  Created by Sarfraz Basha on 12/11/2025.
//

import Foundation

//--------------------------------------
// MARK: - EXT+URLREQUEST -
//--------------------------------------
extension URLRequest {
    /**
     Sets the value for a specified HTTP header field on the URL request.

     This is a convenience wrapper around the standard `setValue(_:forHTTPHeaderField:)` method.

     - Parameters:
       - key: The key (name) of the HTTP header field (e.g., "Authorization").
       - value: The value to set for the header field.
     - Note: This function mutates the `URLRequest` in place.
     */
    public mutating func setHeader(key: String, value: String) {
        setValue(value, forHTTPHeaderField: key)
    }
    
    /**
     Updates the request's `URL` by encoding and appending a dictionary of parameters as URL query items.

     This function is designed to add parameters for `GET`-style requests.
     It correctly handles percent-encoding of parameter values (e.g., spaces become "%20").
     
     **Parameter Handling:**
     - If the `params` dictionary is empty, the function returns immediately without modification.
     - If the URL already contains query parameters, this function preserves them.
     - **If a parameter key exists in both the URL and the new `params` dictionary,
       the value from the `params` dictionary will be used (it overrides the original).**
     
     - Throws: This function will print an error and return without modification if the URL is invalid
       or if the `URLComponents` cannot be reconstructed.
     
     - Parameters:
       - params: A `[String: Any]` dictionary of parameters to add or update in the URL's query string.
     
     - Note: This function mutates the `url` property of the `URLRequest` in place.
     */
    public mutating func updateURL(with params: [String: Any]) throws {
    
        // Ensure we have parameters
        guard !params.isEmpty else { return }
    
        // Ensure we have a URL, then deconstruct it
        // We use resolvingAgainstBaseURL: false to ensure all parts are parsed
        guard let url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { throw PrestoError.invalidURL }
    
        // Get the keys of the new parameters to check for duplication
        let paramKeys = Set(params.keys)
    
        // Get existing queryItems from the URL,
        // and filter out any that are going to be replaced
        var items: [URLQueryItem] = (components.queryItems ?? [])
            .filter { !paramKeys.contains($0.name) }
    
        // Add in the new queryItems
        let newItems = params.flatMap { (key, anyValue) in
            
            // Try to cast value as an array of primitives (Int, String, etc.)
            if let array = anyValue as? [CustomStringConvertible] {
                // Flatten the array into multiple query items with the same key
                return array.map { URLQueryItem(name: key, value: String(describing: $0)) }
            }
            
            else if let value = anyValue as? CustomStringConvertible {
                return [URLQueryItem(name: key, value: String(describing: value))]
            }
            
            else {
                print("Warning: Ignoring parameter \(key) with unsupported type in URL query. Value: \(anyValue)")
                return []
            }
        }
        items.append(contentsOf: newItems)
    
        // Assign these items back to components
        components.queryItems = items
    
        // Reconstruct URL
        guard let newURL = components.url
        else { throw PrestoError.urlConstructionFailure }
        self.url = newURL

    }
    
    /**
     Encodes a dictionary of parameters into a form-urlencoded body (`Data`).

     This function is used for requests with the `.Form` ``ContentType``.
     It correctly handles percent-encoding for both keys and values.

     - Parameters:
       - params: A `[String: Any]` dictionary of parameters to encode.
     - Returns: `Data` representing the form-encoded string (e.g., "key1=value1&key2=value2").
     */
    private static let formAllowedCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        return allowed
    }()

    /**
     Encodes a dictionary of parameters as a `application/x-www-form-urlencoded` body.

     Uses a restricted character set that percent-encodes `&`, `=`, and `+` in both
     keys and values. These characters are form-encoding delimiters and must not appear
     literally inside field values:
     - `&` separates fields — `"love it & want more"` would split into two fields
     - `=` separates key from value — `"p@ss=word"` would truncate the value
     - `+` means space in form encoding — `"C++"` would decode as `"C  "`

     - Parameter params: A `[String: Any]` dictionary of parameters to encode.
     */
    public mutating func formatForm(_ params: [String: Any]) {
        guard !params.isEmpty else { return }
        let allowed = Self.formAllowedCharacters

        let query = params.flatMap { (key, anyValue) -> [String] in
            if let array = anyValue as? [CustomStringConvertible] {
                return array.map { item in
                    let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                    let encodedValue = String(describing: item).addingPercentEncoding(withAllowedCharacters: allowed) ?? String(describing: item)
                    return "\(encodedKey)=\(encodedValue)"
                }
            }
            else if let value = anyValue as? CustomStringConvertible {
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                let encodedValue = String(describing: value).addingPercentEncoding(withAllowedCharacters: allowed) ?? String(describing: value)
                return ["\(encodedKey)=\(encodedValue)"]
            }
            return []
        }.joined(separator: "&")

        httpBody = query.data(using: .utf8)
    }
}
