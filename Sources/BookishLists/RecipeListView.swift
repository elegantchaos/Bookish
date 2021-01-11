// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Developer on 11/01/2021.
//  All code (c) 2021 - present day, Sam Developer.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct OrderView: View {
    @EnvironmentObject var model: Model

    @Binding var order: Order
    @State var item: String = ""
    
    var body: some View {
        let crafter = Crafter(for: order.required, model: model)
        crafter.calculate()
        return VStack {
            ValueStoreEditorView(title: "Input", crafter: crafter, store: $order.required)
            HStack {
                TextField("Enter the item to craft", text: $item)
                Button(action: handleAdd) {
                    Text("Add")
                }
                .disabled(model.recipes[item] == nil)
            }
            
            Spacer()
            
            if order.required.values.count > 0 {
                ScrollView {
                    return VStack {
                        ItemsView(title: "Build List", store: crafter.build)
                        ItemsView(title: "Ore Required", store: crafter.raw)
                        ItemsView(title: "Surplus Materials", store: crafter.owned)
                        ItemsView(title: "Machines Required", store: crafter.machines)
                    }
                }
            }
        }
        .padding()
        .navigationTitle(order.name)
    }
    
    func handleAdd() {
        order.required.add(1, forKey: item)
        item = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        OrderView(order: .constant(Order(name: "Test", required:[:])))
    }
}
