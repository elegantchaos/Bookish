// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

let runner = Runner()
let url = URL(fileURLWithPath:"/Applications/Sketch.app/Contents/Resources/sketchtool/bin/sketchtool")

func process(artboard: [String:Any], catalogue: String) {
    if let name = artboard["name"] as? String, let id = artboard["id"] as? String {
        print("Artboard \(name)/\(id)")
        let catURL = URL(fileURLWithPath: catalogue).appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: catURL, withIntermediateDirectories: true, attributes:nil)
        if let result = try? runner.sync(url, arguments:["export", "artboards", "Bookish.sketch", "--items=\(id)", "--output=\(catalogue).xcassets"]) {
            print(result.stdout)
            print(result.stderr)
        } else {
            print("failed to export \(name)")
        }
    }
}

func process(page: [String:Any]) {
    if let name = page["name"] as? String, let artboards = page["artboards"] as? [[String:Any]] {
        print("Page \(name)")
        for artboard in artboards {
            process(artboard: artboard, catalogue: name)
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
