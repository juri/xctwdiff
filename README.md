#  xctwdiff

xctwdiff reads the message of a failed `XCTAssertEqual` check from stdin and runs [wdiff] and [colordiff]
on the two sections. It assumes you don't write messages in your equality checks.

It's a Xcode command line tool project, so build and archive and copy the binary out of the archive
somewhere along your path, or alternatively add a hashbang line to the top and use it as a script.

It's written in Swift 4.1.

[wdiff]: https://www.gnu.org/software/wdiff/
[colordiff]: https://www.colordiff.org
