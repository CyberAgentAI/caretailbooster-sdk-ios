import SwiftUI

struct FullScreenModalModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let modalContent: () -> ModalContent

    func body(content: Content) -> some View {
        content
            .background(
                FullScreenModal(isPresented: $isPresented, content: modalContent)
            )
    }
}

extension View {
    func fullScreenModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        self.modifier(
            FullScreenModalModifier(isPresented: isPresented, modalContent: content)
        )
    }
}

struct FullScreenModal<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let content: () -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        context.coordinator.parentViewController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            if context.coordinator.modalViewController == nil {
                let modalContent = content()
                    .edgesIgnoringSafeArea(.all)
                
                let hostingController = UIHostingController(rootView: modalContent)
                hostingController.modalPresentationStyle = .overFullScreen
                hostingController.disableSafeArea()
                hostingController.presentationController?.delegate = context.coordinator
                uiViewController.present(hostingController, animated: true) {
                    context.coordinator.modalViewController = hostingController
                }
            }
        } else {
            if let modalVC = context.coordinator.modalViewController {
                modalVC.dismiss(animated: true) {
                    context.coordinator.modalViewController = nil
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var parent: FullScreenModal
        weak var parentViewController: UIViewController?
        weak var modalViewController: UIViewController?

        init(_ parent: FullScreenModal) {
            self.parent = parent
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.isPresented = false
            modalViewController = nil
        }
    }
}

extension UIHostingController {
    func disableSafeArea() {
        guard let viewClass = object_getClass(view) else { return }
        
        let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoreSafeArea")
        if let viewSubclass = NSClassFromString(viewSubclassName) {
            object_setClass(view, viewSubclass)
        } else {
            guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
            guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }
            
            if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                    return .zero
                }
                class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
            }
            
            objc_registerClassPair(viewSubclass)
            object_setClass(view, viewSubclass)
        }
    }
}