//
//  TransactionsListView.swift
//  MoneyTracker
//
//  Created by Андрей Воробьев on 16.02.2022.
//

import SwiftUI

struct TransactionsListView: View {
    
    @State private var shouldShowAddTransactionForm = false
    @State private var shouldShowFilterSheet = false
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        fetchRequest = FetchRequest<CardTransaction>(entity: CardTransaction.entity(), sortDescriptors: [.init(key: "timestamp", ascending: false)], predicate: .init(format: "card == %@", self.card))
    }
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var fetchRequest: FetchRequest<CardTransaction>
    
    var body: some View {
        VStack {
            
            if fetchRequest.wrappedValue.isEmpty {
                Text("Добавьте вашу первую покупку")
                Button {
                    shouldShowAddTransactionForm.toggle()
                } label: {
                    Text("+ Покупка")
                        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                        .background(Color(.label))
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(7)
                        .font(.headline)
                }
                
            } else {
                HStack {
                    Spacer()
                    addTransactionButton
                    filterButton
                        .sheet(isPresented: $shouldShowFilterSheet) {
                            FilterSheet(selectedCategories: self.selectedCategories) { categories in
                                self.selectedCategories = categories
                            }
                        }
                }.padding(.horizontal)
                
                
                
                ForEach(filterTransactions(selectedCategories: self.selectedCategories)) { transaction in
                    CardTransactionView(transaction: transaction)
                }
            }
        }
        .fullScreenCover(isPresented: $shouldShowAddTransactionForm, onDismiss: nil) {
            AddTransactionForm(card: self.card)
            
        }
    }
    
    @State var selectedCategories = Set<TransactionCategory>()
    
    private var addTransactionButton: some View {
        Button {
            shouldShowAddTransactionForm.toggle()
        } label: {
            Text("+ Покупка")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.systemBackground))
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.label))
                .cornerRadius(7)
            
        }
        
    }
    
    private func filterTransactions(selectedCategories: Set<TransactionCategory>) -> [CardTransaction] {
        if selectedCategories.isEmpty {
            return Array(fetchRequest.wrappedValue)
        }
        return fetchRequest.wrappedValue.filter { transaction in
            var shouldKeep = false
            if let categories = transaction.categories as? Set<TransactionCategory> {
                categories.forEach({ category in
                    if selectedCategories.contains(category) {
                        shouldKeep = true
                    }
                })
            }
            return shouldKeep
        }
    }
    
    private var filterButton: some View {
        Button {
            shouldShowFilterSheet.toggle()
        } label: {
            HStack {
                Image(systemName: "line.horizontal.3.decrease.circle")
                Text("Фильтр")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(.systemBackground))
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(.label))
            .cornerRadius(7)
        }
        
    }
    
}

struct FilterSheet: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionCategory.timestamp, ascending: false)], animation: .default)
    private var categories: FetchedResults<TransactionCategory>
    
    //@State var selectedCategories = Set<TransactionCategory>()
    
    @State var selectedCategories: Set<TransactionCategory>
    
    let didSaveFilters: (Set<TransactionCategory>) -> ()
    
    var body: some View {
        NavigationView {
            Form {
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
                
            }.navigationTitle("Выберите фильтры")
                .navigationBarItems(trailing: saveButton)
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    private var saveButton: some View {
        Button {
            didSaveFilters(selectedCategories)
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Сохранить")
        }
        
    }
}

struct CardTransactionView: View {
    
    @State private var shouldPresentActionSheet = false
    
    private func handleDelete() {
        withAnimation {
            do {
                let context = PersistenceController.shared.container.viewContext
                context.delete(transaction)
                try context.save()
            } catch {
                print("Failed to delete transaction: ", error)
            }
        }
        
    }
    
    
    let transaction: CardTransaction
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(transaction.name ?? "")
                        .font(.headline)
                    if let date = transaction.timestamp {
                        Text(dateFormatter.string(from: date))
                    }
                }
                Spacer()
                
                VStack(alignment: .trailing){
                    Button {
                        shouldPresentActionSheet.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 28))
                    }
                    .padding(EdgeInsets(top: 6, leading: 8, bottom: 4, trailing: 0))
                    .actionSheet(isPresented: $shouldPresentActionSheet) {
                        .init(title: Text(transaction.name ?? ""), message: nil, buttons: [.cancel(Text("Отмена")), .destructive(Text("Удалить"), action: handleDelete)])
                    }
                    
                    Text(String(format: "%.2f ₽", transaction.amount))
                    
                }
            }
            if let categories = transaction.categories as? Set<TransactionCategory> {
                
                let sortedByTimestampCategories = Array(categories).sorted(by: {$0.timestamp?.compare($1.timestamp ?? Date()) == .orderedDescending })
                HStack {
                    ForEach(sortedByTimestampCategories) { category in
                        HStack {
                            if let data = category.colorData, let uiColor = UIColor.color(data: data) {
                                let color = Color(uiColor)
                                Text(category.name ?? "")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(color)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                                
                            }
                        }
                    }
                    Spacer()
                }
            }
            if let photoData = transaction.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .foregroundColor(Color(.label))
        .padding()
        .background(Color("TransactionList"))
        .cornerRadius(7)
        .shadow(radius: 7)
        .padding(.horizontal)
    }
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_Ru")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter
    }()
    

}



struct TransactionsListView_Previews: PreviewProvider {
    
    static let firstCard: Card? = {
        let context = PersistenceController.shared.container.viewContext
        let request = Card.fetchRequest()
        request.sortDescriptors = [.init(key: "timestamp", ascending: false)]
        return try? context.fetch(request).first
    }()
    
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        NavigationView{
        ScrollView {
            if let card = firstCard {
                TransactionsListView(card: card)
                    .environment(\.managedObjectContext, context)
        }
        }
    }
        .colorScheme(.dark)
    }
}



