# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# -------------------------------------------------------------------------

LOCAL_DATA = "../Test/new_big_data.csv"
IGNORE_LIST = ["CoreControls", "AzSKCfg", "AzSDKCfg"]

# file name to save to disk in production mode
MODE = "LOCAL"
PROD_DATA = "prod_data.csv"

# MySQL fetching query
MYSQL_QUERY = "SELECT * FROM DBO.LASTKNOWNSERVICESCANRESULTJOINED"

# list of features, every feature is assigned a
# prime number to calculate hash
# see recommendation_engine.get_hash for hash logic
feature_hash = {
	"ContainerRegistry": 13,
	"ServiceBus": 17,
	"CDN": 19,
	"SQLDatabase": 23,
	"AppService": 29,
	"StreamAnalytics": 31,
	"KeyVault": 37,
	"Storage": 41,
	"Automation": 43,
	"EventHub": 47,
	"LogicApps": 53,
	"TrafficManager": 59,
	"VirtualNetwork": 61,
	"DataLakeStore": 67,
	"CosmosDB": 71,
	"RedisCache": 73,
	"DataFactory": 79,
	"DataLakeAnalytics": 83,
	"NotificationHub": 89,
	"ServiceFabric": 97,
	"Search": 101,
	"VirtualMachine": 103,
	"AnalysisServices": 107,
	"Batch": 109,
	"ODG": 113,
	"ERvNet": 127,
	"CloudService": 131,
	"LoadBalancer": 137,
	"APIConnection": 139,
	"BotService": 149,
	"ContainerInstances": 151,
	"DataFactoryV2": 157,
	"Databricks": 163,
}


category_hash = {
	"DataStorage": 13,
	"DataProcessing": 17,
	"ReportingAndAnalytics": 19,
	"WebFrontEnd": 23,
	"API": 29,
	"SecurityInfra": 31,
	"SubscriptionCore": 37,
	"Messaging": 41,
	"Hybrid": 43,
	"NetworkInfra": 47,
	"Caching": 53,
	"BackendProcessing": 59,
	"Repository": 61
}

# maps features to its parents categories
# one feature may fall under multiple categories

get_categories = {
	"CDN": ["DataStorage"],
	"ServiceBus": ["Messaging", "Hybrid"],
	"AppService": ["WebFrontEnd", "API"],
	"SQLDatabase": ["DataStorage", "DataProcessing", "ReportingAndAnalytics"],
	"Storage": ["DataStorage"],
	"LogicApps": ["DataProcessing"],
	"DataFactory": ["DataProcessing", "BackendProcessing"],
	"DataLakeAnalytics": ["ReportingAndAnalytics", "DataProcessing"],
	"Databricks": ["ReportingAndAnalytics", "DataProcessing"],
	"DataLakeStore": ["DataStorage", "ReportingAndAnalytics", "DataProcessing"],
	"NotificationHub": ["Messaging"],
	"ServiceFabric": ["WebFrontEnd", "API", "BackendProcessing"],
	"Search": ["API"],
	"VirtualMachine": ["API", "BackendProcessing", "WebFrontEnd",
					   "DataProcessing", "DataStorage"],
	# Repository or ImageRepository?
	"ContainerRegistry": ["Repository"],
	"VirtualNetwork": ["NetworkInfra", "Hybrid"],
	"AnalysisServices": ["DataProcessing", "ReportingAndAnalytics"],
	"Batch": ["BackendProcessing"],
	"RedisCache": ["Caching"],
	"EventHub": ["Messaging", "Hybrid"],
	"ODG": ["Hybrid"],
	"TrafficManager": ["NetworkInfra"],
	"ERvNet": ["Hybrid", "NetworkInfra"],
	"Automation": ["BackendProcessing"],
	"CosmosDB": ["DataStorage", "ReportingAndAnalytics"],
	"StreamAnalytics": ["ReportingAndAnalytics", "DataProcessing"],
	"CloudService": ["WebFrontEnd", "API", "BackendProcessing"],
	"LoadBalancer": ["NetworkInfra"],
	"APIConnection": ["DataProcessing"],
	"BotService": ["Messaging", "API", "WebFrontEnd"],
	"ContainerInstances": ["WebFrontEnd", "API", "DataProcessing",
						   "BackendProcessing"],
	"DataFactoryV2": ["DataProcessing", "BackendProcessing"],
	"KeyVault": ["SecurityInfra"]
}

# Hybrid: Technology that enables access across hybrid environments such as
# accessing data in a corporate network from a cloud service, or vice versa.

# big prime number to limit the value
# used in hashing functions
BIG_PRIME = 824633720831


def get_csv_filename():
	if MODE == "LOCAL":
		filename = LOCAL_DATA
	elif MODE == "PROD":
		filename = PROD_DATA
	else:
		raise ValueError("Unknown MODE")
	assert filename is not None
	return filename


new_category_names = {
	"Storage": "DataStorage",
	"DataProcessing": "DataProcessing",
	"Reporting": "ReportingAndAnalytics",
	"Web Front End": "WebFrontEnd",
	"APIs": "API",
	"Security Infra": "SecurityInfra",
	"SubscriptionCore": "SubscriptionCore",
	"Commuincation Hub": "Messaging",
	"Hybrid": "Hybrid",
	"Network Isolation": "NetworkInfra",
	"Cache": "Caching",
	"Backend Processing": "BackendProcessing",
	"Repository": "Repository",
}
