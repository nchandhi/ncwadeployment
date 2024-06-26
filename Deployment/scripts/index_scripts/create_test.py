key_vault_name = 'nc6262-kv-2fpeafsylfd2e' #'kv_to-be-replaced'

import pyodbc
import os

from azure.keyvault.secrets import SecretClient  
from azure.identity import DefaultAzureCredential 

def get_secrets_from_kv(kv_name, secret_name):
    key_vault_name = kv_name  # Set the name of the Azure Key Vault  
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=f"https://{key_vault_name}.vault.azure.net/", credential=credential)  # Create a secret client object using the credential and Key Vault name  
    return(secret_client.get_secret(secret_name).value) # Retrieve the secret value  

# print(connectionString)
server = get_secrets_from_kv(key_vault_name,"SQLDB_SERVER")
database = get_secrets_from_kv(key_vault_name,"SQLDB_DATABASE")
username = get_secrets_from_kv(key_vault_name,"SQLDB_USERNAME")
password = get_secrets_from_kv(key_vault_name,"SQLDB_PASSWORD")

file_system_client_name = "data"
directory = 'clientdata' 

from azure.storage.filedatalake import (
    DataLakeServiceClient,
    DataLakeDirectoryClient,
    FileSystemClient
)

account_name = get_secrets_from_kv(key_vault_name, "ADLS-ACCOUNT-NAME")
account_key = get_secrets_from_kv(key_vault_name, "ADLS-ACCOUNT-KEY")

account_url = f"https://{account_name}.dfs.core.windows.net"

service_client = DataLakeServiceClient(account_url, credential=account_key,api_version='2023-01-03') 

file_system_client = service_client.get_file_system_client(file_system_client_name)  
directory_name = directory


connection_string = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
conn = pyodbc.connect(connection_string)


cursor = conn.cursor()

cursor.execute('DROP TABLE Clients')
conn.commit()

create_client_sql = """CREATE TABLE Clients (
                ClientId int NOT NULL PRIMARY KEY,
                Client varchar(255),
                Email varchar(255),
                Occupation varchar(255),
                MaritalStatus varchar(255),
                Dependents int
            );"""
cursor.execute(create_client_sql)
conn.commit()



# Read the CSV file into a Pandas DataFrame
file_path = csv_file_name
print(file_path)
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df_metadata = pd.read_csv(csv_file, encoding='utf-8')

df = pd.read_csv('../Data/Clients.csv')
df.head()

for index, item in df.iterrows():
    cursor.execute(f"INSERT INTO Clients (ClientId,Client, Email, Occupation, MaritalStatus, Dependents) VALUES (?,?, ?, ?, ?, ?)", item.ClientId, item.Client, item.Email, item.Occupation, item.MaritalStatus, item.Dependents)
conn.commit()

cursor.execute(f"select * from Clients")
for row in cursor.fetchall():
    print(row.ClientId, row.Client, row.Email)