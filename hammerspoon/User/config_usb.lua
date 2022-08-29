function usbDeviceCallback(data)
    hs.alert.show("test")
    print("usbDeviceCallback: "..hs.inspect(data))
end
  
usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
usbWatcher:start()