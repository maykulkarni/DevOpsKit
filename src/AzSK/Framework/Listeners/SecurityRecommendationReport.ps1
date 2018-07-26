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
					$dataObject = $Event.SourceArgs.Messages[0].DataObject;
					Write-Host ($dataObject | ConvertTo-Json -Depth 10)
				}
            }
            catch 
            {
                $currentInstance.PublishException($_);
            }
        });
	}


}
