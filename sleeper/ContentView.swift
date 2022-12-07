//
//  ContentView.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.11.2022.
//

import SwiftUI
import Cocoa

struct ContentView: View {
    @State private var wakeUp = Date.now

    var body: some View {

        VStack {
            DatePicker("Enter hibernation time: ", selection: $wakeUp,
                    displayedComponents: [.date, .hourAndMinute])
        }
                .environment(\.timeZone, TimeZone(secondsFromGMT: 3 * 60 * 60)!)
        Button("Go") {
            runCommand()
        }
                .padding()
    }

    func runCommand() -> Void {
        let scheduledDate = MyAPIFunctions.shortString(fromDate: wakeUp)

        let command: String = "pmset schedule sleep '" + scheduledDate + ":00'"
        let convertedPmsetCommand = command.replacingOccurrences(of: ".", with: "/")
        let nsScriptCommand = "do shell script \"" + convertedPmsetCommand + "\" with administrator privileges"

        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: nsScriptCommand)!
        scriptObject.executeAndReturnError(&error)
        if let errorDict = error {
            print("An error occured: \(error)")
        }
    }

    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
