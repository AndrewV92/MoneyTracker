//
//  AddTransactionForm.swift
//  MoneyTracker
//
//  Created by Андрей Воробьев on 15.02.2022.
//

import SwiftUI

struct AddTransactionForm: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        let context = PersistenceController.shared.container.viewContext
        let request = TransactionCategory.fetchRequest()
        request.sortDescriptors = [.init(key: "timestamp", ascending: false)]
        do {
        let result =  try context.fetch(request)
            if let first = result.first {
 //           selectedCategories.insert(first)
                self._selectedCategories = .init(initialValue: [first])
            }
        } catch {
            print("Failed to preselect categories:", error)
        }
    }
    
    @State private var name = ""
    @State private var amount = ""
    @State private var date = Date()
    
    @State private var shouldPresentPhotoPicker = false
    
    @State private var photoData: Data?
    
    @State private var selectedCategories = Set<TransactionCategory>()
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация")) {
                    TextField("Название", text: $name)
                    TextField("Стоимость", text: $amount)
                        .keyboardType(.numberPad)
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                }
                    Section(header: Text("Категории")) {
                        NavigationLink {
                            CategoriesListView(selectedCategories: $selectedCategories)
                                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                                .navigationTitle("Категории")
                        } label: {
                            Text("Выберите категории")
                        }
                        let sortedByTimestampCategories = Array(selectedCategories).sorted(by: {$0.timestamp?.compare($1.timestamp ?? Date()) == .orderedDescending })
                        
                        ForEach(sortedByTimestampCategories) { category in
                            HStack(spacing: 12) {
                            if let data = category.colorData, let uiColor = UIColor.color(data: data) {
                            let color = Color(uiColor)
                                Spacer()
                                    .frame(width: 30, height: 10)
                                    .background(color)
                            }
                            Text(category.name ?? "")
                            }
                        }
                    }
                    
                
                
                Section(header: Text("Фото/чек")) {
                    Button {
                        shouldPresentPhotoPicker.toggle()
                    } label: {
                        Text("Выберите фото")
                    }
                    .fullScreenCover(isPresented: $shouldPresentPhotoPicker, onDismiss: nil) {
                        PhotoPickerView(photoData: $photoData)
                    }
                    if let data = self.photoData, let image = UIImage.init(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(.bottom, 20)
                    }
                }
                
            }.navigationTitle("Добавить покупку")
                .navigationBarItems(leading: cancelButton, trailing: saveButton)
        }
    }
    
   
    
    struct PhotoPickerView: UIViewControllerRepresentable {
        
        @Binding var photoData: Data?
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            
            private let parent: PhotoPickerView
            
            init(parent: PhotoPickerView) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                
                let image = info[.originalImage] as? UIImage
                let resizedImage = image?.resized(to: .init(width: 500, height: 500))
                let imageData = resizedImage?.jpegData(compressionQuality: 0.5)
                self.parent.photoData = imageData
                
                picker.dismiss(animated: true, completion: nil)
            }
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true, completion: nil)
            }
            
        }
        
        func makeUIViewController(context: Context) -> some UIViewController {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = context.coordinator
            return imagePicker
        }
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            
        }
        
        
    }
    
    
    private var cancelButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Отмена")
        }
    }
    
    private var saveButton: some View {
        Button {
            let context = PersistenceController.shared.container.viewContext
            let transaction = CardTransaction(context: context)
            transaction.name = self.name
            transaction.timestamp = self.date
            transaction.amount = Float(self.amount) ?? 0
            transaction.photoData = self.photoData
            transaction.card = self.card
            transaction.categories = self.selectedCategories as NSSet
            
            do {
                try context.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Failed to save transaction: \(error)")
            }
        } label: {
            Text("Сохранить")
        }
    }
}

struct AddTransactionForm_Previews: PreviewProvider {
    static let firstCard: Card? = {
        let context = PersistenceController.shared.container.viewContext
        let request = Card.fetchRequest()
        request.sortDescriptors = [.init(key: "timestamp", ascending: false)]
        return try? context.fetch(request).first
    }()
    static var previews: some View {
        if let card = firstCard {
        AddTransactionForm(card: card)
        }
    }
}


extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image {
        _ in
        let hScale = newSize.height / size.height
        let vScale = newSize.width / size.width
        let scale = max(hScale, vScale)
        let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
        var middle = CGPoint.zero
        if resizeSize.width > newSize.width {
            middle.x -= (resizeSize.width - newSize.width) / 2.0
        }
        if resizeSize.height > newSize.height {
            middle.y -= (resizeSize.height - newSize.height) / 2.0
        }
        draw(in: CGRect(origin: middle, size: resizeSize))
    }
}
}

