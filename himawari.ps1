#
# Himawari-8 Downloader
#
#
#
# This script will scrape the latest image from the Himawari-8 satellite, recombining the tiled image,
# converting it to a JPG which is saved in My Pictures\Himawari\ and then set as the desktop background.
#
# http://himawari8.nict.go.jp/himawari8-image.htm
#
#

#$latestInfoUri = "http://himawari8-dl.nict.go.jp/himawari8/img/D531106/latest.json?" + (New-Guid).ToString();
#$latestInfo = Invoke-RestMethod -Uri $latestInfoUri

#$now = Get-Date $latestInfo.date;

$width = 11000
$height = 11000

#Create the folder My Pictures\Himawari\ if it doesnt exist
$outpath = [Environment]::GetFolderPath("MyPictures") + "\Himawari\"
if(!(Test-Path -Path $outpath ))
{
    [void](New-Item -ItemType directory -Path $outpath)
}

#The filename that will be saved:
$outfile = "latest.jpg" 


$url = "http://rammb.cira.colostate.edu/ramsdis/online/images/latest_hi_res/himawari-8/full_disk_ahi_natural_color.jpg"
[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

$image = New-Object System.Drawing.Bitmap(($width), ($height))
$graphics = [System.Drawing.Graphics]::FromImage($image)
$graphics.Clear([System.Drawing.Color]::Black)

Write-Output "Downloading: $url"   
 
try
{
    
    $request = [System.Net.WebRequest]::create($url)
    $response = $request.getResponse()
    $HTTP_Status = [int]$response.StatusCode
    If ($HTTP_Status -eq 200)
    { 
        $imgblock = [System.Drawing.Image]::fromStream($response.getResponseStream())
        $graphics.DrawImage($imgblock, 0, 0)   
        $imgblock.dispose()
        $response.Close()
    }
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Output "Failed! $ErrorMessage with $FailedItem"
}

$qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)

# Set JPEG quality level here: 0 - 100 (inclusive bounds)
$qualityValue = 95
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($qualityEncoder, $qualityValue)
$jpegCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | where {$_.MimeType -eq 'image/jpeg'}

$image.save(($outpath + $outfile), $jpegCodecInfo, $encoderParams)
$image.Dispose()

<#
 Different settings for the wallpaper:
 
                            Tile :
                                key.SetValue(@"WallpaperStyle", "0") ; 
                                key.SetValue(@"TileWallpaper", "1") ; 
                                break;
                            Center :
                                key.SetValue(@"WallpaperStyle", "0") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
                            Stretch :
                                key.SetValue(@"WallpaperStyle", "2") ; 
                                key.SetValue(@"TileWallpaper", "0") ;
                                break;
                            Fill :
                                key.SetValue(@"WallpaperStyle", "10") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
                            Fit :
                                key.SetValue(@"WallpaperStyle", "6") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
#>


Write-Output "Setting Wallpaper..."
Set-ItemProperty -path "HKCU:Control Panel\Desktop" -name Wallpaper -value ($outpath + $outfile)
Set-ItemProperty -path "HKCU:Control Panel\Desktop" -name WallpaperStyle -value 6
Set-ItemProperty -path "HKCU:Control Panel\Desktop" -name TileWallpaper -value 0
Set-ItemProperty 'HKCU:\Control Panel\Colors' -name Background -Value "0 0 0"
#rundll32.exe user32.dll, UpdatePerUserSystemParameters


$setwallpapersource = @"
using System.Runtime.InteropServices;
public class wallpaper
{
public const int SetDesktopWallpaper = 20;
public const int UpdateIniFile = 0x01;
public const int SendWinIniChange = 0x02;
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
public static void SetWallpaper ( string path )
{
SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
}
}
"@
Add-Type -TypeDefinition $setwallpapersource
[wallpaper]::SetWallpaper(($outpath + $outfile))


Write-Output "Done"