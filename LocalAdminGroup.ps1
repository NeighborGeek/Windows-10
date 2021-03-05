﻿<#	
===========================================================================
	 Created on:   	05/03/2021
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	LocalAdminGroup.ps1
===========================================================================

Version:
1.0 - 05/03/2021

.Synopsis
LocalAdminGroup is a script that can be deployed in a Domain environment, from ConfigMgr, that will add or remove individual users from the Local Administrators group.

Careful thought should be exercised on why you would want to use this.

.Parameter Username
SAMAccountName of the user being added

.Parameter Action
-add will add the user to the Local Administrators Group
-remove will remove the user from the Local Administrators Group

.Example
LocalAdminGroup.ps1 -Username ernest.shackleton -Action "Add"
LocalAdminGroup.ps1 -Username ernest.shackleton -Action "Remove"

#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String]$Username,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateSet ("Add", "Remove")]
    [String]$Action
)

$LocalAdmins = Get-LocalGroupMember Administrators | Select-Object -ExpandProperty Name
$User = (Join-Path $env:USERDOMAIN $Username)
$UserExists = $Null
$UserExistsFinal = $Null

Switch ($Action) {

    Add {
        Write-Output "Checking if $Username is already in the Local Administrators Group"
        foreach ($Admin in $LocalAdmins) {

            If ($Admin -eq $User) {
                Write-Output "$Username already exists in the Local Administrators Group"
                $UserExists = $True
            }
        }

        If (!($UserExists)) {
            Write-Output "Adding $Username to Local Administrators Group"
            Try {
                ([ADSI]("WinNT://" + $env:COMPUTERNAME + "/administrators,group")).add("WinNT://$env:USERDOMAIN/$username,user")
            }
            Catch {
                Write-Warning $error[0]
            }
        }
    }

    Remove {
        Write-Output "Checking if $Username is in the Local Administrators Group"
        foreach ($Admin in $LocalAdmins) {

            If ($Admin -eq $User) {
                Write-Output "$Username is in the Local Administrators Group"
                $UserExists = $True
            }
        }

        If ($UserExists) {
            Write-Output "Removing $Username from Local Administrators Group"
            Try {
                ([ADSI]("WinNT://" + $env:COMPUTERNAME + "/administrators,group")).remove("WinNT://$env:USERDOMAIN/$username,user")
            }
            Catch {
                Write-Warning $error[0]
            }
        }
    }
}

$LocalAdminsFinal = Get-LocalGroupMember Administrators | Select-Object -ExpandProperty Name

foreach ($Admin in $LocalAdminsFinal) {

    If ($Admin -eq $User) {
        $UserExistsFinal = $True
    }
}

If ($UserExistsFinal) {
    Write-Output "Summary: $Username is present in the Local Administrators Group on $env:ComputerName"
}
else {
    Write-Output "Summary: $Username is absent from the Local Administrators Group on $env:ComputerName"
}