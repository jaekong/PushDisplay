import ImageFormats
import Foundation

extension Image<RGB> {
    public var inlineBytes: [460800 of UInt8] {
        assert(self.height == 160)
        assert(self.width == 960)
        
        return self.bytes.withBytes { span in
            return span.load(fromByteOffset: 0, as: [460800 of UInt8].self)
        }
    }
}

extension Image<RGBA> {
    static func load(pngFile: URL) throws -> Image<RGBA> {
        let data = try Data(contentsOf: pngFile)
        let image = try Image<RGBA>.loadPNG(from: [UInt8](data))
        return image
    }
}

extension Image where Pixel: RGBAConvertible {
    static func load(pngFile: URL) throws -> Image<Pixel> {
        let data = try Data(contentsOf: pngFile)
        let image = try Image<RGBA>.loadPNG(from: [UInt8](data))
        return image.convert(to: Pixel.self)
    }
}
