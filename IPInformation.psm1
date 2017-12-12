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

    function CDIRSuffix-zu-Netzmaske([String]$CDIRSuffix)
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
            $netzmaske_String = BinaerString-zu-DezimalString $netzmaskeBinaer_String
            return $netzmaske_String
        }

    function Netzmaske-zu-CDIRSuffix([String]$netzmaske)
        {
            [String]$netzmaskeBinaer_String = DezimalString-zu-BinaerString $netzmaske
            [String]$cidrSuffix_String = ""
            [regex]$regex = "1"
            $cidrSuffix_String = $regex.matches($netzmaskeBinaer_String).count
            return $cidrSuffix_String
        }

    function DezimalString-zu-BinaerString([String]$dezimal_String)
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

    function BinaerString-zu-DezimalString([String]$binaer_String)
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

    function Berechne-AnzahlSubnetIPs([String]$netzmaskeBinaer_String)
        {
            [Double]$anzahl = 0
            [String]$tmp = $netzmaskeBinaer_String.Replace(".","")
            [regex]$regex = "0"
            $anzahl = $regex.matches($tmp).count
            $anzahl = [math]::pow( 2, $anzahl )
            return $anzahl
        }

    function Berechne-Netzwerkadresse([String]$ip_String, [String]$netzmaske_String)
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

    function Berechne-Broadcast([String]$ipBinaer_String, [String]$netzmaskeBinaer_String)
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

    if(($IP -ne $null) -and ($IP -match $regexEingabe))
        {
            $eingabe = $IP
            ### Eingabe aufbereiten
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
    else
        {
            $fehlerMeldung = "Fehlerhafte eingabe!"
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
            if($($ipDaten[$i][1]) -eq "") { $ipDaten[$i][1] = CDIRSuffix-zu-Netzmaske($ipDaten[$i][2]) }
            if($($ipDaten[$i][2]) -eq "") { $ipDaten[$i][2] = Netzmaske-zu-CDIRSuffix($ipDaten[$i][1]) }
            $ipDaten[$i][3] = DezimalString-zu-BinaerString $ipDaten[$i][0] 
            $ipDaten[$i][4] = DezimalString-zu-BinaerString $ipDaten[$i][1] 
            $ipDaten[$i][5] = Berechne-AnzahlSubnetIPs $ipDaten[$i][4]
            $ipDaten[$i][6] = Berechne-Netzwerkadresse $ipDaten[$i][0] $ipDaten[$i][1]
            $ipDaten[$i][7] = Berechne-Broadcast $ipDaten[$i][3] $ipDaten[$i][4]
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
            [string]$IP,
            [parameter()] #,ValueFromPipeline=$true Mandatory=$true
            [int]$NeueSubnetze,
            [parameter()] #,ValueFromPipeline=$true Mandatory=$true
            [switch]$AlleIPs
        )

### Variablen ###
[regex]$regexEingabe = "^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$"

### Variablen Ende ###

$ipDaten = New-Object System.Data.DataTable("IPv6")
$spalte0 = New-Object System.Data.DataColumn("IP Adresse")
$spalte1 = New-Object System.Data.DataColumn("Maske")
$spalte2 = New-Object System.Data.DataColumn("IP Binär")
$spalte3 = New-Object System.Data.DataColumn("Maske Binär")
$spalte4 = New-Object System.Data.DataColumn("max IPs")
$spalte5 = New-Object System.Data.DataColumn("Netzwerkadresse")
$spalte6 = New-Object System.Data.DataColumn("Hinweis")
$ipDaten.Columns.Add($spalte0)
$ipDaten.Columns.Add($spalte1)
$ipDaten.Columns.Add($spalte2)
$ipDaten.Columns.Add($spalte3)
$ipDaten.Columns.Add($spalte4)
$ipDaten.Columns.Add($spalte5)
$ipDaten.Columns.Add($spalte6)

### Hilfsroutinen ###
    
    function Auffuellen-IP([String]$ipKurz)
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

    function HexString-zu-BinaerString([String]$hex_String)
        {
            [String]$binaer_String = ""
            [String[]]$hex_Array = $hex_String.split(':')
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[0]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[1]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[2]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[3]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[4]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[5]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[6]
            $binaer_String += ":"
            $binaer_String += Nibbel-zu-BinaerString $hex_Array[7]
            return $binaer_String
        }

    function Nibbel-zu-BinaerString([String]$nibbel)
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


    function CDIR-zu-Binaer($CDIRSuffix)
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

    function Berechne-AnzahlSubnetIPs([String]$netzmaskeBinaer_String)
        {
            [Double]$anzahl = 0
            [String]$tmp = $netzmaskeBinaer_String.Replace(":","")
            [regex]$regex = "0"
            $anzahl = $regex.matches($tmp).count
            $anzahl = [math]::pow( 2, $anzahl )
            return $anzahl
        }

    function Hinzufuegen-Hinweis([String]$ip)
        {
            # https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xhtml
            [String]$hinweis = ""
            if($ip -match "^(0|:){39}$"){$hinweis += "Unspezifizierte Adresse "}
            if($ip -match "^(0|:){38}1$"){$hinweis += "lokaler Host "}
            if($ip -match "^FE80:*"){$hinweis += "Link Local Unicast "}
            return $hinweis
        }

### Hilfsroutinen Ende ###


### Hauptroutine ###

    if(($IP -ne $null) -and ($IP -match $regexEingabe))
        {
            $eingabe = $IP
            ### Eingabe aufbereiten
            $eingabe_Array = $eingabe.Split("/")
            [String]$eingabeIP = $eingabe_Array[0]
            [String]$eingabeCDIR = $eingabe_Array[1]
            [String]$ip = Auffuellen-IP $eingabeIP
            $zeile = $ipDaten.NewRow()
            $zeile."IP Adresse" = $IP
            $zeile."Maske" = $eingabeCDIR
            $zeile."IP Binär" = HexString-zu-BinaerString $ip
            $zeile."Maske Binär" = CDIR-zu-Binaer $eingabeCDIR
            $zeile."max IPs" = Berechne-AnzahlSubnetIPs $(CDIR-zu-Binaer $eingabeCDIR)
            $zeile."Netzwerkadresse" = ""
            $zeile."Hinweis" = "Eingabe " + $(Hinzufuegen-Hinweis $ip)
            $ipDaten.Rows.Add($zeile)
            ### Ausgabe
            $ipDaten #.Rows | Format-Table
        }
    else
        {
            Write-Output "Fehlerhafte eingabe!"
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

### Hauptroutine Ende ###

}
