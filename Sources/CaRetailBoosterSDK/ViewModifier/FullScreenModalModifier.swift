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
                let hostingController = UIHostingController(rootView: content())
                hostingController.modalPresentationStyle = .overFullScreen
                hostingController.presentationController?.delegate = context.coordinator
                uiViewController.present(hostingController, animated: false) {
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