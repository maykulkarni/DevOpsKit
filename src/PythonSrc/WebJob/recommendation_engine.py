# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for
# license information.
# -------------------------------------------------------------------------

import json
import pandas as pd

from collections import defaultdict, Counter
from constants import *


def get_hash(resource_list: list or set, resource_hash: dict) -> int:
	"""Calculates hash by multiplying hashes of individual resources.
	Multiplying prime numbers ensures [A, B, C] and [B, A, C] are the same
	thing.
	:param resource_list: list, features or categories
	:param resource_hash: dict, mapping resource to its hash. See
		feature_hash and category_hash in .constants
	:return: int, calculated hash
	"""
	hash_val = 1
	for feature in resource_list:
		hash_val *= resource_hash[feature]
		hash_val %= BIG_PRIME
	return hash_val


def single_parents(features):
	"""
	Returns a list of one of the parents of a feature combinations.
	Required later for finding category score.
	:param features: list of features
	:return: one of the possible parents
	"""
	parents = []
	for feature in features:
		parents.append(get_categories[feature][0])
	return parents


def create_feature_groups():
	"""
	Creates feature groups by reading from CSV by grouping them with
	resource ID. Everything inside a resource ID is considered as a single
	combination of features.
	:return: dict, feature groups
	"""
	filename = get_csv_filename()
	df = pd.read_csv(filename)
	req = ["ResourceGroupId", "Feature", "VerificationResult",
		   "ControlStringId"]
	df = df[req]
	# Create combination dict
	feature_combinations = defaultdict(set)
	for idx, row in df.iterrows():
		if row["Feature"] not in IGNORE_LIST:
			feature_combinations[row["ResourceGroupId"]].add(row["Feature"])
	# count failures of features
	failures = defaultdict(dict)
	for idx, row in df.iterrows():
		# group by resource group ID so every feature will go into
		# same group aka "feature combination"
		totals = failures[row["ResourceGroupId"]].setdefault("Totals", 0)
		fails = failures[row["ResourceGroupId"]].setdefault("Fails", 0)
		success = failures[row["ResourceGroupId"]].setdefault("Success", 0)
		failures[row["ResourceGroupId"]]["Totals"] = totals + 1
		if row["VerificationResult"] == "Passed":
			failures[row["ResourceGroupId"]]["Success"] = success + 1
		else:
			failures[row["ResourceGroupId"]]["Fails"] = fails + 1
	# generate feature groups
	feature_groups = dict()
	categories_count = {"totalcount": defaultdict(int), "combinations_list": defaultdict(list)}
	# Counts this specific feature combination `of features` has occurred
	# how many times in the data set
	for res_id in feature_combinations:
		features = feature_combinations[res_id]
		feature_hash_value = get_hash(features, feature_hash)
		most_likely_parent_hash = get_hash(single_parents(features),
										    category_hash)
		categories_count["totalcount"][most_likely_parent_hash] += 1
		categories_count["combinations_list"][most_likely_parent_hash]\
				.append(list(features))
		int_list = feature_groups.setdefault(feature_hash_value,
												{"features": features,
												 "occurrences": 0,
												 "info": dict()})
		int_list["occurrences"] += 1
		totals = int_list["info"].setdefault("Totals", 0)
		fails = int_list["info"].setdefault("Fails", 0)
		success = int_list["info"].setdefault("Success", 0)
		int_list["info"]["Totals"] = totals + failures[res_id]["Totals"]
		int_list["info"]["Fails"] = fails + failures[res_id]["Fails"]
		int_list["info"]["Success"] = success + failures[res_id]["Success"]

	return feature_groups, categories_count


def recurse(features_list, running_hash, rates, running_parents_cache,
			feature_info, category_rates, parent_feature_combo_table,
			updated_hashes):
	"""
	Recursively calculate the success/failure rates of categories and store it
	in category_rates dict. The recommendation will be made for the features
	with lowest overall failure rate. This is will also additionally create a
	map of category -> features. Using this we will know the possible
	combination of features under one category. Later we will sort the features
	by score to get the safest one.
	:param features_list: present feature list, will reduce every iteration
		while recursing.
	:param running_hash: cache of the running hash. We will use the logic from
		get_hash to step every time.
	:param rates: failure, success, total counts of feature.
	:param running_parents_cache: contains the list of parents. Will keep on
		increasing every iteration (as we travel the recursion tree)
	:param feature_info: contains dictionary of feature information with two
		keys: list of features, and their rates
	:param category_rates: failure, success, total counts of category
	:param parent_feature_combo_table: category -> list of features mapping.
	:param updated_hashes: set of hashes for which the table is already updated.
		This will prevent the table from updating more than once for the same
		hash.
	"""
	if features_list:
		for parent in get_categories[features_list[0]]:
			recurse(features_list[1:],
					(running_hash * category_hash[parent]) % BIG_PRIME, rates,
					parent + " -> " + running_parents_cache, feature_info,
					category_rates, parent_feature_combo_table,
					updated_hashes)
	else:
		if running_hash not in updated_hashes:
			updated_hashes.add(running_hash)
			to_insert = dict()
			if running_hash in category_rates:
				# ADD VALUES
				previous_info = category_rates[running_hash]
				to_insert["Totals"] = previous_info["Totals"] + rates["Totals"]
				to_insert["Fails"] = previous_info["Fails"] + rates["Fails"]
				to_insert["Success"] = previous_info["Success"] \
									   + rates["Success"]
			else:
				# FIRST TIME
				to_insert["Totals"] = rates["Totals"]
				to_insert["Fails"] = rates["Fails"]
				to_insert["Success"] = rates["Success"]
			category_rates[running_hash] = to_insert
			parents = running_parents_cache.split(" -> ")[:-1]
			parents_hash = get_hash(parents, category_hash)
			parent_feature_combo_table[parents_hash].append(feature_info)
			# print("Category combination: {}".format(running_parents_cache))
			# print("*" * 50)
		else:
			pass
			# print("Duplicate hash: {}".format(running_parents_cache))
	# print("#" * 70)


def create_master_category_and_combo():
	"""Helper function to execute recursion and returning the result
	:return: feature_groups: groups of features,
			 parent_feature_table: mapping of parents and the occurrences of
			 	features under them.
			 category_rates: failure, success, total rates of category
	"""
	feature_groups, categories_count = create_feature_groups()
	print("Feature groups created")
	category_rates = dict()
	parent_feature_table = defaultdict(list)
	for x in feature_groups:
		feature_info = {
			"features": list(feature_groups[x]["features"]),
			"info": feature_groups[x]["info"],
			"occurrences": feature_groups[x]["occurrences"]
		}
		recurse(list(feature_groups[x]["features"]), 1,
				feature_groups[x]["info"], "", feature_info,
				category_rates, parent_feature_table, set())
	return feature_groups, parent_feature_table, category_rates, \
		   categories_count


def get_feature_safety(features: list or set, category_groups: dict,
					   category_rates: dict) -> float:
	"""Calculates feature safety depending on the failure rate of controls
	:param features: list of features
	:param category_groups: category groups
	:param category_rates: dict containing failure rates of categories
	:return: float, score of the input feature list
	"""
	print("Features: {}".format(features))
	feature_info = category_groups[get_hash(features, feature_hash)]
	print("Possible Parents: {}".format(single_parents(features)))
	category_info = category_rates[
		get_hash(single_parents(features), category_hash)]
	print("Feature info: {}".format(feature_info["info"]))
	print("Category info: {}".format(category_info))
	fails = feature_info["info"]["Fails"]
	totals = feature_info["info"]["Totals"]
	final_score = (fails / totals) * 100
	print("Fail percentage: {0:.2f}%".format(final_score))
	return final_score


def get_safest_features(categories):
	"""Returns the safest feature combination sorted according to the failure
	rates (lower the better) in form of string for the given category
	combination. 
	:param categories: list of categories under which the recommendation is 
		wanted.
	:param parent_feature_table:mapping of parents and the occurrences of
		features under them.
	:return: string of recommendations
	"""
	parent_hash = get_hash(categories, category_hash)
	category_groups, parent_feature_table, master_category_table, \
					categories_count = create_master_category_and_combo()
	value = parent_feature_table[parent_hash]
	if not value:
		print("Combination not found")
		return ""
	print("Input Combination Info: {}".format(value))
	for x in value:
		print(x)
		features_internal = x["features"]
		most_likely_parents = single_parents(features_internal)
		print("Most Likely Parents: {}".format(most_likely_parents))
		mlp_hash = get_hash(most_likely_parents, category_hash)
		counts = categories_count[mlp_hash]
		print("Category count: {}".format(counts))


def score(value) -> float:
	num = value["info"]["Fails"]
	den = value["info"]["Totals"]
	return num / den


def sort_other_most_used(other_most_used_list):
	for x in other_most_used_list:
		x.sort()
	counter = Counter([tuple(x) for x in other_most_used_list])
	ret_dict = dict()
	for x in counter:
		ret_dict[x.__str__()] = counter[x]
	return ret_dict


def convert_counts_to_pct(counter_dict):
	counts = 0
	for x in counter_dict:
		counts += counter_dict[x]
	for x in counter_dict:
		counter_dict[x] /= counts
	return counter_dict


def save_recommendation_json():
	"""Save the recommendation JSON i.e. parent_feature_table offline.
	:return:
	"""
	feature_groups, parent_feature_table, master_category_table, \
		categories_count = create_master_category_and_combo()

	def sort_parent_feature_table(pf_table):
		for x in pf_table:
			recommendations = pf_table[x]
			recommendations.sort(key=score)
			for recommendations_dict in recommendations:
				features_list = recommendations_dict["features"]
				most_likely_parents = single_parents(features_list)
				most_likely_parents_hash = get_hash(most_likely_parents,
													 category_hash)
				f_hash = get_hash(recommendations_dict["features"], feature_hash)
				recommendations_dict["UsagePercentage"] = \
					feature_groups[f_hash]["occurrences"] \
					/ categories_count["totalcount"][most_likely_parents_hash]
				most_likely_counts = sort_other_most_used(
					categories_count["combinations_list"][most_likely_parents_hash])
				recommendations_dict["OtherMostUsed"] = \
					convert_counts_to_pct(most_likely_counts)
		return pf_table

	parent_feature_table = sort_parent_feature_table(parent_feature_table)
	json_str = json.dumps(parent_feature_table)
	with open("recommendation.json", "w") as f:
		f.write(json_str)
	print("Completed writing JSON")


if __name__ == '__main__':
	get_safest_features(["Messaging", "SecurityInfra", "WebFrontEnd",
						 "DataStorage"])

