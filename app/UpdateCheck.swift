import Foundation

/// What GitHub reports as the newest release.
struct ReleaseInfo {
   let tag: String
   let page: String
}

/// Asks GitHub for the newest release. It only reads the public release list and never
/// replaces the app: this copy may carry changes that an update would throw away.
enum UpdateCheck {
   static let repository = "karlingen/i-see-logic-pro"

   static var current: String {
      return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
   }

   /**
    * Compares "1.2.0" with "1.1.1" number by number, so that 1.10 counts as newer than 1.9.
    *
    * @param candidate String - the version of a release, for example "v1.2.0"
    * @param current String - the version of this app
    * @return Bool - true if candidate is newer than current
    */
   static func isNewer(_ candidate: String, than current: String) -> Bool {
      let a = numbers(in: candidate)
      let b = numbers(in: current)

      for index in 0..<max(a.count, b.count) {
         let left = index < a.count ? a[index] : 0
         let right = index < b.count ? b[index] : 0

         if left != right {
            return left > right
         }
      }
      return false
   }

   /**
    * Splits a version into its numbers. Text that is not a digit separates the numbers.
    *
    * @param text String - the version, for example "v1.2.0"
    * @return [Int] - the numbers, for example [ 1, 2, 0 ]
    */
   static func numbers(in text: String) -> [Int] {
      return text.split(whereSeparator: { (c) in return !c.isNumber }).map { (part) in
         return Int(part) ?? 0
      }
   }

   /**
    * Asks the GitHub API for the newest release of this repository.
    *
    * @return ReleaseInfo - the tag and the web page of the release
    */
   static func latest() async throws -> ReleaseInfo {
      let address = "https://api.github.com/repos/\(repository)/releases/latest"
      var request = URLRequest(url: URL(string: address)!)

      request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
      request.timeoutInterval = 15

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let http = response as? HTTPURLResponse, http.statusCode == 200,
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tag = json["tag_name"] as? String else {
         throw NSError(domain: "UpdateCheck", code: 1,
                       userInfo: [NSLocalizedDescriptionKey: "Unexpected answer from GitHub."])
      }
      let releases = "https://github.com/\(repository)/releases"
      // Open only a page of this repository, whatever the answer holds.
      let page = json["html_url"] as? String ?? ""

      return ReleaseInfo(tag: tag, page: page.hasPrefix(releases + "/") ? page : releases)
   }
}
