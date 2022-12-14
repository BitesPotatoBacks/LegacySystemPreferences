//
//  PaneManager.swift
//  Legacy System Preferences
//
//  Created by BitesPotatoBacks on 12/23/22.
//

import SwiftUI
import LocalAuthentication

let dirs = ["/Library/PreferencePanes", "/Library/LegacyPrefPanes"]

enum PaneSection: Int {
    case primary   = 0
    case secondary = 1
    case tertiary  = 3
    case none      = -1
}

struct PaneItem: Identifiable
{
    let id:           String
    let name:         String
    let image:        Image?
    let path:         String
    let pri:          UInt8
    var section:      PaneSection
    var visible:      Bool         = true
    var customizable: Bool         = true
    var keywords:     NSDictionary = NSDictionary()
}


class PaneManager: ObservableObject
{
    // MARK: - Properties
    @Published var collection: [PaneItem] = [PaneItem]() // main grid
    @Published var header:     [PaneItem] = [PaneItem]() // heading grid
    @Published var group:             Int
    @Published var hasItems:       [Bool] = [false,false,false]
    @Published var editing:          Bool = false
    @Published var query:          String = ""
    @Published var currentView: PaneView? = nil
    
    @Published var backready = false
    @Published var forwardready = false
    
    var accesslayer:      PaneAccessLayer = PaneAccessLayer()
    var forwardsHistory:         [PaneItem] = []
    var backwardsHistory:        [PaneItem] = []
    var currentPane:               PaneItem = PaneItem(id: "home", name: "", image: nil, path: "", pri: 0, section: .none)
    var hidden:                  [String] = []
    let exclusion:               [String] = [AppleBundleIDs.Classroom.rawValue,     // <-- excluding temporarily
                                             AppleBundleIDs.ClassKit.rawValue,      // <-- excluding temporarily
                                             AppleBundleIDs.DigiHubDiscs.rawValue,  // <-- excluding until can check IOKit
                                             AppleBundleIDs.FibreChannel.rawValue,  // <-- excluding until can check IOKit
                                             AppleBundleIDs.Profiles.rawValue]      // <-- excluding temporarily
    
    // MARK: - Lifecycle
    
    init() {
        group = UserDefaults.standard.object(forKey: "Group") != nil ? UserDefaults.standard.integer(forKey: "Group") : 0
        update(excluding: exclusion)
        
        if UserDefaults.standard.object(forKey: "Hidden") != nil {
            guard let array = UserDefaults.standard.array(forKey: "Hidden") as? [String] else { return }
            hidden = array
        }
        
        for item in collection {
            print(item.keywords)
        }
    }
    
    // MARK: - Methods
    
    func update(excluding: [String])
    {
        collection = [PaneItem]()
        header     = [PaneItem]()
        
        let fileManager = FileManager()
        do {
            for dir in dirs {
                let files = try fileManager.contentsOfDirectory(atPath: dir)
                for file in files {
                    if file.contains(".prefPane") {
                        var image: Image
                        var name:  String
                        var pri:   UInt8       = 255
                        var sect:  PaneSection = .tertiary
                        let path:  String      = "\(dir)/\(file)"
                        let id:    String      = Bundle(path: path)?.bundleIdentifier ?? "\(UUID())"
                        var keywords: NSMutableDictionary = NSMutableDictionary()
                        
                        // check exclude panes
                        if excluding.contains(id) {
                            print("Skipped \(file) due to exclusion")
                            continue
                        }
                        
                        // check device for battery
                        if id == AppleBundleIDs.Battery.rawValue || id == AppleBundleIDs.EnergySaver.rawValue {
                            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMPowerSource"))
                            let installed = IORegistryEntryCreateCFProperty(service, "BatteryInstalled" as CFString?, kCFAllocatorDefault, 0)
                            
                            if id == AppleBundleIDs.Battery.rawValue {
                                if installed?.takeRetainedValue() as! Bool == false {
                                    print("Skipped \(file), device has no battery")
                                    continue
                                }
                            } else {
                                if installed?.takeRetainedValue() as! Bool == true {
                                    print("Skipped \(file), device has a battery")
                                    continue
                                }
                            }
                        }
                        
                        
                        
                        // check device for biometrics
                        if id == AppleBundleIDs.TouchID.rawValue {
                            if !LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                                print("Skipped \(file), device has no biometrics")
                                continue
                            }
                        }
                        
                        // pull data from Info.plist
                        if let plist = Bundle(path: path)?.infoDictionary {
                            // check stored IOService
                            if let asset = plist["NSPrefPaneIOServiceToMatch"] as? String {
                                if IOServiceMatching(asset) == nil {
                                    print("Skipped \(file), pane does not apply to system abilities")
                                    continue
                                }
                            }
                            
                            // get proper name string for pane
                            if let asset = plist["CFBundleName"] as? String {
                                name = asset
                            } else if let asset = plist["NSPrefPaneIconLabel"] as? String {
                                name = asset
                            } else {
                                name = file.replacing(".prefPane", with: "")
                            }
                            
                            // get proper icon for pane
                            if let asset = plist["NSPrefPaneIconName"] as? String {
                                image = Image(asset, bundle: Bundle(path: path))
                            } else if let asset = plist["CFBundleIconFile"] as? String {
                                let url = URL(fileURLWithPath: "\(path)/Contents/Resources/\(asset)")
                                
                                if let nsimage = NSImage(contentsOf: url) {
                                    image = Image(nsImage: nsimage)
                                } else {
                                    print("Skipped \(file), no icon found")
                                    continue
                                }
                            } else if let asset = plist["NSPrefPaneIconFile"] as? String {
                                image = Image(asset, bundle: Bundle(path: path))
                            } else {
                                print("Skipped \(file), no icon found")
                                continue
                            }
                            
                            // collect search terms
                            if let asset = plist["NSPrefPaneSearchParameters"] as? String {
                                if let termsFile = Bundle(path: path)?.url(forResource: asset, withExtension: "searchTerms") {
                                    if let termDict = NSDictionary(contentsOf: termsFile) {
                                        for (_, value) in termDict {
                                            if let strngArr = (value as? [String:NSArray])?["localizableStrings"] {
                                                if strngArr.count > 0 {
                                                    if let strngs = (strngArr[0] as? NSDictionary) {
                                                        if strngs.value(forKey: "index") != nil && strngs.value(forKey: "title") != nil {
                                                            if strngs.value(forKey: "index") as! String != "" && strngs.value(forKey: "title") as! String != "" {
                                                                keywords.setValue(strngs["index"] as! String, forKey: strngs["title"] as! String)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        print("No search terms found for \(file)")
                                    }
                                } else {
                                    print("No search terms found for \(file)")
                                }
                                
                            } else {
                                print("No search terms found for \(file)")
                            }
                        } else {
                            print("Skipped \(file), no Info.plist found")
                            continue
                        }
                        
                        // generate the priority based on bundle ID
                        for i in AppleBundleIDs.allCases {
                            if id == i.rawValue {
                                for (key, value) in bundlePriority {
                                    if key.rawValue == id {
                                        pri = value
                                        break
                                    }
                                }
                            }
                        }
                        
                        // decide which section to render in
                        if pri != INT_MAX && pri > 17 {
                            sect = .secondary
                        } else if pri <= 17 {
                            sect = .primary
                        }
                        
                        // this isn't the cleanest but it works for the native panes with improper CFBundleNames
                        if id == AppleBundleIDs.Dock.rawValue {
                            name = "Dock & Menu Bar"
                        }
                        if id == AppleBundleIDs.Siri.rawValue {
                            name = "Siri"
                        }
                        if id == AppleBundleIDs.Security.rawValue {
                            name = "Security & Privacy"
                        }
                        if id == AppleBundleIDs.StartupDisk.rawValue {
                            name = "Startup\nDisk"
                        }
                        if id == AppleBundleIDs.StartupDisk.rawValue {
                            name = "Startup\nDisk"
                        }
                        if id == AppleBundleIDs.DateAndTime.rawValue {
                            name = "Data & Time"
                        }
                        
                        // specifaclly checking for Apple ID and Family Sharing,
                        // that way we may set them in the top grid
                        if id == AppleBundleIDs.AppleID.rawValue {
                            header.append(PaneItem(id: id, name: "Apple ID", image: image, path: path, pri: pri, section: sect, customizable: false, keywords: keywords))
                        } else if id == AppleBundleIDs.FamilySharing.rawValue {
                            header.append(PaneItem(id: id, name: "Family Sharing", image: image, path: path, pri: pri, section: sect, customizable: false, keywords: keywords))
                        } else {
                            // we also look for sw update beacuse the pane already has a CFBundleName,
                            // it just doesn't contain proper spaces and I'm not messing with that data
                            if id == AppleBundleIDs.SoftwareUpdate.rawValue {
                                collection.append(PaneItem(id: id, name: "Software Update", image: image, path: path, pri: pri, section: sect, keywords: keywords))
                            } else {
                                collection.append(PaneItem(id: id, name: name, image: image, path: path, pri: pri, section: sect, keywords: keywords))
                            }
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
        
        sort()
        checkItems()
    }
    
    
    func sort() {
        header = header.sorted(by: { $0.pri < $1.pri })
        
        if group == 0 {
            collection = collection.sorted(by: { $0.pri < $1.pri })
        } else {
            collection = collection.sorted(by: { $0.name < $1.name })
            for i in 0..<collection.count {
                collection[i].section = .primary
            }
        }
    }
    
    func checkItems() {
        hasItems = [false,false,false]
        
        for item in collection {
            if item.section == .tertiary {
                hasItems[2] = true
            }
            if item.section == .secondary {
                hasItems[1] = true
            }
            if item.section == .primary {
                hasItems[0] = true
            }
        }
    }

    
    func openPane(pane: PaneItem) -> Bool {
        accesslayer.loadPreference(pane.path)
        if accesslayer.applyViewFromPreference() {
            backwardsHistory.append(currentPane)

            currentPane = pane
            
            withAnimation(.linear(duration: 0.25)) {
                currentView = PaneView(pane: accesslayer.prefView)
            }
            NSApp.mainWindow?.title = pane.name
            backready = true
            
            return true
        }
        return false
    }
    
    func allPanes() -> [PaneItem] {
        var arr = header
        arr.append(contentsOf: collection)
        return arr.sorted(by: {$0.name < $1.name})
    }
    
    func returnSpotlightFocus(query: String, pane: PaneItem) -> Image {
        let panename  = pane.name.lowercased()
        let query     = query.lowercased()
        
        for (key, value) in pane.keywords {
            if let string = value as? String {
                let arr = string.split(separator: ", ")
                
                if panename == query {
                    return Image("spotlightmask")
                } else if panename.contains(query) {
                    return Image("spotlightdimmask")
                }
                
                for item in arr {
                    if item.lowercased() == query {
                        return Image("spotlightmask")
                    } else if item.lowercased().contains(query) {
                        return Image("spotlightdimmask")
                    }
                }
            }
            
            if let string = key as? String {
                if string.lowercased() == query {
                    return Image("spotlightmask")
                }
            }
        }
        
        return Image("filler")
    }
}
