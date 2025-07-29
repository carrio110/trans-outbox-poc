using namespace Azure.Identity
using namespace Microsoft.Azure.Functions.Worker.Builder
using namespace Microsoft.Extensions.Configuration
using namespace Microsoft.Extensions.Hosting

class AmpRequest {
    # Class Properties
    [string]    $Id
    [string]    $UserId
    [string]    $TenantId
    [datetime]  $SubmissionDateTime
    [datetime]  $ScheduledFulfilmentDateTime
    [string]    $RequestType
    [object]    $Task
    [string]    $SumbmissionInterface
    [string]    $Status
    [bool]      $IsTest
    
    # Default Constructor
    AmpRequest() { $this.Init(@{}) }
    
    # Convenience constructor from hashtable
    AmpRequest([hashtable]$Properties) { $this.Init($Properties) }

    # Shared initializer method
    [void] Init([hashtable]$Properties) {
        $this.Id                            = (New-Guid).Guid
        $this.UserId                        = $this.ValidateUserId($Properties.UserId)
        $this.TenantId                      = $this.ValidateTenantId($Properties.TenantId)
        $this.SubmissionDateTime            = Get-date -format u # This will be updated later when the submit method is called. This is just a placeholder.
        $this.ScheduledFulfilmentDateTime   = $this.ValidateScheduledFulfilmentDateTime($Properties.ScheduledFulfilmentDateTime)
        $this.RequestType                   = $this.ValidateRequestType($Properties.RequestType)
        $this.Task                          = $this.ValidateTask($Properties.Task)
        $this.SumbmissionInterface          = $this.ValidateSubmissionInterface($Properties.SumbmissionInterface)
        $this.Status                        = 'New'
        $this.IsTest                        = $this.ValidateIsTest($Properties.IsTest)

        # Additional initialization logic can go here if needed
    }

    #region Validation Methods
    # Validation methods defined here for use in the constructor(s) and elsewhere.
    # Note: That while these methods do return a value, it is just the value that was passed in and must not have been modified.
    # They are used to validate the input and throw exceptions if validation fails.
        hidden [string] ValidateUserId([string]$UserId) {
            if ([string]::IsNullOrWhiteSpace($UserId)) {
                Write-Host "Validating supplied UserId: $UserId"
                throw "UserId is required."
            }
            return $UserId
        }

        hidden [string] ValidateTenantId([string]$TenantId) {
            if ([string]::IsNullOrWhiteSpace($TenantId)) {
                throw "TenantId is required."
            }
            return $TenantId
        }

        hidden [datetime] ValidateScheduledFulfilmentDateTime([datetime]$ScheduledFulfilmentDateTime) {
            if ($null -eq $ScheduledFulfilmentDateTime) {
                throw "ScheduledFulfilmentDateTime is required."
            }
            if ($ScheduledFulfilmentDateTime -lt (Get-Date)) {
                throw "ScheduledFulfilmentDateTime cannot be in the past."
            }
            return $ScheduledFulfilmentDateTime
        }
        
        hidden [string] ValidateRequestType([string]$RequestType) {
            if ([string]::IsNullOrWhiteSpace($RequestType)) {
                throw "RequestType is required."
            }
            if ($RequestType -notmatch '^req-[a-z][0-9]{3}$') {
                throw "RequestType must be in the form: 'req-x123' where x is a letter and 123 is a three-digit number."
            }
            return $RequestType
        }

        hidden [object] ValidateTask([object]$Task) {
            if ($null -eq $Task) {
                throw "Task is required."
            }
            <# Beyond this is domain specific validation logic for the Task object. Need to figure out the best way to implement this.
            
            if (-not $Task.ContainsKey('Type') -or [string]::IsNullOrWhiteSpace($Task.Type)) {
                throw "Task Type is required."
            }
            if (-not $Task.ContainsKey('Data') -or $null -eq $Task.Data) {
                throw "Task Data is required."
            }
            #>
            return $Task
        }
        
        hidden [string] ValidateSubmissionInterface([string]$SubmissionInterface) {
            if ([string]::IsNullOrWhiteSpace($SubmissionInterface)) {
                throw "SubmissionInterface is required."
            }
            if ($SubmissionInterface -notin @('web', 'api', 'mobile')) {
                throw "SubmissionInterface must be one of: web, api, mobile."
            }
            return $SubmissionInterface
        }

        hidden [bool] ValidateIsTest([bool]$IsTest) {
            if ($null -eq $IsTest) {
                throw "IsTest must not be null."
            }
            if ($IsTest -notin $true, $false) {
                throw "IsTest must be a boolean value."
            }
            return $IsTest
        }
    #endregion

    # Method to submit the request to the queue
    [object] Submit() {
        [string]$daprHttpPort = $env:DAPR_HTTP_PORT
        [string]$stateStoreName = 'dapr-conf-submit-queue-state' # The name of the statestore component defined in the components folder.

        Write-Host "dapr port environment variable is: $($daprHttpPort)"

        $this.SubmissionDateTime = Get-Date -format u # Update the submission date time to now

        $transOutboxBody =
@"
{
  "operations": [
    {
      "operation": "upsert",
      "request": {
        "key": "$($this.Id)",
        "value": $($this | ConvertTo-Json -Depth 10)
      }
    }
  ]
}
"@

        $RestParams = @{
            Method      = 'Post'
            ContentType = 'application/json'
            Uri         = "http://localhost:$($daprHttpPort)/v1.0/state/$($stateStoreName)/transaction"
            Body        = $transOutboxBody
            ErrorAction = 'Stop'
        }

        try {
            $response = Invoke-RestMethod @RestParams            
            Write-Host "The request has been successfully submitted to the queue."

            return $this
        }
        catch {
            $response = "An error occurred while submitting the request to the queue."
            Write-Error $_.Exception.Message
            Write-Host "The request submission failed."
            return $response
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
            
        }
    }

    # [object[]] GetSubmittedRequests($CustomerId,UserId)
}
