//
//  Foundation.swift
//  宋文通
//
//  Created by 宋文通 on 2019/8/7.
//  Copyright © 2019 newsdog. All rights reserved.
//

import Foundation
func dprint<T>(_ items:T, separator: String = " ", terminator: String = "\n",file:String = #file, function:String = #function, line:Int = #line) -> Void {
    #if DEBUG
    cprint(items, separator: separator, terminator: terminator,file:file, function:function, line:line)
    #endif
}
func cprint<T>(_ items: T,  separator: String = " ", terminator: String = "\n",file:String = #file, function:String = #function, line:Int = #line) -> Void {
    print("\((file as NSString).lastPathComponent)[\(line)], \(function): \(items)", separator: separator, terminator: terminator)
}
extension Data{
    public func utf8String() -> String {
        return String.init(data: self, encoding: .utf8) ?? "not utf8 string"
    }
}
func debugBlock(_ block:()->Void) -> Void {
    #if DEBUG
    block()
    #endif
}
extension Locale{
    static func en_US() -> Locale {
        return Locale.init(identifier: "en_US")
    }
    static func korea() -> Locale{
        return Locale.init(identifier: "ko-Kore_KR")
    }
}
extension Double{
    func numberObject() -> NSNumber {
        return NSNumber.init(value: self)
    }
}

extension DispatchQueue{
    public static func backgroundQueue()->DispatchQueue{
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    }
    public static func utilityQueue()->DispatchQueue{
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    }
    public static func userInitiatedQueue()->DispatchQueue{
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    }
    public static func userInteractiveQueue()->DispatchQueue{
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    }
    //安全同步到主线程
    public static func safeSyncInMain(execute work: @escaping @convention(block) () -> Swift.Void){
        let main:DispatchQueue = DispatchQueue.main
        if Thread.isMainThread {
            main.async(execute: work)
        }else{
            main.sync(execute: work)
        }
        //        print("425 wt test")
    }
    //异步回到主线程
    public static func asyncInMain(execute work: @escaping @convention(block) () -> Swift.Void){
        DispatchQueue.main.async(execute: work)
    }
    func perform( closure: @escaping () -> Void, afterDelay:Double) -> Void {
        let time = Int64(afterDelay * Double(NSEC_PER_SEC))
        let t:DispatchTime = DispatchTime.now() + Double(time) / Double(NSEC_PER_SEC)
        self.asyncAfter(deadline: t, execute: closure)
    }
}
enum URLSessionError:Error {
    case noURL
    case nodata
    case parseEror
    case none
    case ok
}
extension URLSession{
    @discardableResult
    open func dataTask<T:Codable>(withPath urlPath:String,complectionHandler: @escaping (T?,Error?) -> Void) -> URLSessionDataTask?{
        guard let url = URL.init(string: urlPath) else {
            DispatchQueue.main.async {
                complectionHandler(nil,URLSessionError.noURL)
            }
            return nil
        }
        return dataTask(with: url, completionHandler: complectionHandler)
    }
    @discardableResult
    open func dataTask<T:Codable>(with url: URL, completionHandler: @escaping (T?,Error?) -> Void ) -> URLSessionDataTask{
        return dataTask(with: URLRequest.init(url: url), completionHandler: completionHandler)
    }
    @discardableResult
    open func dataTask<T:Codable>(with request: URLRequest, completionHandler: @escaping (T?,Error?) -> Void) -> URLSessionDataTask{
        let task = dataTask(with: request) { (data, urlres, err) in
            if err != nil{
                completionHandler(nil,err)
            }
            guard let data = data else{
                DispatchQueue.main.async {
                    completionHandler(nil,URLSessionError.nodata)
                }
                return
            }
            do{
                let obj = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(obj,.none)
                }
                
            }catch{
                DispatchQueue.main.async {
                    completionHandler(nil,error)
                }
            }
        }
        task.resume()
        return task
    }
    
    @discardableResult
    static func useCacheElseLoadURLData(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var request = URLRequest.init(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data,res,err) in
            DispatchQueue.main.async {
                completionHandler(data,res,err)
            }
        })
        if let response = URLCache.shared.cachedResponse(for: request){
            let data = response.data
            completionHandler(data,response.response,nil)
            //            task.resume()
        }else{
            task.resume()
        }
        return task
    }
    
}



extension DateFormatter{
    //https://nsdateformatter.com
    static let globalFormatter:DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
extension Bundle{
    func appName() -> String {
        let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        return appName
    }
}
extension String{
    func localized(_ lang:String) ->String {

        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = Bundle(path: path!)

        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
    func convertTextToFullWidth()->String{
        if #available(iOS 9.0, *) {
            return self.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? ""
        } else {
            // Fallback on earlier versions
            return ""
        }
    }
    func converToHalfWidth() -> String {
        var dict = [String:String]()
        for (index,ele) in String.fullWidthPunctuation().enumerated(){
            for (index2,ele2) in String.halfWidthPunctuation().enumerated(){
                if index == index2{
                    dict["\(ele)"] = "\(ele2)"
                }
            }
        }
        var result = ""
        result = self
        for (k,v) in dict {
            result = result.replacingOccurrences(of: k, with: v)
        }
        return result
    }
    static func fullWidthPunctuation()->String{
        return "“”，。：¥"
    }
    static func halfWidthPunctuation()->String{
        return "\"\",.:¥"
    }
}
func convertCodableTypeToParameters<T:Codable,B>(_ t:T) -> B? {
    do{
        let data = try JSONEncoder().encode(t)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let j = json as? B{
            return j
        }
    }catch{
        return nil
    }
    return nil
}

