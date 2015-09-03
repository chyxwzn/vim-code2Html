#include <string.h>
#include <windows.h>
#include <stdio.h>

static int cfid = 0;

int GBKToUTF8(char *lpGBKStr, char *lpUTF8Str, int nUTF8StrLen)
{
    wchar_t *lpUnicodeStr = NULL;
    int nRetLen = 0;

    if (!lpGBKStr)
    {
        return 0;
    }

    //get the length to contain the unicode string.
    nRetLen = ::MultiByteToWideChar(CP_ACP, 0, lpGBKStr, -1, NULL, NULL);
    lpUnicodeStr = new WCHAR[nRetLen + 1];
    //convert to unicode
    nRetLen = ::MultiByteToWideChar(CP_ACP, 0, lpGBKStr, -1, lpUnicodeStr, nRetLen);

    if (!nRetLen)
    {
        return 0;
    }

    //get the length to contain the utf8 string.
    nRetLen = ::WideCharToMultiByte(CP_UTF8, 0, lpUnicodeStr, -1, NULL, 0, NULL,
                                    NULL);

    if (!lpUTF8Str)
    {
        if (lpUnicodeStr)
        {
            delete []lpUnicodeStr;
        }

        return nRetLen;
    }

    if (nUTF8StrLen < nRetLen)
    {
        if (lpUnicodeStr)
        {
            delete []lpUnicodeStr;
        }

        return 0;
    }

    //really convert to utf8 string.
    nRetLen = ::WideCharToMultiByte(CP_UTF8, 0, lpUnicodeStr, -1, lpUTF8Str,
                                    nUTF8StrLen, NULL, NULL);

    if (lpUnicodeStr)
    {
        delete []lpUnicodeStr;
    }

    return nRetLen;
}

int CopyHTML()
{
    // Open the clipboard...
    if (OpenClipboard(0))
    {
        // Get handle of clipboard object for ANSI text
        HANDLE hData = GetClipboardData(CF_TEXT);

        if (!hData)
        {
            printf("there is no CF_TEXT clipboard data\n");
            CloseClipboard();
            return -1;
        }

        // Lock the handle to get the actual text pointer
        char *html = static_cast<char *>(GlobalLock(hData));
        int nRetLen = 0;
        nRetLen = GBKToUTF8(html, NULL, NULL);
        char *htmlU8 = new char[nRetLen + 1];
        nRetLen = GBKToUTF8(html, htmlU8, nRetLen);

        if (!nRetLen)
        {
            printf("convert to utf8 failed\n");
        }

        htmlU8[nRetLen] = '\0';
        // Create temporary buffer for HTML header...
        char *buf = new char [400 + strlen(htmlU8)];

        if (!buf)
        {
            printf("buf NULL\n");
            CloseClipboard();
            delete [] htmlU8;
            return -1;
        }

        // Get clipboard id for HTML format...
        if (!cfid)
        {
            cfid = RegisterClipboardFormat("HTML Format");
        }

        // Create a template string for the HTML header...
        strcpy(buf,
               "Version:0.9\r\n"
               "StartHTML:00000000\r\n"
               "EndHTML:00000000\r\n"
               "StartFragment:00000000\r\n"
               "EndFragment:00000000\r\n"
               "<html><body>\r\n"
               "<!--StartFragment -->\r\n");
        // Append the HTML...
        strcat(buf, htmlU8);
        strcat(buf, "\r\n");
        // Finish up the HTML format...
        strcat(buf,
               "<!--EndFragment-->\r\n"
               "</body>\r\n"
               "</html>");
        // Now go back, calculate all the lengths, and write out the
        // necessary header information. Note, wsprintf() truncates the
        // string when you overwrite it so you follow up with code to replace
        // the 0 appended at the end with a '\r'...
        char *ptr = strstr(buf, "StartHTML");
        wsprintf(ptr + 10, "%08u", strstr(buf, "<html>") - buf);
        *(ptr + 10 + 8) = '\r';
        ptr = strstr(buf, "EndHTML");
        wsprintf(ptr + 8, "%08u", strlen(buf));
        *(ptr + 8 + 8) = '\r';
        ptr = strstr(buf, "StartFragment");
        wsprintf(ptr + 14, "%08u", strstr(buf, "<!--StartFrag") - buf);
        *(ptr + 14 + 8) = '\r';
        ptr = strstr(buf, "EndFragment");
        wsprintf(ptr + 12, "%08u", strstr(buf, "<!--EndFrag") - buf);
        *(ptr + 12 + 8) = '\r';
        // Empty what's in there...
        EmptyClipboard();
        // Allocate global memory for transfer...
        HGLOBAL hText = GlobalAlloc(GMEM_MOVEABLE | GMEM_DDESHARE, strlen(buf) + 4);
        // Put your string in the global memory...
        ptr = (char *)GlobalLock(hText);
        strcpy(ptr, buf);
        // Clean up...
        delete [] buf;
        delete [] htmlU8;
        GlobalUnlock(hText);
        SetClipboardData(cfid, hText);
        CloseClipboard();
        // Free memory...
        GlobalFree(hText);
    }
}

int main(int argc, char *argv[])
{
    CopyHTML();
    return 0;
}
