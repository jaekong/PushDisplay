import USB

/// A class representing an Ableton Push device.
public struct Push: ~Copyable {
    /// USB Vendor ID of Ableton.
    static public let abletonVendorID: UInt16 = 0x2982 // 10626
    /// USB Endpoint of Push's display interface.
    static public let endpoint: USBEndpoint = USBEndpoint(address: 0x01, direction: .output)
    
    /// Frame header bytes, sent before actual frame data.
    static public let frameHeader: [16 of UInt8] = [
        0xFF, 0xCC, 0xAA, 0x88,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    ]
    
    /// USB interface.
    static private let usb = try! USB()
    
    /// USB serial number of this Push.
    ///
    /// This is not the same as product serial number found in Push's options.
    public let serialNumber: String?
    
    /// USB device interface.
    private var device: USBDevice
    
    /// Find and initialize a connected Push device.
    ///
    /// Defaults to a connected Push 3 device. Returns `nil` if no device matching the options was found.
    public init?(model: Version = .push3, serialNumber: String? = nil) throws(USBError) {
        let devices = try? Self.usb.getDevices { device in
            return if let serialNumber {
                device.productID == model.rawValue &&
                device.vendorID == Push.abletonVendorID &&
                device.serialNumber == serialNumber
            } else {
                device.productID == model.rawValue &&
                device.vendorID == Push.abletonVendorID
            }
        }
        
        guard var devices else { return nil }
        
        guard let device = devices.popLast() else { return nil }
        
        self.serialNumber = device.serialNumber
        self.device = consume device
        
        try self.device.open()
    }
    
    private init(device: consuming USBDevice) throws(USBError) {
        self.serialNumber = device.serialNumber
        self.device = consume device
        try self.device.open()
    }
    
    /// Find and initialize all Push devices matching provided configurations.
    static public func getAllDevices(models: Set<Version> = [.push2, .push3], serialNumber: String? = nil) throws(USBError) -> UniqueArray<Push> {
        var devices = try usb.getDevices { device in
            guard let push = Version(rawValue: device.productID) else { return false }
            
            return if let serialNumber {
                models.contains(push) &&
                device.vendorID == Push.abletonVendorID &&
                device.serialNumber == serialNumber
            } else {
                models.contains(push) &&
                device.vendorID == Push.abletonVendorID
            }
        }
        
        var result: UniqueArray<Push> = .init()
        
        while let device = devices.popLast() {
            result.append(try Push(device: consume device))
        }
        
        return result
    }
    
    deinit {
        self.device.close()
    }
    
    /// Open and connect to the Push.
    mutating public func open() throws(USBError) {
        try self.device.claim()
    }
    
    /// Release the connection.
    mutating public func close() {
        self.device.release()
    }
    
    public func send(_ data: borrowing RawSpan) throws(USBError) {
        try device.bulkTransfer(Push.frameHeader.span.bytes, to: Push.endpoint)
        try device.bulkTransfer(data, to: Push.endpoint)
    }
    
    @concurrent
    public func send(_ data: borrowing RawSpan) async throws(USBError) {
        try await device.bulkTransfer(Push.frameHeader.span.bytes, to: Push.endpoint)
        try await device.bulkTransfer(data, to: Push.endpoint)
    }
    
    public func send(_ data: borrowing [327680 of UInt8]) throws(USBError) {
        try device.bulkTransfer(Push.frameHeader.span.bytes, to: Push.endpoint)
        try device.bulkTransfer(data.span.bytes, to: Push.endpoint)
    }
    
    @concurrent
    public func send(_ data: borrowing [327680 of UInt8]) async throws(USBError) {
        try await device.bulkTransfer(Push.frameHeader.span.bytes, to: Push.endpoint)
        try await device.bulkTransfer(data.span.bytes, to: Push.endpoint)
    }
    
    public func send(_ data: borrowing [460800 of UInt8]) throws(USBError) {
        try device.bulkTransfer(Push.frameHeader.span.bytes, to: Push.endpoint)
        try device.bulkTransfer(data.pushUSBPacket.span.bytes, to: Push.endpoint)
    }
    
    @concurrent
    public func send(_ data: borrowing [460800 of UInt8]) async throws(USBError) {
        try await device.bulkTransfer(Push.frameHeader.span.bytes, to: Push.endpoint)
        try await device.bulkTransfer(data.pushUSBPacket.span.bytes, to: Push.endpoint)
    }
    
    /// Versions of supported Push devices.
    public enum Version: UInt16 {
        case push2 = 0x1967 // 6503
        case push3 = 0x1969 // 6505
    }
}
