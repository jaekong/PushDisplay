// Reference: https://github.com/Ableton/push-interface

/// A struct containing values of a pixel in 24-bit RGB.
public struct Pixel: BitwiseCopyable {
    public var red, green, blue: UInt8
    
    /**
     Color value converted to BGR565.
     
     Push uses BGR565 format, consisting of 5 bits of blue, 6 bits of green, and 5 bits of red value in the following layout.
     
     | bit | 07 | 06 | 05 | 04 | 03 | 02 | 01 | 00 |
     | --- | --- | --- | --- | --- | --- | --- | --- | --- |
     | LSB (first sent) | g2 | g1 | g0 | r4 | r3 | r2 | r1 | r0 |
     | MSB (last sent) | b4 | b3 | b2 | b1 | b0 | g5 | g4 | g3 |
     
     This value has type of ``UInt64`` since this package computes four pixels at a time. See ``PixelGroup`` for more information.
     */
    @inlinable
    public var bgr565: UInt64 {
        let r: UInt64 = UInt64(red >> 3)
        let g: UInt64 = UInt64(green >> 2) << 5
        let b: UInt64 = UInt64(blue >> 3) << 11
        
        return r | g | b
    }
}

/// A struct containing values of four RGB24 pixels.
///
/// Ableton Push expects BGR565 pixel data with specific shaping pattern XORed. The shaping pattern is 32 bits, or two pixels long. This struct contains four RGB24 pixels, which is converted to 64 bits of display data, for optimal performance.
public struct PixelGroup: BitwiseCopyable {
    public let pixels: (Pixel, Pixel, Pixel, Pixel)
    
    @inlinable
    public var packet: UInt64 {
        let b0 = pixels.0.bgr565
        let b1 = pixels.1.bgr565 << 16
        let b2 = pixels.2.bgr565 << 32
        let b3 = pixels.3.bgr565 << 48
        return (b0 | b1 | b2 | b3) ^ 0xFFE7F3E7FFE7F3E7
    }
}

extension [460800 of UInt8] {
    /// Convert RGB24 image contained in this ``InlineArray`` to data Push expects.
    ///
    /// Push expects 327,680 bytes of display data each frame. 960×160 RGB24 image contained in this ``[460800 of UInt8]`` has to be converted into 960×160 BGR565 data, with 128 bytes of padding each row. Every pixel also gets XORed with a shaping pattern specified by Ableton.
    public var pushUSBPacket: [327680 of UInt8] {
        return [327680 of UInt8] { (output: inout OutputSpan) in
            for y in 0..<160 {
                for x in 0..<240 {
                    let byteCount = 2880 * y + (12 * x)
                    let pixels = span.bytes.extracting(byteCount..<(byteCount + 12)).unsafeLoad(as: PixelGroup.self)

                    output.append(pixels.packet)
                }
                
                // Ableton Push expects 128 bytes of padding after a row of pixels.
                output.append(repeating: 0, count: 128)
            }
        }
    }
}

extension OutputSpan<UInt8> {
    /// Append 64 bits of data to the ``OutputSpan``, in little-endian order.
    @inlinable
    mutating internal func append(_ bytes: UInt64) {
        let bytes = bitCast(bytes.littleEndian, to: [8 of UInt8].self)
        self.append(bytes[0])
        self.append(bytes[1])
        self.append(bytes[2])
        self.append(bytes[3])
        self.append(bytes[4])
        self.append(bytes[5])
        self.append(bytes[6])
        self.append(bytes[7])
    }
}
