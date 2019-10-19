# This is a super **SIMPLE** example of how to create a very basic powershell webserver
# 2019-05-18 UPDATE — Created by me and and evalued by @jakobii and the comunity.
# Based off of https://gist.github.com/19WAS85/5424431


# https://gist.github.com/theit8514/58a31895ae901206f6957a382f61618b
function Get-MimeType() {
    param($extension);
    switch ($extension) {
        ".doc" { "application/msword" }
        ".dot" { "application/msword" }

        ".docx" { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
        ".dotx" { "application/vnd.openxmlformats-officedocument.wordprocessingml.template" }
        ".docm" { "application/vnd.ms-word.document.macroEnabled.12" }
        ".dotm" { "application/vnd.ms-word.template.macroEnabled.12" }

        ".xls" { "application/vnd.ms-excel" }
        ".xlt" { "application/vnd.ms-excel" }
        ".xla" { "application/vnd.ms-excel" }

        ".xlsx" { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
        ".xltx" { "application/vnd.openxmlformats-officedocument.spreadsheetml.template" }
        ".xlsm" { "application/vnd.ms-excel.sheet.macroEnabled.12" }
        ".xltm" { "application/vnd.ms-excel.template.macroEnabled.12" }
        ".xlam" { "application/vnd.ms-excel.addin.macroEnabled.12" }
        ".xlsb" { "application/vnd.ms-excel.sheet.binary.macroEnabled.12" }

        ".ppt" { "application/vnd.ms-powerpoint" }
        ".pot" { "application/vnd.ms-powerpoint" }
        ".pps" { "application/vnd.ms-powerpoint" }
        ".ppa" { "application/vnd.ms-powerpoint" }

        ".pptx" { "application/vnd.openxmlformats-officedocument.presentationml.presentation" }
        ".potx" { "application/vnd.openxmlformats-officedocument.presentationml.template" }
        ".ppsx" { "application/vnd.openxmlformats-officedocument.presentationml.slideshow" }
        ".ppam" { "application/vnd.ms-powerpoint.addin.macroEnabled.12" }
        ".pptm" { "application/vnd.ms-powerpoint.presentation.macroEnabled.12" }
        ".potm" { "application/vnd.ms-powerpoint.template.macroEnabled.12" }
        ".ppsm" { "application/vnd.ms-powerpoint.slideshow.macroEnabled.12" }

        ".gif" { "image/gif" }
        ".png" { "image/png" }
        { $_ -in ".jpg", ".jpeg" } { "image/jpeg" }

        { $_ -in ".htm", ".html" } { "text/html" }
        ".js" { "application/x-javascript" }
        ".css" { "text/css" }

        ".mp3" { "audio/mpeg" }
        ".avi" { "video/x-msvideo" }

        ".pdf" { "application/pdf" }
        ".zip" { "application/zip" }
        ".txt" { "text/plain" }
        default { "application/octet-stream" }
    }
}


# Http Server
$http = [System.Net.HttpListener]::new() 

$SERVER_URL = "http://localhost:8989/"

# Hostname and port to listen on
$http.Prefixes.Add($SERVER_URL)

# Start the Http Server 
$http.Start()



# Log ready message to terminal 
if ($http.IsListening) {
    write-host "Now loaded at $($http.Prefixes)" -f 'y'

    # Start-Process -Path $SERVER_URL
    #& "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "--app=$SERVER_URL"
    & "start" "chrome" "--app=$SERVER_URL"
}

[console]::TreatControlCAsInput = $true

# INFINTE LOOP
# Used to listen for requests
while ($http.IsListening) {

    # Allow any pipeline stop requests (like Ctrl + C) to be processed
    # https://www.reddit.com/r/PowerShell/comments/9n2q03/http_listener_question/e7ju5w4?utm_source=share&utm_medium=web2x
    $contextTask = $http.GetContextAsync()
    while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {
        if ([console]::KeyAvailable) {
            $key = [system.console]::readkey($true)
            if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C")) {
                $http.Stop()
                write-host ""
                write-host " Stopped server. " -f 'black' -b 'red'
                break;
            }
        }
    }

    if (!$http.IsListening) {
        # Server has stopped
        break;
    }

    $context = $contextTask.GetAwaiter().GetResult()

    if ($context.Request.HttpMethod -eq 'GET') {
        # Log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        if ($context.Request.RawUrl -eq '/api/quit') {
            $http.Stop()
            write-host ""
            write-host " Stopped server because webpage closed. " -f 'black' -b 'red'
            stop-process -Id $PID
        }
        
        elseif ($context.Request.RawUrl.StartsWith('/api/get-availability')) {
            [string]$email = $context.Request.QueryString['email']

            # Open up Outlook appointment availability view with the given person set as an attendee
            $Outlook = New-Object -ComObject Outlook.Application
            $appointment = $Outlook.CreateItem(1)
            $appointment.Recipients.Add($email)
            $appointment.GetInspector.SetCurrentFormPage("Scheduling Assistant")
            $appointment.display() # show the window


            $buffer = [System.Text.Encoding]::UTF8.GetBytes("200 OK") # convert html to bytes
            $context.Response.statuscode = 200 
            $context.Response.ContentLength64 = $buffer.Length

            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
            $context.Response.OutputStream.Close() # close the response
            continue; # next listen loop
        }
        elseif ($context.Request.RawUrl.StartsWith('/api/search')) {

            # Handle /api paths separately
            [string]$queryString = $context.Request.QueryString['q']
            # $queryStringSplit = (-Split $queryString)
            
            $context.Response.AppendHeader("Access-Control-Allow-Origin", "*");

            if ($queryString.Length -le 2) {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("{""error"": ""Keep typing to see results.""}") # convert html to bytes
                $context.Response.statuscode = 422 
                $context.Response.ContentType = "application/json"
                $context.Response.ContentLength64 = $buffer.Length

                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
                $context.Response.OutputStream.Close() # close the response
                continue; # next listen loop
            }

            if ($queryString) {
                # Write-Host "Searching for $queryString..."
                $queryStringSplit = [string]$queryString -split " "

                $filter = "(|(displayname=$queryString*)(sn=$queryString*)(mail=$queryString*)(Name=$queryString*)(&(sn=" + $queryStringSplit[0] + "*)(GivenName=" + $queryStringSplit[1] + "*)))"

                $results = @(Get-ADUser -LDAPFilter $filter -Properties DisplayName, Department, CN, EmailAddress, UserPrincipalName, Title, Office, OfficePhone -ResultSetSize 20)

            }
            else {
                $results = @()
            }

            $parsedResults = @()

            foreach ($result in $results) {
                $parsedResults += @{
                    name       = $result.DisplayName
                    department = $result.Department
                    id         = $result.CN
                    emailAlias = $result.EmailAddress
                    email      = $result.UserPrincipalName
                    title      = $result.Title
                    phone      = $result.OfficePhone
                    location   = $result.Office
                }
            }

            [string]$json = ConvertTo-Json -InputObject $parsedResults

            if (!$json) {
                $json = "[]"
            }
            
            #resposed to the request
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json) # convert htmtl to bytes
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.ContentType = "application/json"
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
            $context.Response.OutputStream.Close() # close the response
        }
        else {
            # Serve content from /dist folder

            $path = Join-Path $PSScriptRoot "/dist" $context.Request.RawUrl -Resolve -ErrorAction SilentlyContinue

            if ($path -and (Get-Item $path -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]) {
                # Path exists and it points to a directory; serve index.html if it exists in this directory.
                $path = Join-Path $path "/index.html" -ErrorAction SilentlyContinue
            }

            if (!$path -or !(Test-Path -Path $path)) {
                # File not found
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found") # convert htmtl to bytes
                $context.Response.statuscode = 404
                $context.Response.ContentLength64 = $buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
                $context.Response.OutputStream.Close() # close the response
                continue;
            }
            else {
                # File found
                # $file = Get-Content -Path $path -Raw
                $extension = [System.IO.Path]::GetExtension($path)
                $file = [System.IO.File]::ReadAllBytes($path)
                # $buffer = [System.Text.Encoding]::UTF8.GetBytes($file) # convert htmtl to bytes
                $context.Response.ContentLength64 = $file.Count
                $context.Response.ContentType = Get-MimeType $extension
                $context.Response.OutputStream.Write($file, 0, $file.Length) #stream to broswer
                $context.Response.OutputStream.Close() # close the response
            }
        }
        

    
    }

} 

