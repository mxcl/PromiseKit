import AVFoundation.AVAudioSession

extension AVAudioSession {
    func requestRecordPermission() -> Promise<Bool> {
        return Promise { (fulfill, _) in self.requestRecordPermission(fulfill) }
    }
}
