#!/usr/bin/env python
# -*- coding: utf-8 -*-

import ctypes
import ctypes.wintypes

sprintf = ctypes.cdll.msvcrt.sprintf
openClipboard = ctypes.windll.user32.OpenClipboard
emptyClipboard = ctypes.windll.user32.EmptyClipboard
registerClipboardFormat = ctypes.windll.user32.RegisterClipboardFormatW #unicode version api
registerClipboardFormat.argtypes = ctypes.wintypes.LPWSTR, # must, or CF_HTML would be wrong
registerClipboardFormat.restype = ctypes.wintypes.UINT
getClipboardData = ctypes.windll.user32.GetClipboardData
setClipboardData = ctypes.windll.user32.SetClipboardData
closeClipboard = ctypes.windll.user32.CloseClipboard
globalAlloc = ctypes.windll.kernel32.GlobalAlloc
globalFree = ctypes.windll.kernel32.GlobalFree
globalLock = ctypes.windll.kernel32.GlobalLock
globalUnlock = ctypes.windll.kernel32.GlobalUnlock
CF_HTML = registerClipboardFormat("HTML Format")
GMEM_DDESHARE = 0x2000 
CF_TEXT = 1

def HtmlClipboard():
    openClipboard(None) # Open Clip, Default task
    pcontents = getClipboardData(CF_TEXT)
    data = ctypes.c_char_p(pcontents).value
    emptyClipboard()
    strData = str(data)
    strLen = len(strData)
    hCd = globalAlloc(GMEM_DDESHARE, strLen+400)
    pchData = globalLock(hCd)
    sprintf(ctypes.c_char_p(pchData),
        "Version:0.9\r\n"
        "StartHTML:%08u\r\n"
        "EndHTML:%08u\r\n"
        "StartFragment:%08u\r\n"
        "EndFragment:%08u\r\n"
        "<html><body>\r\n"
        "<!--StartFragment -->\r\n"
        "%s\r\n"
        "<!--EndFragment-->\r\n"
        "</body></html>",
        97, 172+strLen, 111, 136+strLen,strData);
    globalUnlock(hCd)
    setClipboardData(CF_HTML,hCd)
    closeClipboard()
    globalFree(hCd)

def main():
    HtmlClipboard()

if __name__ == "__main__":
    main()
