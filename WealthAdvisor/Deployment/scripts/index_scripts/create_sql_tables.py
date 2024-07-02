key_vault_name = 'nc6211-kv-isgqgxlmv6y5k' #'kv_to-be-replaced'

import pandas as pd
import pymssql
import os

from azure.keyvault.secrets import SecretClient  
from azure.identity import DefaultAzureCredential 

def get_secrets_from_kv(kv_name, secret_name):
    key_vault_name = kv_name  # Set the name of the Azure Key Vault  
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=f"https://{key_vault_name}.vault.azure.net/", credential=credential)  # Create a secret client object using the credential and Key Vault name  
    return(secret_client.get_secret(secret_name).value) # Retrieve the secret value  

server = get_secrets_from_kv(key_vault_name,"SQLDB-SERVER")
database = get_secrets_from_kv(key_vault_name,"SQLDB-DATABASE")
username = get_secrets_from_kv(key_vault_name,"SQLDB-USERNAME")
password = get_secrets_from_kv(key_vault_name,"SQLDB-PASSWORD")

# connection_string = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
# print(connection_string)
# conn = pyodbc.connect(connection_string)

conn = pymssql.connect(server, username, password, database)
cursor = conn.cursor()

from azure.storage.filedatalake import (
    DataLakeServiceClient
)

account_name = get_secrets_from_kv(key_vault_name, "ADLS-ACCOUNT-NAME")
account_key = get_secrets_from_kv(key_vault_name, "ADLS-ACCOUNT-KEY")

account_url = f"https://{account_name}.dfs.core.windows.net"

service_client = DataLakeServiceClient(account_url, credential=account_key,api_version='2023-01-03') 


file_system_client_name = "data"
directory = 'clientdata' 

file_system_client = service_client.get_file_system_client(file_system_client_name)  
directory_name = directory

cursor = conn.cursor()

cursor.execute('DROP TABLE IF EXISTS Clients')
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
file_path = directory + '/Clients.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

for index, item in df.iterrows():
    # cursor.execute(f"INSERT INTO Clients (ClientId,Client, Email, Occupation, MaritalStatus, Dependents) VALUES (?,?, ?, ?, ?, ?)", item.ClientId, item.Client, item.Email, item.Occupation, item.MaritalStatus, item.Dependents)
    cursor.execute(f"INSERT INTO Clients (ClientId,Client, Email, Occupation, MaritalStatus, Dependents) VALUES (%s,%s,%s,%s,%s,%s)", (item.ClientId, item.Client, item.Email, item.Occupation, item.MaritalStatus, item.Dependents))
conn.commit()

# # cursor.execute(f"select * from Clients")
# # for row in cursor.fetchall():
# #     print(row.ClientId, row.Client, row.Email)


cursor = conn.cursor()

cursor.execute('DROP TABLE IF EXISTS ClientInvestmentPortfolio')
conn.commit()

create_client_sql = """CREATE TABLE ClientInvestmentPortfolio (
                ClientId int,
                AssetDate date,
                AssetType varchar(255),
                Investment float,
                ROI float,
                RevenueWithoutStrategy float
            );"""

cursor.execute(create_client_sql)
conn.commit()

# df = pd.read_csv('../Data/ClientInvestmentPortfolio.csv')
# df.head()

file_path = directory + '/ClientInvestmentPortfolio.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

for index, item in df.iterrows():
    # cursor.execute(f"INSERT INTO ClientInvestmentPortfolio (ClientId, AssetDate, AssetType, Investment, ROI, RevenueWithoutStrategy) VALUES (?,?, ?, ?, ?, ?)", item.ClientId, item.AssetDate, item.AssetType, item.Investment, item.ROI, item.RevenueWithoutStrategy)
    cursor.execute(f"INSERT INTO ClientInvestmentPortfolio (ClientId, AssetDate, AssetType, Investment, ROI, RevenueWithoutStrategy) VALUES (%s,%s, %s,%s, %s, %s)", (item.ClientId, item.AssetDate, item.AssetType, item.Investment, item.ROI, item.RevenueWithoutStrategy))
    
conn.commit()

# cursor.execute(f"select * from ClientInvestmentPortfolio")
# for row in cursor.fetchall():
#     print(row.ClientId, row.AssetType, row.Investment)


from decimal import Decimal

cursor.execute('DROP TABLE IF EXISTS Assets')
conn.commit()

create_assets_sql = """CREATE TABLE Assets (
                ClientId int NOT NULL,
                AssetDate Date,
                Investment Decimal(18,2),
                ROI Decimal(18,2),
                Revenue Decimal(18,2),
                AssetType varchar(255)
            );"""

cursor.execute(create_assets_sql)
conn.commit()

# df = pd.read_csv('../Data/Assets.csv')
file_path = directory + '/Assets.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

df['AssetDate'] = pd.to_datetime(df['AssetDate'], format='%m/%d/%Y') #   %Y-%m-%d')
df['ClientId'] = df['ClientId'].astype(int)
df['Investment'] = df['Investment'].astype(float)
df['ROI'] = df['ROI'].astype(float)
df['Revenue'] = df['Revenue'].astype(float)


for index, item in df.iterrows():
    #cursor.execute(f"INSERT INTO Assets (ClientId,AssetDate, Investment, ROI, Revenue, AssetType) VALUES (?,?, ?, ?, ?, ?)", item.ClientId, item.AssetDate, item.Investment, item.ROI, item.Revenue, item.AssetType)
    cursor.execute(f"INSERT INTO Assets (ClientId,AssetDate, Investment, ROI, Revenue, AssetType) VALUES (%s,%s,%s,%s,%s,%s)", (item.ClientId, item.AssetDate, item.Investment, item.ROI, item.Revenue, item.AssetType))
conn.commit()

# cursor.execute(f"select * from Assets")
# for row in cursor.fetchall():
#     print(row.Investment, row.ROI)

cursor.execute('DROP TABLE IF EXISTS InvestmentGoals')
conn.commit()

create_ig_sql = """CREATE TABLE InvestmentGoals (
                ClientId int NOT NULL,
                InvestmentGoal varchar(255)
            );"""

cursor.execute(create_ig_sql)
conn.commit()

# df = pd.read_csv('../Data/InvestmentGoals.csv')


file_path = directory + '/InvestmentGoals.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

df['ClientId'] = df['ClientId'].astype(int)

for index, item in df.iterrows():
    #cursor.execute(f"INSERT INTO InvestmentGoals (ClientId,InvestmentGoal) VALUES (?,?)", item.ClientId, item.InvestmentGoal)
    cursor.execute(f"INSERT INTO InvestmentGoals (ClientId,InvestmentGoal) VALUES (%s,%s)", (item.ClientId, item.InvestmentGoal))
conn.commit()

# cursor.execute(f"select * from InvestmentGoals")
# for row in cursor.fetchall():
#     print(row.ClientId,row.InvestmentGoal)

cursor.execute('DROP TABLE IF EXISTS InvestmentGoalsDetails')
conn.commit()

create_ig_sql = """CREATE TABLE InvestmentGoalsDetails (
                ClientId int NOT NULL,
                InvestmentGoal nvarchar(255), 
                TargetAmount Decimal(18,2), 
                Contribution Decimal(18,2), 
            );"""

cursor.execute(create_ig_sql)
conn.commit()

# df = pd.read_csv('../Data/InvestmentGoalsDetails.csv')
file_path = directory + '/InvestmentGoalsDetails.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

df['ClientId'] = df['ClientId'].astype(int)

for index, item in df.iterrows():
    # cursor.execute(f"INSERT INTO InvestmentGoalsDetails (ClientId,InvestmentGoal, TargetAmount, Contribution) VALUES (?,?,?,?)", item.ClientId, item.InvestmentGoal, item.TargetAmount, item.Contribution)
    cursor.execute(f"INSERT INTO InvestmentGoalsDetails (ClientId,InvestmentGoal, TargetAmount, Contribution) VALUES (%s,%s,%s,%s)", (item.ClientId, item.InvestmentGoal, item.TargetAmount, item.Contribution))
conn.commit()

# cursor.execute(f"select * from InvestmentGoalsDetails")
# for row in cursor.fetchall():
#     print(row.ClientId,row.InvestmentGoal)


import pandas as pd
cursor = conn.cursor()

cursor.execute('DROP TABLE IF EXISTS ClientMeetings')
conn.commit()

create_cs_sql = """CREATE TABLE ClientMeetings (
                ClientId int NOT NULL,
                ConversationId nvarchar(255),
                Title nvarchar(255),
                StartTime DateTime,
                EndTime DateTime,
                Advisor nvarchar(255),
                ClientEmail nvarchar(255)
            );"""

cursor.execute(create_cs_sql)
conn.commit()

# df = pd.read_csv('../Data/ClientMeetingsMetadata.csv')
# df['ClientId'] = df['ClientId'].astype(int)

file_path = directory + '/ClientMeetingsMetadata.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

for index, item in df.iterrows():
    # cursor.execute(f"INSERT INTO ClientMeetings (ClientId,ConversationId,Title,StartTime,EndTime,Advisor,ClientEmail) VALUES (?,?,?,?,?,?,?)", item.ClientId, item.ConversationId, item.Title, item.StartTime, item.EndTime, item.Advisor, item.ClientEmail)
    cursor.execute(f"INSERT INTO ClientMeetings (ClientId,ConversationId,Title,StartTime,EndTime,Advisor,ClientEmail) VALUES (%s,%s,%s,%s,%s,%s,%s)", (item.ClientId, item.ConversationId, item.Title, item.StartTime, item.EndTime, item.Advisor, item.ClientEmail))
conn.commit()


# df = pd.read_csv('../Data/ClientFutureMeetings.csv')

file_path = directory + '/ClientFutureMeetings.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

df['ClientId'] = df['ClientId'].astype(int)
df['ConversationId'] = ''

for index, item in df.iterrows():
    #cursor.execute(f"INSERT INTO ClientMeetings (ClientId,ConversationId,Title,StartTime,EndTime,Advisor,ClientEmail) VALUES (?,?,?,?,?,?,?)", item.ClientId, item.ConversationId, item.Title, item.StartTime, item.EndTime, item.Advisor, item.ClientEmail)
    cursor.execute(f"INSERT INTO ClientMeetings (ClientId,ConversationId,Title,StartTime,EndTime,Advisor,ClientEmail) VALUES (%s,%s,%s,%s,%s,%s,%s)", (item.ClientId, item.ConversationId, item.Title, item.StartTime, item.EndTime, item.Advisor, item.ClientEmail))
conn.commit()

# cursor.execute(f"select * from ClientMeetings")
# for row in cursor.fetchall():
#     print(row)
#     break

cursor.execute('DROP TABLE IF EXISTS ClientSummaries')
conn.commit()

create_cs_sql = """CREATE TABLE ClientSummaries (
                ClientId int NOT NULL,
                ClientSummary nvarchar(255)
            );"""

cursor.execute(create_cs_sql)
conn.commit()

# df = pd.read_csv('../Data/ClientSummaries.csv')
file_path = directory + '/ClientSummaries.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

df['ClientId'] = df['ClientId'].astype(int)

for index, item in df.iterrows():
    # cursor.execute(f"INSERT INTO ClientSummaries (ClientId,ClientSummary) VALUES (?,?)", item.ClientId, item.ClientSummary)
    cursor.execute(f"INSERT INTO ClientSummaries (ClientId,ClientSummary) VALUES (%s,%s)", (item.ClientId, item.ClientSummary))
conn.commit()


# cursor.execute(f"select * from ClientSummaries")
# for row in cursor.fetchall():
#     print(row.ClientId,row.ClientSummary)

cursor.execute('DROP TABLE IF EXISTS Retirement')
conn.commit()

create_cs_sql = """CREATE TABLE Retirement (
                ClientId int NOT NULL,
                StatusDate Date,
                RetirementGoalProgress Decimal(18,2),
                EducationGoalProgress Decimal(18,2)
            );"""

cursor.execute(create_cs_sql)
conn.commit()

# df = pd.read_csv('../Data/Retirement.csv')
file_path = directory + '/Retirement.csv'
file_client = file_system_client.get_file_client(file_path)
csv_file = file_client.download_file()
df = pd.read_csv(csv_file, encoding='utf-8')

df['ClientId'] = df['ClientId'].astype(int)

for index, item in df.iterrows():
    #cursor.execute(f"INSERT INTO Retirement (ClientId,StatusDate, RetirementGoalProgress, EducationGoalProgress) VALUES (?,?,?,?)", item.ClientId, item.StatusDate, item.RetirementGoalProgress, item.EducationGoalProgress)
    cursor.execute(f"INSERT INTO Retirement (ClientId,StatusDate, RetirementGoalProgress, EducationGoalProgress) VALUES (%s,%s,%s,%s)", (item.ClientId, item.StatusDate, item.RetirementGoalProgress, item.EducationGoalProgress))
conn.commit()

# cursor.execute(f"select * from Retirement")
# for row in cursor.fetchall():
#     print(row.ClientId,row.RetirementGoalProgress)


# to adjust dates in meetings table
cursor = conn.cursor()
sql_query = 'select 8 - datediff(day,getdate(), max(cast([StartTime] as date))) as n FROM ClientMeetings'
cursor.execute(sql_query)
for row in cursor.fetchall():
    # ndays = row.n
    ndays = row[0]
    break

sql_query = f'UPDATE ClientMeetings SET StartTime = DATEADD (day, {ndays}, StartTime)'
cursor.execute(sql_query)
sql_query = f'UPDATE ClientMeetings SET EndTime = DATEADD (day, {ndays}, EndTime)'
cursor.execute(sql_query)
conn.commit()