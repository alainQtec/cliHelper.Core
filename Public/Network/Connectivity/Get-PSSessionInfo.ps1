﻿function Get-PSSessionInfo {
  # .SYNOPSIS
  #  Gets details about the current PowerShell session
  [cmdletbinding()]
  [Alias("gsin")]
  [OutputType("PSSessionInfo")]
  Param()

  begin {
    Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
  }

  process {
    Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting information for PSSession $PID "

    $proc = Get-Process -Id $PID
    #get the command line from CIM if in Windows PowerShell
    if ($PSEdition -eq 'Desktop') {
      $cim = Get-CimInstance -ClassName Win32_process -Filter "processID = $pid" -Property CommandLine, ParentProcessID
      $cmd = $cim.CommandLine
      $parent = Get-Process -Id $cim.ParentProcessId
    } else {
      $cmd = $proc.CommandLine
      $parent = $proc.parent
    }

    [PSCustomObject]@{
      PSTypeName = "PSSessionInfo"
      ProcessID  = $PID
      Command    = $cmd
      Host       = $Host.Name
      Started    = $proc.StartTime
      PSVersion  = $PSVersionTable.PSVersion
      Elevated   = $false #Test-IsElevated
      Parent     = $parent
    }
  }
  end {
    Update-TypeData -TypeName PSSessionInfo -MemberType ScriptProperty -MemberName Runtime -Value { (Get-Date) - $this.Started } -Force
    Update-TypeData -TypeName PSSessionInfo -MemberType ScriptProperty -MemberName Memory -Value { (Get-Process -Id $this.ProcessID).WorkingSet / 1MB -AS [int32] } -Force
    Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
  }
}