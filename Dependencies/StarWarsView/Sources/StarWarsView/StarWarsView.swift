// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Displays a block of text as a cinematic perspective crawl.
///
/// The view runs one crawl each time it appears. It uses a conventional,
/// scrollable reading layout when Reduce Motion is enabled.
public struct StarWarsView: View {
  /// The sample copy used by the parameter-free initializer.
  public static let defaultText = """

    The story so far...

    A long time ago, in a galaxy far far away...

    There was an app called Delicious Library.

    It was for cataloguing your books.
    
    It was kind of cool, with a feature that drew them as if they were on real shelves (which some people liked, though not me), and a feature that used your laptop camera to scan barcodes (which I really liked).
    
    It used a well known online book retailer for its meta data, at a time when said retailer was mostly well regarded. Or at least, not actively hated...

    Time went by, and the app grew. 
    
    An iPhone version was born, briefly flourished, then sadly died, allegedly due to licensing restrictions with the aforementioned retailer.

    Which was annoying, as the iPhone app was a great way to scan things, and a great way to check if you had a book when standing in a bookshop looking at said book.

    Skeumorphism went out of fashion, but the macOS version of the app continued to plough its own furrough. Then, one day, it just wasn't there any more.

    More time passed...

    ... and then one day I decided to make a new app, called Bookish.

    It would be cool, like Delicious Library, but with less wood panelling.

    It would work on iPhones as well as Macs.

    It wouldn't be tied to the large book retailer (who by now were also an *anything at all* retailer). At least - not exclusively so.

    It would bring back barcode scanning, but also add other cooler ways to input books, because: AI.
    
    I so I started working on it...
    
    Then got distracted by a contract...
    
    Then changed the technology stack...
    
    Multiple times...
    
    Then got distracted again by another contract...
    
    ... or two ...
    
    But now I'm back. Now I'm working on it again.
    
    I might have changed the stack again... but this time it'll be different...
    
    This is an early preview build.
    
    There are lots of features missing, but the good news is that the specification is really solid... due in large part to me having mostly-made it multiple times.
    
    Anyhoo... good luck, and let me know how you get on...
    
    """

  /// Whether the user has requested motion to be reduced.
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// The text that the view presents.
  private let text: String

  /// The duration of one crawl.
  private let duration: TimeInterval

  /// Creates a cinematic crawl.
  ///
  /// - Parameters:
  ///   - text: The text to animate.
  ///   - duration: The duration of one crawl in seconds. It must be greater than zero.
  public init(text: String = Self.defaultText, duration: TimeInterval = 40) {
    precondition(duration > 0, "The crawl duration must be greater than zero.")

    self.text = text
    self.duration = duration
  }

  /// Chooses either the cinematic crawl or the accessible static presentation.
  public var body: some View {
    Group {
      if reduceMotion {
        StarWarsStaticCrawl(text: text)
      } else {
        StarWarsAnimatedCrawl(text: text, duration: duration)
      }
    }
    .background(.black)
  }
}

#Preview("Crawl") {
  StarWarsView()
    .frame(width: 640, height: 480)
}
