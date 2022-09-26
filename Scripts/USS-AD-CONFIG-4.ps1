﻿<#
NAME
    AD-CONFIG-4.ps1

SYNOPSIS
    Configures network adapter(s); installs an additional DC into the domain

SYNTAX
    .\$ScriptName
 #>

# Declare Variables
# -----------------------------------------------------------------------------
$ScriptName = Split-Path $MyInvocation.MyCommand.Path –Leaf
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path –Parent
$DTG = Get-Date -Format yyyyMMddTHHmm
$RootDir = Split-Path $ScriptDir –Parent
$ConfigFile = "$RootDir\config.xml"

Start-Transcript -Path "$RootDir\LOGS\$env:COMPUTERNAME\$ScriptName.log"
Start-Transcript -Path "$env:WINDIR\Temp\$env:COMPUTERNAME-$DTG-$ScriptName.log"

# Load variables from config.xml
If (!(Test-Path -Path $ConfigFile)) {Throw "ERROR: Unable to locate $ConfigFile Exiting..."} 
$XML = ([XML](Get-Content $ConfigFile)).get_DocumentElement()
$WS = ($XML.Component | ? {($_.Name -eq "WindowsServer")}).Settings.Configuration
$Server = $Env:COMPUTERNAME
$MgmtIP = ($WS | ? {($_.Name -eq "$Server")}).Value
$DNS1 = ($WS | ? {($_.Role -eq "DC1")}).Value
$DNS2 = ($WS | ? {($_.Role -eq "DC2")}).Value
$DefaultGW = ($WS | ? {($_.Name -eq "DefaultGateway")}).Value
$PrefixLen = ($WS | ? {($_.Name -eq "SubnetMaskBitLength")}).Value
$DomainDnsName = ($WS | ? {($_.Name -eq "DomainDnsName")}).Value
$DomainName = ($WS | ? {($_.Name -eq "DomainName")}).Value
$MgmtNICName = "NIC_MGMT1_1GB"
$PKI = ($XML.Component | ? {($_.Name -eq "PKI")}).Settings.Configuration
$RootCACred = ($PKI | ? {($_.Name -eq "RootCACred")}).Value
$DSRMPASS = ConvertTo-SecureString -AsPlainText -Force -String $RootCACred

# =============================================================================
# MAIN ROUTINE
# =============================================================================

# Configure the MGMT NIC
Write-Host -ForegroundColor Green "Configuring NIC(s)"
If (Get-NetAdapter "Ethernet" -ErrorAction SilentlyContinue) {Rename-NetAdapter –Name "Ethernet" –NewName "$MgmtNICName"}
Get-NetAdapter "$MgmtNICName" | Get-NetIPAddress -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false
Get-NetAdapter "$MgmtNICName" | New-NetIPAddress -IPAddress $MgmtIP -AddressFamily IPv4 -PrefixLength $PrefixLen -DefaultGateway $DefaultGW -Confirm:$false
$MgmtNICIP = (Get-NetAdapter "$MgmtNICName" | Get-NetIPAddress -AddressFamily IPv4).IPAddress
If ($MgmtNICIP -eq $DNS1) {Get-NetAdapter "$MgmtNICName" | Set-DnsClientServerAddress -ServerAddresses "127.0.0.1",$DNS2}
ElseIf ($MgmtNICIP -eq $DNS2) {Get-NetAdapter "$MgmtNICName" | Set-DnsClientServerAddress -ServerAddresses "127.0.0.1",$DNS1}
Else {Get-NetAdapter "$MgmtNICName" | Set-DnsClientServerAddress -ServerAddresses $DNS1,$DNS2}
Disable-NetAdapterBinding "$MgmtNICName" -ComponentID ms_tcpip6

# Add Windows Features to support Active Directory Directory Services (ADDS)
Add-WindowsFeature -Name "AD-Domain-Services,DNS,GPMC" -IncludeAllSubFeature -IncludeManagementTools

# Install ADDSDomainController for additional DC
Install-ADDSDomainController -CreateDnsDelegation:$false `
-DomainName $DomainDnsName `
-SafeModeAdministratorPassword $DSRMPASS `
-DatabasePath "C:\Windows\NTDS" `
-LogPath "C:\Windows\NTDS" `
-InstallDns:$true `
-NoRebootOnCompletion:$true `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true `
-NoGlobalCatalog:$false `
-SiteName "Default-First-Site-Name"

Stop-Transcript
