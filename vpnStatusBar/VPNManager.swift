//
//  VPNManager.swift
//  vpnStatusBar
//
//  Created by Fabio J L Ferreira on 23/03/24.
//

import Foundation

struct VPNConfiguration: Identifiable, Codable {
    var id = UUID()
    var nickname: String
    var filePath: String
}

class VPNManager {
    func checkVpnStatus(completion: @escaping (Bool) -> Void) {
        let process = Process()
        let pipe = Pipe()

        process.launchPath = "/usr/bin/pgrep"
        process.arguments = ["openfortivpn"]
        process.standardOutput = pipe
        process.standardError = pipe

        process.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Se houver algum output, isso significa que o pgrep encontrou o processo
            DispatchQueue.main.async {
                completion(!output.isEmpty)
            }
        }

        process.launch()
    }

    func disconnectVPN() {
        let killTask = Process()
        killTask.launchPath = "/usr/bin/sudo"
        killTask.arguments = ["/usr/bin/pkill", "-f", "openfortivpn"]
        killTask.launch()
        killTask.waitUntilExit()
        
        defer {
            killTask.terminate()
        }
        
        do {
            if killTask.terminationStatus == 0 {
                print("VPN encerrada!")
            } else if killTask.terminationStatus == 1 {
                print("Nenhum processo de VPN encontrado.")
            } else {
                print("Error!")
            }
        }
    }

    func connectVPN(withConfigPath configPath: String) {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.launchPath = "/usr/bin/sudo"
            task.arguments = ["/opt/homebrew/bin/openfortivpn", "-c", configPath]
            
            let pipe = Pipe()
            task.standardError = pipe
            
            // Redireciona a saída padrão para /dev/null para descartá-la
            let devNull = FileHandle(forWritingAtPath: "/dev/null")
            task.standardOutput = devNull
            
            task.launch()
            task.waitUntilExit()
            
            defer {
                pipe.fileHandleForReading.closeFile()
                task.terminate()
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    print(output)
                }
            }
        }
    }
}

extension VPNManager {
    func saveConfigurations(_ configurations: [VPNConfiguration]) {
        if let encoded = try? JSONEncoder().encode(configurations) {
            UserDefaults.standard.set(encoded, forKey: "vpnConfigurations")
        }
    }

    func loadConfigurations() -> [VPNConfiguration] {
        if let savedData = UserDefaults.standard.data(forKey: "vpnConfigurations"),
           let savedConfigurations = try? JSONDecoder().decode([VPNConfiguration].self, from: savedData) {
            return savedConfigurations
        }
        return []
    }

    func saveSelectedConfigurationId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: "selectedConfigurationId")
    }

    func loadSelectedConfigurationId() -> UUID? {
        if let idString = UserDefaults.standard.string(forKey: "selectedConfigurationId"),
           let id = UUID(uuidString: idString) {
            return id
        }
        return nil
    }
}
