import Foundation
import ImageFormats
import Testing
@testable import PushKitDisplay

@Test @MainActor func displayTest() async throws {
    guard let imageURL = Bundle.module.url(forResource: "TestImage", withExtension: "png") else { fatalError() }
    let rgbImg = try! Image<RGB>.load(pngFile: imageURL)
    
    let testPacket = rgbImg.inlineBytes.pushUSBPacket
    
    guard var push = try Push() else {
        assertionFailure("Push is not connected.")
    }
    
    try push.open()
    
    while true {
        try await push.send(testPacket.span.bytes)
    }
}
