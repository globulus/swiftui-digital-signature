//
//  SignatureView.swift
//  SwiftUI Recipes
//
//  Created by Gordan Glavaš on 28.06.2021..
//

import SwiftUI
import CoreGraphics
import UIKit

private let fontFamlies = ["Zapfino", "SavoyeLetPlain", "SnellRoundhand", "SnellRoundhand-Black"]
private let bigFontSize: CGFloat = 44
private let placeholderText = "Signature"
private let maxHeight: CGFloat = 160
private let lineWidth: CGFloat = 5

public struct SignatureView: View {
    public let onSave: (UIImage) -> Void
    public let onCancel: () -> Void
    
    @State private var selectedTab = 0
    private let tabTitles = ["Draw", "Image", "Type"]
    
    @State private var saveSignature = false
    
    @State private var fontFamily = fontFamlies[0]
    @State private var color = Color.blue
    
    @State private var drawing = DrawingPath()
    @State private var image = UIImage()
    @State private var isImageSet = false
    @State private var text = ""
    
    public init(onSave: @escaping (UIImage) -> Void,
                onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack {
            HStack {
                Button("Done", action: extractImageAndHandle)
                Spacer()
                Button("Cancel", action: onCancel)
            }
            Picker(selection: $selectedTab, label: EmptyView()) {
                ForEach(tabTitles, id: \.self) { tab in
                    Text(tab)
                        .tag(tabTitles.firstIndex(of: tab)!)
                }
            }.pickerStyle(SegmentedPickerStyle())
            signatureContent
            Button("Clear signature", action: clear)
            HStack {
                if selectedTab == Tab.type.rawValue {
                    FontFamilyPicker(selection: $fontFamily)
                }
                ColorPickerCompat(selection: $color)
//                Toggle(isOn: $saveSignature) {
//                    Text("Save on done")
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                }
            }
            Spacer()
        }.padding()
    }
    
    private var signatureContent: some View {
        let tab = Tab(rawValue: selectedTab)
        return Group {
            if tab == .draw {
                SignatureDrawView(drawing: $drawing,
                                  fontFamily: $fontFamily,
                                  color: $color)
            } else if tab == .image {
                SignatureImageView(isSet: $isImageSet, selection: $image)
            } else if tab == .type {
                SignatureTypeView(text: $text,
                                  fontFamily: $fontFamily,
                                  color: $color)
            }
        }.padding(.vertical)
    }
    
    private func extractImageAndHandle() {
        guard let tab = Tab(rawValue: selectedTab) else { return }
        let image: UIImage
        switch tab {
        case .draw:
            let path = drawing.cgPath
            let maxX = drawing.points.map { $0.x }.max() ?? 0
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxX, height: maxHeight))
            let uiImage = renderer.image { ctx in
                ctx.cgContext.setStrokeColor(color.uiColor.cgColor)
                ctx.cgContext.setLineWidth(lineWidth)
                ctx.cgContext.beginPath()
                ctx.cgContext.addPath(path)
                ctx.cgContext.drawPath(using: .stroke)
            }
            image = uiImage
        case .image:
            image = self.image
        case .type:
            let rendererWidth: CGFloat = 512
            let rendererHeight: CGFloat = 128
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: rendererWidth, height: rendererHeight))
            let uiImage = renderer.image { ctx in
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                let attrs = [NSAttributedString.Key.font: UIFont(name: fontFamily, size: bigFontSize)!,
                             NSAttributedString.Key.foregroundColor: color.uiColor,
                             NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                text.draw(with: CGRect(x: 0, y: 0, width: rendererWidth, height: rendererHeight), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            }
            image = uiImage
        }
        if saveSignature {
            if let data = image.pngData(),
               let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let filename = docsDir.appendingPathComponent("Signature-\(Date()).png")
                try? data.write(to: filename)
            }
        }
        onSave(image)
    }
    
    private func clear() {
        drawing = DrawingPath()
        image = UIImage()
        isImageSet = false
        text = ""
    }
    
    private enum Tab: Int {
        case draw = 0, image, type
    }
}

struct ColorPickerCompat: View {
    @Binding var selection: Color
    
    @State private var showPopover = false
    private let availableColors: [Color] = [.blue, .black, .red]
    
    var body: some View {
        if #available(iOS 14.0, *) {
            ColorPicker(selection: $selection) {
                EmptyView()
            }
        } else {
            Button(action: {
                showPopover.toggle()
            }, label: {
                colorCircle(selection)
            }).popover(isPresented: $showPopover) {
                ForEach(availableColors, id: \.self) { color in
                    Button(action: {
                        selection = color
                        showPopover.toggle()
                    }, label: {
                        colorCircle(color)
                    })
                }
            }
        }
    }
    
    private func colorCircle(_ color: Color) -> some View {
        Circle()
            .foregroundColor(color)
            .frame(width: 32, height: 32)
    }
}

struct FontFamilyPicker: View {
    @Binding var selection: String
    
    @State private var showPopover = false
    
    var body: some View {
        Button(action: {
            showPopover.toggle()
        }, label: {
            buttonLabel(selection, size: 16)
        }).popover(isPresented: $showPopover) {
            VStack(spacing: 20) {
                ForEach(fontFamlies, id: \.self) { fontFamily in
                    Button(action: {
                        selection = fontFamily
                        showPopover.toggle()
                    }, label: {
                        buttonLabel(fontFamily, size: 24)
                    })
                }
            }
        }
    }
    
    private func buttonLabel(_ fontFamily: String, size: CGFloat) -> Text {
        Text(placeholderText)
            .font(.custom(fontFamily, size: size))
            .foregroundColor(.black)
    }
}

struct SignatureDrawView: View {
    @Binding var drawing: DrawingPath
    @Binding var fontFamily: String
    @Binding var color: Color
    
    var body: some View {
        return ZStack {
            Color.white
            if drawing.isEmpty {
                Text(placeholderText)
                    .foregroundColor(.gray)
                    .font(.custom(fontFamily, size: bigFontSize))
            } else {
                DrawShape(drawingPath: drawing)
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(color)
            }
        }.frame(height: maxHeight)
        .gesture(DragGesture()
            .onChanged( { value in
                drawing.addPoint(value.location)
            }).onEnded( { value in
                drawing.addBreak()
            }))
        .overlay(RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray))
    }
}

struct DrawingPath {
    private(set) var points = [CGPoint]()
    private var breaks = [Int]()
    
    var isEmpty: Bool {
        points.isEmpty
    }
    
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    mutating func addBreak() {
        breaks.append(points.count)
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }

        }
        return path
    }
    
    var path: Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }

        }
        return path
    }
}

struct DrawShape: Shape {
    let drawingPath: DrawingPath
    
    func path(in rect: CGRect) -> Path {
        drawingPath.path
    }
}

struct SignatureImageView: View {
    @Binding var isSet: Bool
    @Binding var selection: UIImage
    
    @State private var showPopover = false
    
    var body: some View {
        Button(action: {
            showPopover.toggle()
        }) {
            if isSet {
                Image(uiImage: selection)
                    .resizable()
                    .frame(maxHeight: maxHeight)
            } else {
                ZStack {
                    Color.white
                    Text("Choose signature image")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }.frame(height: maxHeight)
                .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray))
            }
        }.popover(isPresented: $showPopover) {
            ImagePicker(selectedImage: $selection, didSet: $isSet)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage
    @Binding var didSet: Bool
    var sourceType = UIImagePickerController.SourceType.photoLibrary
     
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.navigationBar.tintColor = .clear
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
 
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let control: ImagePicker
        
        init(_ control: ImagePicker) {
            self.control = control
        }
     
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                control.selectedImage = image
                control.didSet = true
            }
            control.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SignatureTypeView: View {
    @Binding var text: String
    @Binding var fontFamily: String
    @Binding var color: Color
    
    var body: some View {
        TextField(placeholderText, text: $text)
            .disableAutocorrection(true)
            .font(.custom(fontFamily, size: bigFontSize))
            .foregroundColor(color)
    }
}

struct SignatureViewTest: View {
    @State private var image: UIImage? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("GO", destination: SignatureView(onSave: { image in
                    self.image = image
                }, onCancel: {
                    
                }))
                if image != nil {
                    Image(uiImage: image!)
                }
            }
        }
    }
}

struct SignatureView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureViewTest()
    }
}

extension Color {
    var uiColor: UIColor {
        if #available(iOS 14, *) {
            return UIColor(self)
        } else {
            let components = self.components
            return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
        }
    }
    
    private var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
}
