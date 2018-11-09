# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# -------------------------------------------------------------------------
import pyodbc
import pandas as pd
import sys

from functools import wraps
from azure.keyvault import KeyVaultClient
from azure.storage.file import FileService
from msrestazure.azure_active_directory import MSIAuthentication
from recommendation_engine import save_recommendation_json
from constants import *
from time import time


def validate(raise_error=False):
	def validate_decorator(caller):
		"""Decorator to validate the calling function"""
		@wraps(caller)
		def executor(*args, **kwargs):
			result = None
			try:
				result = caller(*args, **kwargs)
			except Exception as e:
				print("Error at {} Exception: {}".format(caller.__name__, e))
				if raise_error:
					sys.exit(-1)
			return result
		return executor
	return validate_decorator


def timeit(caller):
	def executor(*args, **kwargs):
		start = time()
		caller(*args, **kwargs)
		end = time()
		print("Executing {} took {} secs".format(caller.__name__, end - start))
	return executor


@validate(raise_error=False)
def get_from_keyvault(key_name):
	"""Gets a certain secret from Keyvault"""
	credentials = MSIAuthentication(resource='https://vault.azure.net')
	key_vault_client = KeyVaultClient(credentials)

	# azskrecoenginekv
	key_vault_uri = "https://sqltostoragekeyvault.vault.azure.net/"

	secret = key_vault_client.get_secret(
		key_vault_uri,
		key_name,
		""
	)
	return secret.value


@timeit
@validate(raise_error=True)
def get_csv_from_mysql():
	connection = pyodbc.connect(get_from_keyvault("sql-server-credentials"))
	query = MYSQL_QUERY
	try:
		# cursor = connection.cursor()
		# cursor.execute(query)
		# rows = cursor.fetchall()
		df = pd.read_sql(query, connection, index_col="Id")
		# df.set_index("Id", inplace=True)
		df.to_csv(get_csv_filename())
	except Exception as ex:
		print("YO", ex)
	print("Saved CSV to disk")


@validate(raise_error=False)
def save_file_to_storage(file):
	fs = FileService(account_name="recoenginestorage",
					 account_key=get_from_keyvault("storage-account-key"))
	fs.create_file_from_path("myshare", None, file, file)


@validate(raise_error=False)
def upload_recommendations():
	save_recommendation_json()
	save_file_to_storage("recommendation.json")


if __name__ == '__main__':
	print("Running in mode:", MODE)
	if MODE == "PROD":
		get_csv_from_mysql()
		upload_recommendations()
	elif MODE == "LOCAL":
		save_recommendation_json()
	else:
		raise ValueError("Unknown mode in webjob main")

