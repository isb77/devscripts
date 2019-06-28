# генерирует xml файл для импорта акции
Param
(
    
    [Parameter (Mandatory=$false, Position = 0)]
    [string] $targetFilename = "offer_import.xml"
)



function WritePartners {
    param (
        [System.Xml.XmlTextWriter] $xml
    )
    
    $xml.WriteStartElement("Partners")
    $xml.WriteStartElement("Partner")
    
    $xml.WriteAttributeString("ID", "016e8025-7068-43e5-c689-8b01e638c43a")

    $xml.WriteEndElement()
    $xml.WriteEndElement()

}

function WriteLoyaltyProgram {
    param (
        [System.Xml.XmlTextWriter] $xml
    )
    
    $xml.WriteStartElement("LoyaltyPrograms")
    $xml.WriteStartElement("LoyaltyProgram")

    $xml.WriteAttributeString("ID","Default")

    $xml.WriteEndElement()
    $xml.WriteEndElement()
}

function WriteActions{
    param (
        [System.Xml.XmlTextWriter] $xml
    )

    $xml.WriteStartElement("Actions");

        $xml.WriteStartElement("ChequeMessageAction");
            $xml.WriteAttributeString("Order","2")
            $xml.WriteStartElement("Message");
                $xml.WriteString("Offer from 01.06")
            $xml.WriteEndElement()
        $xml.WriteEndElement()

        $xml.WriteStartElement("DiscountAction")
            $xml.WriteAttributeString("Order","1")
            $xml.WriteElementString("Percent","10.0")
            $xml.WriteElementString("DistributeToAll","false")
            $xml.WriteElementString("DiscountType","Percent")
            $xml.WriteStartElement("CalculationExclusionDiscountTypes")
            $xml.WriteEndElement()
        $xml.WriteEndElement()

    $xml.WriteEndElement()
}

function WriteChain{
    param (
        [System.Xml.XmlTextWriter] $xml,
        [int] $order,
        [string] $name
    )

    $xml.WriteStartElement("Chain");
        $xml.WriteAttributeString("Order", $order);
        $xml.WriteAttributeString("Name", $name);
        $xml.WriteStartElement("Filters");        
            $xml.WriteStartElement("CardsFilter");
                $xml.WriteAttributeString("Name", "filter_$name");
                $xml.WriteStartElement("Card");
                $xml.WriteString("300099920")                
                $xml.WriteEndElement()
            $xml.WriteEndElement()
        $xml.WriteEndElement()    

        WriteActions $xml

    $xml.WriteEndElement()
}


$xml = New-Object System.XMl.XmlTextWriter($targetFilename,$Null)

$xml.Formatting = 'Indented'
$xml.Indentation = 4

$xml.WriteStartDocument("");
    $xml.WriteStartElement("Offers")
        $xml.WriteAttributeString("xmlns:xsd","http://www.w3.org/2001/XMLSchema")
        $xml.WriteAttributeString("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
        $xml.WriteAttributeString("Version","2.0")

        $xml.WriteStartElement("Offer")
            $xml.WriteAttributeString("ID", "664AA65C-BAB8-4F3D-89AA-8138EEE6EDD2")
            $xml.WriteAttributeString("Title", "1000 Chains")
            $xml.WriteAttributeString("ApplyChangesDate", "2019-06-25T00:00:17")
            $xml.WriteAttributeString("State", "Running")
            $xml.WriteAttributeString("ChangesState", "Approved")
            $xml.WriteAttributeString("Priority", "100")
            $xml.WriteAttributeString("IsSum","false")

            $xml.WriteStartElement("Description")
            $xml.WriteEndElement()

            WritePartners($xml)
            WriteLoyaltyProgram($xml)

            $xml.WriteStartElement("Rules")
                $xml.WriteStartElement("PurchaseCalculate")
                    $xml.WriteStartElement("Chains")

                    for ( $n = 0; $n -le 1000; $n++ ) {
                        WriteChain -xml $xml -order $n -name "New chain $n"
                    }

                    $xml.WriteEndElement();
                $xml.WriteEndElement();
            $xml.WriteEndElement();
        $xml.WriteEndElement();
    $xml.WriteEndElement();
$xml.WriteEndDocument();

$xml.Flush()
$xml.Close()


