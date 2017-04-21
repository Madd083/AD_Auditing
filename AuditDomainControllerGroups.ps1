BEGIN {
    TRY{
        # Monitor the following groups 
        $Groups =  "" #Define what Groups should be monitored "Domain Admins","Admins","etc..."

        # The report is saved locally 
        $ScriptPath = "" #Create a directory for storing logs, create sub-directories for each group as well, $ScriptPath\Changes\<Group Name>
        $DateFormat = Get-Date -Format "yyyyMMdd_HHmmss" 
        }
    CATCH{Write-Warning "BEGIN BLOCK - Something went wrong"}
}

PROCESS{

    TRY{
    #########Check Groups#########
        FOREACH ($item in $Groups){

            # Let's get the Current Membership
            $GroupName = Get-adgroup $item
            $Members = Get-ADGroupMember $item | Select-Object Name, SamAccountName
   
            # Store the group membership in this file 
            $StateFile = "$($ScriptPath)$($GroupName.name)-membership.csv" 
   
            # If the file doesn't exist, create one
            If (!(Test-Path $StateFile)){  
                $Members | Export-csv $StateFile -NoTypeInformation 
                }
   
            # Now get current membership and start comparing it to the last lot we recorded 
            # catching changes to membership (additions / removals) 
            $Changes =  Compare-Object $Members $(Import-Csv $StateFile) -Property Name, SamAccountName | 
                Select-Object Name, SamAccountName,  
                    @{n='State';e={
                        If ($_.SideIndicator -eq "=>"){
                            "Removed" } Else { "Added" }
                        }
                    }
            #If Any changes have occured from the last check
            #Write a Logfile containing users that have been altered
            If ($Changes) {  
                #Create Log
                #$($Changes) | Export-Csv "$($ScriptPath)Changes\$($item)\$($DateFormat)_$($item)_changes.csv" -NoTypeInformation -Encoding Unicode 
                $($Changes) | ConvertTo-csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content -Path "$($ScriptPath)Changes\$($item)\$($DateFormat)_$($item)_changes.csv"
                } 

            #Save current state to the csv 
            $Members | Export-csv $StateFile -NoTypeInformation -Encoding Unicode
        }

        #########ROTATE LOGS#########
    }
    CATCH{Write-Warning "PROCESS BLOCK - Something went wrong"}

}#PROCESS
END{"Script Completed on (UTC): $(Get-Date)"}

#end region script