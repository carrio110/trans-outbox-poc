using namespace System.Net
using module .\AmpRequest.psm1

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

if ($Request.Method -eq 'POST') {
    
    # In REST terms, this is the create standard method where we create a new resource:
    try {
        # Ensure the request body is a json
        if (-not ($Request.Body -is [json])) {
            Write-Host $Request.Body | Out-String
            throw "Request body must be a json."
        }
        $newAmpRequest = [AmpRequest]::new(($Request.Body | ConvertFrom-Json))
        Write-Host "Successfully constructed the AMP request object fom the request body. You can now submit it to the queue using the Submit method."
        Write-Debug "$($newAmpRequest)"
    } catch {
        Write-Error $_.Exception.Message
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            # It is ok to return brief summary of the violated business rules here, but don't leak sensitive information.
            # e.g. "Schduled Fulfilment DateTime cannot be in the past."
            Body = $_.Exception.Message
        })
        return
    }

     # ... and this is the _side effect_ of the create standard method:
    try {
        $result = $newAmpRequest.Submit()
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Created
            Body = $result
        })
    }
    catch {
        Write-Error $_.Exception.Message
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            # In production we should not include the full exception message. Used here for demonstration purposes.
            Body = $_.Exception.Message
        })
    }
    Write-Host "PowerShell HTTP trigger function processed a POST request."
}   

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Associate values to output bindings by calling 'Push-OutputBinding'.

<#
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
#>