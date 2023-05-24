import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum FilterType: String, CaseIterable {
    case sepiaTone = "CISepiaTone"
    case vignette = "CIVignette"
    case photoEffectNoir = "CIPhotoEffectNoir"
    // 他のフィルタを追加する場合はここに追加してください
    
    var displayName: String {
        return rawValue
    }
    
    var filter: CIFilter? {
        return CIFilter(name: rawValue)
    }
}

extension CIFilter {
    convenience init?(filterType: FilterType) {
        self.init(name: filterType.rawValue)
    }
}

struct ContentView: View {
    @State private var inputImage: UIImage? = UIImage(named: "sample") ?? nil
    @State private var outputImage: UIImage?
    
    @State private var selectedFilter: FilterType = .sepiaTone
     let filters: [FilterType] = [
         .sepiaTone,
         .vignette,
         .photoEffectNoir,
         // 他のフィルタを追加する場合はここに追加してください
     ]
    
    @State private var image: UIImage = UIImage(named: "sample")!
    @State var showingImagePicker = false
    
    var body: some View {
        VStack {
            if let outputImage = outputImage {
                Image(uiImage: outputImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
            }
            Button("Choose Image") {
                showingImagePicker = true
            }
            Picker("Filter", selection: $selectedFilter) {
                 ForEach(filters, id: \.self) { filter in
                     Text(filter.displayName)
                 }
             }
             .pickerStyle(SegmentedPickerStyle())
             .padding()
             .onChange(of: selectedFilter) { _ in
                 updateImage()
             }
        }
        .onAppear {
            updateImage()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary, didFinishPicking: { selectedImage in
                self.inputImage = selectedImage
                self.updateImage()
            })
        }
        
    }
    
    func updateImage() {
        guard let inputImage = self.inputImage else { return }
        
        let ciImage = CIImage(image: inputImage)
        let filteredImage = applyFilter(to: ciImage, filter: selectedFilter.filter!)
        
        if let outputCIImage = filteredImage {
            let context = CIContext()
            if let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
                outputImage = UIImage(cgImage: outputCGImage)
            }
        }
    }
    
    func applyFilter(to image: CIImage?, filter: CIFilter) -> CIImage? {
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    let didFinishPicking: (UIImage) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                parent.didFinishPicking(image)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

