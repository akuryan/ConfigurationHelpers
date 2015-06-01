<#
    .SYNOPSIS
        This Azure Automation runbook automates the scheduled shutdown and startup of virtual machines in an Azure subscription. 

    .DESCRIPTION
        The runbook implements a solution for scheduled power management of Azure virtual machines in combination with tags
        on resource groups which define a shutdown schedule. Each time it runs, the runbook looks for all resource groups with
        a tag named "AutoShutdownSchedule" having a value defining the schedule, e.g. "10PM -> 6AM". It then checks the current
        time against each schedule entry, ensuring that VMs in tagged groups are shut down or started to conform to the schedule.

        This runbook requires the Azure Resource Manager module to be present in the Azure Automation account. This module must be imported
        separately at the time of this writing. For more details, see: 
        
        https://automys.com/library/asset/scheduled-virtual-machine-shutdown-startup-microsoft-azure

    .PARAMETER  AzureCredentialName
        The name of the PowerShell credential asset in the Automation account that contains username and password
        for the account used to connect to target Azure subscription. This user must be configured as co-administrator
        of the subscription. 

        By default, the runbook will use the credential with name "Default Automation Credential"

        For for details on credential configuration, see:
        http://azure.microsoft.com/blog/2014/08/27/azure-automation-authenticating-to-azure-using-azure-active-directory/
    
    .PARAMETER  AzureSubscriptionName
        The name of Azure subscription in which the resources will be created. By default, the runbook will use 
        the value defined in the Variable setting named "Default Azure Subscription"

    .EXAMPLE
        For testing example, see the documentation at:

        https://automys.com/library/asset/scheduled-virtual-machine-shutdown-startup-microsoft-azure
    
    .INPUTS
        None.

    .OUTPUTS
        Human-readable informational and error messages produced during the job. Not intended to be consumed by another runbook.
#>

workflow Assert-AutoShutdownSchedule
{
    Param
    (
		[parameter(Mandatory=$false)]
        [String] $AzureCredentialName = "Use *Default Automation Credential* Asset",

        [parameter(Mandatory=$false)]
        [String] $AzureSubscriptionName = "Use *Default Azure Subscription* Variable Value"
    )
   	
    # Note: Use of "Write-Output" is not recommended generally for recording informational or error messages
    # but is used here for ease of seeing everything in the "Output" pane in the Azure portal
    Write-Output "Runbook started"
	$currDate = Get-Date
	Write-Output($currDate)
    # Retrieve credential name from variable asset if not specified
    if($AzureCredentialName -eq "Use *Default Automation Credential* asset")
    {
        $azureCredential = Get-AutomationPSCredential -Name "Default Automation Credential"
        if($azureCredential -eq $null)
        {
			Write-Output "ERROR: No automation credential name was specified, and no credential asset with name 'Default Automation Credential' was found. Either specify a stored credential name or define the default using a credential asset"
            Write-Output "Exiting runbook due to error"
			return
        }
    }
    else
    {
        $azureCredential = Get-AutomationPSCredential -Name $AzureCredentialName
        if($azureCredential -eq $null)
        {
            Write-Output "ERROR: Failed to get credential with name [$AzureCredentialName]"
			Write-Output "Exiting runbook due to error"
            return
        }
    }
    
    # Connect to Azure using credential asset
    $addAccountResult = Add-AzureAccount -Credential $azureCredential

    # Retrieve subscription name from variable asset if not specified
    if($AzureSubscriptionName -eq "Use *Default Azure Subscription* Variable Value")
    {
        $AzureSubscriptionName = Get-AutomationVariable -Name "Default Azure Subscription"
        if($AzureSubscriptionName.length -eq 0)
        {
            Write-Output "ERROR: No subscription name was specified, and no variable asset with name 'Default Azure Subscription' was found. Either specify an Azure subscription name or define the default using a variable setting"
            Write-Output "Exiting runbook due to error"
			return
        }
    }
    
    # Validate subscription
    InlineScript 
    {
        $subscription = Get-AzureSubscription -Name $Using:AzureSubscriptionName
        if($subscription -eq $null)
        {
            Write-Output "ERROR: No subscription found with name [$Using:AzureSubscriptionName] that is accessible to user [$($Using:azureCredential.UserName)]"
			Write-Output "Exiting runbook due to error"
            return
        }
    }
    
	# Select the Azure subscription we will be working against
    $subscriptionResult = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    
    InlineScript
	{
		# Define function to check current time against specified range
	    function CheckScheduleEntry ([string]$TimeRange)
	    {	
	        # Initialize variables
	        $rangeStart, $rangeEnd, $parsedDay = $null
	        $currentTime = (Get-Date).ToUniversalTime()
	    
	        Write-Output "Checking current time [$($currentTime.ToString("yyyy MMM dd HH:mm:ss"))] against range [$TimeRange]"
	
	        try
	        {
	            # Parse as range if contains '->'
	            if($TimeRange -like "*->*")
	            {
	                $timeRangeComponents = $TimeRange -split "->" | foreach {$_.Trim()}
	                if($timeRangeComponents.Count -eq 2)
	                {
	                    $rangeStart = Get-Date $timeRangeComponents[0]
	                    $rangeEnd = Get-Date $timeRangeComponents[1]
	
	                    # Check for crossing midnight. If start is greater than end, interpret start time as yesterday.
	                    if($rangeStart -gt $rangeEnd)
	                    {
	                        $rangeStart = $rangeStart.AddDays(-1)
	                    }
	                }
	                else
	                {
	                    Write-Output "`tWARNING: Invalid time range format. Expects valid .Net DateTime-formatted start time and end time separated by '->'" 
	                }
	            }
	            # Otherwise attempt to parse as a full day entry, e.g. 'Monday' or 'December 25' 
	            else
	            {
	                # If specified as day of week, check if today
	                if([System.DayOfWeek].GetEnumValues() -contains $TimeRange)
	                {
	                    if($TimeRange -eq (Get-Date).DayOfWeek)
	                    {
	                        $parsedDay = Get-Date "00:00"
	                    }
	                    else
	                    {
	                        Write-Output "`tSkipping detected day of week [$TimeRange] that isn't today"
	                    }
	                }
	                # Otherwise attempt to parse as a date, e.g. 'December 25'
	                else
	                {
	                    $parsedDay = Get-Date $TimeRange
	                }
	    
	                if($parsedDay -ne $null)
	                {
	                    $rangeStart = $parsedDay # Defaults to midnight
	                    $rangeEnd = $parsedDay.AddHours(23).AddMinutes(59).AddSeconds(59) # End of the same day
	                }
	            }
	        }
	        catch
	        {
	            # Record any errors and return false by default
	            Write-Output "`tWARNING: Exception encountered while parsing time range. Details: $($_.Exception.Message). Check the syntax of entry, e.g. '<StartTime> -> <EndTime>', or days/dates like 'Sunday' and 'December 25'"   
	            return $false
	        }
	
	        # Check if current time falls within range
	    
	        if($currentTime -ge $rangeStart -and $currentTime -le $rangeEnd)
	        {
	            return $true
	        }
	        else
	        {
	            return $false
	        }
	
	    } # End function CheckScheduleEntry
		
		# Get resource groups that are tagged for automatic shutdown of resources
		$taggedResourceGroups = @() 
		$taggedResourceGroups += Get-AzureResourceGroup | where {$_.Tags.Count -gt 0 -and $_.Tags.Name -contains "AutoShutdownSchedule"}
		
		# If no tagged groups found, return without action
		if($taggedResourceGroups.Count -eq 0)
		{
		    Write-Output "No resource groups found with 'AutoShutdownSchedule' tag."
		    return
		}
		
		# Process each group, building a table of desired VM state
		$targetVMState = @{}
		foreach($group in $taggedResourceGroups)
		{
			# Get the shutdown time ranges definition tag and extract the value
		    $shutdownTag =  $group.Tags | where Name -eq "AutoShutdownSchedule"
		    $shutdownTimeRangesDefinition = $shutdownTag.Value
		    
		    Write-Output "Found resource group [$($group.ResourceGroupName)] with 'AutoShutdownSchedule' tag with value [$shutdownTimeRangesDefinition]. Checking schedules..."
		
		    # Parse the ranges in the Tag value. Expects a string of comma-separated time ranges, or a single time range
		    $timeRangeList = @()
		    $timeRangeList += $shutdownTimeRangesDefinition -split "," | foreach {$_.Trim()}
		
		    # Check each range against the current time to see if any schedule is matched
		    $scheduleMatched = $false
		    foreach($entry in $timeRangeList)
		    {
		        if((CheckScheduleEntry -TimeRange $entry) -eq $true)
		        {
		            $scheduleMatched = $true
		            break
		        }
		    }
		
		    # Record desired state for group resources based on result. If schedule is matched, shut down the VM if it is running. Otherwise start the VM if stopped.
		    if($scheduleMatched)
		    {
		        Write-Output "Current time falls within the range [$entry]"
		        
		        # Set target state as stopped
		        $targetState = "StoppedDeallocated"
		    }
		    else
		    {
		        Write-Output "Current time is outside of all shutdown schedule ranges for resource group [$($group.ResourceGroupName)]"
		        
		        # Set target state as stopped
		        $targetState = "Started"
		    }
		
		    # Get VM resources in group and record target state for each in table
		    $taggedVMs = $group | Get-AzureResource | where ResourceType -eq "Microsoft.ClassicCompute/virtualMachines"
		    foreach($vmResource in $taggedVMs)
		    {
		        $targetVMState.Add($vmResource.Name, $targetState)
		    }
		}
		
		Write-Output "Checking all virtual machines for desired power state"
		
		# Get list of Azure VMs
		$vmList = Azure\Get-AzureVM
		Write-Output "Number of Virtual Machines found in subscription: [$($vmList.Count)]"
		
		# Ensure each of the VMs is in the desired state
		foreach($entry in $targetVMState.GetEnumerator())
		{	
		    # Get the VM matching this configuration entry
		    $vm =  $vmList | where Name -eq $entry.Name
		
		    # Check for unmatched name case
		    if($vm.Count -eq 0)
		    {
		        Write-Output "WARNING: No virtual machine found with name from resource [$($entry.Name)]"
		        continue
		    }
		
		    # Check for duplicate name case
		    if($vm.Count -gt 1)
		    {
		        Write-Output "WARNING: More than one virtual machine found with name [$($entry.Name)]. Please ensure all VM names are unique in subscription. Skipping these VMs."
		        continue
		    }
		
		    # If should be started and isn't, start VM
		    if($entry.Value -eq "Started" -and $vm.PowerState -notmatch "Started|Starting")
		    {
		        Write-Output "Starting VM [$($entry.Name)]"
		        $vm | Azure\Start-AzureVM
		    }
		
		    # If should be stopped and isn't, stop VM
		    if($entry.Value -eq "StoppedDeallocated" -and $vm.PowerState -ne "Stopped")
		    {
		        Write-Output "Stopping VM [$($entry.Name)]"
		        $vm | Azure\Stop-AzureVM -Force
		    }
		}
		
		Write-Output "All VMs configured for correct power state based on current time"
	}
	  
    Write-Output "Runbook completed"
    
    # End of runbook
}