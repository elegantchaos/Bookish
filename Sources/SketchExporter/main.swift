// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

func process(artboard: [String:Any]) {
    print("Artboard \(artboard["name"]!)")
}
func process(page: [String:Any]) {
    if let name = page["name"] as? String, let artboards = page["artboards"] as? [[String:Any]] {
        print("Page \(name)")
        for artboard in artboards {
            process(artboard: artboard)
        }
    }
}

func process(_ dict: [String:Any]) {
    if let pages = dict["pages"] as? [[String:Any]] {
        for page in pages {
            process(page: page)
        }
    }
}

let runner = Runner()
let url = URL(fileURLWithPath:"/Applications/Sketch.app/Contents/Resources/sketchtool/bin/sketchtool")
if let result = try? runner.sync(url, arguments:["list", "artboards", "Bookish.sketch"]) {
    if result.status == 0 {
        let json = result.stdout
        if let data = json.data(using: .utf8) {
            if let object = try? JSONSerialization.jsonObject(with: data, options:[]), let dict = object as? [String:Any] {
                process(dict)
            }
        }
    }
}
