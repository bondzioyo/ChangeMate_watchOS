//
//  ContentView.swift
//  ChangeMate Watch App
//
//  Created by Wojciech Świątek on 06/10/2023.
//

import SwiftUI
import UserNotifications
import Combine
import AVFoundation


struct ContentView: View {
    @State private var remainingTime = 0
    @State private var isTimerRunning = false
    @State private var selectedPlayers = 0
    @State private var selectedMinutes = 5
    @State private var selectedSeconds = 0
    @State private var timerCancellable: AnyCancellable?
    @State private var showRestartButton = false
    @State private var showContinueButton = false
    @State private var firstCountDownDone = false
    @State private var screen = 0
    @State private var currentPlayer = 1
    @State private var myTeamScore = 0
    @State private var rivalScore = 0
    @State private var ownScore = 0

    
    var body: some View {
        ScrollView {
            VStack{
                if screen != 2 {
                    Text("ChangeMate™")
                        .font(.title2)
                        .padding(.bottom, 5)
                }
                
                if screen == 0 {
                    VStack{
                        HStack{
                            Text("Liczba graczy: ")
                            Picker("Players", selection: $selectedPlayers) {
                                ForEach(1..<12) { players in
                                    Text("\(players)")
                                }
                            }
                                .frame(width: 60, height: 60)
                                .pickerStyle(WheelPickerStyle())
                        }
                            .padding(.bottom, 10)
                        Button("Dalej"){
                            nextScreen()
                        }
                            .buttonStyle(BorderedButtonStyle(tint: .green))
                    }
                }
                if screen == 1 {
                    VStack{
                        if(isTimerRunning){
                            Text("Zmiana na bramce za: ")
                            Text(formatTime(remainingTime))
                                .font(.caption)
                                .padding()
                                .foregroundStyle(.red)
                        }
                        else{
                            Text("Zmiana na bramce co: ")
                            HStack{
                                Picker("Minuty", selection: $selectedMinutes) {
                                    ForEach(0..<60) { minute in
                                        Text(String(format: "%02d", minute))
                                    }
                                }
                                    .frame(width: 60, height: 60)
                                    .pickerStyle(WheelPickerStyle())

                                Text(":")

                                Picker("Sekundy", selection: $selectedSeconds) {
                                    ForEach(0..<60) { second in
                                        Text(String(format: "%02d", second))
                                    }
                                }
                                    .frame(width: 60, height: 60)
                                    .pickerStyle(WheelPickerStyle())
                            }
                            .padding(.bottom, 10)
                        }
                        
                        HStack{
                            Button("Wróć"){
                                prevScreen()
                            }
                                .padding(.horizontal, 5)
                            
                            Button("Dalej"){
                                nextScreen()
                            }
                                .buttonStyle(BorderedButtonStyle(tint: .green))
                                .padding(.horizontal, 1)
                        }
                    }
                }
                if screen == 2 {
                    HStack{
                        Text("Nr bramkarza: \(currentPlayer)")
                        Button("➥"){
                            nextPlayer()
                        }.frame(width: 40)
                    }
                    
                    Text(formatTime(remainingTime))
                        .font(.largeTitle)
                        .padding()
                    if !isTimerRunning && !showRestartButton && !showContinueButton{
                        Button("Rozpocznij") {
                            startTimer()
                        }.buttonStyle(BorderedButtonStyle(tint: .green))
                    }
                    else if !isTimerRunning && showRestartButton {
                        Button("Powtórz") {
                            restartTimer()
                        }.buttonStyle(BorderedButtonStyle(tint: .green))
                    }
                    else if !isTimerRunning && showContinueButton {
                        VStack{
                            Button("Kontynuuj") {
                                startTimer()
                            }.buttonStyle(BorderedButtonStyle(tint: .green))
                            Spacer()
                            Button("Powtórz") {
                                restartTimer()
                            }.buttonStyle(BorderedButtonStyle(tint: .red))
                        }
                    }
                    else {
                        Button("Zatrzymaj") {
                            stopTimer()
                        }.buttonStyle(BorderedButtonStyle(tint: .green))
                    }
                    HStack{
                        Button("Wróć"){
                            prevScreen()
                        }
                            .padding(.horizontal, 5)
                        Button("Dalej"){
                            nextScreen()
                        }.buttonStyle(BorderedButtonStyle(tint: .green))
                            .padding(.horizontal, 1)
                    }
                }
                if screen == 3 {
                    VStack{
                        VStack{
                            Text("\(myTeamScore) ⚽️")
                                .font(.title2)
                            HStack{
                                Button("+"){
                                    addMyTeamGoal()
                                }
                                Button("-"){
                                    removeMyTeamGoal()
                                }
                            }
                        }.padding(.top,5).overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.green, lineWidth: 4)
                        )
                        Spacer()
                        VStack{
                            Text("\(rivalScore) ⚽️")
                                .font(.title2)
                            HStack{
                                Button("+"){
                                    addRivalGoal()
                                }
                                Button("-"){
                                    removeRivalGoal()
                                }
                            }
                        }.padding(.top,5).overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.red, lineWidth: 4)
                        )
                        Spacer()
                        VStack{
                            Text("\(ownScore) ⚽️")
                                .font(.title2)
                            HStack{
                                Button("+"){
                                    addMyOwnGoal()
                                }
                                Button("-"){
                                    removeMyOwnGoal()
                                }
                            }
                        }.padding(.top,5).overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.blue, lineWidth: 4)
                        )
                        Spacer()
                        Button("Wróć"){
                            prevScreen()
                        }.padding(.top,10)
                    }
                }
            }
        }
        .onChange(of: selectedMinutes, initial: true) { newSelectedMinutes, _ in
            setTimer()

        }
        .onChange(of: selectedSeconds, initial: true) { newSelectedSeconds, _ in
            setTimer()
        }
    }

    
    func formatTime(_ time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func setTimer() {
        remainingTime = selectedMinutes * 60 + selectedSeconds
    }

    
    func playAlarmSound() {
            guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
                return
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.play()
            } catch {
                print("Błąd odtwarzania dźwięku: \(error.localizedDescription)")
            }
        }
    
    func startTimer() {
            showContinueButton = false
            isTimerRunning = true
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink(receiveValue: { _ in
                    if remainingTime > 0 {
                        remainingTime -= 1
                    } else {
                        stopTimer()
                        showNotification()
                        playAlarmSound() // Odtwórz dźwięk alarmu
                        showRestartButton = true // Pokaż przycisk restartu
                    }
                })
        }
    
    func stopTimer() {
        if remainingTime > 0 {
            showContinueButton = true
        }
        firstCountDownDone = true
        isTimerRunning = false
        timerCancellable?.cancel()
    }
    
    func resetTimer() {
        if timerCancellable != nil {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        remainingTime = 0
    }
    func restartTimer() {
         remainingTime = selectedMinutes * 60 + selectedSeconds
         showRestartButton = false // Ukryj przycisk restartu
         startTimer() // Rozpocznij odliczanie ponownie
     }
    
    func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Czas minął!"
        content.body = "Czy chcesz zresetować licznik na kolejne 5 minut?"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Błąd powiadomienia: \(error.localizedDescription)")
            }
        }
    }
    
    func nextScreen(){
        screen += 1
    }
    func prevScreen(){
        screen -= 1
    }
    func nextPlayer(){
        if(selectedPlayers >= currentPlayer) { currentPlayer += 1 }
        else{ currentPlayer = 1 }
    }
    func addMyTeamGoal(){
        myTeamScore += 1
    }
     func addRivalGoal(){
        rivalScore += 1
     }
     func addMyOwnGoal(){
        ownScore += 1
        myTeamScore += 1
     }
    func removeMyTeamGoal(){
        if(myTeamScore > 0){myTeamScore -= 1}
    }
     func removeRivalGoal(){
         if(rivalScore > 0){rivalScore -= 1}
     }
     func removeMyOwnGoal(){
         if(ownScore > 0){ownScore -= 1}
         if(myTeamScore > 0){myTeamScore -= 1}
     }
}
