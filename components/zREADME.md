The components folder is for local development and debugging purposes. When deployed to Azure, the -dapr.bicep files define the DAPR components.

dapr run --app-protocol http --dapr-http-port 3601 --components-path componentsdapr run --app-protocol http --dapr-http-port 3601 --components-path .