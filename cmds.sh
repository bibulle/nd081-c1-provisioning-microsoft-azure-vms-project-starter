set -e

IP_ADDRESS=$(curl ifconfig.me)

RESOURCE_GROUP="bibulle-resource-group"
LOCATION="francecentral"
#SQL_SERVER="bibulle-server-$(uuidgen)"
SQL_SERVER="bibulle-serverea91a754-7e82-4dca-9a72-23971bc605b9"
SQL_ADMIN_USER="bibulle1234"
SQL_ADMIN_PASSWORD="my-bibulle-password1234"
SQL_DB_NAME="bibulle-db"
STORAGE_ACCOUNT="bibullestorageaccount"
STORAGE_CONTAINER="images"
APP_DISPLAY_NAME="bibulle-app"
APP_NAME="bibulle-app"

#1. Create a Resource Group in Azure.
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

#2. Create an SQL Database in Azure
az sql server create \
  --admin-user ${SQL_ADMIN_USER} \
  --admin-password ${SQL_ADMIN_PASSWORD} \
  --name ${SQL_SERVER} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION} \
  --enable-public-network true

az sql server firewall-rule create \
  -g ${RESOURCE_GROUP} \
  -s ${SQL_SERVER} \
  -n azureaccess \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

az sql server firewall-rule create \
  -g ${RESOURCE_GROUP} \
  -s ${SQL_SERVER} \
  -n clientip \
  --start-ip-address ${IP_ADDRESS} \
  --end-ip-address ${IP_ADDRESS}

az policy assignment delete --name cloud-demo513-PolicyDefinition
az policy definition delete --name cloud-demo513-PolicyDefinition

az sql db create \
  --name ${SQL_DB_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --server ${SQL_SERVER} \
  --tier Basic

set -x

set +e
sqlcmd -S ${SQL_SERVER}.database.windows.net -U ${SQL_ADMIN_USER} -P ${SQL_ADMIN_PASSWORD} -d ${SQL_DB_NAME} -i sql_scripts/users-table-test.sql | grep -q "1 rows affected"
if [ $? -ne 0 ]; then
  set -e
  sqlcmd -S ${SQL_SERVER}.database.windows.net -U ${SQL_ADMIN_USER} -P ${SQL_ADMIN_PASSWORD} -d ${SQL_DB_NAME} -i sql_scripts/users-table-init.sql
fi

set +e
sqlcmd -S ${SQL_SERVER}.database.windows.net -U ${SQL_ADMIN_USER} -P ${SQL_ADMIN_PASSWORD} -d ${SQL_DB_NAME} -i sql_scripts/posts-table-test.sql | grep -q "1 rows affected"
if [ $? -ne 0 ]; then
  set -e
  sqlcmd -S ${SQL_SERVER}.database.windows.net -U ${SQL_ADMIN_USER} -P ${SQL_ADMIN_PASSWORD} -d ${SQL_DB_NAME} -i sql_scripts/posts-table-init.sql
fi

set -e
#3. Create a Storage Container
az storage account create \
  --name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION}

az storage container create \
  --account-name ${STORAGE_ACCOUNT} \
  --name ${STORAGE_CONTAINER} \
  --auth-mode login \
  --public-access container

#4. Add functionality to the Sign In With Microsoft
az ad app create --display-name ${APP_DISPLAY_NAME} --available-to-other-tenants false --reply-urls https://localhost --native-app false
echo "APP_CLIENTID:" $(az ad app list --display-name ${APP_DISPLAY_NAME} --query "[*].appId" | grep '"')

echo "create a new client secret manually"
# value mEf7Q~ez0ZDxy8Z671BrTGSZeguKZ9pQ8vU~A
# upgrade config.py with two secret keys
# change views.py with code


#5. Go through with deployment.
az webapp up \
 --resource-group ${RESOURCE_GROUP} \
 --name ${APP_NAME} \
 --sku F1