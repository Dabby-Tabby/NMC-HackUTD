// ContentView.swift (watch target)
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var health = FakeHealthDataManager()
    @State private var selectedPerson: String? = nil
    
    // demo contact list — you could replace with discovered peers
    let people = ["Alex", "Jordan", "Sam", "Taylor"]
    let me = "Nick" // set sender name dynamically if needed
    
    var body: some View {
        VStack(spacing: 8) {
            Text("PulseLink").font(.headline)
            
            List {
                ForEach(people, id: \.self) { person in
                    HStack {
                        Text(person)
                        Spacer()
                        if selectedPerson == person {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPerson = person
                    }
                }
            }
            .frame(height: 120)
            
            HStack {
                Button("Ping") {
                    guard let target = selectedPerson else { return }
                    health.sendPing(to: target, senderName: me)
                    // local feedback to confirm send
                    WKInterfaceDevice.current().play(.directionUp)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    selectedPerson = nil
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 6)
            
            Spacer()
        }
        .padding()
    }
}
