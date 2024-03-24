//
//  ContentView.swift
//  vpnStatusBar
//
//  Created by Fabio J L Ferreira on 23/03/24.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var configPath: String = VPNManager().loadConfigPath()
    @State private var isVpnConnected: Bool = false
    let vpnManager = VPNManager()

    var body: some View {
        VStack {
            TextField("Path to VPN config file", text: $configPath)
                .padding()
                .onChange(of: configPath) {
                    vpnManager.saveConfigPath(configPath)
                }

            Button(isVpnConnected ? "Disconnect VPN" : "Connect VPN") {
                if isVpnConnected {
                    vpnManager.disconnectVPN()
                } else {
                    vpnManager.connectVPN(withConfigPath: configPath)
                }
            }
            .padding()
            
            Button("Quit") {
                vpnManager.disconnectVPN()
                NSApp.terminate(nil)
            }
            .padding()
        }
        .frame(width: 400, height: 200)
        .padding()
        .onAppear {
            vpnManager.checkVpnStatus { isConnected in
                isVpnConnected = isConnected
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("VpnStatusChanged"), object: nil, queue: .main) { notification in
                    if let userInfo = notification.userInfo, let isConnected = userInfo["isConnected"] as? Bool {
                        self.isVpnConnected = isConnected
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
