//
//  SettingsView.swift
//  Finance
//
//  Created by Andrii Zuiok on 09.07.2020.
//  Copyright © 2020 Andrii Zuiok. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    //@State var isDarkMode: Bool = false
    
    var body: some View {
        
        VStack {
            Text("Settings")
            
            Toggle(isOn: Binding<Bool>(
                get: {
                    //debugPrint("get")
                    return UserDefaults.standard.integer(forKey: "LastStyle") != UIUserInterfaceStyle.light.rawValue },
                set: {
                    //debugPrint("set")
                    SceneDelegate.shared?.window!.overrideUserInterfaceStyle = $0 ? .dark : .light
                    UserDefaults.standard.setValue($0 ? UIUserInterfaceStyle.dark.rawValue : UIUserInterfaceStyle.light.rawValue, forKey: "LastStyle")
            }
            )) {
                Text("Set Dark Mode")
            }
        .padding()
            
            //            Toggle(isOn: $isDarkMode) {
            //                //Text("hello")
            //                Text(isDarkMode ? "Dark mode" : "Light Mode")
            //            }
            //            .padding()
            
        }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}