import Foundation

struct FakeRequest {
    let response: Any?
    let responseType: Networking.ResponseType
    let statusCode: Int

    static func find(ofType type: Networking.RequestType, forPath path: String, in collection: [Networking.RequestType: [String: FakeRequest]]) -> FakeRequest? {
        guard let requests = collection[type] else { return nil }

        guard path.characters.count > 0 else { return nil }
        var evaluatedPath = path
        evaluatedPath.removeFirstLetterIfDash()
        evaluatedPath.removeLastLetterIfDash()
        let lookupPathParts = evaluatedPath.components(separatedBy: "/")

        for originalFakedPath in requests.keys {
            guard originalFakedPath.characters.count > 0 else { continue }
            guard let fakeRequest = requests[originalFakedPath] else { return nil }
            switch fakeRequest.responseType {
            case .data, .image:
                return fakeRequest
            case .json:
                guard let response = fakeRequest.response else { return fakeRequest }

                var fakedPath = originalFakedPath
                fakedPath.removeFirstLetterIfDash()
                fakedPath.removeLastLetterIfDash()
                let fakePathParts = fakedPath.components(separatedBy: "/")
                guard lookupPathParts.count == fakePathParts.count else { continue }
                guard lookupPathParts.first == fakePathParts.first else { continue }
                guard lookupPathParts.count != 1 && fakePathParts.count != 1 else { return requests[originalFakedPath] }

                var replacedValues = [String: String]()
                for (index, fakePathPart) in fakePathParts.enumerated() {
                    if fakePathPart.contains("{") {
                        replacedValues[fakePathPart] = lookupPathParts[index]
                    }
                }

                var responseString = String(data: try! JSONSerialization.data(withJSONObject: response, options: .prettyPrinted), encoding: .utf8)!
                for (key, value) in replacedValues {
                    responseString = responseString.replacingOccurrences(of: key, with: value)
                }
                let stringData = responseString.data(using: .utf8)
                let finalJSON = try! JSONSerialization.jsonObject(with: stringData!, options: [])

                return FakeRequest(response: finalJSON, responseType: fakeRequest.responseType, statusCode: fakeRequest.statusCode)
            }
        }

        let result = requests[path]

        return result
    }
}

extension String {

    mutating func removeFirstLetterIfDash() {
        let initialCharacter = self.substring(to: self.index(after: self.startIndex))
        if initialCharacter == "/" {
            if self.characters.count > 1 {
                self.remove(at: self.startIndex)
            } else {
                self = ""
            }
        }
    }

    mutating func removeLastLetterIfDash() {
        let initialCharacter: String
        if self.characters.count > 1 {
            let index = self.index(self.endIndex, offsetBy: -1)
            initialCharacter = self.substring(from: index)
        } else {
            initialCharacter = self.substring(to: self.endIndex)
        }

        if initialCharacter == "/" {
            if self.characters.count > 1 {
                self.remove(at: self.index(self.endIndex, offsetBy: -1))
            } else {
                self = ""
            }
        }
    }
}