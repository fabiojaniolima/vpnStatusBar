//
//  ContentView.swift
//  vpnStatusBar
//
//  Created by Fabio J L Ferreira on 23/03/24.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var configurations = VPNManager().loadConfigurations()
    @State private var selectedConfigurationId: UUID?
    @State private var newNickname: String = ""
    @State private var newConfigPath: String = ""
    @State private var isVpnConnected: Bool = false
    @State private var showAlert = false
    @State private var showAlertFieldsMissing = false
    @State private var alertMessage: String = ""
    @State private var editingConfiguration: VPNConfiguration?

    let vpnManager = VPNManager()

    var body: some View {
        VStack {
            TextField("Alias", text: $newNickname)
            TextField("VPN configuration file path", text: $newConfigPath)
            HStack {
                Button(editingConfiguration == nil ? "Add" : "Save change") {
                    
                    if newNickname.isEmpty || newConfigPath.isEmpty {
                        alertMessage = "Both Alias and VPN configuration file path are required."
                        showAlertFieldsMissing = true
                        return 
                    }
                    
                    if let editingConfig = editingConfiguration {
                        if let index = configurations.firstIndex(where: { $0.id == editingConfig.id }) {
                            configurations[index].nickname = newNickname
                            configurations[index].filePath = newConfigPath
                        }
                        editingConfiguration = nil
                    } else {
                        let newConfig = VPNConfiguration(nickname: newNickname, filePath: newConfigPath)
                        configurations.append(newConfig)
                    }
                    
                    newNickname = ""
                    newConfigPath = ""
                    vpnManager.saveConfigurations(configurations)
                }
                if editingConfiguration != nil {
                        Button("Dismiss") {
                            newNickname = ""
                            newConfigPath = ""
                            editingConfiguration = nil
                        }
                        .padding(.leading)
                    }
            }

            List(configurations) { config in
                HStack {
                    Button(action: { selectedConfigurationId = config.id }) {
                        Image(systemName: selectedConfigurationId == config.id ? "checkmark.circle.fill" : "circle")
                    }
                    Text(config.nickname)
                    Spacer()
                    Button("Edit") {
                        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
                            let editingConfig = configurations[index]
                            newNickname = editingConfig.nickname
                            newConfigPath = editingConfig.filePath
                            editingConfiguration = editingConfig // Entra no modo de edição
                        }
                    }
                    Button("Delete") {
                        configurations.removeAll { $0.id == config.id }
                        vpnManager.saveConfigurations(configurations)
                    }
                }
            }

            Button(isVpnConnected ? "Disconnect VPN" : "Connect VPN") {
                if let selectedId = selectedConfigurationId,
                   let config = configurations.first(where: { $0.id == selectedId }) {
                    if isVpnConnected {
                        vpnManager.disconnectVPN()
                    } else {
                        vpnManager.connectVPN(withConfigPath: config.filePath)
                    }
                    isVpnConnected.toggle()
                } else {
                    showAlert = true
                }
            }
            
            Button("Quit") {
                vpnManager.disconnectVPN()
                NSApp.terminate(nil)
            }
            .padding()
        }
        .frame(width: 480, height: 400)
        .padding()
        .alert("No Configuration Selected", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
            Text("Please select a VPN configuration before trying to connect.")
        }.alert("Required Fields Missing", isPresented: $showAlertFieldsMissing) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            selectedConfigurationId = vpnManager.loadSelectedConfigurationId()
            vpnManager.checkVpnStatus { isConnected in
                isVpnConnected = isConnected
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("VpnStatusChanged"), object: nil, queue: .main) { notification in
                    if let isConnected = notification.userInfo?["isConnected"] as? Bool {
                        isVpnConnected = isConnected
                    }
                }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("VpnStatusChanged"), object: nil)
        }
        .onChange(of: selectedConfigurationId) { newValue in
            if let newValue = newValue {
                vpnManager.saveSelectedConfigurationId(newValue)
            }
        }
    }
}

#Preview {
    ContentView()
}
