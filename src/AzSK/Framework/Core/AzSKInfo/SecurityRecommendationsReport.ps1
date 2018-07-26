Set-StrictMode -Version Latest 

class SecurityRecommendationsReport: CommandBase
{    
	
	hidden [PSObject] $AzSKRG = $null
	hidden [String] $AzSKRGName = ""


	SecurityRecommendationsReport([string] $subscriptionId, [InvocationInfo] $invocationContext): 
        Base($subscriptionId, $invocationContext) 
    { 
		#$this.DoNotOpenOutputFolder = $true;
		$this.AzSKRGName = [ConfigurationManager]::GetAzSKConfigData().AzSKRGName;
		$this.AzSKRG = Get-AzureRmResourceGroup -Name $this.AzSKRGName -ErrorAction SilentlyContinue
	}
	

	[MessageData[]] GenerateReport([string] $ResourceGroupName, [ResourceTypeName[]] $ResourceTypeNames,[string[]] $Categories)
    {		    	    
	    [MessageData[]] $messages = @();	   
		try
		{
			[SecurityReportInput] $userInput = [SecurityReportInput]::new();
			if(-not [string]::IsNullOrWhiteSpace($ResourceGroupName))
			{
				$resources = Find-AzureRmResource -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
				if(($resources | Measure-Object).Count -gt 0)
				{
					[SVTMapping]::GetSupportedResourceMap();
					$resources | ForEach-Object{						
						if($null -ne [SVTMapping]::SupportedResourceMap[$_.ResourceType.ToLower()])
						{
							$userInput.Features += ([SVTMapping]::SupportedResourceMap[$_.ResourceType.ToLower()]).ToString();
						}
					}	
				}
				elseif(($ResourceTypeNames | Measure-Object).Count -gt 0)
				{
					$ResourceTypeNames | ForEach-Object { $userInput.Features += $_.ToString();}
				}
				elseif(($Categories | Measure-Object).Count -gt 0)
				{
					$userInput.Categories = Categories
				}
			}

			$uri = "";
			$content = [Helpers]::ConvertToJsonCustomCompressed($userInput);
			write-host $content;
			$headers = @();
			#$result = [Helpers]::InvokeWebRequest("Post", $uri,$headers, $content, "application/json");
			[RecommendedSecureCombination] $dummy = [RecommendedSecureCombination]::new();

			$dummy.CompliancePercentage = 60.00;
			$dummy.TotalOccurances = 5;
			$dummy.IsCurrentGroupRecommended = $true;
			$dummyFG1 = [RecommendedFeatureGroup]::new();
			$dummyFG1.Features = @("AppService","Storage");
			# $dummyFG1.Features.Add("AppService");
			# $dummyFG1.Features.Add("Storage");
			$dummyFG1.Ranking = 2;
			$dummyFG1.TotalSuccessCount = 300;
			$dummyFG1.TotalFailCount = 100;
			$dummy.RecommendedFeatureGroups += $dummyFG1;

			$dummyFG2 = [RecommendedFeatureGroup]::new();
			$dummyFG2.Features = @("AppService", "Storage","KeyVault");
			# $dummyFG2.Features.Add("AppService");
			# $dummyFG2.Features.Add("Storage");
			# $dummyFG2.Features.Add("KeyVault");
			$dummyFG2.Ranking = 1;
			$dummyFG2.TotalSuccessCount = 350;
			$dummyFG2.TotalFailCount = 50;
			$dummy.RecommendedFeatureGroups += $dummyFG2;
			Write-Host ($dummy | ConvertTo-Json -Depth 10)
			#$outputReponse = [RecommendedSecureCombination]($result)
			#AddToMessages
			#$messages.
			
		}
		catch
		{
			$this.PublishEvent([AzSKGenericEvent]::Exception, "Unable to generate the security recommendation report");
			$this.PublishException($_);
		}
		return $messages;
	}
}

