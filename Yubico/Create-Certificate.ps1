# EOBO Signer args: 89A22802E373A986C9961D414422A873B912B05E CSIS\Mike request.csr cert.crt
# TODO: Verify path to yubico-piv-tool

$enrollmentAgent = "89A22802E373A986C9961D414422A873B912B05E"
$mgmKey = "3A1E5C7F32D527D3B3CB86A10366A908ABBD0BF430DE0666"
$user = Read-Host 'Input User (Domain\User)'

$pin = Read-Host 'Input PIN' -AsSecureString
$pin = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pin))

# Set CHUID
Write-Host "Setting CHUID"

$p = Start-Process .\bin\yubico-piv-tool -ArgumentList "-k $mgmKey -a set-chuid" -Wait -NoNewWindow -PassThru

if ($p.ExitCode -ne 0)
{
	Write-Error "Error setting CHUID. Bad Management key?"
	return
}

# Generate key
Write-Host "Generating key on Yubikey"
Start-Process .\bin\yubico-piv-tool -ArgumentList "-k $mgmKey -s 9a -a generate -o public.pem" -Wait -NoNewWindow

# Make CSR
Write-Host "Generating CSR"

Start-Process .\bin\yubico-piv-tool -ArgumentList @"
-a verify-pin -P $pin -s 9a -a request-certificate -S "/CN=example/O=test/" -i public.pem -o request.csr
"@ -Wait -NoNewWindow

# Sign CSR
Write-Host "Signing CSR for user $user"

Start-Process .\EOBOSigner.exe -ArgumentList "$enrollmentAgent $user request.csr cert.crt" -Wait # -NoNewWindow

# Import Cert
Write-Host "Importing certificate"

Start-Process .\bin\yubico-piv-tool -ArgumentList "-k $mgmKey -s 9a -a import-certificate -i cert.crt" -Wait -NoNewWindow

# Cleanup
Write-Host "Cleaning up"

Remove-Item cert.crt
Remove-Item request.csr
Remove-Item public.pem