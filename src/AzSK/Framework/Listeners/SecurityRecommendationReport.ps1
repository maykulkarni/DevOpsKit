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

		

		 $this.RegisterEvent([SVTEvent]::CommandCompleted, {
            $currentInstance = [SecurityRecommendationReport]::GetInstance();
            try 
            {
                $props = $Event.SourceArgs[0];
            }
            catch 
            {
                $currentInstance.PublishException($_);
            }
        });
	}


}
