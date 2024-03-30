import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    let vpnManager = VPNManager()
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.action = #selector(togglePopover(_:))
        }
        
        popover.contentSize = NSSize(width: 480, height: 430)
        popover.behavior = .transient // Faz o popover fechar automaticamente quando o usuário clica fora dele
        popover.contentViewController = NSHostingController(rootView: ContentView())

        updateVpnStatus()

        timer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { [weak self] _ in
            self?.updateVpnStatus()
        }
    }

    private func updateVpnStatus() {
        vpnManager.checkVpnStatus { [weak self] isConnected in
            DispatchQueue.main.async {
                let imageName = isConnected ? "VpnIconConnected" : "VpnIconDisconnected"
                self?.statusItem?.button?.image = NSImage(named: imageName)
                
                NotificationCenter.default.post(name: NSNotification.Name("VpnStatusChanged"), object: nil, userInfo: ["isConnected": isConnected])
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
            if let button = statusItem?.button {
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
}

