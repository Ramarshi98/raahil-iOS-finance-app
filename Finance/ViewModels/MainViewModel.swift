//
//  UserData.swift
//  Finance
//
//  Created by Andrii Zuiok on 16.03.2020.
//  Copyright © 2020 Andrii Zuiok. All rights reserved.
//
import Foundation
import Combine
import SwiftUI

//MARK: - MAINVIEWMODEL
final class MainViewModel: ObservableObject, Identifiable {
    
    @Published var internetChecker: Bool {
        didSet {
            if let detailViewModel = self.detailViewModel {
                detailViewModel.internetChecker = self.internetChecker
            } else {
                self.chartViewModels.forEach{ $0.internetChecker = self.internetChecker}
            }
            
            if self.internetChecker {
                self.setRssSubscription()
                self.start()
            }
        }
    }

    @Published var chartViewModels: [ChartViewModel] = []

    
    @Published var symbolsLists: [SymbolsList] = [] {
        didSet {
            storeDefaultsFromSymbolLists(symbolsLists)
        }
//        willSet {
//            objectWillChange.send()
//        }
    }
    
    var detailViewModel: DetailChartViewModel?
    
    var currentRssUrl: URL?
    
    @Published var rss: [RSSItem] = []
    
    var rssSymbols: String {
        
        var array: [[String]] = []
        for list in self.symbolsLists {
            array.append(list.symbolsArray)
        }
        return array.flatMap { $0 }.joined(separator: ",")
        
    }
    private var rssURL: URL { WebService.makeRSSURL(symbol: self.rssSymbols ) }
    
    var rssSubscription: AnyCancellable?
    var rssSubject = PassthroughSubject<Void, WebServiceError>()
    
    init() {
        self.symbolsLists = [SymbolsList]()
        self.chartViewModels = [ChartViewModel]()
        self.internetChecker = true
    }
    
    init(from symbolsLists: [SymbolsList], internetChecker: Bool = true) {
        self.symbolsLists = symbolsLists
        self.internetChecker = internetChecker
        var chartViewModels: [ChartViewModel] = []
        for list in self.symbolsLists {
            for symbol in list.symbolsArray {
                let viewModel = ChartViewModel(withSymbol: symbol, internetChecker: self.internetChecker)
                
                if internetChecker {
                    viewModel.mode = list.isActive ? .active : .hidden
                } else {
                    viewModel.mode = list.isActive ? .waiting : .hidden
                }
                
                chartViewModels.append(viewModel)
            }
        }
        
        self.chartViewModels = chartViewModels
        
        setRssSubscription()
                
        if self.internetChecker {
            start()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillTDeactivate(notification:)), name: UIScene.willDeactivateNotification, object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(sceneDidActivate(notification:)), name: UIScene.didActivateNotification, object: nil)
        
        checkInternetAvailabilityIfChangedPreviousValue(internetChecker)
        
    }
    
    
    // ONLY FOR PRESENTATION:
    init(from JSON: String) {
        var chartViewModels: [ChartViewModel] = []
        self.symbolsLists = [SymbolsList(name: "My List", symbolsArray: [JSON], isActive: true)]
        let viewModel = ChartViewModel(withJSON: JSON)
        chartViewModels.append(viewModel)
        self.chartViewModels = chartViewModels
        self.internetChecker = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func modelWithId(_ id: String) -> ChartViewModel {
        
        for index in 0..<self.chartViewModels.count {
            if self.chartViewModels[index].id == id {
                return chartViewModels[index]
            }
        }
        return ChartViewModel(withSymbol: "")
    }
    
    @objc func sceneWillTDeactivate(notification: Notification) {
        
        self.chartViewModels.forEach {
            $0.storeFundamentalToDisc()
            if $0.mode == .active {
                $0.mode = .waiting
            }
            
        }
        
    }
    
    @objc func sceneDidActivate(notification: Notification) {
        
        //debugPrint("sceneDidActivate")
        
        self.chartViewModels.forEach {
            
            if self.internetChecker {
                if $0.mode == .waiting {
                    $0.mode = .active
                }
            }
        }
    }
    
    
    func setRssSubscription() {
        rssSubscription = rssSubject
            .flatMap { _ in WebService.makeNetworkQueryForXML(for: self.rssURL).receive(on: DispatchQueue.main)}
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    debugPrint(error)
                case .finished:
                    break
                }
            }) { rss in self.rss = rss }
    }
    
    func start() {
        rssSubject.send()
    }
    
    func cancelSubscriptions() {
        rssSubscription?.cancel()
    }
    
    
    func checkInternetAvailabilityIfChangedPreviousValue(_ previousValue: Bool) {
        let currentValue = InternetConnectionManager.isConnectedToNetwork()
        if !previousValue && currentValue {
            self.internetChecker = true
        } else if previousValue && !currentValue {
            self.internetChecker = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.checkInternetAvailabilityIfChangedPreviousValue(self.internetChecker)
        }
    }
    
    
    
    func addNewModelWithSimbol(_ symbol: String, from detailViewModel: DetailChartViewModel, toListWithIndex index: Int) {
        
        let newViewModel = ChartViewModel(withSymbol: symbol)
        
        if self.internetChecker {
            if self.symbolsLists[index].isActive {
                newViewModel.mode = .active
            } else {
                newViewModel.mode = .hidden
            }
        } else {
            newViewModel.mode = .waiting
        }
        
        newViewModel.fundamental = self.detailViewModel?.fundamental
        
        self.chartViewModels.append(newViewModel)
    }
    
    
    
}



