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

struct ListIndexView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var linkController: LinkController
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var editMode
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var list: CDRecord
    @State var selection: String?
    @State var filter: String = ""

    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        return VStack {
            LinkSessionHost(delegate: self) {
                if isEditing {
                    TextField("Notes", text: list.binding(forProperty: "notes"))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                } else {
                    Text(list.string(forKey: "notes") ?? "")
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
                
                if isEditing {
                    FieldEditorView(fields: list.fields)
                }
                
                let items: [CDRecord] = list.sortedContents
                List(selection: $selection) {
                    ForEach(items) { item in
                        if include(item) {
                            if isEditing {
                                RecordLabel(record: item)
                            } else {
                                RecordLink(item, in: list, selection: $selection)
                            }
                        }
                    }
                    .onDelete(perform: handleDelete)
                }
                .listStyle(.plain)
                .searchable(text: $filter)
                
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                DeferredTextField(label: "Name", text: $list.name)
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ActionsMenuButton {
                    ListActionsMenu(list: list, selection: $selection)
                        .environment(\.recordContainer, self)
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

extension ListIndexView: AddLinkDelegate {
    func handleAddLink(to linked: CDRecord) {
        if let session = linkController.session {
            list.addToContents(linked)
            if let role = session.role {
                list.addRole(role, for: linked)
            }
            linkController.session = nil
        }
    }
}

extension ListIndexView: RecordContainerView {
    var container: CDRecord { return list }
    func dismiss() { presentationMode.wrappedValue.dismiss() }
}

struct LinkSessionHost<Content>: View where Content: View {
    @EnvironmentObject var linkController: LinkController

    let delegate: AddLinkDelegate
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if let session = linkController.session {
            AddLinkSessionView(session: session, delegate: delegate)
                .toolbar {
                    ToolbarItem {
                        Button(action: { linkController.session = nil} ) {
                            Text("Cancel")
                        }
                    }
                }
        } else {
            content()
        }
    }
}
