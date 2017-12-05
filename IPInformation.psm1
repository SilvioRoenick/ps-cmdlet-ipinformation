#####
#
# IP Information
#
#
#
#####

function Get-IPv4Information
{

    [CmdletBinding()]Param
        (
            [parameter()] #,ValueFromPipeline=$true Mandatory=$true
            [string]$IP,
           # [parameter()] #,ValueFromPipeline=$true Mandatory=$true
           # [string]$IPundMaske,
            #[parameter()] #,ValueFromPipeline=$true Mandatory=$true
            #[string]$IP,
           # [parameter()] #,ValueFromPipeline=$true Mandatory=$true
           # [string]$Maske,
            [parameter()] #,ValueFromPipeline=$true Mandatory=$true
            [int]$NeueSubnetze,
            [parameter()] #,ValueFromPipeline=$true Mandatory=$true
            [switch]$AlleIPs

        )



### Variablen ###
[regex]$regexEingabe = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/)(([012]?[0-9]|3[0-2])|((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"

$ipDaten = @()
$ipDatenMuster = ("IP Adresse", "Netzmaske", "CIDR Suffix", "IP Binär", "Netzmaske Binär", "max IPs", "Netzwerkadresse", "Broadcast", "Hinweis")
$ipDatenLeerMuster = ("", "", "", "", "", "", "", "", "")
$ipDaten += ,@($ipDatenMuster)
[String]$fehlerMeldung = ""

### Variablen Ende ###



### Hilfsroutinen ###

    function fCDIRSuffixZuNetzmaske([String]$CDIRSuffix)
        {
            [String]$netzmaskeBinaer_String = ""
            [String]$netzmaske_String = ""
            $CDIRSuffix = [int]$CDIRSuffix
            for($i = 1; $i -le $CDIRSuffix; $i++)
                {
                    $netzmaskeBinaer_String += "1"
                }
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.PadRight(32,"0")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(8,".")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(17,".")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(26,".")
            $netzmaske_String = fbinaerStringZuDezimalString $netzmaskeBinaer_String
            return $netzmaske_String
        }

    function fNetzmaskeZuCDIRSuffix([String]$netzmaske)
        {
            [String]$netzmaskeBinaer_String = fdezimalStringZuBinaerString $netzmaske
            [String]$cidrSuffix_String = ""
            [regex]$regex = "1"
            $cidrSuffix_String = $regex.matches($netzmaskeBinaer_String).count
            return $cidrSuffix_String
        }

    function fdezimalStringZuBinaerString([String]$dezimal_String)
        {
            [String]$binaer_String = ""
            [String[]]$tmp_Array = ""
            $tmp_Array = $dezimal_String.Split(".")
            $binaer_String += [convert]::ToString($tmp_Array[0],2).Padleft(8,"0")
            $binaer_String += "."
            $binaer_String += [convert]::ToString($tmp_Array[1],2).Padleft(8,"0")
            $binaer_String += "."
            $binaer_String += [convert]::ToString($tmp_Array[2],2).Padleft(8,"0")
            $binaer_String += "."
            $binaer_String += [convert]::ToString($tmp_Array[3],2).Padleft(8,"0")
            return $binaer_String
        }

    function fbinaerStringZuDezimalString([String]$binaer_String)
        {
            [String]$dezimal_String = ""
            [String[]]$tmp_Array = ""
            $tmp_Array = $binaer_String.Split(".")
            $dezimal_String += [convert]::ToInt32($tmp_Array[0],2)
            $dezimal_String += "."
            $dezimal_String += [convert]::ToInt32($tmp_Array[1],2)
            $dezimal_String += "."
            $dezimal_String += [convert]::ToInt32($tmp_Array[2],2)
            $dezimal_String += "."
            $dezimal_String += [convert]::ToInt32($tmp_Array[3],2)
            return $dezimal_String
        }

    function fberechneAnzahlSubnetIPs([String]$netzmaskeBinaer_String)
        {
            [int]$anzahl = 0
            [String]$tmp = $netzmaskeBinaer_String.Replace(".","")
            [regex]$regex = "0"
            $anzahl = $regex.matches($tmp).count
            $anzahl = [math]::pow( 2, $anzahl )
            return $anzahl
        }

    function fberechneNetzwerkadresse([String]$ip_String, [String]$netzmaske_String)
        {
            [String]$netzwerkadresse = ""
            [byte[]]$ip_Array = $ip_String.split('.')
            [byte[]]$maske_Array = $netzmaske_String.split('.')
            [byte[]]$netzwerkadresse_Array = 0,0,0,0
            $netzwerkadresse += $netzwerkadresse_Array[0] = ($ip_Array[0] -band $maske_Array[0])
            $netzwerkadresse += "."
            $netzwerkadresse += $netzwerkadresse_Array[1] = ($ip_Array[1] -band $maske_Array[1])
            $netzwerkadresse += "."
            $netzwerkadresse += $netzwerkadresse_Array[2] = ($ip_Array[2] -band $maske_Array[2])
            $netzwerkadresse += "."
            $netzwerkadresse += $netzwerkadresse_Array[3] = ($ip_Array[3] -band $maske_Array[3])
            return $netzwerkadresse
        }

    function fberechneBroadcast([String]$ipBinaer_String, [String]$netzmaskeBinaer_String)
        {
            [String]$broadcast = ""
            $netzmaskeBinaerInvert_String = $netzmaskeBinaer_String
            $netzmaskeBinaerInvert_String = $netzmaskeBinaerInvert_String.Replace("1","x")
            $netzmaskeBinaerInvert_String = $netzmaskeBinaerInvert_String.Replace("0","1")
            $netzmaskeBinaerInvert_String = $netzmaskeBinaerInvert_String.Replace("x","0")
            [String[]]$ipBinaer_Array = $ipBinaer_String.split('.')
            [String[]]$netzmaskeBinaerInvert_Array = $netzmaskeBinaerInvert_String.split('.')
            $broadcast += (([convert]::ToByte($ipBinaer_Array[0],2)) -bor ([convert]::ToByte($netzmaskeBinaerInvert_Array[0],2)))
            $broadcast += "."
            $broadcast += (([convert]::ToByte($ipBinaer_Array[1],2)) -bor ([convert]::ToByte($netzmaskeBinaerInvert_Array[1],2)))
            $broadcast += "."
            $broadcast += (([convert]::ToByte($ipBinaer_Array[2],2)) -bor ([convert]::ToByte($netzmaskeBinaerInvert_Array[2],2)))
            $broadcast += "."
            $broadcast += (([convert]::ToByte($ipBinaer_Array[3],2)) -bor ([convert]::ToByte($netzmaskeBinaerInvert_Array[3],2)))
            return $broadcast
        }

### Hilfsroutinen Ende ###



### Hauptroutine ###

    #if(($IPundMaske -ne $null) -and ($IPundMaske -match $regexEingabe))
    if(($IP -ne $null) -and ($IP -match $regexEingabe))
        {
          #  $eingabe = $IPundMaske
          $eingabe = $IP
        }
    #elseif((($IP -ne $null) -and ($Maske -ne $null)) -and (($IP + "/" + $Maske) -match $regexEingabe))
     #   {
     #       $eingabe = $IP + "/" + $Maske
      #  }
    else
        {
            $fehlerMeldung = "Fehlerhafte eingabe!"
        }

    ### Eingabe aufbereiten

    if($fehlerMeldung -eq "")
        {
            $ipDaten += ,@($ipDatenLeerMuster)
            $eingabe_Array = $eingabe.Split("/")
            $ipDaten[1][0] = $eingabe_Array[0]
            if($eingabe_Array[1] -match "^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$")
                {
                    $ipDaten[1][1] = $eingabe_Array[1]
                }
            elseif($eingabe_Array[1] -match "^([012]?[0-9]|3[0-2])$")
                {
                    $ipDaten[1][2] = $eingabe_Array[1]
                }
            $ipDaten[1][8] = "Eingabe"
        }

    ### Auffüllen von Daten

    if($NeueSubnetze -ne 0)
        {
            "neue subs"
        }

    if($AlleIPs -eq $true)
        {
            "allips"

        }

    ### Ausfüllen der Daten

    for($i = 1; $i -le $ipDaten.Length - 1; $i++)
        {
            #$i
            #$ipDaten[$i][0]
            if($($ipDaten[$i][1]) -eq "") { $ipDaten[$i][1] = fCDIRSuffixZuNetzmaske($ipDaten[$i][2]) }
            if($($ipDaten[$i][2]) -eq "") { $ipDaten[$i][2] = fNetzmaskeZuCDIRSuffix($ipDaten[$i][1]) }
            $ipDaten[$i][3] = fdezimalStringZuBinaerString $ipDaten[$i][0] 
            $ipDaten[$i][4] = fdezimalStringZuBinaerString $ipDaten[$i][1] 
            $ipDaten[$i][5] = fberechneAnzahlSubnetIPs $ipDaten[$i][4]
            $ipDaten[$i][6] = fberechneNetzwerkadresse $ipDaten[$i][0] $ipDaten[$i][1]
            $ipDaten[$i][7] = fberechneBroadcast $ipDaten[$i][3] $ipDaten[$i][4]
            #$ipDaten[$i][8]
        }


    ### Ausgabe

    if($fehlerMeldung -ne "")
        {
            Write-Output $fehlerMeldung
        }
        else
        {
            #$ipDaten
            #$ipDaten | Format-Table –AutoSize
            foreach($datensatz in $ipDaten)
                {
                    $ausgabe = ""
                    foreach($datenfeld in $datensatz)
                        {
                       # $datenfeld 
                            $ausgabe += "$datenfeld`t"
                        }
                    Write-Output $ausgabe
                }
        }


### Hauptroutine Ende ###

}



function Get-IPv6Information
{


    [CmdletBinding()]Param
        (
    
            [parameter()] #,ValueFromPipeline=$true Mandatory=$true
            [string]$IP

        )



### Variablen ###
[regex]$regexEingabe = "^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$"

$ipDaten = @()
$ipDatenMuster = ("IP Adresse", "Maske", "IP Binär", "Maske Binär", "Hinweis") # ipkurz mod hinweis erweitern
$ipDatenLeerMuster = ("", "", "", "", "")
$ipDaten += ,@($ipDatenMuster)
[String]$fehlerMeldung = ""

### Variablen Ende ###


### Hilfsroutinen ###
    
    function fipauffuellen([String]$ipKurz)
        {
            [String]$ipKomplett = ""
            [regex]$regex = ":" 
            $anzahl = $regex.matches($ipKurz).count
            $bedarf = 7 - $anzahl
            if($bedarf -gt 0)
                {
                    $einfuegen = ""
                        for($i = 0; $i -lt $bedarf + 2; $i++)
                            {
                                $einfuegen += ":"
                            }
                    $ipKurz = $ipKurz.Replace("::",$einfuegen)
                }
            [String[]]$ip_Array = $ipKurz.split(':')
            $ipKomplett += $ip_Array[0].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[1].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[2].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[3].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[4].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[5].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[6].Padleft(4,"0")
            $ipKomplett += ":"
            $ipKomplett += $ip_Array[7].Padleft(4,"0")
            return $ipKomplett.ToUpper()
        }

    function fhexStringZuBinaerString([String]$hex_String)
        {
            [String]$binaer_String = ""
            [String[]]$hex_Array = $hex_String.split(':')
            $binaer_String += fnibbelZuBinaerString $hex_Array[0]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[1]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[2]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[3]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[4]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[5]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[6]
            $binaer_String += ":"
            $binaer_String += fnibbelZuBinaerString $hex_Array[7]
            return $binaer_String
        }

    function fnibbelZuBinaerString([String]$nibbel)
        {
            [String]$nibbelBinaer_String = ""
            $nibbel_CharArray = [char[]]$nibbel

            for($i = 0; $i -le $nibbel_CharArray.Length - 1; $i++)
                {
                    [int]$wert = 0
                    if ($nibbel_CharArray[$i] -eq "A") { $wert = 10}
                    elseif ($nibbel_CharArray[$i] -eq "B") { $wert = 11}
                    elseif ($nibbel_CharArray[$i] -eq "C") { $wert = 12}
                    elseif ($nibbel_CharArray[$i] -eq "D") { $wert = 13}
                    elseif ($nibbel_CharArray[$i] -eq "E") { $wert = 14}
                    elseif ($nibbel_CharArray[$i] -eq "F") { $wert = 15}
                    else { $wert = [int][string][char]$nibbel_CharArray[$i]}
                    $nibbelBinaer_String +=  [convert]::ToString($wert,2).Padleft(4,"0")
               }
            return $nibbelBinaer_String
        }


    function fcdirZuBinaer($CDIRSuffix)
        {
            [String]$netzmaskeBinaer_String = ""
            $CDIRSuffix = [int]$CDIRSuffix
            for($i = 1; $i -le $CDIRSuffix; $i++)
                {
                    $netzmaskeBinaer_String += "1"
                }
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.PadRight(128,"0")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(16,":")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(33,":")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(50,":")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(67,":")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(84,":")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(101,":")
            $netzmaskeBinaer_String = $netzmaskeBinaer_String.Insert(118,":")
            return $netzmaskeBinaer_String
        }


### Hilfsroutinen Ende ###



### Hauptroutine ###

    if(($IP -ne $null) -and ($IP -match $regexEingabe))
        {
            $eingabe = $IP
        }
    else
        {
            $fehlerMeldung = "Fehlerhafte eingabe!"
        }

    if($fehlerMeldung -eq "")
        {
            $eingabe_Array = $eingabe.Split("/")
            [String]$eingabeIP = $eingabe_Array[0]
            [String]$eingabeCDIR = $eingabe_Array[1]
            [String]$ip = fipauffuellen $eingabeIP
            $ipDaten += ,@($ipDatenLeerMuster)
            $ipDaten[1][0] = $ip
            $ipDaten[1][1] = $eingabeCDIR
            $ipDaten[1][2] = fhexStringZuBinaerString $ip
            $ipDaten[1][3] = fcdirZuBinaer $eingabeCDIR
            $ipDaten[1][4] = "Eingabe"  
        }


    ### Ausgabe

    if($fehlerMeldung -ne "")
        {
            Write-Output $fehlerMeldung
        }
        else
        {
            $ipDaten
          
        }


### Hauptroutine Ende ###

}