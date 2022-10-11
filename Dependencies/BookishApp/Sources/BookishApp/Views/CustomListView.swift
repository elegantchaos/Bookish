// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

extension Binding where Value == String? {
    func onNone(_ fallback: String) -> Binding<String> {
        return Binding<String>(get: {
            return self.wrappedValue ?? fallback
        }) { value in
            self.wrappedValue = value
        }
    }
}

struct CustomListView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var linkController: LinkController
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var editMode
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var list: CDRecord
    @ObservedObject var fields: FieldList
    @State var selection: String?
    @State var filter: String = ""

    @AppStorage("showItems") var showItems = true

    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        return VStack(spacing: 0) {
            LinkSessionHost(delegate: self) {
                List {
                    FieldsView(record: list, fields: fields)
                        .padding(.bottom)
                    
                    let items: [CDRecord] = list.sortedContents
                    //                DisclosureGroup("Items", isExpanded: $showItems) {
                    LazyVStack(alignment: .leading, spacing: 8.0) {
                        ForEach(items) { item in
                            if include(item) {
                                if isEditing {
                                    RecordLabel(record: item)
                                } else {
                                    RecordNavigationLink(item, in: list)
                                }
                            }
                        }
                        .onDelete(perform: handleDelete)
                        .foregroundColor(.primary)
                        //                    .searchable(text: $filter)
                    }
                    .padding(.vertical)
                    //                }
                    
                    RawPropertiesGroup(record: list)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(isEditing || linkController.session != nil)
        .navigationTitle(list.name)
        .toolbar {
            ToolbarItem {
                if isEditing {
                    EditButton()
                } else if linkController.session == nil {
                    ActionsMenuButton {
                        ListActionsMenu(list: list, selection: $selection)
                            .environment(\.recordViewer, self)
                    }
                }
                
            }

            ToolbarItem(placement: .principal) {
                if linkController.session == nil {
                    DeferredTextField(label: "Name", text: $list.name)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("_Adding To_ \(list.name)")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                }
            }
        }
    }
    
    func include(_ item: CDRecord) -> Bool {
        filter.isEmpty || item.name.contains(filter)
    }
    
    func handleDelete(_ items: IndexSet?) {
//        if let items = items {
//            items.forEach { index in
//                let entry = list.sortedBooks[index]
//                model.delete(entry)
//            }
//            model.save()
//        }
    }
    
}

extension CustomListView: AddLinkDelegate {
    func handleAddLink(to linked: CDRecord) {
        onMainQueue {
            if let session = linkController.session {
                list.addToContents(linked)
                if let role = session.role {
                    list.addLink(to: linked, role: role)
                }
                linkController.session = nil
            }
        }
    }
}

extension CustomListView: RecordViewer {
    var record: CDRecord { return list }
    func dismiss() { presentationMode.wrappedValue.dismiss() }
}
