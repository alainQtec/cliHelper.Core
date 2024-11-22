function Show-Tree {
  [CmdletBinding(DefaultParameterSetName = "Path")]
  Param(
    [Parameter(Position = 0,
      ParameterSetName = "Path",
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [ValidateNotNullOrEmpty()]
    [alias("FullName")]
    [string[]]$Path = ".",

    [Parameter(Position = 0,
      ParameterSetName = "LiteralPath",
      ValueFromPipelineByPropertyName
    )]
    [ValidateNotNullOrEmpty()]
    [string[]]$LiteralPath,

    [Parameter(Position = 1)]
    [ValidateRange(0, 2147483647)]
    [int]$Depth = [int]::MaxValue,

    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$IndentSize = 3,

    [Parameter()]
    [alias("files")]
    [switch]$ShowItem,

    [Parameter(HelpMessage = "Display item properties. Use * to show all properties or specify a comma separated list.")]
    [alias("properties")]
    [string[]]$ShowProperty
  )
  DynamicParam {
    #define the InColor parameter if the path is a FileSystem path
    if ($PSBoundParameters.containsKey("Path")) {
      $here = $psboundParameters["Path"]
    } elseif ($PSBoundParameters.containsKey("LiteralPath")) {
      $here = $psboundParameters["LiteralPath"]
    } else {
      $here = (Get-Location).path
    }
    if (((Get-Item -Path $here).PSprovider.Name -eq 'FileSystem' ) -OR ((Get-Item -LiteralPath $here).PSprovider.Name -eq 'FileSystem')) {
      #define a parameter attribute object
      $attributes = New-Object System.Management.Automation.ParameterAttribute
      $attributes.HelpMessage = "Show tree and item colorized."

      #add an alias
      $alias = [System.Management.Automation.AliasAttribute]::new("ansi")

      #define a collection for attributes
      $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
      $attributeCollection.Add($attributes)
      $attributeCollection.Add($alias)

      #define the dynamic param
      $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("InColor", [Switch], $attributeCollection)

      #create array of dynamic parameters
      $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
      $paramDictionary.Add("InColor", $dynParam1)
      #use the array
      return $paramDictionary
    }
  }

  Begin {
    if (!$Path -and $psCmdlet.ParameterSetName -eq "Path") {
      $Path = Get-Location
    }

    if ($PSBoundParameters.containskey("InColor")) {
      $Colorize = $True
      $script:top = ($script:PSAnsiFileMap).where( { $_.description -eq 'TopContainer' }).Ansi
      $script:child = ($script:PSAnsiFileMap).where( { $_.description -eq 'ChildContainer' }).Ansi
    }
    function GetIndentString {
      [CmdletBinding()]
      Param([bool[]]$IsLast)

      #  $numPadChars = 1
      $str = ''
      for ($i = 0; $i -lt $IsLast.Count - 1; $i++) {
        $sepChar = if ($IsLast[$i]) { ' ' } else { '┃' }
        $str += "$sepChar"
        $str += " " * ($IndentSize - 1)
      }
      $teeChar = if ($IsLast[-1]) { '╰' } else { '┃' }
      $str += "$teeChar"
      $str += "━" * ($IndentSize - 1)
      $str
    }
    function ShowProperty() {
      [cmdletbinding()]
      Param(
        [string]$Name,
        [string]$Value,
        [bool[]]$IsLast
      )
      $indentStr = GetIndentString $IsLast
      $propStr = "${indentStr} $Name = "
      $availableWidth = $host.UI.RawUI.BufferSize.Width - $propStr.Length - 1
      if ($Value.Length -gt $availableWidth) {
        $ellipsis = '...'
        $val = $Value.Substring(0, $availableWidth - $ellipsis.Length) + $ellipsis
      } else {
        $val = $Value
      }
      $propStr += $val
      $propStr
    }
    function ShowItem {
      [CmdletBinding()]
      Param(
        [string]$Path,
        [string]$Name,
        [bool[]]$IsLast,
        [bool]$HasChildItems = $false,
        [switch]$Color,
        [ValidateSet("topcontainer", "childcontainer", "file")]
        [string]$ItemType
      )
      if ($IsLast.Count -eq 0) {
        if ($Color) {
          # Write-Output "$([char]0x1b)[38;2;0;255;255m$("$(Resolve-Path $Path)")$([char]0x1b)[0m"
          Write-Output "$($script:top)$("$(Resolve-Path $Path)")$([char]0x1b)[0m"
        } else {
          "$(Resolve-Path $Path)"
        }
      } else {
        $indentStr = GetIndentString $IsLast
        if ($Color) {
          #ToDo - define a user configurable color map
          Switch ($ItemType) {
            "topcontainer" {
              Write-Output "$indentStr$($script:top)$($Name)$([char]0x1b)[0m"
              #Write-Output "$indentStr$([char]0x1b)[38;2;0;255;255m$("$Name")$([char]0x1b)[0m"
            }
            "childcontainer" {
              Write-Output "$indentStr$($script:child)$($Name)$([char]0x1b)[0m"
              #Write-Output "$indentStr$([char]0x1b)[38;2;255;255;0m$("$Name")$([char]0x1b)[0m"
            }
            "file" {
              #only use map items with regex patterns
              foreach ($item in ($script:PSAnsiFileMap | Where-Object Pattern)) {
                if ($name -match $item.pattern -AND (!$done)) {
                  Write-Output "$indentStr$($item.ansi)$($Name)$([char]0x1b)[0m"
                  #set a flag indicating we've made a match to stop looking
                  $done = $True
                }
              }
              #no match was found so just write the item.
              if (!$done) {
                # No ansi match for $Name
                Write-Output "$indentStr$Name$([char]0x1b)[0m"
              }
            } #file
            Default {
              Write-Output "$indentStr$Name"
            }
          } #switch
        } #if color
        else {
          "$indentStr$Name"
        }
      }
      if ($ShowProperty) {
        $IsLast += @($false)

        $excludedProviderNoteProps = 'PSChildName', 'PSDrive', 'PSParentPath', 'PSPath', 'PSProvider'
        $props = @(Get-ItemProperty $Path -ea 0)
        if ($props[0] -is [pscustomobject]) {
          if ($ShowProperty -eq "*") {
            $props = @($props[0].psobject.properties | Where-Object { $excludedProviderNoteProps -notcontains $_.Name })
          } else {
            $props = @($props[0].psobject.properties |
                Where-Object { $excludedProviderNoteProps -notcontains $_.Name -AND $showproperty -contains $_.name })
          }
        }

        for ($i = 0; $i -lt $props.Count; $i++) {
          $prop = $props[$i]
          $IsLast[-1] = ($i -eq $props.count - 1) -and (!$HasChildItems)
          $showParams = @{
            Name   = $prop.Name
            Value  = $prop.Value
            IsLast = $IsLast
          }
          ShowProperty @showParams
        }
      }
    }
    function ShowContainer {
      [CmdletBinding()]
      Param (
        [string]$Path,
        [string]$Name = $(Split-Path $Path -Leaf),
        [bool[]]$IsLast = @(),
        [switch]$IsTop,
        [switch]$Color
      )
      if ($IsLast.Count -gt $Depth) { return }

      $childItems = @()
      if ($IsLast.Count -lt $Depth) {
        try {
          $rpath = Resolve-Path -LiteralPath $Path -ErrorAction stop
        } catch {
          Throw "Failed to resolve $path. This PSProvider and path may be incompatible with this command."
          #bail out
          return
        }
        $childItems = @(Get-ChildItem $rpath -ErrorAction $ErrorActionPreference | Where-Object { $ShowItem -or $_.PSIsContainer })
      }
      $hasChildItems = $childItems.Count -gt 0

      # Show the current container
      $sParams = @{
        path          = $Path
        name          = $Name
        IsLast        = $IsLast
        hasChildItems = $hasChildItems
        Color         = $Color
        ItemType      = If ($isTop) { "topcontainer" } else { "childcontainer" }
      }
      ShowItem @sParams

      # Process the children of this container
      $IsLast += @($false)
      for ($i = 0; $i -lt $childItems.count; $i++) {
        $childItem = $childItems[$i]
        $IsLast[-1] = ($i -eq $childItems.count - 1)
        if ($childItem.PSIsContainer) {
          $iParams = @{
            path   = $childItem.PSPath
            name   = $childItem.PSChildName
            isLast = $IsLast
            Color  = $color
          }
          ShowContainer @iParams
        } elseif ($ShowItem) {
          $unresolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($childItem.PSPath)
          $name = Split-Path $unresolvedPath -Leaf
          $iParams = @{
            Path     = $childItem.PSPath
            Name     = $name
            IsLast   = $IsLast
            Color    = $Color
            ItemType = "File"
          }
          ShowItem @iParams
        }
      }
    }
  }

  Process {
    if ($psCmdlet.ParameterSetName -eq "Path") {
      # In the -Path (non-literal) resolve path in case it is wildcarded.
      $resolvedPaths = @($Path | Resolve-Path | ForEach-Object { $_.Path })
    } else {
      # Must be -LiteralPath
      $resolvedPaths = @($LiteralPath)
    }
    foreach ($rpath in $resolvedPaths) {
      $showParams = @{
        Path  = $rpath
        Color = $colorize
        IsTop = $True
      }
      ShowContainer @showParams
    }
  }
}
