//
//  ContentView.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.11.2022.
//

import SwiftUI

struct ContentView: View {
    @State private var wakeUp = Date.now

    var body: some View {
        
        VStack {
            DatePicker("Enter hibernation time: ", selection: $wakeUp,
                       displayedComponents: [.date, .hourAndMinute])
                }.environment(\.timeZone, TimeZone(secondsFromGMT: 3*60*60)!)
        Button("Go") {
            runCommand()
        }
        .padding()
    }
//    true -    sudo pmset schedule sleep "11/13/22 03:30:00"
//    false -   sudo pmset schedule sleep "18/11/2022 17:50:00"
    func runCommand() -> Void {
        let scheduledDate = MyAPIFunctions.shortString(fromDate: wakeUp)

        let command: String = "pmset schedule sleep \"" + scheduledDate + ":00\""
        let convertedPmsetCommand = command.replacingOccurrences(of: ".", with: "/")
        print(convertedPmsetCommand)
//        shell(convertedPmsetCommand)

//do shell script "pmset schedule sleep "12/01/22 16:19:00"" with administrator privileges
        var nsScriptCommand = "do shell script \"" + convertedPmsetCommand + "\" with administrator privileges"
        print(nsScriptCommand)
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: nsScriptCommand)!
        var eventResult = scriptObject.executeAndReturnError(&error)
        print(error)
//        print(eventResult)

//        if let scriptObject = NSAppleScript(source: myAppleScript) {
//            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
//                    &error) {
//                print(output.stringValue)
//            } else if (error != nil) {
//                print("error: \(error)")
//            }
//        }

        print("command executed...")
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
