$newPin = Read-Host 'Set new PIN (max 8 characters)' -AsSecureString
$newPin = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPin))

if ($newPin.Length -gt 8)
{
	Write-Error "PIN must be at most 8 characters"
	return
}

$newPuk = ""
$newPukLen = 8
$chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

$bytes = new-object "System.Byte[]" $newPukLen
$rng = new-object System.Security.Cryptography.RNGCryptoServiceProvider
$rng.GetBytes($bytes)

for( $i=0; $i -lt $newPukLen; $i++ )
{
	$newPuk += $chars[ $bytes[$i] % $chars.Length ]	
}

# TODO: Verify path to yubico-piv-tool
# TODO: Run programs and capture errors

$newMgm = "3A1E5C7F32D527D3B3CB86A10366A908ABBD0BF430DE0666"

$oldPin = "123456"
$oldPuk = "12345678"

# Reset
Write-Host "Resetting Yubikey"

Start-Process .\bin\yubico-piv-tool -ArgumentList "-a verify-pin -P RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a verify-pin -P RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a verify-pin -P RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a verify-pin -P RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a change-puk -P RNADOMSI -N RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a change-puk -P RNADOMSI -N RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a change-puk -P RNADOMSI -N RNADOMSI" -Wait -NoNewWindow
Start-Process .\bin\yubico-piv-tool -ArgumentList "-a change-puk -P RNADOMSI -N RNADOMSI" -Wait -NoNewWindow
$p = Start-Process .\bin\yubico-piv-tool -ArgumentList "-a reset" -Wait -NoNewWindow -PassThru

if ($p.ExitCode -ne 0)
{
	Write-Error "Error blocking pin"
	return
}

# Set Management key
Write-Host "Setting Management key"

Start-Process .\bin\yubico-piv-tool -ArgumentList "-a set-mgm-key -n $newMgm" -Wait -NoNewWindow

# Set PIN
Write-Host "Setting PIN key"

Start-Process .\bin\yubico-piv-tool -ArgumentList "-k $newMgm -a change-pin -P $oldPin -N $newPin" -Wait -NoNewWindow

# Set PUK
Write-Host "Setting PUK key"

Start-Process .\bin\yubico-piv-tool -ArgumentList "-k $newMgm -a change-puk -P $oldPuk -N $newPuk" -Wait -NoNewWindow

# Log Puk to file
$id = iex "bin\ykinfo.exe -H"
[System.IO.File]::AppendAllText("$pwd\yubico-log.txt", "ID: $id; Puk: $newPuk" + [Environment]::NewLine)