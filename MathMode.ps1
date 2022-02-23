<# 
    Simple function to return the Mathamatical Mode of a list of items. 
    Will return array of items if multiple share top rank
    Testing Code below function definition
    
    Author. 	Victor Willingham (https://github.com/BigBobFro)
    License. 	Free to use as long as credit given where credit due
#>

function MathMode ([array]$ListIn = $null)
{
	[array]$MostItem 	= $null
	[int]$MostCount 	= 0
	foreach($item in $ListIn){
		if($MostItem -notcontains $item){
			$itemCount = $($ListIn|?{$_ -eq $item}).count
			if($ItemCount -ge $MostCount){
				if($ItemCount -eq $mostcount){
					$MostItem += $item
				}
				else{
					$MostCount = $ItemCount
					$MostItem = $item
				}
			}
		}
	}
	RETURN $MostItem
}




[array]$list = 'a','a','a','a','a','a','a','a','a','a','a','a','a','a','a'
$list += 'b','b'
$list += 'c','c','c','c','c','c','c','c','c','c','c','c','c','c','c','c'#,'c'
$list += 'd','d','d'
$list += 'e','e','e','e','e','e','e','e','e','e','e','e','e','e','e','e','e'
$list += 'f','f','f','f'


write-host "Mode of list: $(MathMode($list))"
