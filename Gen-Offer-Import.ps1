# генерирует xml файл для импорта акции
Param
(
    
    [Parameter (Mandatory=$false, Position = 0)]
    [string] $targetFilename = "offer_import.xml",

    [Parameter (Position = 1)]
    [string] $partnerID = "016e8025-7068-43e5-c689-8b01e638c43a",

    [Parameter (Position = 2)]
    [string] $catalogID = "15a586da-3323-42aa-b72f-5461d0ef4cea",

    [Parameter (Position = 3)]
    [int] $startCard = 10000001,

    [Parameter (Position = 4)]
    [int] $countCards = 100,
    
    [Parameter (Position = 5)]
    [int] $countOffers = 1000    
)


function WriteProductsFilter(){
    param (
        [System.Xml.XmlTextWriter] $xml,
        [string] $name
    )

    $xml.WriteStartElement("ChequePositionGoodsFilter");
        $xml.WriteAttributeString("Name", "goods_filter_$name");
        $xml.WriteAttributeString("Type", "OnlyGoods");

        $xml.WriteStartElement("GoodsGroups")
            $xml.WriteStartElement("NewGoodsGroup")
            $xml.WriteAttributeString("Name", "goods_filter_$name");
            $xml.WriteAttributeString("CatalogId", $catalogID);
            
            $id = New-Guid;
            $xml.WriteElementString("Id", $id)
            $xml.WriteElementString("State", "Visible")
            for($i = 0; $i -lt 100; $i++){
                $id = "{0:000000}" -f $i
                $xml.WriteElementString("IncludeItem", $id)
            }

            $xml.WriteEndElement()
        $xml.WriteEndElement()                                    
                                
    $xml.WriteEndElement()
}

function WritePartners {
    param (
        [System.Xml.XmlTextWriter] $xml
    )
    
    $xml.WriteStartElement("Partners")
    $xml.WriteStartElement("Partner")
    
    $xml.WriteAttributeString("ID", $partnerID)

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
                
                for($i = 0; $i -lt $countCards; $i++){
                    $number = "{0:000000000}" -f $startCard++
                    $xml.WriteElementString("Card", $number)
                }
                                
            $xml.WriteEndElement()

            #WriteProductsFilter -xml $xml -name $name
            
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
            $id = New-Guid
            $xml.WriteAttributeString("ID", $id)
            $xml.WriteAttributeString("Title", "1000 Chains")
            $xml.WriteAttributeString("ApplyChangesDate", "2019-06-25T00:00:17")
            $xml.WriteAttributeString("State", "Running")
            $xml.WriteAttributeString("ChangesState", "Approved")
            $xml.WriteAttributeString("Priority", "100")
            $xml.WriteAttributeString("IsSum","false")

            $xml.WriteStartElement("Description")
            $xml.WriteEndElement()

            WritePartners($xml)
            #WriteLoyaltyProgram($xml)

            $xml.WriteStartElement("Rules")
                $xml.WriteStartElement("PurchaseCalculate")
                    $xml.WriteStartElement("Chains")

                    for ( $n = 0; $n -lt $countOffers; $n++ ) {
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


