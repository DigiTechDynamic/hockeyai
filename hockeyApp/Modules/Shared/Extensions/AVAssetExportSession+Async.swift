import AVFoundation

// Async helper to await AVAssetExportSession completion
// Used across MediaCaptureKit and AIFeatureKit where `await export()` is called
extension AVAssetExportSession {
    func export() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.exportAsynchronously {
                continuation.resume()
            }
        }
    }
}

