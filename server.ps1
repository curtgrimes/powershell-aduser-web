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

# https://rosettacode.org/wiki/Reverse_words_in_a_string#PowerShell
function Reverse-Words($lines) {
    $lines | foreach { 
        $array = $PSItem.Split(' ') 
        $array[($array.Count - 1)..0] -join ' '
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

    # Get Request Url
    # When a request is made in a web browser the GetContext() method will return a request object
    # Our route examples below will use the request object properties to decide how to respond
    # $context = $contextTask.GetAwaiter().GetResult()


    # ROUTE EXAMPLE 1
    # http://127.0.0.1/
    if ($context.Request.HttpMethod -eq 'GET') {
        # Log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        
        if ($context.Request.RawUrl.StartsWith('/api/quit')) {
            $http.Stop()
            write-host ""
            write-host " Stopped server because webpage closed. " -f 'black' -b 'red'
            break;
        }
        elseif ($context.Request.RawUrl.StartsWith('/api/search')) {

            # Handle /api paths separately
            [string]$queryString = $context.Request.QueryString['q']
            # $queryStringSplit = (-Split $queryString)
            

            if ($queryString.Length -le 3) {
                continue;
            }

            if ($queryString) {
                # Write-Host "Searching for $queryString..."
                $queryStringReversed = Reverse-Words $queryString
                # Write-Host $queryStringReversed
                $filter = "(displayname -like ""$queryString*"") -or (displayname -like ""$queryStringReversed*"")"
                $results = @(Get-ADUser -filter $filter -SearchBase "OU=DK,DC=niunt,DC=niu,DC=edu" -Properties DisplayName, Department, CN, EmailAddress, UserPrincipalName, Title, Office, OfficePhone -ResultPageSize 10)
                # $results = Get-ADUser -filter { displayname -like "$queryString*" -or surname -like $queryString } -Properties Department, Name, displayname -ResultPageSize 10

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

            $resultCount = $results.Length
            
            #resposed to the request
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json) # convert htmtl to bytes
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.ContentType = "application/json"
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
            $context.Response.OutputStream.Close() # close the response
        }
        else {
            # Serve content from /dist folder

            $path = Join-Path "./dist" $context.Request.RawUrl -Resolve -ErrorAction SilentlyContinue
            
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


    # # ROUTE EXAMPLE 2
    # # http://127.0.0.1/some/form'
    # if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/some/form') {

    #     # We can log the request to the terminal
    #     write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

    #     [string]$html = "
    #     <h1>A Powershell Webserver</h1>
    #     <form action='/some/post' method='post'>
    #         <p>A Basic Form</p>
    #         <p>fullname</p>
    #         <input type='text' name='fullname'>
    #         <p>message</p>
    #         <textarea rows='4' cols='50' name='message'></textarea>
    #         <br>
    #         <input type='submit' value='Submit'>
    #     </form>
    #     "

    #     #resposed to the request
    #     $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
    #     $context.Response.ContentLength64 = $buffer.Length
    #     $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
    #     $context.Response.OutputStream.Close()
    # }

    # # ROUTE EXAMPLE 3
    # # http://127.0.0.1/some/post'
    # if ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/some/post') {

    #     # decode the form post
    #     # html form members need 'name' attributes as in the example!
    #     $FormContent = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()

    #     # We can log the request to the terminal
    #     write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'
    #     Write-Host $FormContent -f 'Green'

    #     # the html/data
    #     [string]$html = "<h1>A Powershell Webserver</h1><p>Post Successful!</p>" 

    #     #resposed to the request
    #     $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    #     $context.Response.ContentLength64 = $buffer.Length
    #     $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    #     $context.Response.OutputStream.Close() 
    # }


    # powershell will continue looping and listen for new requests...
} 

