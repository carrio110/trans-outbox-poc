using namespace Azure.Identity
using namespace Microsoft.Azure.Functions.Worker.Builder
using namespace Microsoft.Extensions.Configuration
using namespace Microsoft.Extensions.Hosting


class AmpRequest {
    # Class Properties
    [string]    $CustomerId
    [datetime]  $ScheduledFulfilmentDateTime
    [object]    $Task
    [string]    $Owner
    [string]    $SumbmissionInterface
    [string]    $Status
    [bool]      $IsTest
    
    # Default Constructor
    AmpRequest() { $this.Init(@{}) }
    
    # Convenience constructor from hashtable
    AmpRequest([hashtable]$Properties) { $this.Init($Properties) }

    # Method to submit the request to the queue
    [object] Submit([object]$Request) {

        try {
            $response = Invoke-RestMethod 
                -Method Post 
                -ContentType 'application/json'
                -Uri 'http://localhost:3601/v1.0/state/statestore/transaction'
                -Body $Request
                -ErrorAction stop
            
            Write-Host "The request has been successfully submitted to the queue."

            return $response.content
        }
        catch {
            $response = "An error occurred while submitting the request to the queue."
            Write-Host "The request submission failed."
            return $response
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
            
        }
    }

    # [object[]] GetSubmittedRequests($CustomerId,UserId)
}
