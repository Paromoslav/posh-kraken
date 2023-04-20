#Function - Download a file from krakenfiles.com
Function Invoke-KrakenFileDownload {
    Param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('URI')]
        [URI]$URL,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Path')]
        [String]$LiteralPath
    )

    Begin {
        Try {
            $Null = New-Item -Path (Split-Path $LiteralPath) -ItemType Directory -Force
        }
        Catch {
            Throw "Failed to create a directory '$(Split-Path $LiteralPath)'."
        }        
    }

    Process {
        $WebResponse = Invoke-WebRequest -Uri $URL -SessionVariable 'Session'
        $WebContent = $WebResponse.Content
        $DLToken = $WebResponse.InputFields.Where{$_.id -eq 'dl-token'}.value
        $RegexMatch = [Regex]::Match($WebContent, '(?<=data-file-hash=")[^"]*')
        If ($RegexMatch.Success) {
            $DataFileHash = $RegexMatch.Value
        }
        Else {
            $DataFileHash = $URL.Split('/')[4]
        }

        $Headers = @{
            'content-type' = 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW';
            'cache-control' = 'no-cache';
            hash = $DataFileHash
        }

        $Payload = "------WebKitFormBoundary7MA4YWxkTrZu0gW`nContent-Disposition: form-data; name=`"token`"`n`n$DLToken`n------WebKitFormBoundary7MA4YWxkTrZu0gW--"

        $DownloadURL = ((Invoke-WebRequest -Uri "https://krakenfiles.com/download/$DataFileHash" -Headers $Headers -Body $Payload -Method Post -WebSession $Session).Content | ConvertFrom-Json).url
        Invoke-WebRequest -Uri $DownloadURL -OutFile $LiteralPath -WebSession $Session
    }
}