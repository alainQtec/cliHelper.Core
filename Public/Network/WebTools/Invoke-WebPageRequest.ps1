﻿function Invoke-WebPageRequest {
    # For Version up to 5.1
    <#
    .ForwardHelpTargetName
        Microsoft.PowerShell.Utility\Invoke-WebRequest
    .ForwardHelpCategory
        Cmdlet
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=217035')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSAvoidUsingConvertToSecureStringWithPlainText", '', Justification = "Converting received plaintext token to SecureString")]
    param(
        [switch]
        ${UseBasicParsing},

        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri},

        [Microsoft.PowerShell.Commands.WebRequestSession]
        ${WebSession},

        [Alias('SV')]
        [string]
        ${SessionVariable},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty,

        [switch]
        ${UseDefaultCredentials},

        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint},

        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        ${Certificate},

        [string]
        ${UserAgent},

        [switch]
        ${DisableKeepAlive},

        [ValidateRange(0, 2147483647)]
        [int32]
        ${TimeoutSec},

        [System.Collections.IDictionary]
        ${Headers},

        [ValidateRange(0, 2147483647)]
        [int]
        ${MaximumRedirection},

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        ${Method},

        [uri]
        ${Proxy},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${ProxyCredential} = [System.Management.Automation.PSCredential]::Empty,

        [switch]
        ${ProxyUseDefaultCredentials},

        [Parameter(ValueFromPipeline = $true)]
        [System.Object]
        ${Body},

        [string]
        ${ContentType},

        [ValidateSet('chunked', 'compress', 'deflate', 'gzip', 'identity')]
        [string]
        ${TransferEncoding},

        [string]
        ${InputFile},

        [string]
        ${OutFile},

        [switch]
        ${PassThru}
    )

    begin {
        if ($Credential -and ($Credential -ne [System.Management.Automation.PSCredential]::Empty)) {
            $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)))
            $Headers["Authorization"] = "Basic $($SecureCreds)"
            $PSBoundParameters.Remove("Credential")
        }

        if ($InputFile) {
            $boundary = [System.Guid]::NewGuid().ToString()
            $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
            $fileName = Split-Path -Path $InputFile -Leaf
            $readFile = Get-Content -Path $InputFile -Encoding Byte
            $fileEnc = $enc.GetString($readFile)
            $PSBoundParameters["Body"] = @'
--{0}
Content-Disposition: form-data; name="file"; filename="{1}"
Content-Type: application/octet-stream

{2}
--{0}--

'@ -f $boundary, $fileName, $fileEnc

            $PSBoundParameters["Headers"]['X-Atlassian-Token'] = 'nocheck'
            $PSBoundParameters["ContentType"] = "multipart/form-data; boundary=`"$boundary`""
            $null = $PSBoundParameters.Remove("InputFile")
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Invoke-WebRequest', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
            if ($SessionVariable) {
                Set-Variable -Name $SessionVariable -Value (Get-Variable $SessionVariable).Value -Scope 1
            }
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

if ($PSVersionTable.PSVersion.Major -ge 6) {
    function Invoke-WebPageRequest {
        #require -Version 6
        <#
        .ForwardHelpTargetName
            Microsoft.PowerShell.Utility\Invoke-WebRequest
        .ForwardHelpCategory
            Cmdlet
        #>
        [CmdletBinding(DefaultParameterSetName = 'StandardMethod', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=217035')]
        param(
            [switch]
            ${UseBasicParsing},

            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [uri]
            ${Uri},

            [Microsoft.PowerShell.Commands.WebRequestSession]
            ${WebSession},

            [Alias('SV')]
            [string]
            ${SessionVariable},

            [switch]
            ${AllowUnencryptedAuthentication},

            [Microsoft.PowerShell.Commands.WebAuthenticationType]
            ${Authentication},

            [pscredential]
            [System.Management.Automation.CredentialAttribute()]
            ${Credential},

            [switch]
            ${UseDefaultCredentials},

            [ValidateNotNullOrEmpty()]
            [string]
            ${CertificateThumbprint},

            [ValidateNotNull()]
            [X509Certificate]
            ${Certificate},

            [switch]
            ${SkipCertificateCheck},

            [Microsoft.PowerShell.Commands.WebSslProtocol]
            ${SslProtocol},

            [securestring]
            ${Token},

            [string]
            ${UserAgent},

            [switch]
            ${DisableKeepAlive},

            [ValidateRange(0, 2147483647)]
            [int32]
            ${TimeoutSec},

            [System.Collections.IDictionary]
            ${Headers},

            [ValidateRange(0, 2147483647)]
            [int]
            ${MaximumRedirection},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'StandardMethodNoProxy')]
            [Microsoft.PowerShell.Commands.WebRequestMethod]
            ${Method},

            [Parameter(ParameterSetName = 'CustomMethod', Mandatory = $true)]
            [Parameter(ParameterSetName = 'CustomMethodNoProxy', Mandatory = $true)]
            [Alias('CM')]
            [ValidateNotNullOrEmpty()]
            [string]
            ${CustomMethod},

            [Parameter(ParameterSetName = 'CustomMethodNoProxy', Mandatory = $true)]
            [Parameter(ParameterSetName = 'StandardMethodNoProxy', Mandatory = $true)]
            [switch]
            ${NoProxy},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'CustomMethod')]
            [uri]
            ${Proxy},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'CustomMethod')]
            [pscredential]
            [System.Management.Automation.CredentialAttribute()]
            ${ProxyCredential},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'CustomMethod')]
            [switch]
            ${ProxyUseDefaultCredentials},

            [Parameter(ValueFromPipeline = $true)]
            [System.Object]
            ${Body},

            [string]
            ${ContentType},

            [ValidateSet('chunked', 'compress', 'deflate', 'gzip', 'identity')]
            [string]
            ${TransferEncoding},

            [string]
            ${InputFile},

            [string]
            ${OutFile},

            [switch]
            ${PassThru},

            [switch]
            ${PreserveAuthorizationOnRedirect},

            [switch]
            ${SkipHeaderValidation})

        begin {
            if ($Credential -and (!($Authentication))) {
                $PSBoundParameters["Authentication"] = "Basic"
            }
            if ($InputFile) {
                $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
                $FileStream = [System.IO.FileStream]::new($InputFile, [System.IO.FileMode]::Open)
                $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
                $fileHeader.Name = "file"
                $fileHeader.FileName = ([System.io.FileInfo]$InputFile).name
                $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
                $fileContent.Headers.ContentDisposition = $fileHeader
                $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
                $multipartContent.Add($fileContent)
                $PSBoundParameters["Headers"]['X-Atlassian-Token'] = 'nocheck'
                $PSBoundParameters["Body"] = $multipartContent
                $null = $PSBoundParameters.Remove("InputFile")
            }
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Invoke-WebRequest', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = { & $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            } catch {
                throw
            }
        }

        process {
            try {
                $steppablePipeline.Process($_)
                if ($SessionVariable) {
                    Set-Variable -Name $SessionVariable -Value (Get-Variable $SessionVariable).Value -Scope 1
                }
            } catch {
                throw
            }
        }

        end {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
    }
}
