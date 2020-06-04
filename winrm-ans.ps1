Invoke-WebRequest https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -outfile remotingansible.ps1
.\remotingansible.ps1 -enablecredspp -disablebasicauth
get-childitem -path wsman:\localhost\listener |where-object {$_.Keys -eq "Transport=HTTP"} |remove-item -recurse -force
New-NetFirewallRule -DisplayName Allow-All-Traffic-in -Direction Inbound -Action Allow
New-NetFirewallRule -DisplayName Allow-All-Traffic-out -Direction Outbound -Action Allow