// Tests for the parts of the app that run without a window. The update check reads and
// compares version strings, so this program can compile its file and call its functions.

import Foundation

var failures = 0

/**
 * Records a failed check and prints it.
 *
 * @param isPassed Bool - the result of the check
 * @param label String - what the check tests
 */
func check(_ isPassed: Bool, _ label: String) {
   if !isPassed {
      failures += 1
      print("FAIL: \(label)")
   }
}

func testNumbers() {
   check(UpdateCheck.numbers(in: "v1.2.0") == [ 1, 2, 0 ], "a release tag splits into its numbers")
   check(UpdateCheck.numbers(in: "dev") == [], "a version without digits has no numbers")
   check(UpdateCheck.numbers(in: "1.4.0-beta.2") == [ 1, 4, 0, 2 ], "text separates the numbers")
   check(UpdateCheck.numbers(in: "1.10.0") == [ 1, 10, 0 ], "a two-digit number stays one number")
}

func testIsNewer() {
   check(UpdateCheck.isNewer("v1.2.0", than: "1.1.1"), "a newer release counts as newer")
   check(!UpdateCheck.isNewer("1.1.1", than: "1.1.1"), "the same version is not newer")
   check(!UpdateCheck.isNewer("1.0.3", than: "1.1.0"), "an older release is not newer")
   check(UpdateCheck.isNewer("1.10.0", than: "1.9.0"), "1.10 is newer than 1.9, because it counts numbers")
   check(UpdateCheck.isNewer("1.2", than: "1.1.9"), "a shorter version compares with a zero")
   check(UpdateCheck.isNewer("2", than: "1.99.99"), "the first number decides")
   check(!UpdateCheck.isNewer("dev", than: "1.0.0"), "a version without digits is not newer")
   // A local build has no numbers, so any release counts as newer here. The app checks
   // for "dev" itself before it uses this result, because a local build must not be replaced.
   check(UpdateCheck.isNewer("v1.2.0", than: "dev"), "a release counts as newer than a version without numbers")
}

/**
 * Runs every check and sets the exit code. A program with two files has no top level
 * statements, so the runner is a main type.
 */
@main
struct AppTests {
   static func main() {
      testNumbers()
      testIsNewer()

      if failures > 0 {
         print("\(failures) check(s) failed")
         exit(1)
      }
      print("All app checks passed")
   }
}
