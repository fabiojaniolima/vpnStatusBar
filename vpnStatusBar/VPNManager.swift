//
//  VPNManager.swift
//  vpnStatusBar
//
//  Created by Fabio J L Ferreira on 23/03/24.
//

import Foundation

class VPNManager {
    func checkVpnStatus(completion: @escaping (Bool) -> Void) {
        let pgrepTask = Process()
        pgrepTask.launchPath = "/usr/bin/pgrep"
        pgrepTask.arguments = ["openfortivpn"]
        pgrepTask.launch()
        pgrepTask.waitUntilExit()
        
        defer {
            pgrepTask.terminate()
        }
        
        let isSuccess = pgrepTask.terminationStatus == 0
        
        completion(isSuccess)
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
    func saveConfigPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "vpnConfigPath")
    }

    func loadConfigPath() -> String {
        return UserDefaults.standard.string(forKey: "vpnConfigPath") ?? ""
    }
}
