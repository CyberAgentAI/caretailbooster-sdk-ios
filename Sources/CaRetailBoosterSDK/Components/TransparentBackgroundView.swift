//
//  ClearBackgroundView.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/22.
//
import SwiftUI

@available(iOS 13.0, *)
struct TransparentBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return InnerView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
            superview?.superview?.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }
    }
}
