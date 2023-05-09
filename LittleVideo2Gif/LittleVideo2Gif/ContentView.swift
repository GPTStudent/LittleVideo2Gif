//
//  ContentView.swift
//  LittleVideo2Gif
//
//  Created by Demo Stone on 2023/5/7.
//

import SwiftUI
import PhotosUI
import AVFoundation
import MobileCoreServices

struct ContentView: View {
    @State private var isVideoPickerShown = false
    @State private var videoURL: URL?
    @State private var gifURL: URL?
    
    var body: some View {
        VStack {
            if let gifURL = gifURL {
                Text("GIF Created")
                Button("Share GIF") {
                    shareGIF(url: gifURL)
                }
            } else {
                Text("Select a Video")
            }
            
            Button("Import Video") {
                isVideoPickerShown = true
            }
            .padding()
            .sheet(isPresented: $isVideoPickerShown) {
                VideoPicker(isPresented: $isVideoPickerShown, onVideoPicked: { url in
                    videoURL = url
                    createGIF(from: url)
                })
            }
        }
    }
    
    private func shareGIF(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    private func createGIF(from url: URL) {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let duration = CMTimeGetSeconds(asset.duration)
        var times: [NSValue] = []
        
        for i in stride(from: 0, to: duration, by: 0.1) {
            let time = CMTimeMakeWithSeconds(i, preferredTimescale: Int32(NSEC_PER_SEC))
            times.append(NSValue(time: time))
        }
        
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let gifURL = documentsURL.appendingPathComponent("output.gif")
            
            let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, kUTTypeGIF, times.count, nil)
            let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.1]]
            let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
            
            CGImageDestinationSetProperties(destination!, gifProperties as CFDictionary)
            
            for time in times {
                do {
                    let imageRef = try generator.copyCGImage(at: time.timeValue, actualTime: nil)
                    CGImageDestinationAddImage(destination!, imageRef, frameProperties as CFDictionary)
                } catch {
                    print("Error capturing frame at time \(time): \(error)")
                }
            }
            
            if CGImageDestinationFinalize(destination!) {
                self.gifURL = gifURL
            } else {
                print("Failed to create GIF")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onVideoPicked: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = [kUTTypeMovie as String]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.onVideoPicked(url)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
