# генерирует xml файл для импорта каталога товаров
Param
(    
    [Parameter (Mandatory=$false, Position = 0)]
    [string] $targetFilename = "catalog_import.xml",

    [Parameter (Position = 1)]
    [string] $partnerID = "Partner1",

    [Parameter (Position = 2)]
    [string] $name = "Cat1",

    [Parameter (Position = 3)]
    [int] $countGoods = 1000        
)

#$productPrefix = 

$xml = New-Object System.XMl.XmlTextWriter($targetFilename,$Null)

$xml.Formatting = "Indented"
$xml.Indentation = 4

write-host "start..." $xml

$xml.WriteStartDocument("");
    $xml.WriteStartElement("TreeNode")
        $xml.WriteAttributeString("Name", $name)
        $xml.WriteAttributeString("ID", $partnerID)
        $xml.WriteAttributeString("IsDiff", "false")

        $xml.WriteStartElement("Leafs")

            for($i = 0; $i -lt $countGoods; $i++)
            {
                $id = "{0:000000}" -f $i
                $productName = "Product ($id)"

                $xml.WriteStartElement("TreeLeaf");
                    $xml.WriteAttributeString("Name", $productName)
                    $xml.WriteAttributeString("ID", $id)

                    $xml.WriteStartElement("BarCode");
                        $part = Get-Random -Maximum 99999999999 -Minimum 0
                        $part += $i
                        $barcode = "{0:0000000000000}" -f $part
                        $xml.WriteAttributeString("Value",$barcode);
                        $xml.WriteAttributeString("IsWeight","false");
                        $xml.WriteAttributeString("Multiplier","1");
                    $xml.WriteEndElement();

                $xml.WriteEndElement();    

            }            

        $xml.WriteEndElement()

    $xml.WriteEndElement()

$xml.WriteEndDocument()

$xml.Flush()
$xml.Close()
