# trans-outbox-poc

create a vanilla new function project

[install dapr to the function:](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-dapr?tabs=in-process%2Cbundle-v4x%2Cbicep1&pivots=programming-language-powershell)

use the dapr vs code extenstion to scaffold your function project (creates a components folder with sample yamls)

# folder structure

trans-outbox-poc  
 | - components         (DAPR component definitions)  
 | | - statestore.yaml  
 | | - configstore.yaml  
 | - functionapp        (Azure functions code)  
 | | - run.ps1  
 | | - function.json  
 | - infrasctructure    (Bicep files that define the infrastructure in use)  
 | | - app.bicep  
 | | - keyvault.bicep  

# submission choreography

sub