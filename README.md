# SwiftUIDigitalSignature

**Plug'n' play Digital Signatures in SwiftUI**.

## Features

* Freeform signature drawing.
* Selecting signature image.
* Typing signature in oblique font.
* Choose signature color.
* Choose signature font.
* Callback produces `UIImage` that you can save/use.
* iOS 13/14 compatible.

![Preview](https://github.com/globulus/swiftui-digital-signature/blob/main/Images/preview.gif?raw=true)

## Installation

This component is distributed as a **Swift package**.

## Sample usage

```swift
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
```
