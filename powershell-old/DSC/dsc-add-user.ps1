configuration AddUser
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $Credential
    )    

    Node localhost {      
     
        User LocalAdmin
        {
            Username = $Credential.UserName
            Password = $Credential
            Disabled = $false
            Ensure = "Present"
            FullName = "Local Admin"
            Description = "Local Admin, created via DSC"
            PasswordNeverExpires = $true
        } 

        Group Administrators {
            GroupName = "Administrators"
            DependsOn = "[User]LocalAdmin"
            MembersToInclude = $Credential.UserName
        }

    }  
}