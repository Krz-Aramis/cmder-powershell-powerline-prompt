$ALIASNAME = "connect"
$connectionProfiles = (Get-Content 'connect.config' -Raw) | ConvertFrom-Json

function checkExecutables() {
    $check_ok = $true;
    $programs = @("ssh", "plink")
    foreach ($program in $programs) {
        if ($null -eq (Get-Command $program -ErrorAction SilentlyContinue))
        {
            Write-Warning "Unable to find '$program' in your PATH"
            $check_ok = $false;
        }
    }
    return $check_ok
}

function printUsage() {
    Write-Host "'$ALIASNAME' alias for Powershell"
    Write-Host "Aims to simplify connecting to remote server over SSH."
    Write-Host "Uses a simple 'profile' mechanism to construct the required command."
    Write-Host "It is strongly encouraged to use Public/Private Key (pki) exchange "
    Write-Host "instead of usernames with password."
    Write-Host "This utility parses the 'connect.config' file as JSON array of profile objects."
    Write-Host "Please refers to the 'connect.config.example' file for configuration details."
}

function usePKI() {
    Param(
        [parameter(mandatory=$true,
        HelpMessage="Name of the SSH server to connect to.")]
        [String]
        $targetServer,
        [parameter(mandatory=$true,
        HelpMessage="Name of the user to connect as.")]
        [String]
        $username,
        [parameter(mandatory=$true,
        HelpMessage="Full path to identity key associated with the given user.")]
        [String]
        $pkiKeyPath
    )

    $command = "ssh -i $pkiKeyPath -l $username $targetServer"

    #Write-Host "usePKI would produce the command '$command' "
    Invoke-Expression $command
}

function usePassword() {
    Param(
        [parameter(mandatory=$true,
        HelpMessage="Name of the SSH server to connect to.")]
        [String]
        $targetServer,
        [parameter(mandatory=$true,
        HelpMessage="Name of the user to connect as.")]
        [String]
        $username,
        [parameter(mandatory=$true,
        HelpMessage="Passsword of the given user.")]
        [String]
        $pw
    )

    $command = "plink -l $username -pw $pw $targetServer"
    #Write-Host "usePassword would produce the command '$command' "
    Invoke-Expression $command
}

function connectToServer() {
    Param(
        [parameter(mandatory=$true,
        HelpMessage="Name of the SSH server to connect to.")]
        [String]
        $targetServer,
        [parameter(mandatory=$false,
        HelpMessage="Name of the profile to use to construct the SSH pr PLINK command. If not supplied, assumes 'default'.")]
        [String]
        $chosenProfileName='default'
    )

    $check = checkExecutables
    if ($check -eq $false) {
        Write-Warning "One or more dependencies missing! This utility might not operate properly."
    }

    $finished  = $false;
    $printHelp = $false;

    for ($iCount = 0; $iCount -lt $connectionProfiles.profiles.count; ++$iCount) {
        # Get hold of the current profile and its data.
        $name = $connectionProfiles.profiles[$iCount].name
        $type = $connectionProfiles.profiles[$iCount].type
        $user = $connectionProfiles.profiles[$iCount].specs.username
        $cred = $connectionProfiles.profiles[$iCount].specs.data

        # is this the profile we wish to use
        if ($chosenProfileName -eq $name)
        {
            # Figure out the correct connection method.
            if ($type -eq 'pki') {
                usePKI $targetServer $user $cred
                $finished = $true;
                break
            }
            elseif ($type -eq 'password') {
                # In the event we need to use secure strings
                #$secureCred = ConvertTo-SecureString  $cred -AsPlainText -Force
                usePassword $targetServer $user $cred
                $finished = $true;
                break
            }
            else {
                Write-Error "Unknown or unsupported type $type for profile named $name"
                $printHelp = $true
            }
        }
    }

    if ($finished -eq $false) {
        Write-Warning "Choosen profile ('$chosenProfileName') not found or configuration incorrect."
        $printHelp = $true;
    }

    if ($printHelp -eq $true) { printUsage }
}


Set-Alias -name $ALIASNAME -value "connectToServer"