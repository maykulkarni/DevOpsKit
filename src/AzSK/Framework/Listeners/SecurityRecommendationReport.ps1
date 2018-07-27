Set-StrictMode -Version Latest 
#Listner to write CA scan status on completion of resource scan 
class SecurityRecommendationReport: ListenerBase
{
    hidden static [SecurityRecommendationReport] $Instance = $null;
    static [SecurityRecommendationReport] GetInstance()
    {
        if ( $null -eq  [SecurityRecommendationReport]::Instance)
        {
            [SecurityRecommendationReport]::Instance = [SecurityRecommendationReport]::new();
        }    
        return [SecurityRecommendationReport]::Instance
    }


	[void] RegisterEvents()
    {
        $this.UnregisterEvents();       

        $this.RegisterEvent([AzSKRootEvent]::GenerateRunIdentifier, {
            $currentInstance = [SecurityRecommendationReport]::GetInstance();
            try 
            {
                $currentInstance.SetRunIdentifier([AzSKRootEventArgument] ($Event.SourceArgs | Select-Object -First 1));
            }
            catch 
            {
                $currentInstance.PublishException($_);
            }
        });

		

		 $this.RegisterEvent([AzSKRootEvent]::CommandCompleted, {
            $currentInstance = [SecurityRecommendationReport]::GetInstance();
            try 
            {
                $messages = $Event.SourceArgs.Messages;
                if(($messages | Measure-Object).Count -gt 0 -and $Event.SourceArgs.Messages[0].Message -eq "RecommendationData")
                {
                    $reportTemplateFileContent = [ConfigurationHelper]::LoadOfflineConfigFile("SecurityRecommendationReport.html", $false);
                    $reportObject = [RecommendedSecurityReport] $Event.SourceArgs.Messages[0].DataObject;
                    
                    if([string]::IsNullOrWhiteSpace($reportObject.ResourceGroupName))
                    {
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#rgName#]", "Not Specified");
                    }
                    else {
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#rgName#]", "[$($reportObject.ResourceGroupName)]");
                    }

                    if(($reportObject.Input.Features | Measure-Object).Count -le 0)
                    {
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#features#]", "Not Specified");
                    }
                    else {
                        $featuresString = [String]::Join(",", $reportObject.Input.Features);
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#features#]", "[$featuresString]");
                    }

                    if(($reportObject.Input.Categories | Measure-Object).Count -le 0)
                    {
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#categories#]", "Not Specified");
                    }
                    else {
                        $categoriesString = [String]::Join(",", $reportObject.Input.Categories);                        
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#categories#]", "[$categoriesString]");
                    }                    
                    if($null -ne $reportObject.Recommendations.CurrentFeatureGroup)
                    {
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#cgranking#]", "$($reportObject.Recommendations.CurrentFeatureGroup.Ranking)");
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#cgInstCount#]", "$($reportObject.Recommendations.CurrentFeatureGroup.TotalOccurances)");
                        $featuresString = [String]::Join(",", $reportObject.Recommendations.CurrentFeatureGroup.Features);
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#cgF#]", "$featuresString");
                        $categoriesString = [String]::Join(",", $reportObject.Recommendations.CurrentFeatureGroup.Categories);
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#cgC#]", "$categoriesString");
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#cgPass#]", "$($reportObject.Recommendations.CurrentFeatureGroup.TotalSuccessCount)]");
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#cgFail#]", "$($reportObject.Recommendations.CurrentFeatureGroup.TotalFailCount)]");
                    }
                    else {
                        #TODO: need to hide the div
                        #$currentInstance.WriteMessage("Cannot find exact matching combination for the current user input.", [MessageType]::Default);
                    }
                    if(($reportObject.Recommendations.RecommendedFeatureGroups | Measure-Object).Count -gt 0)
                    {
                        $recommendationTemplate = @"
                        <table class="tablePadding">
                    <tr><div class="dataPoint" id="cgranking[#i#]"><td class="masterCol"> Category Group Ranking</td><td class="tablePadding"> [#cgranking#]</td></b></div></tr>
              <tr><div class="dataPoint" id="instcount[#i#]"><td class="masterCol"> No. of instances with same combination</td><td class="tablePadding"> [#instcount#]</td></div></tr>
              <tr><div class="dataPoint" id="fc[#i#]"><td class="masterCol"> Feature combination</td><td class="tablePadding">[#fc#]</td></div></tr>
              <tr><div class="dataPoint" id="cc[#i#]"> <td class="masterCol">Category Combination</td><td class="tablePadding"> [#cc#]</td></div></tr>
              <tr><div class="dataPoint" id="measures[#i#]"><td class="masterCol"> Measures</td><td class="tablePadding"> [Total Pass: [#pass#] [Total Fail: [#fail#]]</td></div></tr>
              </table>
              <br />
"@;

                        $recommendationHtml = "";
                        $i = 0;
                        $orderedRecommendations = $reportObject.Recommendations.RecommendedFeatureGroups | Sort-Object -Property Ranking
                        $orderedRecommendations | ForEach-Object {
                            $recommendation = $_;
                            $i = $i + 1;
                            $recommendationPart = $recommendationTemplate.Replace("[#i#]", $i);
                            $recommendationPart = $recommendationPart.Replace("[#cgranking#]","$($recommendation.Ranking)");
                            $recommendationPart = $recommendationPart.Replace("[#instcount#]","$($recommendation.TotalOccurances)");
                            $featuresString = [String]::Join(",", $recommendation.Features);
                            $recommendationPart = $recommendationPart.Replace("[#fc#]","$featuresString");
                            $categoriesString = [String]::Join(",", $recommendation.Categories);
                            $recommendationPart = $recommendationPart.Replace("[#cc#]","$categoriesString");
                            $recommendationPart = $recommendationPart.Replace("[#pass#]","$($recommendation.TotalSuccessCount)");
                            $recommendationPart = $recommendationPart.Replace("[#fail#]","$($recommendation.TotalFailCount)");
                            $recommendationHtml += $recommendationPart
                        }
                        $reportTemplateFileContent = $reportTemplateFileContent.Replace("[#recommendations#]", "$recommendationHtml");
                    }
                    
                    $reportFilePath = [WriteFolderPath]::GetInstance().FolderPath + "/SecurityRecommendationReport-" + $currentInstance.RunIdentifier + ".html";
                    $reportTemplateFileContent | Out-File -FilePath $reportFilePath -Force;
				}
            }
            catch 
            {
                $currentInstance.PublishException($_);
            }
        });
	}


}
