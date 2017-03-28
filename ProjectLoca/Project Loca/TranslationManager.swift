//
//  TranslationManager.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/17/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

class TranslationManager: NSObject, TranslationDelegate, LanguageSetupDelegate {
    
    static let sharedInstance = TranslationManager()
    var translatedLanguage: String?
    let finshedTranslation = Notification.Name.init(rawValue: "finishedTranslation")

    
    override init() {
        super.init()
        DataInterface.translationDelegate = self
        HomeViewController.languageSetupDelegate = self
    }
    
    func didReceiveText(input: String) {
        YandexAPICall(word: input)
    }
    
    func didChangeLanguage(language: String) {
        self.translatedLanguage = language
    }
    
    func YandexAPICall(word: String) -> String{
        
        let toTranslate = word.replacingOccurrences(of: " ", with: "+")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        var baseURL: String = "https://translate.yandex.net/api/v1.5/tr.json/translate"
        let key: String = "trnsl.1.1.20170206T214522Z.d28a904e6f61ba84.aac82dfc3243245cfe6429478e1e72257716f354"
        
        let inCode = "English"
        var outCode = ""
        if self.translatedLanguage == nil {
            outCode = languages["Spanish"]!
        } else {
            outCode = languages[translatedLanguage!]!
        }
        
        print("in code is \(inCode)")
        print("out code is \(outCode)")
        
        guard let tokenURL: URL = URL(string: "\(baseURL)?key=\(key)&lang=\(inCode)-\(outCode)&text=\(toTranslate)") else{
            print("error making tokenURL")
            return "error"
        }
        print(tokenURL)
        var urlRequest = URLRequest(url: tokenURL)
        urlRequest.httpMethod = "GET"
        print("url request: \(urlRequest)")
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if response != nil{
                print("response: \(response)")
            }
            if data != nil{
                print("data: \(data)")
            }
            if (error != nil){
                print("error at 1\(error)")
            }else{
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: Any]
                    print("we got the json: \(json)")
                    let word = (json["text"] as! [String]).joined()
                    DispatchQueue.main.async(){
                        DataInterface.sharedInstance.translatedImageLabels.append(word)
                        NotificationCenter.default.post(name: self.finshedTranslation, object: nil)
                    }
                    
                }catch{
                    print("error in JSON serialization: \(error)")
                }
            }
        }
        print("executing api call")
        task.resume()
        return "loading"
    }
    
    var languages: [String: String] = [
        "English"	:"en",	"Chinese" : "zh",
        "Spanish"	:"es",
        "Azerbaijan":	"az",	"Maltese":	"mt",
        "Albanian":	"sq",	"Macedonian":	"mk",
        "Amharic":	"am",	"Maori"		:"mi",
        "Marathi"	:"mr",
        "Arabic"	:"ar",	"Mari"		:"mhr",
        "Armenian":	"hy",	"Mongolian"	:"mn",
        "Afrikaans":"af",	"German"	:"de",
        "Basque"	:"eu",	"Nepali"	:"ne",
        "Bashkir"	:"ba",	"Norwegian"	:"no",
        "Belarusian":"be",	"Punjabi"	:"pa",
        "Bengali"	:"bn",	"Papiamento":"pap",
        "Bulgarian"	:"bg",	"Persian"	:"fa",
        "Bosnian"	:"bs",	"Polish"	:"pl",
        "Welsh"		:"cy",	"Portuguese":"pt",
        "Hungarian"	:"hu",	"Romanian"	:"ro",
        "Vietnamese":	"vi",	"Russian":"ru",
        "Haitian (Creole)":	"ht",	"Cebuano":"ceb",
        "Galician"	:"gl",	"Serbian"	:"sr",
        "Dutch"		:"nl",	"Sinhala"	:"si",
        "Hill Mari"	:"mrj",	"Slovakian"	:"sk",
        "Greek"		:"el",	"Slovenian"	:"sl",
        "Georgian"	:"ka",	"Swahili"	:"sw",
        "Gujarati"	:"gu",	"Sundanese" :"su",
        "Danish"	:"da",	"Tajik"		:"tg",
        "Hebrew"	:"he",	"Thai"		:"th",
        "Yiddish"	:"yi",	"Tagalog"	:"tl",
        "Indonesian":"id",	"Tamil"		:"ta",
        "Irish"		:"ga",	"Tatar"		:"tt",
        "Italian"	:"it",	"Telugu"	:"te",
        "Icelandic"	:"is",	"Turkish"	:"tr",
        "Udmurt"	:"udm",
        "Kazakh"	:"kk",	"Uzbek"		:"uz",
        "Kannada"	:"kn",	"Ukrainian"	:"uk",
        "Catalan"	:"ca",	"Urdu"		:"ur",
        "Kyrgyz"	:"ky",	"Finnish"	:"fi",
        "French"	:"fr",
        "Korean"	:"ko",	"Hindi"		:"hi",
        "Xhosa"		:"xh",	"Croatian"	:"hr",
        "Latin"		:"la",	"Czech"		:"cs",
        "Latvian"	:"lv",	"Swedish"	:"sv",
        "Lithuanian":"lt",	"Scottish"	:"gd",
        "Luxembourgish":"lb","Estonian" :"et",
        "Malagasy"	:"mg",	"Esperanto"	:"eo",
        "Malay"		:"ms",	"Javanese"	:"jv",
        "Malayalam"	:"ml",	"Japanese"	:"ja"
    ]
}
