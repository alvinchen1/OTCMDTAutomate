﻿<#
NAME
    Publish-ADCSTemplates.ps1

SYNOPSIS
    Publishes certificate templates in the AD domain

SYNTAX
    .\$ScriptName
 #>

Start-Transcript

# Declare Variables
# -----------------------------------------------------------------------------
$ScriptName = Split-Path $MyInvocation.MyCommand.Path –Leaf
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path –Parent
$RootDir = Split-Path $ScriptDir –Parent
$ConfigFile = "$RootDir\config.xml"

# Load variables from config.xml
If (!(Test-Path -Path $ConfigFile)) 
{
    Write-Host "Missing configuration file $ConfigFile" -ForegroundColor Red
    Stop-Transcript
    Exit
}
$XML = ([XML](Get-Content $ConfigFile)).get_DocumentElement()
$WS = ($XML.Component | ? {($_.Name -eq "WindowsServer")}).Settings.Configuration
$DomainName = ($WS | ? {($_.Name -eq "DomainName")}).Value
$DomainDistinguishedName = ($WS | ? {($_.Name -eq "DomainDistinguishedName")}).Value

#region JSONs

$JSON_User = @'
    {
        "name":  "User",
        "displayName":  "User",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131642,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.15741648.5891680.6701205.15104761.10548936.199.12145933.6618996",
        "msPKI-Certificate-Application-Policy":  [
                                                        "1.3.6.1.5.5.7.3.2",
                                                        "1.3.6.1.5.5.7.3.4",
                                                        "1.3.6.1.4.1.311.10.3.4"
                                                    ],
        "msPKI-Certificate-Name-Flag":  -1509949440,
        "msPKI-Enrollment-Flag":  41,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056784,
        "msPKI-RA-Signature":  0,
        "msPKI-Template-Minor-Revision":  2,
        "msPKI-Template-Schema-Version":  4,
        "pKICriticalExtensions":  [
                                        "2.5.29.15"
                                    ],
        "pKIDefaultCSPs":  [
                                "1,Microsoft Enhanced Cryptographic Provider v1.0"
                            ],
        "pKIDefaultKeySpec":  1,
        "pKIExpirationPeriod":  [
                                    0,
                                    64,
                                    57,
                                    135,
                                    46,
                                    225,
                                    254,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.5.5.7.3.2",
                                    "1.3.6.1.5.5.7.3.4",
                                    "1.3.6.1.4.1.311.10.3.4"
                                ],
        "pKIKeyUsage":  [
                            160,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                    0,
                                    128,
                                    166,
                                    10,
                                    255,
                                    222,
                                    255,
                                    255
                                ]
    }
'@

$JSON_Workstation = @'
    {
        "name":  "Workstation",
        "displayName":  "Workstation",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131680,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.15741648.5891680.6701205.15104761.10548936.199.5834742.15271609",
        "msPKI-Certificate-Application-Policy":  [
                                                        "1.3.6.1.5.5.8.2.2",
                                                        "1.3.6.1.5.5.7.3.2"
                                                    ],
        "msPKI-Certificate-Name-Flag":  134217728,
        "msPKI-Enrollment-Flag":  32,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056768,
        "msPKI-RA-Signature":  0,
        "msPKI-Supersede-Templates":  [
                                            "Machine",
                                            "Workstation"
                                        ],
        "msPKI-Template-Minor-Revision":  3,
        "msPKI-Template-Schema-Version":  4,
        "pKICriticalExtensions":  [
                                        "2.5.29.15"
                                    ],
        "pKIDefaultCSPs":  [
                                "1,Microsoft RSA SChannel Cryptographic Provider"
                            ],
        "pKIDefaultKeySpec":  1,
        "pKIExpirationPeriod":  [
                                    0,
                                    64,
                                    57,
                                    135,
                                    46,
                                    225,
                                    254,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.5.5.8.2.2",
                                    "1.3.6.1.5.5.7.3.2"
                                ],
        "pKIKeyUsage":  [
                            160,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                    0,
                                    128,
                                    166,
                                    10,
                                    255,
                                    222,
                                    255,
                                    255
                                ]
    }
'@

$JSON_WebServer = @'
    {
        "name":  "WebServer",
        "displayName":  "Web Server",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131649,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.10506257.10940304.8343203.16255837.11131461.100.3468337.13663427",
        "msPKI-Certificate-Application-Policy":  [
                                                        "1.3.6.1.5.5.7.3.1",
                                                        "1.3.6.1.5.5.8.2.2"
                                                    ],
        "msPKI-Certificate-Name-Flag":  1,
        "msPKI-Enrollment-Flag":  0,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056528,
        "msPKI-RA-Signature":  0,
        "msPKI-Supersede-Templates":  [
                                            "WebServer"
                                        ],
        "msPKI-Template-Minor-Revision":  3,
        "msPKI-Template-Schema-Version":  2,
        "pKICriticalExtensions":  [
                                        "2.5.29.15"
                                    ],
        "pKIDefaultCSPs":  [
                                "2,Microsoft DH SChannel Cryptographic Provider",
                                "1,Microsoft RSA SChannel Cryptographic Provider"
                            ],
        "pKIDefaultKeySpec":  1,
        "pKIExpirationPeriod":  [
                                    0,
                                    128,
                                    114,
                                    14,
                                    93,
                                    194,
                                    253,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.5.5.7.3.1",
                                    "1.3.6.1.5.5.8.2.2"
                                ],
        "pKIKeyUsage":  [
                            160,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                    0,
                                    128,
                                    166,
                                    10,
                                    255,
                                    222,
                                    255,
                                    255
                                ]
    }
'@

$JSON_DC = @'
    {
        "name":  "DomainController",
        "displayName":  "Domain Controller",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131168,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.15741648.5891680.6701205.15104761.10548936.199.11642508.5320445",
        "msPKI-Certificate-Application-Policy":  [
                                                        "1.3.6.1.4.1.311.20.2.2",
                                                        "1.3.6.1.5.5.7.3.1",
                                                        "1.3.6.1.5.2.3.5",
                                                        "1.3.6.1.5.5.8.2.2",
                                                        "1.3.6.1.5.5.7.3.2"
                                                    ],
        "msPKI-Certificate-Name-Flag":  138412032,
        "msPKI-Enrollment-Flag":  32,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056768,
        "msPKI-RA-Signature":  0,
        "msPKI-Supersede-Templates":  [
                                            "DomainController",
                                            "DomainControllerAuthentication",
                                            "KerberosAuthentication"
                                        ],
        "msPKI-Template-Minor-Revision":  1,
        "msPKI-Template-Schema-Version":  4,
        "pKICriticalExtensions":  [
                                        "2.5.29.17",
                                        "2.5.29.15"
                                    ],
        "pKIDefaultCSPs":  [
                                "1,Microsoft RSA SChannel Cryptographic Provider"
                            ],
        "pKIDefaultKeySpec":  1,
        "pKIExpirationPeriod":  [
                                    0,
                                    64,
                                    57,
                                    135,
                                    46,
                                    225,
                                    254,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.4.1.311.20.2.2",
                                    "1.3.6.1.5.5.7.3.1",
                                    "1.3.6.1.5.2.3.5",
                                    "1.3.6.1.5.5.8.2.2",
                                    "1.3.6.1.5.5.7.3.2"
                                ],
        "pKIKeyUsage":  [
                            160,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                    0,
                                    128,
                                    166,
                                    10,
                                    255,
                                    222,
                                    255,
                                    255
                                ]
    }
'@
        
$JSON_IPsec = @'
    {
        "name":  "IPSec",
        "displayName":  "IPSec",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131680,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.15741648.5891680.6701205.15104761.10548936.199.5235899.13576313",
        "msPKI-Certificate-Application-Policy":  [
                                                        "1.3.6.1.5.5.7.3.1",
                                                        "1.3.6.1.5.5.8.2.2",
                                                        "1.3.6.1.5.5.7.3.2"
                                                    ],
        "msPKI-Certificate-Name-Flag":  134217728,
        "msPKI-Enrollment-Flag":  32,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056768,
        "msPKI-RA-Signature":  0,
        "msPKI-Supersede-Templates":  [
                                            "IPSECIntermediateOnline"
                                        ],
        "msPKI-Template-Minor-Revision":  2,
        "msPKI-Template-Schema-Version":  4,
        "pKICriticalExtensions":  [
                                        "2.5.29.15"
                                    ],
        "pKIDefaultCSPs":  [
                                "1,Microsoft RSA SChannel Cryptographic Provider"
                            ],
        "pKIDefaultKeySpec":  1,
        "pKIExpirationPeriod":  [
                                    0,
                                    128,
                                    114,
                                    14,
                                    93,
                                    194,
                                    253,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.5.5.7.3.1",
                                    "1.3.6.1.5.5.8.2.2",
                                    "1.3.6.1.5.5.7.3.2"
                                ],
        "pKIKeyUsage":  [
                            160,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                    0,
                                    128,
                                    166,
                                    10,
                                    255,
                                    222,
                                    255,
                                    255
                                ]
    }
'@

$JSON_OCSP = @'
    {
        "name":  "OCSPResponseSigning",
        "displayName":  "OCSP Response Signing",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131648,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.15318887.14476376.10111367.8586198.7996877.234.9955856.6461100",
        "msPKI-Certificate-Application-Policy":  [
                                                        "1.3.6.1.5.5.7.3.9"
                                                    ],
        "msPKI-Certificate-Name-Flag":  402653184,
        "msPKI-Enrollment-Flag":  20512,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056512,
        "msPKI-RA-Application-Policies":  [
                                                "msPKI-Asymmetric-Algorithm`PZPWSTR`RSA`msPKI-Hash-Algorithm`PZPWSTR`SHA384`msPKI-Key-Security-Descriptor`PZPWSTR`D:P(A;;FA;;;BA)(A;;FA;;;SY)(A;;GR;;;S-1-5-80-3804348527-3718992918-2141599610-3686422417-2726379419)`msPKI-Key-Usage`DWORD`2`"
                                            ],
        "msPKI-RA-Signature":  0,
        "msPKI-Supersede-Templates":  [
                                            "OCSPResponseSigning"
                                        ],
        "msPKI-Template-Minor-Revision":  2,
        "msPKI-Template-Schema-Version":  4,
        "pKICriticalExtensions":  [
                                        "2.5.29.15"
                                    ],
        "pKIDefaultKeySpec":  2,
        "pKIExpirationPeriod":  [
                                    0,
                                    128,
                                    55,
                                    174,
                                    255,
                                    244,
                                    255,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.5.5.7.3.9"
                                ],
        "pKIKeyUsage":  [
                            128,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                    0,
                                    128,
                                    44,
                                    171,
                                    109,
                                    254,
                                    255,
                                    255
                                ]
    }
'@

$JSON_RDS = @'
    {
        "name":  "RDS",
        "displayName":  "RDS",
        "objectClass":  "pKICertificateTemplate",
        "flags":  131680,
        "revision":  100,
        "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.91327.1187215.2115508.15901540.15331481.18.94010429.68117242",
        "msPKI-Certificate-Application-Policy":  [
                                                     "1.3.6.1.4.1.311.54.1.2"
                                                 ],
        "msPKI-Certificate-Name-Flag":  1207959552,
        "msPKI-Enrollment-Flag":  32,
        "msPKI-Minimal-Key-Size":  2048,
        "msPKI-Private-Key-Flag":  101056512,
        "msPKI-RA-Signature":  0,
        "msPKI-Template-Minor-Revision":  6,
        "msPKI-Template-Schema-Version":  2,
        "pKICriticalExtensions":  [
                                      "2.5.29.15"
                                  ],
        "pKIDefaultCSPs":  [
                               "1,Microsoft RSA SChannel Cryptographic Provider"
                           ],
        "pKIDefaultKeySpec":  1,
        "pKIExpirationPeriod":  [
                                    0,
                                    128,
                                    114,
                                    14,
                                    93,
                                    194,
                                    253,
                                    255
                                ],
        "pKIExtendedKeyUsage":  [
                                    "1.3.6.1.4.1.311.54.1.2"
                                ],
        "pKIKeyUsage":  [
                            160,
                            0
                        ],
        "pKIMaxIssuingDepth":  0,
        "pKIOverlapPeriod":  [
                                 0,
                                 128,
                                 166,
                                 10,
                                 255,
                                 222,
                                 255,
                                 255
                             ]
    }
'@

#endregion JSONs

# =============================================================================
# FUNCTIONS
# =============================================================================

Function Check-Role()
{
   param (
    [Parameter(Mandatory=$false, HelpMessage = "Enter what role you want to check for. Default check is for 'Administrator'")]
    [System.Security.Principal.WindowsBuiltInRole]$role = [System.Security.Principal.WindowsBuiltInRole]::Administrator
   )

    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity

    return $windowsPrincipal.IsInRole($role)
}

Function Check-Prereqs
{
    Write-Verbose "----- Entering Check-Prereqs function -----"
    
    # Ensure script is run elevated
    If (!(Check-Role)) {Throw "Script is NOT running elevated. Be sure the script runs under elevated conditions."}
    
    # Ensure RSAT-AD-PowerShell is installed
    If (!(Get-WindowsFeature RSAT-AD-PowerShell).Installed) {Add-WindowsFeature RSAT-AD-PowerShell}

    # Import modules
    Import-Module ActiveDirectory
    Import-Module -Name ADCSTemplate
}

# =============================================================================
# MAIN ROUTINE
# =============================================================================

Check-Prereqs

# Create Web Servers security group
If (!([bool] (Get-ADGroup -Filter {sAMAccountName -eq 'Web Servers'}))) 
{
    New-ADGroup -Name 'Web Servers' -GroupScope DomainLocal -GroupCategory Security -Description "Members are computer accounts that can enroll the Web Server certificate template for the domain"
}

<# This is not fully tested yet

# Create Remote Desktop Authentication OID
$ADConfig = (Get-ADRootDSE).configurationNamingContext
If (!([bool] (Get-ADObject -Filter {(objectclass -eq "msPKI-Enterprise-Oid") -and (msPKI-Cert-Template-OID -eq "1.3.6.1.4.1.311.54.1.2")} -SearchBase $ADConfig))) 
{
$Signature = @"
[SecurityCritical]
[DllImport("Crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern Boolean CryptRegisterOIDInfo(
    CRYPT_OID_INFO pInfo,
    int dwFlags
);
[SecurityCritical]
[DllImport("Crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern Boolean CryptUnregisterOIDInfo(
    CRYPT_OID_INFO pInfo
);
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
public struct CRYPT_OID_INFO {
    public int cbSize;
    [MarshalAs(UnmanagedType.LPStr)]
    public string pszOID;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string pwszName;
    public int dwGroupId;
    // actually this is a Union, but at this point we don't care about this
    public int dwValue;
    public CRYPTOAPI_BLOB ExtraInfo;
    // for compatibility purposes I'm using structure definition that is supported by
    // Windows XP/Windows Server 2003 (without CNG algorithms).
    // Uncomment the block below if necessary:
    // [MarshalAs(UnmanagedType.LPWStr)]
    // public string pwszCNGAlgid;
    // [MarshalAs(UnmanagedType.LPWStr)]
    // public string pwszCNGExtraAlgid;
}
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public struct CRYPTOAPI_BLOB {
    public UInt32 cbData;
    public IntPtr pbData;
}
"@
    Add-Type -MemberDefinition $Signature -Namespace PKI -Name Crypt32 -UsingNamespace System.Security

    $OID = New-Object PKI.Crypt32+CRYPT_OID_INFO -Property @{
        cbSize = [Runtime.InteropServices.Marshal]::SizeOf([Type][PKI.Crypt32+CRYPT_OID_INFO]);
        pszOID = "1.3.6.1.4.1.311.54.1.2";
        pwszName = "Remote Desktop Authentication";
        dwGroupId = 7;
    }
    [PKI.Crypt32]::CryptRegisterOIDInfo($OID,0)

    # Restart service
    $service = Get-Service | Where-Object {$_.Name -eq "certsvc"}
    If($service.Status -eq "Running") {Restart-Service $service}
    Else {Start-Service $service}
}

#>

# Create certificate templates
New-ADCSTemplate -DisplayName "$DomainName User" -JSON $JSON_User -Publish -Identity "$DomainName\Domain Users"
New-ADCSTemplate -DisplayName "$DomainName Workstation" -JSON $JSON_Workstation -Publish -Identity "$DomainName\Domain Computers"
$DCAcl = @("$DomainName\Domain Controllers","$DomainName\Enterprise Read-only Domain Controllers")
New-ADCSTemplate -DisplayName "$DomainName Domain Controller" -JSON $JSON_DC -Publish -Identity $DCAcl
New-ADCSTemplate -DisplayName "$DomainName IPsec" -JSON $JSON_IPsec -Publish
New-ADCSTemplate -DisplayName "$DomainName Web Server" -JSON $JSON_WebServer -Publish -Identity "$DomainName\Web Servers"
New-ADCSTemplate -DisplayName "$DomainName OCSP Response Signing" -JSON $JSON_OCSP -Publish
New-ADCSTemplate -DisplayName "RDS" -JSON $JSON_RDS -Publish -Identity "$DomainName\Domain Computers"

# Check work
Write-Host "`nThe following templates were created:`n"
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "$DomainName User"}
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "$DomainName Workstation"}
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "$DomainName Domain Controller"}
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "$DomainName IPsec"}
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "$DomainName Web Server"}
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "$DomainName OCSP Response Signing"}
(Get-ADCSTemplate).DisplayName | Where-Object {$_ -eq "RDS"}


Stop-Transcript
