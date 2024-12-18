function Get-WebTemplateEditableRegion {
  <#
    .Synopsis
        Extracts out the editable regions from a dynamic web template
    .Description
        Determines what portions of a document are editable
    .Example
        Get-ChildItem -Filter *.dwt | Get-WebTemplateEditableRegion
    .Link
        Get-Web
    #>
  [CmdletBinding(DefaultParameterSetName = 'FilePath')]
  [OutputType([PSObject])]
  param(
    # The path to a document
    [Parameter(Mandatory = $true,
      ParameterSetName = 'FilePath',
      ValueFromPipelineByPropertyName = $true)]
    [Alias('Fullname')]
    [String]
    $FilePath,


    # The content of the document
    [Parameter(Mandatory = $true,
      Position = 0,
      ParameterSetName = 'DynamicWebTemplate',
      ValueFromPipelineByPropertyName = $true)]
    [Alias('DWT')]
    [String]
    $DynamicWebTemplate
  )



  process {
    if ($PSCmdlet.ParameterSetName -eq 'FilePath') {

      $resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($FilePath)

      if (!$resolvedPath) { return }

      if ([IO.file]::Exists($resolvedPath)) {
        $text = [IO.File]::ReadAllText($resolvedPath)
        $rInf = Get-WebTemplateEditableRegion -DynamicWebTemplate $text -ErrorAction SilentlyContinue
        $regionInfo =
        New-Object PSObject -Property @{
          FilePath  = "$resolvedPath"
          Region    = $rInf | Select-Object -ExpandProperty Region
          MatchInfo = $rInf | Select-Object -ExpandProperty MatchInfo
        }
        $regionInfo.pstypenames.clear()
        $regionInfo.pstypenames.add('DWTInfo')
        $regionInfo

      }



    } elseif ($PSCmdlet.ParameterSetName -eq 'DynamicWebTemplate') {

      # Find the start of the HTML tag, and try to convert to XHTML.
      # If this fails, present an error to the user.  Be sure to ignore the case, because we
      # really don't care
      $htmlStart = $DynamicWebTemplate.IndexOf("<html", [StringComparison]::OrdinalIgnoreCase)
      if (!$htmlStart) {
        Write-Error "This content does not appear to be an HTML document.  It does not have a <html> tag."
        return
      }


      $r = New-Object Text.RegularExpressions.Regex ("<!--\s#BeginEditable\s`"(?<region>\w+)`""), ("Singleline", "IgnoreCase")
      $results = @($r.Matches($DynamicWebTemplate))
      foreach ($r in $results) {
        $regionInfo =
        New-Object PSObject -Property @{
          Region    = $r.Groups[1].Value
          MatchInfo = $r
        }
        $regionInfo.pstypenames.clear()
        $regionInfo.pstypenames.add('DWTInfo')
        $regionInfo
      }
    }
  }
}
