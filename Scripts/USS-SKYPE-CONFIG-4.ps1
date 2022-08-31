<#
NAME
    USS-SKYPE-CONFIG-2.ps1

SYNOPSIS
    Installs Skype For Business in the AD domain

SYNTAX
    .\$ScriptName
 #>

# Declare Variables
# -----------------------------------------------------------------------------
$ScriptName = Split-Path $MyInvocation.MyCommand.Path �Leaf
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path �Parent
$RootDir = Split-Path $ScriptDir �Parent
$ConfigFile = "$RootDir\config.xml"

# Load variables from config.xml
If (!(Test-Path -Path $ConfigFile)) 
{
    Write-Host "Missing configuration file $ConfigFile" -ForegroundColor Red
### Stop-Transcript
    Exit
}

$XML = ([XML](Get-Content $ConfigFile)).get_DocumentElement()
$WS = ($XML.Component | ? {($_.Name -eq "WindowsServer")}).Settings.Configuration
$InstallShare = ($WS | ? {($_.Name -eq "InstallShare")}).Value 
$DomainDnsName = ($WS | ? {($_.Name -eq "DomainDnsName")}).Value
$Windows2019SourcePath = ($WS | ? {($_.Name -eq "InstallShare")}).Value + "\W2019\sources\sxs"
$Skype4BusinessPrereqPath = ($WS | ? {($_.Name -eq "InstallShare")}).Value + "\Skype4BusinessPrereqs"
$DOTNETFRAMEWORKPath = ($WS | ? {($_.Name -eq "InstallShare")}).Value + "\DOTNETFRAMEWORK_4.8"
$Skype4BusinessPath = ($WS | ? {($_.Name -eq "InstallShare")}).Value + "\SkypeForBusiness\OCS_Eval"
$SkypeForBusiness = ($XML.Component | ? {($_.Name -eq "SkypeForBusiness")}).Settings.Configuration
$SkypeForBusinessCUPath = ($WS | ? {($_.Name -eq "InstallShare")}).Value + "\Skype4BusinessCU"
$SQLServer2019Path = ($WS | ? {($_.Name -eq "InstallShare")}).Value + "\SQLServer2019"
$CSShareName = ($SkypeForBusiness | ? {($_.Name -eq "CSShareName")}).Value
$CSShareNamePath = ($SkypeForBusiness | ? {($_.Name -eq "CSShareNamePath")}).Value
$LDAPDomain = ($WS | ? {($_.Name -eq "DomainDistinguishedName")}).Value
$CertTemplate = ($WS | ? {($_.Name -eq "DomainName")}).Value + "WebServer"

###################################################################################################
### Start-Transcript
### Stop-Transcript
### Overwrite existing log.
Start-Transcript -Path C:\Windows\Temp\MDT-PS-LOGS\$ScriptName.log
Start-Transcript -Path $RootDir\LOGS\$env:COMPUTERNAME\$ScriptName.log

###------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
###
###    Alvin Chen
###    Install Skype For Business 2019
###    Prerequisites, a file share, AD joined, IP addressed, Schema Admins, Enterprise Admins, all variables above set
###
###    Prerequisties as of 7/26/2022
###         https://docs.microsoft.com/en-us/SkypeForBusiness/plan/system-requirements
###         Download .net Framework 4.8:  
###                  https://go.microsoft.com/fwlink/?linkid=2088631
###             See   https://support.microsoft.com/en-us/topic/microsoft-net-framework-4-8-offline-installer-for-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0
###                   Place in DOTNETFRAMEWORK_4.8
###         Download Skype For Business ISO
###                  https://www.microsoft.com/en-us/evalcenter/download-skype-business-server-2019
###             Open ISO and Extract folders under Skype4BusinessPath such that in the root of Skype4BusinessPath is autorun.inf, and Setup and Support Folders
###         Download Latest Skype For Business Cumulative Update
###             See   https://docs.microsoft.com/en-us/skypeforbusiness/sfb-server-updates
###                   Place in Skype4BusinessCU
###         Download Latest SQL Server 2019 Express Offline
###                  https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLEXPRADV_x64_ENU.exe
###                   Place in SQLServer2019
###------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
clear-host

# =============================================================================
# FUNCTIONS
# =============================================================================

#Adapted from https://gist.github.com/altrive/5329377
#Based on <https://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542>
function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}

 return $false
}

# =============================================================================
# MAIN ROUTINE
# =============================================================================
$WindowsFeature = Get-WindowsFeature -Name Web* | Where Installed
If ($WindowsFeature.count -gt '35') {
   write-host "Windows Server prerequisites already installed" -ForegroundColor Green
   }
   Else {
         IF ((Test-PendingReboot) -eq $false) {
            IF ((Get-ChildItem -Path $Windows2019SourcePath).count -gt 1) {
                write-host "Installing Windows Server Prerequisites" -Foregroundcolor green
                Add-WindowsFeature RSAT-ADDS, Web-Server, Web-Static-Content, Web-Default-Doc, Web-Http-Errors, Web-Asp-Net, Web-Net-Ext, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor, Web-Http-Tracing, Web-Basic-Auth, Web-Windows-Auth, Web-Client-Auth, Web-Filtering, Web-Stat-Compression, Web-Dyn-Compression, NET-WCF-HTTP-Activation45, Web-Asp-Net45, Web-Mgmt-Tools, Web-Scripting-Tools, Web-Mgmt-Compat, Windows-Identity-Foundation, Server-Media-Foundation, Telnet-Client, BITS, ManagementOData, Web-Mgmt-Console, Web-Metabase, Web-Lgcy-Mgmt-Console, Web-Lgcy-Scripting, Web-WMI, Web-Scripting-Tools, Web-Mgmt-Service -Source $Windows2019SourcePath
                }
                Else {
                      write-host ".net Framework SXS not found." -Foregroundcolor red
                      exit
                     }
                }
            Else {
                  write-host "Reboot Needed... return script after reboot." -Foregroundcolor red
                  exit
                 }
         }
   
$WindowsFeature = Get-WindowsFeature -Name Web* | Where Installed
$dotnetFramework48main = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').version.Substring(0,1)
$dotnetFramework48rev = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').version.Substring(2,1)
If ($dotnetFramework48main -eq '4' -and $dotnetFramework48rev -gt 7) {write-host ".net Framework 4.8 already installed" -ForegroundColor Green}
Else {
      If ($WindowsFeature.count -gt '34') {
         write-host "Installing .net Framework 4.8" -Foregroundcolor green
         start-process $DOTNETFRAMEWORKPath"\ndp48-x86-x64-allos-enu.exe" -Wait -Argumentlist " /q /norestart"
      }
      Else {
            write-host "Windows Components for Skype Not Installed...skipping net Framework 4.8" -Foregroundcolor red
            exit
           }
     }

$BootStrapCore = Get-Package | where {$_.Name -like "Skype for Business Server 2019, Core Components"}
If ($BootStrapCore.count -eq '0') {
      write-host "Installing Skype for Business Server Core" -ForegroundColor Green
      start-process $Skype4BusinessPath"\Setup\amd64\setup.exe" -Wait -Argumentlist "/bootstrapcore"
      }
Else {
      write-host "Skype for Business Server detected, skipping bootstrap core" -Foregroundcolor green
     }

####
####  Check is ADPS Module is installed before proceeding with Schema check, currently not working consistently, will attempt to update ####       schema when get-addomain fails
####
$BootStrapCore = Get-Package | where {$_.Name -like "Skype for Business Server 2019, Core Components"}
If ($BootStrapCore.count -eq '1') {
      import-module "C:\Program Files\Common Files\Skype for Business Server 2019\Modules\SkypeForBusiness\SkypeForBusiness.psd1"
      import-module ActiveDirectory 2>&1 | out-null
      $ADPSModule = get-module | ? {$_.Name -eq "ActiveDirectory"}
      IF ($ADPSModule.count -eq '1') {
             $ADOSchemaLocation = 'CN=Schema,CN=Configuration,'+$LDAPDomain
             IF ((get-adobject -SearchBase $ADOSchemaLocation -filter * | Where {$_.DistinguishedName -like "CN=ms-RTC-SIP-SchemaVersion*"}).count -eq 0) {
                 $ADSchemaLocation = 'AD:\CN=Schema,CN=Configuration,'+$LDAPDomain
                 $SkypeSchemaLocation = 'AD:\CN=ms-RTC-SIP-SchemaVersion,CN=Schema,CN=Configuration,'+$LDAPDomain
                 $ADSchema = Get-ItemProperty $SkypeSchemaLocation -Name rangeUpper
                 If ($ADSchema.rangeUpper -lt '1149') {
                     write-host "Extending AD Schema for Skype For Business" -Foregroundcolor green
                     Install-CSAdServerSchema -Confirm:$false
                     write-host "Pausing for Schema replication" -Foregroundcolor green
                     Start-Sleep -seconds 300
                  }
             }
             Else {
                   write-host "Active Directory Schema already extended for Skype For Business 2019" -ForegroundColor Green
                  }
      }
      Else {
            write-host "Active Directory PowerShell not detected, skipping Schema check" -ForegroundColor Red
            exit
           }
      }
Else {
      write-host "Skype for Business Server not detected, skipping schema check" -Foregroundcolor green
      exit
     }

### Prepare Forest
###     TO DO: Check to see if Forest Already Prepared, Group CSAdministrators?
###            Check if member of Enteprise Admins
$CSAdminsobj = Get-ADGroup -LDAPFilter "(SAMAccountName=CSAdministrator)"
$BootStrapCore = Get-Package | where {$_.Name -like "Skype for Business Server 2019, Core Components"}
If ($BootStrapCore.count -eq '1') {
      IF ($CSAdminsobj -eq $null){
            write-host "Preparing Forest for Skype For Business." -ForegroundColor Green
            Enable-CSAdForest  -Verbose -Confirm:$false
            write-host "Forest Prepared for Skype For Business." -ForegroundColor Green
            write-host "Pausing for Forest Prep replication." -Foregroundcolor green
            Start-Sleep -seconds 300
      }
      ELSE {
            write-host "Forest Already Prepared for Skype For Business 2019." -ForegroundColor Green
            }
      }
Else {
      write-host "Skype for Business Server not detected, skipping forest prep." -Foregroundcolor green
     }

### Prepare Domain
$ADDomainPrep = get-csaddomain
if ($ADDomainPrep -ne "LC_DOMAINSETTINGS_STATE_READY") { 
     write-host "Preparing Domain for Skype For Business." -ForegroundColor Green
     Enable-CSAdDomain -Verbose -Confirm:$false
     write-host "Domain Prepared for Skype For Business." -ForegroundColor Green
     }
Else {
     write-host "Domain already prepared for Skype For Business." -Foregroundcolor green
     }

###Add to  CSAdministrators and RTCUniversalServerAdmins
IF ($CSAdminsobj -ne $null) {
     $CSAdminsMembers = Get-ADGroupMember -Identity CSAdministrator -Recursive | Select -ExpandProperty Name
     IF ($CSAdminsMembers -contains $env:UserName){
         write-host $env:UserName "already in CSAdministrator Group." -Foregroundcolor green
     }
     ELSE {
          Add-AdGroupMember -identity "CSAdministrator" -members $env:UserName
          write-host $env:UserName "added to CSAdministrator.  Logoff and Logon may be needed before proceeding." -Foregroundcolor red
          }
     }


$RTCUniversalServerAdminsobj = Get-ADGroup -LDAPFilter "(SAMAccountName=RTCUniversalServerAdmins)"
IF ($RTCUniversalServerAdminsobj -ne $null) {
     $RTCUniversalServerAdminsMembers = Get-ADGroupMember -Identity RTCUniversalServerAdmins -Recursive | Select -ExpandProperty Name
     IF ($RTCUniversalServerAdminsMembers -contains $env:UserName){
         write-host $env:UserName "already in RTCUniversalServerAdmins Group." -Foregroundcolor green
     }
     ELSE {
          Add-AdGroupMember -identity "RTCUniversalServerAdmins" -members $env:UserName
          write-host $env:UserName "added to RTCUniversalServerAdmins.  Logoff and Logon may be needed before proceeding." -Foregroundcolor red
          }
    }

####Install Admin Tools
$AdminTools  = Get-Package | where {$_.Name -like "Skype for Business Server 2019, Administrative Tools*"}
If ($AdminTools.count -eq '1') {write-host "Skype for Business Server 2019, Administrative Tools already installed." -ForegroundColor Green}
Else {
      write-host "Installing Skype for Business Server 2019, Administrative Tools" -Foregroundcolor green
      start-process msiexec.exe -Wait -Argumentlist " /i $Skype4BusinessPath\Setup\amd64\Setup\admintools.msi /qn"
     }

IF ((get-fileshare | ? {$_.Name -eq $CSShareName}).count -eq "0") {
    write-host "Creating CSShare" -Foregroundcolor green
    [system.io.directory]::CreateDirectory($CSShareNamePath)
    New-SMBShare -Name $CSShareName -Path $CSShareNamePath -FullAccess "Authenticated Users" -CachingMode None
    }
ELSE {
     Write-host "CSShare already exists." -ForegroundColor Green
}

IF ((get-service | Where {$_.Name -eq 'MSSQL$RTC'}).count -eq 0) {
     Write-host "Creating CMS Database." -ForegroundColor Green
     start-process "C:\Program Files\Skype for Business Server 2019\Deployment\Bootstrapper.exe" -Wait -Argumentlist " /BootstrapSQLExpress"
     start-process "netsh" -Wait -Argumentlist ' advfirewall firewall add rule name="SQL Browser" dir=in action=allow protocol=UDP localport=1434'
     }
ELSE {
     Write-host "CMS Database already exists." -ForegroundColor Green
}

####Write-host "Run Skype For Business Server Topology Builder, build new topology and successfully publish." -ForegroundColor Red

IF ((get-service | Where {$_.Name -eq 'MSSQL$RTCLOCAL'}).count -eq 0) {
     Write-host "Creating Local Configuration Store." -ForegroundColor Green
     start-process "netsh" -Wait -Argumentlist ' advfirewall firewall add rule name="SQL Browser" dir=in action=allow protocol=UDP localport=1434'
     start-process "C:\Program Files\Skype for Business Server 2019\Deployment\Bootstrapper.exe" -Wait -Argumentlist " /BootstrapLocalMgmt"
     Write-host "Local Configuration Store created.  Importing Configuration into Local Store." -ForegroundColor Green
     $CSConfiguration = Export-CsConfiguration -AsBytes
     Import-CsConfiguration -ByteInput $CSConfiguration -LocalStore
     Write-host "Enabling Replica." -ForegroundColor Green
     Enable-CSReplica -force
     Write-host "Replica enabled.  Installing Skype For Business Roles" -ForegroundColor Green
     ###### Replicate-CsCmsCertificates
     start-process "C:\Program Files\Skype for Business Server 2019\Deployment\Bootstrapper.exe" -Wait
     }
ELSE {
     Write-host "Local Configuration Store already exists." -ForegroundColor Green
}

Write-Host 'Obtaining New Certificate' -ForegroundColor Green
IF ((get-adgroup -identity "Web Servers").ObjectClass -eq "group") {
     Add-AdGroupMember -identity "Web Servers" -members $env:COMPUTERNAME$
     $SkypeFQDN = ([System.Net.DNS]::GetHostByName($env:computerName)).hostname
     $Certificate = Get-Certificate -Template $CertTemplate -DNSName $SkypeFQDN,dialin.$DomainDnsName,meet.$DomainDnsName,lyncdiscoverinternal.$DomainDnsName,lyncdiscover.$DomainDnsName,sip.$DomainDnsName -CertStoreLocation cert:\LocalMachine\My -subjectname cn=$SkypeFQDN
     Set-CSCertificate -Type Default,WebServicesInternal,WebServicesExternal -Thumbprint $Certificate.certificate.thumbprint -Confirm:$false
     $Certificate | FL
    }

If ((get-package | where {($_.Name -like "Skype for Business*") -and ($_.Version -eq "7.0.2046.0")}).count -gt '9') {
      write-host "Applying Skype for Business Server Cumulative Update." -ForegroundColor Green
      start-process $SkypeForBusinessCUPath"\SkypeServerUpdateInstaller" -Wait -Argumentlist "/silentmode"
      Stop-CsWindowsService
      start-process "net " -Wait -Argumentlist " stop w3svc"
      Install-CsDatabase -Update -LocalDatabases
      }
Else {
      write-host "Skype for Business not installed or Skype for Business Cumulative Updates already Applied." -Foregroundcolor green
     }

If ((get-service | ? {$_.Name -like 'MSSQL*'}).count -eq 3) {
      IF ((Test-PendingReboot) -eq $false){
          write-host "Checking SQL Server Version on RTC." -ForegroundColor Green
          IF ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").RTC -eq "MSSQL13.RTC"){
                write-host "RTC SQL Server needs to upgrade to SQL Server 2019." -Foregroundcolor green
                Stop-CsWindowsService -force
                start-process "net " -Wait -Argumentlist " stop w3svc"
                Start-Sleep -seconds 300
                IF((Test-PendingReboot) -eq $false){
                start-process $SQLServer2019Path"\SQLEXPRADV_x64_ENU.exe" -Wait -Argumentlist " /q /ACTION=Upgrade /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=RTC /HIDECONSOLE /ERRORREPORTING=0 /UpdateEnabled=0"
                }
                   ELSE {
                        write-host "Reboot Needed." -Foregroundcolor red
                        }
          }
          Else {
                write-host "RTC SQL Server instance is SQL Server 2019." -Foregroundcolor green
                write-host "Checking SQL Server Version on RTC for CU." -ForegroundColor Green
                  IF ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.RTC\Setup").PatchLevel -eq "15.0.2000.5"){
                        write-host "RTC SQL Server 2019 needs latest CU." -Foregroundcolor green
                        Stop-CsWindowsService -force
                        start-process "net " -Wait -Argumentlist " stop w3svc"
                        IF ((Test-PendingReboot) -eq $false){
                             start-process $SQLServer2019Path"\SQLServer2019-CU-x64.exe" -Wait -Argumentlist " /q /ACTION=patch /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=RTC /HIDECONSOLE /ERRORREPORTING=0"
                             }
                             ELSE{
                                 write-host "Reboot Needed." -Foregroundcolor red
                                 }
                  }
                  Else {
                        write-host "RTC SQL Server 2019 has the latest CU." -Foregroundcolor green
                       }
               }
          write-host "Checking SQL Server Version on RTCLOCAL." -ForegroundColor Green
          IF ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").RTCLOCAL -eq "MSSQL13.RTCLOCAL"){
                write-host "RTCLOCAL SQL Server needs to upgrade to SQL Server 2019." -Foregroundcolor green
                Stop-CsWindowsService -force
                start-process "net " -Wait -Argumentlist " stop w3svc"
                IF((Test-PendingReboot) -eq $false){
                start-process $SQLServer2019Path"\SQLEXPRADV_x64_ENU.exe" -Wait -Argumentlist " /q /ACTION=Upgrade /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=RTCLOCAL /HIDECONSOLE /ERRORREPORTING=0 /UpdateEnabled=0"
                }
                   ELSE {
                        write-host "Reboot Needed." -Foregroundcolor red
                        }
          }
          Else {
                write-host "RTCLOCAL SQL Server instance is SQL Server 2019." -Foregroundcolor green
                write-host "Checking SQL Server Version on RTCLOCAL for CU." -ForegroundColor Green
                  IF ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.RTCLOCAL\Setup").PatchLevel -eq "15.0.2000.5"){
                        write-host "RTCLOCAL SQL Server 2019 needs latest CU." -Foregroundcolor green
                        Stop-CsWindowsService -force
                        start-process "net " -Wait -Argumentlist " stop w3svc"
                        IF ((Test-PendingReboot) -eq $false){
                             start-process $SQLServer2019Path"\SQLServer2019-CU-x64.exe" -Wait -Argumentlist " /q /ACTION=patch /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=RTCLOCAL /HIDECONSOLE /ERRORREPORTING=0"
                             }
                             ELSE{
                                 write-host "Reboot Needed." -Foregroundcolor red
                                 }
                  }
                  Else {
                        write-host "RTCLOCAL SQL Server 2019 has the latest CU." -Foregroundcolor green
                       }
               }
          write-host "Checking SQL Server Version on LYNCLOCAL." -ForegroundColor Green
          IF ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").LYNCLOCAL -eq "MSSQL13.LYNCLOCAL"){
                write-host "LYNCLOCAL SQL Server needs to upgrade to SQL Server 2019." -Foregroundcolor green
                Stop-CsWindowsService -force
                start-process "net " -Wait -Argumentlist " stop w3svc"
                IF((Test-PendingReboot) -eq $false){
                start-process $SQLServer2019Path"\SQLEXPRADV_x64_ENU.exe" -Wait -Argumentlist " /q /ACTION=Upgrade /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=LYNCLOCAL /HIDECONSOLE /ERRORREPORTING=0 /UpdateEnabled=0"
                }
                   ELSE {
                        write-host "Reboot Needed." -Foregroundcolor red
                        }
          }
          Else {
                write-host "LYNCLOCAL SQL Server instance is SQL Server 2019." -Foregroundcolor green
                write-host "Checking SQL Server Version on LYNCLOCAL for CU." -ForegroundColor Green
                  IF ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.LYNCLOCAL\Setup").PatchLevel -eq "15.0.2000.5"){
                        write-host "LYNCLOCAL SQL Server 2019 needs latest CU." -Foregroundcolor green
                        Stop-CsWindowsService -force
                        start-process "net " -Wait -Argumentlist " stop w3svc"
                        IF ((Test-PendingReboot) -eq $false){
                             start-process $SQLServer2019Path"\SQLServer2019-CU-x64.exe" -Wait -Argumentlist " /q /ACTION=patch /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=LYNCLOCAL /HIDECONSOLE /ERRORREPORTING=0"
                             }
                             ELSE{
                                 write-host "Reboot Needed." -Foregroundcolor red
                                 }
                  }
                  Else {
                        write-host "LYNCLOCAL SQL Server 2019 has the latest CU." -Foregroundcolor green
                       }
               }
      }
    Else {
    write-host "Reboot Needed." -Foregroundcolor red
    }
      }
Else {
      write-host "3 SQL Server Instanaces not present or reboot needed." -Foregroundcolor green
     }


###################################################################################################
#### DNS Entries
####       Need to get IP address and name from variables
write-host 'Checking DNS for' meet.$DomainDnsName -ForegroundColor Green

$dnsresolve = resolve-dnsname meet.$DomainDnsName 2>&1 | out-null

IF ($dnsresolve.count -lt 1) {
      Install-WindowsFeature RSAT-DNS-Server
      Import-Module DNSServer
      $dotDomainDNSName = "." + $DomainDNSName
      $addomaincontroller = (get-addomaincontroller).name
      $SkypeFQDN = ([System.Net.DNS]::GetHostByName($env:computerName)).hostname
      $DNSZone = get-dnsserverzone -computername $addomaincontroller -name $DomainDNSName
      Add-DnsServerResourceRecord -cname -Computername $addomaincontroller -ZoneName $DNSZone.ZoneName -name dialin -HostNameAlias $SkypeFQDN -TimeToLive 00:05:00
      Add-DnsServerResourceRecord -cname -Computername $addomaincontroller -ZoneName $DNSZone.ZoneName -name meet -HostNameAlias $SkypeFQDN -TimeToLive 00:05:00
      Add-DnsServerResourceRecord -cname -Computername $addomaincontroller -ZoneName $DNSZone.ZoneName -name lyncdiscoverinternal -HostNameAlias $SkypeFQDN -TimeToLive 00:05:00
      Add-DnsServerResourceRecord -cname -Computername $addomaincontroller -ZoneName $DNSZone.ZoneName -name lyncdiscover -HostNameAlias $SkypeFQDN -TimeToLive 00:05:00
      Add-DnsServerResourceRecord -cname -Computername $addomaincontroller -ZoneName $DNSZone.ZoneName -name sip -HostNameAlias $SkypeFQDN -TimeToLive 00:05:00
      Add-DnsServerResourceRecord -Srv -Name "_sipinternaltls._tcp" -ZoneName $DNSZone.ZoneName -DomainName sip.$DomainDnsName -Priority 0 -Weight 0 -Port 5060 -TimeToLive 00:05:00
      remove-windowsfeature RSAT-DNS-Server
      }


###################################################################################################
Stop-Transcript

######################################### REBOOT SERVER ###########################################
