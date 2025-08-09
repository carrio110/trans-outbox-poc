The components folder is for local development and debugging purposes. The -dapr.bicep files when deployed to Azure define the DAPR components as the Azure resources to the container app environment.

Run the following command from the functionapp folder:
```
dapr run \
--app-id functionapp \
--app-port 3601 \
--log-level debug \
--components-path ../components \
-- func start
```

This has the effect of firing up the necessary sidecars in the local container runtime with and binding them to the function process, which is launched in the final line.