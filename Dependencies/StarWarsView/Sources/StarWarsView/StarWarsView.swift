// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

let message = """

  The story so far...
  
  A long time ago, in a galaxy far far away...
  
  There was an app called Delicious Library.

  It was for cataloguing your books. 
  It had a feature that drew them as if they were on real shelves, which people thought was kind of cool (although I never really liked that).
  It also had the ability to use your computer's camera to scan barcodes - which I really did think was cool.
  It used a well known online book retailer for its meta data, at a time when said retailer was mostly well regarded. Or at least, not actively hated...
  
  Time went by, and the app grew. You could use it for other things like DVDs. An iPhone version was born, and briefly flourished, but then quietly died, allegedly due to licensing restrictions with the aforementioned retailer.
  
  Which was annoying, as the iPhone app was a great way to scan things.
  
  Skeumorphism went out of fashion, but the app continued to plough its own furrough.
  
  Then, one day, it wasn't there any more.
  
  More time passed...
  
  ... and then one day I decided to make a new app, called Bookish.
  
  It would be cool, like Delicious Library, but with less wood panelling.
  
  It would work on iPhones as well as Macs.
  
  It wouldn't be tied to the large book retailer (who by now were also an *anything at all* retailer). At least - not exclusively so.
  
  It would bring back barcode scanning.

  """

struct StarWarsView: View {
  private let duration = 10.0
  @State private var running = false
  
  var body: some View {
    Text(message)
      .frame(width: 256)
      .fixedSize()
      .offset(x: 0, y: running ? -1000 : 400)
      .fontWeight(.bold)
      .font(.title)
      .foregroundColor(.gray)
      .multilineTextAlignment(.center)
      .lineSpacing(10)
      .padding()
      .rotation3DEffect(
        .degrees(60),
        axis: (x: 1, y: 0, z: 0),
        anchor: .top,
      )
      .shadow(color: .gray, radius: 2, x: 0, y: 5)
      .animation(Animation.linear(duration: duration), value: running)
      .frame(width: 600)
      .task {
        running = true
      }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    StarWarsView()
  }
}
