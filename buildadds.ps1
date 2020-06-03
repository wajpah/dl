configuration BuildDomainController
{
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xNetworking, xDnsServer
    Node localhost
    {

        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
  
        xIPAddress NewIPAddress {
            IPAddress = $node.IPAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily = 'IPV4'
        }

        xDefaultGatewayAddress NewIPGateway {
            Address = $node.GatewayAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily = 'IPV4'
            DependsOn = '[xIPAddress]NewIPAddress'
        }

        xDnsServerAddress PrimaryDNSClient {
            Address = $node.DnsAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily = 'IPV4'
            DependsOn = '[xDefaultGatewayAddress]NewIPGateway'
        }

        User Administrator {
            Ensure = 'Present'
            UserName = 'Administrator'
            Password = $Cred
            DependsOn = '[xDnsServerAddress]PrimaryDNSClient'
        }

        xComputer NewComputerName {
            Name = $node.ThisComputerName
            DependsOn = '[User]Administrator'
        }

        WindowsFeature ADDSInstall {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            DependsOn = '[xComputer]NewComputerName'
        }

        xADDomain FirstDC {
            DomainName = $node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $domainCred
            DatabasePath = $node.DCDatabasePath
            LogPath = $node.DCLogPath
            SysvolPath = $node.SysvolPath 
            DependsOn = '[WindowsFeature]ADDSInstall'
        }

        xADUser myaccount {
            DomainName = $node.DomainName
            Path = "CN=Users,$($node.DomainDN)"
            UserName = 'myaccount'
            GivenName = 'My'
            Surname = 'Account'
            DisplayName = 'My Account'
            Enabled = $true
            Password = $Cred
            DomainAdministratorCredential = $Cred
            PasswordNeverExpires = $true
            DependsOn = '[xADDomain]FirstDC'
        }

        xADUser pfajfer {
            DomainName = $node.DomainName
            Path = "CN=Users,$($node.DomainDN)"
            UserName = 'pfajfer'
            GivenName = 'Patryk'
            Surname = 'Fajfer'
            DisplayName = 'Patryk Fajfer'
            Enabled = $true
            Password = $Cred
            DomainAdministratorCredential = $Cred
            PasswordNeverExpires = $true
            DependsOn = '[xADDomain]FirstDC'
        }

        xADUser mtestowy {
            DomainName = $node.DomainName
            Path = "CN=Users,$($node.DomainDN)"
            UserName = 'mtestowy'
            GivenName = 'Maciej'
            Surname = 'Testowy'
            DisplayName = 'Maciej Testowy'
            Enabled = $true
            Password = $Cred
            DomainAdministratorCredential = $Cred
            PasswordNeverExpires = $true
            DependsOn = '[xADDomain]FirstDC'
        }

        xADUser jkowalski {
            DomainName = $node.DomainName
            Path = "CN=Users,$($node.DomainDN)"
            UserName = 'jkowalski'
            GivenName = 'Janusz'
            Surname = 'Kowalski'
            DisplayName = 'Janusz Kowalski'
            Enabled = $true
            Password = $Cred
            DomainAdministratorCredential = $Cred
            PasswordNeverExpires = $true
            DependsOn = '[xADDomain]FirstDC'
        }

        xADGroup IT {
            GroupName = 'IT'
            Path = "CN=Users,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Global'
            MembersToInclude = 'pfajfer', 'jkowalski', 'myaccount'
            DependsOn = '[xADDomain]FirstDC'
        }

        xADGroup DomainAdmins {
            GroupName = 'Domain Admins'
            Path = "CN=Users,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Global'
            MembersToInclude = 'pfajfer', 'myaccount'
            DependsOn = '[xADDomain]FirstDC'
        }

        xADGroup EnterpriseAdmins {
            GroupName = 'Enterprise Admins'
            Path = "CN=Users,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            MembersToInclude = 'pfajfer', 'myaccount'
            DependsOn = '[xADDomain]FirstDC'
        }

        xADGroup SchemaAdmins {
            GroupName = 'Schema Admins'
            Path = "CN=Users,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            MembersToInclude = 'pfajfer', 'myaccount'
            DependsOn = '[xADDomain]FirstDC'
        }

        xDnsServerADZone addReverseADZone {
            Name = '122.168.192.in-addr.arpa'
            DynamicUpdate = 'Secure'
            ReplicationScope = 'Forest'
            Ensure = 'Present'
            DependsOn = '[xADDomain]FirstDC'
        }
    }
}
            
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = "localhost"
            ThisComputerName = "dc"
            IPAddress = "192.168.122.10/24"
            DnsAddress = "192.168.122.10"
            GatewayAddress = "192.168.122.1"
            InterfaceAlias = "Ethernet0"
            DomainName="testowa.local"
            DomainDN = "DC=testowa,DC=local"
            DCDatabasePath = "C:\NTDS"
            DCLogPath = "C:\NTDS"
            SysvolPath = "C:\Sysvol"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}

$domainCred = Get-Credential -UserName testowa\Administrator -Message "Please enter a new password for Domain Administrator."
$Cred = Get-Credential -UserName Administrator -Message "Please enter a new password for Local Administrator and other accounts."

BuildDomainController -ConfigurationData $ConfigData

Set-DSCLocalConfigurationManager -Verbose -Path ".\BuildDomainController" 
Start-DscConfiguration -Wait -Force -Path .\BuildDomainController -Verbose