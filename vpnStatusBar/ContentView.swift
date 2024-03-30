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
            configurationInputFields
            configurationList
            connectionButton
            quitButton
        }
        .frame(width: 480, height: 400)
        .padding()
        .alert("Required Fields Missing", isPresented: $showAlertFieldsMissing) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("No Configuration Selected", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a VPN configuration before trying to connect.")
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: cleanUpView)
        .onChange(of: selectedConfigurationId, perform: saveSelectedConfiguration)
    }

    // UI Components

    var configurationInputFields: some View {
        VStack {
            TextField("Alias", text: $newNickname)
            TextField("VPN configuration file path", text: $newConfigPath)
            addButton
        }
    }

    var addButton: some View {
        HStack {
            Button(editingConfiguration == nil ? "Add" : "Save change") {
                addOrSaveConfiguration()
            }
            if editingConfiguration != nil {
                Button("Dismiss") {
                    clearInputFields()
                }
                .padding(.leading)
            }
        }
    }

    var configurationList: some View {
        List(configurations) { config in
            configurationRow(for: config)
        }
    }

    var connectionButton: some View {
        Button(isVpnConnected ? "Disconnect VPN" : "Connect VPN") {
            toggleVpnConnection()
        }
    }

    var quitButton: some View {
        Button("Quit") {
            vpnManager.disconnectVPN()
            NSApp.terminate(nil)
        }
        .padding()
    }

    // Actions

    private func addOrSaveConfiguration() {
        guard !newNickname.isEmpty, !newConfigPath.isEmpty else {
            alertMessage = "Both Alias and VPN configuration file path are required."
            showAlertFieldsMissing = true
            return
        }

        if let editingConfig = editingConfiguration, let index = configurations.firstIndex(where: { $0.id == editingConfig.id }) {
            configurations[index].nickname = newNickname
            configurations[index].filePath = newConfigPath
        } else {
            configurations.append(VPNConfiguration(nickname: newNickname, filePath: newConfigPath))
        }

        clearInputFields()
        vpnManager.saveConfigurations(configurations)
    }

    private func clearInputFields() {
        newNickname = ""
        newConfigPath = ""
        editingConfiguration = nil
    }

    private func configurationRow(for config: VPNConfiguration) -> some View {
        HStack {
            Button(action: { selectedConfigurationId = config.id }) {
                Image(systemName: selectedConfigurationId == config.id ? "checkmark.circle.fill" : "circle")
            }
            Text(config.nickname)
            Spacer()
            Button("Edit") {
                enterEditMode(for: config)
            }
            Button("Delete") {
                deleteConfiguration(config)
            }
        }
    }

    private func toggleVpnConnection() {
        guard let selectedId = selectedConfigurationId, let config = configurations.first(where: { $0.id == selectedId }) else {
            showAlert = true
            return
        }

        if isVpnConnected {
            vpnManager.disconnectVPN()
        } else {
            vpnManager.connectVPN(withConfigPath: config.filePath)
        }
        isVpnConnected.toggle()
    }

    // Utility Methods

    private func setupView() {
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

    private func cleanUpView() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("VpnStatusChanged"), object: nil)
    }

    private func saveSelectedConfiguration(_ newValue: UUID?) {
        if let newValue = newValue {
            vpnManager.saveSelectedConfigurationId(newValue)
        }
    }

    private func enterEditMode(for config: VPNConfiguration) {
        newNickname = config.nickname
        newConfigPath = config.filePath
        editingConfiguration = config
    }

    private func deleteConfiguration(_ config: VPNConfiguration) {
        configurations.removeAll { $0.id == config.id }
        vpnManager.saveConfigurations(configurations)
    }
}

#Preview {
    ContentView()
}
