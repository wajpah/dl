powershell -command "& {wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -outfile remotingansible.ps1}"
powershell -command "& {.\remotingansible.ps1 -enablecredspp -disablebasicauth}"
powershell -command "& {get-childitem -path wsman:\localhost\listener |where-object {$_.Keys -eq "Transport=HTTP"} |remove-item -recurse -force}"