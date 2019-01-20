function tailFile(){
    Param(
        [parameter(mandatory=$true,
        HelpMessage="File to tail.")]
        [String]
        $file
    )
    Get-Content $file -Wait
}

Set-Alias -name "tail" -value "tailFile"