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
			[RecommendedSecurityReport] $report = [RecommendedSecurityReport]::new();
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
					$report.ResourceGroupName = $ResourceGroupName;
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

			$uri = "http://104.211.204.4/recommend";
			$content = [Helpers]::ConvertToJsonCustomCompressed($userInput);
			#write-host $content;
			$headers = @{};
			$result = [WebRequestHelper]::InvokeWebRequest([Microsoft.PowerShell.Commands.WebRequestMethod]::Post, $uri,$headers, $content, "application/json");
			[RecommendedSecureCombination] $Combination = [RecommendedSecureCombination]::new();
			
			if(($result | Measure-Object).Count -gt 0)
			{
				$currentFeatureGroup = [RecommendedFeatureGroup]::new();
				$currentFeatureGroup.Features = $userInput.Features;
				$currentFeatureGroup.Categories = $result.CurrentCategoryGroup;
				$currentFeatureGroup.Ranking = 2;
				$currentFeatureGroup.TotalSuccessCount = $result.TotalSuccessCount;
				$currentFeatureGroup.TotalFailCount = $result.TotalFailCount;
				$currentFeatureGroup.SecurityRating = (1-$result.SecurityRating)*100;
				$currentFeatureGroup.TotalOccurances = $result.TotalOccurrences;
				$Combination.CurrentFeatureGroup = $currentFeatureGroup;

				$result.RecommendedFeatureGroups | ForEach-Object{
					$recommendedGroup = $_;
					$recommededFeatureGroup = [RecommendedFeatureGroup]::new();
					$recommededFeatureGroup.Features = $recommendedGroup;
					$recommededFeatureGroup.Categories = $result.CurrentCategoryGroup;		
					$recommededFeatureGroup.Ranking = 2;
					$recommededFeatureGroup.TotalSuccessCount = 300;
					$recommededFeatureGroup.TotalFailCount = 100;
					$recommededFeatureGroup.SecurityRating = 60.00;
					$recommededFeatureGroup.TotalOccurances = 4;
					$Combination.RecommendedFeatureGroups += $recommededFeatureGroup;
				}

			}

			<#[RecommendedSecureCombination] $dummy = [RecommendedSecureCombination]::new();

			$dummyCFG = [RecommendedFeatureGroup]::new();
			$dummyCFG.Features = @("AppService","Storage");
			$dummyCFG.Categories = @("Web App","Storage");		
			$dummyCFG.Ranking = 2;
			$dummyCFG.TotalSuccessCount = 300;
			$dummyCFG.TotalFailCount = 100;
			$dummyCFG.SecurityRating = 60.00;
			$dummyCFG.TotalOccurances = 4;
			$dummy.CurrentFeatureGroup = $dummyCFG;

			$dummyFG1 = [RecommendedFeatureGroup]::new();
			$dummyFG1.Features = @("AppService","Storage");
			$dummyFG1.Categories = @("Web App","Storage");		
			$dummyFG1.Ranking = 2;
			$dummyFG1.TotalSuccessCount = 300;
			$dummyFG1.TotalFailCount = 100;
			$dummyFG1.SecurityRating = 60.00;
			$dummyFG1.TotalOccurances = 4;
			$dummy.RecommendedFeatureGroups += $dummyFG1;

			$dummyFG2 = [RecommendedFeatureGroup]::new();
			$dummyFG2.Features = @("AppService", "Storage","KeyVault");			
			$dummyFG2.Categories = @("Web App","Storage", "Security Infra");		
			$dummyFG2.Ranking = 1;
			$dummyFG2.TotalSuccessCount = 350;
			$dummyFG2.TotalFailCount = 50;
			$dummyFG2.SecurityRating = 60.00;
			$dummyFG2.TotalOccurances = 4;
			$dummy.RecommendedFeatureGroups += $dummyFG2;

			$dummyFG3 = [RecommendedFeatureGroup]::new();
			$dummyFG3.Features = @("AppService", "Automation","KeyVault");			
			$dummyFG3.Categories = @("Web App","Backend Processing", "Security Infra");		
			$dummyFG3.Ranking = 1;
			$dummyFG3.TotalSuccessCount = 350;
			$dummyFG3.TotalFailCount = 50;
			$dummyFG3.SecurityRating = 60.00;
			$dummyFG3.TotalOccurances = 4;
			$dummy.RecommendedFeatureGroups += $dummyFG3; #>
			#Write-Host ($dummy | ConvertTo-Json -Depth 10)
			[MessageData] $message = [MessageData]::new();
			$message.Message = "RecommendationData"
			$report.Input = $userInput;
			$report.Recommendations =$Combination;
			$message.DataObject = $report;
			$messages += $message;
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

