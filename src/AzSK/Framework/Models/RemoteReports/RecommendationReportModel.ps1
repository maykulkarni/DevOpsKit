Set-StrictMode -Version Latest

class SecurityReportInput
{        
    [string[]] $Categories = @();
    [string[]] $Features = @();    
}

class RecommendedSecureCombination
{
    [RecommendedFeatureGroup[]] $RecommendedFeatureGroups;
    [float] $CompliancePercentage;
    [int] $TotalOccurances;    
    [bool] $IsCurrentGroupRecommended;
}

class RecommendedFeatureGroup{
    [string[]] $Features;
    [int] $Ranking;
    [int] $TotalSuccessCount;
    [int] $TotalFailCount;
}
# 
# class Category
# {
# 	static [string] $Storage = "Storage";
#     static [string] $WebFrontEnd = "Web Front End";
#     static [string] $APIs = "APIs";
#     static [string] $Cache = "Cache";
#     static [string] $NetworkIsolation = "Network Isolation";
#     static [string] $CommuincationHub = "Commuincation Hub";
#     static [string] $Logs = "Logs";
#     static [string] $Reporting = "Reporting";
#     static [string] $DataProcessing = "DataProcessing";
#     static [string] $SubscriptionCore = "SubscriptionCore";
#     static [string] $BackendProcessing = "Backend Processing";
#     static [string] $Hybrid = "Hybrid";
#     static [string] $SecurityInfra = "Security Infra";

# }