// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

let runner = Runner()
let url = URL(fileURLWithPath:"/Applications/Sketch.app/Contents/Resources/sketchtool/bin/sketchtool")
if let result = try? runner.sync(url, arguments:["list", "artboards", "Bookish.sketch"]) {
    if result.status == 0 {
        let json = result.stdout
        if let data = json.data(using: .utf8) {
            if let dict = try? JSONSerialization.jsonObject(with: data, options:[]) {
                print(dict)
            }
        }
    }
}
