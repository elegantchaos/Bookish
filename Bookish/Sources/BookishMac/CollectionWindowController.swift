//
//  WindowController.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

protocol DocumentWindowController {
    associatedtype ViewModel: DocumentViewModel
    var viewModel: ViewModel? { get set }
}

protocol DocumentViewModel {
    associatedtype WindowController: DocumentWindowController
}

class CollectionWindowController: NSWindowController, DocumentWindowController {
    var viewModel: CollectionDocumentViewModel?
    typealias ViewModel = CollectionDocumentViewModel
}
