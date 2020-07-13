import Foundation

@objc(PhotoLibrary) class PhotoLibrary : CDVPlugin {

    lazy var concurrentQueue: DispatchQueue = DispatchQueue(label: "photo-library.queue.plugin", qos: DispatchQoS.utility, attributes: [.concurrent])
    
    override func pluginInitialize() {

        // Do not call PhotoLibraryService here, as it will cause permission prompt to appear on app start.

        URLProtocol.registerClass(PhotoLibraryProtocol.self)
        NSLog("-- PhotoLibrary --11")
        // NotificationCenter.default.addObserver(
        //     self,
        //     selector: #selector(self.onPause),
        //     name:   Notification.Name("CDVPluginHandleOpenURLNotification"),
        //     object: nil
        // )
        
        // print("is vpn \(checkVpn())")
//        UIScreen.main.brightness = CGFloat(1)

    }

    override func onMemoryWarning() {
        // self.service.stopCaching()
        NSLog("-- MEMORY WARNING --")
   
    }
    
    @objc func checkVpn(_ command: CDVInvokedUrlCommand)  {
 
        if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? Dictionary<String, Any>,
            let scopes = settings["__SCOPED__"] as? [String:Any] {
            for (key, _) in scopes {
                if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: false)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        return
      
    }
    @objc func onPause (notification: NSNotification) {
//        UIScreen.main.brightness = CGFloat(0.1)
        print("CDVViewWillDisappearNotification")
    }
    // Will sort by creation date
    @objc(getLibrary:) func getLibrary(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let options = command.arguments[0] as! NSDictionary
            
            
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let itemsInChunk = options["itemsInChunk"] as! Int
            let chunkTimeSec = options["chunkTimeSec"] as! Double
            let useOriginalFileNames = options["useOriginalFileNames"] as! Bool
            let includeAlbumData = options["includeAlbumData"] as! Bool
            let includeCloudData = options["includeCloudData"] as! Bool
            let includeVideos = options["includeVideos"] as! Bool
            let includeImages = options["includeImages"] as! Bool
            let maxItems = options["maxItems"] as! Int
            
            func createResult (library: [NSDictionary], chunkNum: Int, isLastChunk: Bool) -> [String: AnyObject] {
                let result: NSDictionary = [
                    "chunkNum": chunkNum,
                    "isLastChunk": isLastChunk,
                    "library": library
                ]
                return result as! [String: AnyObject]
            }

            let getLibraryOptions = PhotoLibraryGetLibraryOptions(thumbnailWidth: thumbnailWidth,
                                                                  thumbnailHeight: thumbnailHeight,
                                                                  itemsInChunk: itemsInChunk,
                                                                  chunkTimeSec: chunkTimeSec,
                                                                  useOriginalFileNames: useOriginalFileNames,
                                                                  includeImages: includeImages,
                                                                  includeAlbumData: includeAlbumData,
                                                                  includeCloudData: includeCloudData,
                                                                  includeVideos: includeVideos,
                                                                  maxItems: maxItems)

            service.getLibrary(getLibraryOptions,
                completion: { (library, chunkNum, isLastChunk) in

                    let result = createResult(library: library, chunkNum: chunkNum, isLastChunk: isLastChunk)
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
                    pluginResult!.setKeepCallbackAs(!isLastChunk)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            )
        }
    }
    
    @objc(getAlbums:) func getAlbums(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            
            let albums = service.getAlbums()
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: albums)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            
        }
    }
    
    @objc(getPhotosFromAlbum:) func getPhotosFromAlbum(_ command: CDVInvokedUrlCommand) {
        print("C getPhotosFromAlbum 0");
        concurrentQueue.async {
            
            print("C getPhotosFromAlbum 1");
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            print("C getPhotosFromAlbum 2");
            
            let service = PhotoLibraryService.instance
            
            let albumTitle = command.arguments[0] as! String
            
            let photos = service.getPhotosFromAlbum(albumTitle);
            
            print("C getPhotosFromAlbum 3");
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: photos)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            
        }
    }
    
    
    @objc(isAuthorized:) func isAuthorized(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: PhotoLibraryService.hasPermission())
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    
    @objc(getThumbnail:) func getThumbnail(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let photoId = command.arguments[0] as! String
            let options = command.arguments[1] as! NSDictionary
            let thumbnailWidth = options["thumbnailWidth"] as! Int
            let thumbnailHeight = options["thumbnailHeight"] as! Int
            let quality = options["quality"] as! Float

            service.getThumbnail(photoId, thumbnailWidth: thumbnailWidth, thumbnailHeight: thumbnailHeight, quality: quality) { (imageData) in

                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data, imageData!.mimeType])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: "Could not fetch the thumbnail")

                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId )

            }

        }
    }

    @objc(getPhoto:) func getPhoto(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let photoId = command.arguments[0] as! String

            service.getPhoto(photoId) { (imageData) in
                
                let pluginResult = imageData != nil ?
                    CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsMultipart: [imageData!.data, imageData!.mimeType])
                    :
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: "Could not fetch the image")

                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
            }

        }
    }

    @objc(getLibraryItem:) func getLibraryItem(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {
            
            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let service = PhotoLibraryService.instance
            let info = command.arguments[0] as! NSDictionary
            let mime_type = info["mimeType"] as! String
            service.getLibraryItem(info["id"] as! String, mimeType: mime_type, completion: { (base64: String?) in
                self.returnPictureData(callbackId: command.callbackId, base64: base64, mimeType: mime_type)
            })
        }
    }
    
    
    func returnPictureData(callbackId : String, base64: String?, mimeType: String?) {
        let pluginResult = (base64 != nil) ?
            CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsMultipart: [base64!, mimeType!])
            :
            CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Could not fetch the image")
        
        self.commandDelegate!.send(pluginResult, callbackId: callbackId)

    }
    
    
    @objc(stopCaching:) func stopCaching(_ command: CDVInvokedUrlCommand) {

        let service = PhotoLibraryService.instance

        service.stopCaching()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)

    }

    @objc(requestAuthorization:) func requestAuthorization(_ command: CDVInvokedUrlCommand) {

        let service = PhotoLibraryService.instance

        service.requestAuthorization({
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
        }, failure: { (err) in
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: err)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
        })

    }

    @objc(saveImage:) func saveImage(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String

            service.saveImage(url, album: album) { (libraryItem: NSDictionary?, error: String?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: libraryItem as! [String: AnyObject]?)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId	)
                }
            }

        }
    }

    @objc(saveVideo:) func saveVideo(_ command: CDVInvokedUrlCommand) {
        concurrentQueue.async {

            if !PhotoLibraryService.hasPermission() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PhotoLibraryService.PERMISSION_ERROR)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let service = PhotoLibraryService.instance

            let url = command.arguments[0] as! String
            let album = command.arguments[1] as! String
            

            service.saveVideo(url, album: album) { (_ libraryItem: NSDictionary?, error: String?) in
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: libraryItem as! [String: AnyObject]?)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId    )
                }
            }

        }
    }

}
