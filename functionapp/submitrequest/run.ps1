using namespace System.Net
using module .\AmpRequest.psm1

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

if ($Request.Method -eq 'POST') {
    
    # In REST terms, this is the create standard method where we create a new resource:
    try {
        # Ensure the request body is a json
        Write-Host $Request.Body | Out-String
        $newAmpRequest = [AmpRequest]::new($Request.Body)
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
elseif ($Request.Method -eq 'GET') {
    # In REST terms, this is the read standard method where we either retrieve a specific resource or return a collection of resources:
    $requestId = $Request.id
    if (-not $requestId) {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = "Missing 'id' query parameter."
        })
        return
    }

    try {
        $ampRequest = [AmpRequest]::GetRequestById($requestId)
        if ($null -eq $ampRequest) {
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::NotFound
                Body = "Request with ID '$requestId' not found."
            })
        } else {
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = $ampRequest
            })
        }
    }
    catch {
        Write-Error $_.Exception.Message
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body = $_.Exception.Message
        })
    }
    Write-Host "PowerShell HTTP trigger function processed a GET request."
}
else {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::MethodNotAllowed
        Body = "Method not allowed. Only GET and POST are supported."
    })
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Associate values to output bindings by calling 'Push-OutputBinding'.

<#
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
#>