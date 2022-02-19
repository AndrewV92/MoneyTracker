//
//  CategoriesListView.swift
//  MoneyTracker
//
//  Created by Андрей Воробьев on 18.02.2022.
//

import SwiftUI

struct CategoriesListView: View {
    
    @State private var name = ""
    @State private var color = Color.red
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionCategory.timestamp, ascending: false)], animation: .default)
    private var categories: FetchedResults<TransactionCategory>
    
    //@State var selectedCategories = Set<TransactionCategory>()
    @Binding var selectedCategories: Set<TransactionCategory>
    
    var body: some View {
        Form {
            Section(header: Text("Выберите категории")) {
                ForEach(categories) { category in
                    Button {
                        if selectedCategories.contains(category){
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if let data = category.colorData, let uiColor = UIColor.color(data: data) {
                            let color = Color(uiColor)
                                Spacer()
                                    .frame(width: 30, height: 10)
                                    .background(color)
                            }
                            Text(category.name ?? "")
                                .foregroundColor(Color(.label))
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { i in
                        let category = categories[i]
                        selectedCategories.remove(category)
                        viewContext.delete(category)
                    }
                    try? viewContext.save()
                }
            }
            Section(header: Text("Создать новую категорию")) {
                TextField("Название", text: $name)
                ColorPicker("Цвет", selection: $color)
                Button(action: handleCreate) {
                    HStack {
                        Spacer()
                        Text("Создать")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(10)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
        private func handleCreate() {
            let context = PersistenceController.shared.container.viewContext
            let category = TransactionCategory(context: context)
            category.name = self.name
            category.colorData = UIColor(color).encode()
            category.timestamp = Date()
            try? context.save()
            self.name = ""
        }
}

struct CategoriesListView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesListView(selectedCategories: .constant(Set<TransactionCategory>()))
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

