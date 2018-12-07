//
//  UIDevice+Honqi.swift
//  HQFoundation
//
//  Created by HonQi on 6/11/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import Foundation

extension Namespace where T: UIDevice {
    // MARK : - Device info
    public static var deviceID: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { (identifier, element) in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    public static var deviceName: String { return UIDevice.current.name }
    
    public static var deviceScreen: String {
        let scale = UIScreen.main.scale
        return "\(UIScreen.main.bounds.width*scale) X \(UIScreen.main.bounds.height*scale)"
    }
    
    public static var isJailBroken: Bool {
        guard !isSimulator else { return false }
        
        let paths: [String] = ["/Applications/Cydia.app","/private/var/lib/apt/","/private/var/lib/cydia","/private/var/stash"]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) { return true }
        }
        
        let bash = fopen("/bin/bash", "r")
        if bash != nil { fclose(bash); return true }
        
        let path = String(format: "/private/%s", UUID().uuidString)
        do {
            try "isJail".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
    
    public static var deviceActiveDate: Date {
        let time = ProcessInfo.processInfo.systemUptime
        return Date(timeIntervalSinceNow: 0-time)
    }
    
    
    // MARK : - Network info
    public static var ipAddressWIFI: String? {
        return UIDevice.hq.ipAddress()
    }
    
    public static var ipAddressCell: String? {
        return UIDevice.hq.ipAddress(name: "pdp_ip0")
    }
    
    /// Default is wifi address
    public static func ipAddress(name: String = "en0") -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr?.pointee
            defer { ptr = ptr?.pointee.ifa_next }
            
            if String(cString: (interface?.ifa_name)!) != name { continue }
            
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    
    // MARK : - Device judge
    public static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    public static var isSimulator: Bool {
        #if TARGET_OS_SIMULATOR
        return true
        #else
        return false
        #endif
    }
    
    public static var isTV: Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }
    
    public static var isCarPlay: Bool {
        return UIDevice.current.userInterfaceIdiom == .carPlay
    }
    
    
    // MARK : - Storage Info
    public static var diskSpace: Int64 {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attrs[FileAttributeKey.systemSize] as! Int64
        } catch {
            return -1
        }
    }
    
    public static var disSpaceFree: Int64 {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attrs[FileAttributeKey.systemFreeSize] as! Int64
        } catch {
            return -1
        }
    }
    
    public static var diskSpaceUsed: Int64 {
        guard disSpaceFree > 0 || diskSpace > 0 else {
            return -1
        }
        return diskSpace - disSpaceFree
    }
}
