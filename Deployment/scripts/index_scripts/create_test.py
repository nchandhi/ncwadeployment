key_vault_name = 'nc6262-kv-2fpeafsylfd2e' #'kv_to-be-replaced'

import pyodbc
import os

from azure.keyvault.secrets import SecretClient  
from azure.identity import DefaultAzureCredential 

def get_secrets_from_kv(kv_name, secret_name):
  # Set the name of the Azure Key Vault  
  key_vault_name = kv_name 
  credential = DefaultAzureCredential()

  # Create a secret client object using the credential and Key Vault name  
  secret_client = SecretClient(vault_url=f"https://{key_vault_name}.vault.azure.net/", credential=credential)  
    
  # Retrieve the secret value  
  return(secret_client.get_secret(secret_name).value)

# print(connectionString)
server = get_secrets_from_kv(key_vault_name,"SQLDB_SERVER")
database = get_secrets_from_kv(key_vault_name,"SQLDB_DATABASE")
username = get_secrets_from_kv(key_vault_name,"SQLDB_USERNAME")
password = get_secrets_from_kv(key_vault_name,"SQLDB_PASSWORD")

connection_string = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
conn = pyodbc.connect(connection_string)