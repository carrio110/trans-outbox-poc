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
    [object] Submit() {

        try {
            $response = Invoke-RestMethod 
                -Method Post 
                -ContentType 'application/json'
                -Uri 'http://localhost:3601/v1.0/state/statestore/transaction'
                -Body '{"operations": [{"operation":"upsert", "request": {"key": "order_1", "value": "250"}}, {"operation":"delete", "request": {"key": "order_2"}}]}'
                -ErrorAction stop
            
            return $response
        }
        catch {
            $response = "An error occurred while submitting the request to the queue."
            return $response
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
            
        }
        
    }

    [object] GetAzAppConfigValues() {
        $builder = FunctionsApplication.CreateBuilder(args)
        $builder.Configuration.AddAzureAppConfiguration()
    }

}
