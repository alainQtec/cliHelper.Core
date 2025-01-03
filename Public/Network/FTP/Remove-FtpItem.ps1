function Remove-FtpItem {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
  [CmdletBinding()]
  param ()

  process {
    #$sourceuri = 'ftp://proftpd:123@ubuntu64:21/estel/test.xlsx'
    $ftprequest = [System.Net.FtpWebRequest]::create($sourceuri)
    $ftpusername = "proftpd"
    $ftppassword = "123"
    $ftprequest.Credentials = New-Object System.Net.NetworkCredential($ftpusername, $ftppassword)
    $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
    $ftprequest.GetResponse()
  }
}