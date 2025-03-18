#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

display_help() {
  echo -e "${GREEN}Usage:${NC} $0 <${YELLOW}RESOURCE_TYPE${NC}>"
  echo
  echo -e "${BLUE}This script provides operations for various Azure resource types. Please specify the ${YELLOW}RESOURCE_TYPE${BLUE} as a parameter.${NC}"
  echo
  echo -e "${GREEN}Available ${YELLOW}RESOURCE_TYPE${GREEN} options include:${NC}"
  echo -e "  ${YELLOW}app-service${NC}      - Azure App Service"
  echo -e "  ${YELLOW}acr${NC}              - Azure Container Registry"
  echo -e "  ${YELLOW}aks${NC}              - Azure Kubernetes Service"
  echo -e "  ${YELLOW}vm${NC}               - Virtual Machine"
  echo -e "  ${YELLOW}vnet${NC}             - Virtual Network"
  echo -e "  ${YELLOW}ag${NC}               - Application Gateway"
  echo -e "  ${YELLOW}apim${NC}             - API Management"
  echo -e "  ${YELLOW}storage${NC}          - Storage Account"
  echo -e "  ${YELLOW}db${NC}               - Database (Azure SQL, MySQL, PostgreSQL, etc.)"
  echo -e "  ${YELLOW}cache${NC}            - Azure Cache for Redis"
  echo -e "  ${YELLOW}asb${NC}              - Azure Service Bus"
  echo -e "  ${YELLOW}key-vault${NC}        - Key Vault"
  echo -e "  ${YELLOW}azure-function${NC}   - Azure Function"
  echo -e "  ${YELLOW}rg${NC}               - Resource Group"
  echo
  echo -e "${GREEN}Example:${NC}"
  echo -e "  $0 ${YELLOW}app-service${NC}"
  echo
  echo -e "${RED}Note:${NC}"
  echo -e "  If you are unable to see all the listed subscriptions or directories in the Azure portal, you may need to re-authenticate."
  echo -e "  To log out of the Azure CLI, use the command: ${YELLOW}az logout${NC}"
  echo -e "  To log back in, use the command: ${YELLOW}az login --use-device-code${NC}"
  echo
  exit 1
}

# Check if the az command is available
if ! command -v az &>/dev/null; then
  echo -e "${RED}Error:${NC} az command not found. Please install Azure CLI to use this script."
  exit 1
fi

# Validate input
if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  display_help
fi

# Map common names to Azure resource types
declare -A RESOURCE_TYPE_MAP
RESOURCE_TYPE_MAP=(
  ["app-service"]="Microsoft.Web/sites"
  ["acr"]="Microsoft.ContainerRegistry/registries"
  ["aks"]="Microsoft.ContainerService/managedClusters"
  ["vm"]="Microsoft.Compute/virtualMachines"
  ["vnet"]="Microsoft.Network/virtualNetworks"
  ["ag"]="Microsoft.Network/applicationGateways"
  ["apim"]="Microsoft.ApiManagement/service"
  ["storage"]="Microsoft.Storage/storageAccounts Microsoft.Storage/tableServices Microsoft.Storage/blobServices Microsoft.Storage/fileServices Microsoft.Storage/queueServices"
  ["db"]="Microsoft.Sql/servers Microsoft.Sql/databases Microsoft.DocumentDB/databaseAccounts Microsoft.DBforMySQL/servers Microsoft.DBforPostgreSQL/servers Microsoft.DBforMariaDB/servers"
  ["cache"]="Microsoft.Cache/Redis"
  ["asb"]="Microsoft.ServiceBus/namespaces"
  ["key-vault"]="Microsoft.KeyVault/vaults"
  ["azure-function"]="Microsoft.Web/sites"
  ["rg"]="resourceGroups"
)

RESOURCE_TYPES=${RESOURCE_TYPE_MAP[$1]}

# Check if RESOURCE_TYPES is valid
if [ -z "$RESOURCE_TYPES" ]; then
  echo -e "${RED}Invalid RESOURCE_TYPE: $1${NC}"
  display_help
fi

# Function to get resources for the given subscription
get_resources() {
  local subscription_id=$1
  local resource_type=$2
  if [ "$resource_type" == "resourceGroups" ]; then
    az group list --subscription "$subscription_id" --query "[].{Name:name, Type:'resourceGroup'}" -o tsv
  else
    az resource list --subscription "$subscription_id" --resource-type "$resource_type" --query "[].{Name:name, Type:type, ResourceGroup:resourceGroup}" -o tsv
  fi
}

# Function to get subscription name
get_subscription_name() {
  local subscription_id=$1
  az account show --subscription "$subscription_id" --query "name" -o tsv
}

echo -e "\n${YELLOW}Fetching list of subscriptions...${NC}"
SUBSCRIPTIONS=($(az account list --query "[].id" -o tsv))
echo -e "${GREEN}Fetched subscriptions successfully.${NC}"

OUTPUT_FILE=$(mktemp)

if [ "$1" == "rg" ]; then
  echo -e "Resource Name\tResource Type\tResource Subscription" >>"$OUTPUT_FILE"
  echo -e "-------------\t-------------\t---------------------" >>"$OUTPUT_FILE"
else
  echo -e "Resource Name\tResource Type\tResource Group\tResource Subscription" >>"$OUTPUT_FILE"
  echo -e "-------------\t-------------\t-------------\t---------------------" >>"$OUTPUT_FILE"
fi

for SUBSCRIPTION in "${SUBSCRIPTIONS[@]}"; do
  SUBSCRIPTION_ID=$(echo "$SUBSCRIPTION" | tr -d '\r')
  az account set --subscription "$SUBSCRIPTION_ID"

  SUBSCRIPTION_NAME=$(get_subscription_name "$SUBSCRIPTION_ID")
  echo -e "${BLUE}Fetching Resource List from:${NC} ${GREEN}$SUBSCRIPTION_NAME${NC}"

  for RESOURCE_TYPE in $RESOURCE_TYPES; do
    echo -e "${YELLOW}Checking resources of type ${RESOURCE_TYPE} in subscription ${SUBSCRIPTION_NAME}...${NC}"
    RESOURCES=$(get_resources "$SUBSCRIPTION_ID" "$RESOURCE_TYPE")

    if [ -n "$RESOURCES" ]; then
      if [ "$1" == "rg" ]; then
        echo "$RESOURCES" | awk -v sub_name="$SUBSCRIPTION_NAME" -F'\t' '{print $1 "\t" $2 "\t" sub_name}' >>"$OUTPUT_FILE"
      else
        echo "$RESOURCES" | awk -v sub_name="$SUBSCRIPTION_NAME" -F'\t' '{print $1 "\t" $2 "\t" $3 "\t" sub_name}' >>"$OUTPUT_FILE"
      fi
      echo -e "${GREEN}Found resources of type ${RESOURCE_TYPE} in subscription ${SUBSCRIPTION_NAME}.${NC}"
    else
      echo -e "${RED}No resources found for:${NC} ${RESOURCE_TYPE} in ${SUBSCRIPTION_NAME}"
    fi
  done
done

echo -e "${YELLOW}Preparing final output...${NC}\n"
column -t -s $'\t' <"$OUTPUT_FILE"

rm "$OUTPUT_FILE"
echo -e "\n${GREEN}Script execution completed.${NC}"
