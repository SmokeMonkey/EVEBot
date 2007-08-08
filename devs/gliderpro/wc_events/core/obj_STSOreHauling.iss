/*
	Station-to-Station Ore Hauling (originally written by Amadeus)

BUGS:
	
			
*/



variable(script) index:item MyCargo
variable(script) index:item HangarCargo
variable(script) index:item CargoToTransfer

variable(script) bool EverythingHauled

function atexit()
{
 	echo "EVE Ore Hauler Script -- Ended"
	return
}

function TransferOreToHangar()
{	
    if !${EVEWindow[MyShipCargo](exists)}
		{
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 30
		}
		if !${EVEWindow[hangarFloor](exists)}
		{
			EVE:Execute[OpenHangarFloor]
			wait 30		
		}
		
		Me.Ship:DoGetCargo[MyCargo]
		
		variable iterator ThisCargo
		
		MyCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			variable int CategoryID
			variable string Name

			CategoryID:Set[${ThisCargo.Value.CategoryID}]
			Name:Set[${ThisCargo.Value.Name}]

			;echo "DEBUG: obj_Cargo:TransferToHangar: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"			
			switch ${CategoryID}
			{
				case 4
					CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				case 25
					CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}

		if ${CargoToTransfer.Used} > 0
		{
			EVE:Execute[OpenHangarFloor]
			wait 30
			
			variable iterator CargoIterator
			CargoToTransfer:GetIterator[CargoIterator]
			
			if ${CargoIterator:First(exists)}
			do
			{
				;echo "obj_Cargo:TransferToHangar: Unloading Cargo: ${CargoIterator.Value.Name}"
				CargoIterator.Value:MoveTo[Hangar]
				wait 30
			}
			while ${CargoIterator:Next(exists)}
			wait 10
		}

		CargoToTransfer:Clear[]
 
    ; After everything is done ...let's clean up the stacks.
    Me.Station:StackAllHangarItems
    wait 5
    
    EVEWindow[MyShipCargo]:Close
    wait 10
    EVEWindow[hangarFloor]:Close
    wait 10    
}


function TransferOreToShip()
{	
    variable float TotalOreVolumeRemaining
    
    echo "- Transferring ${Me.Ship.CargoCapacity.Precision[2]} m3 of Ore to ship..."

    if !${EVEWindow[MyShipCargo](exists)}
		{
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 30
		}
		if !${EVEWindow[hangarFloor](exists)}
		{
			EVE:Execute[OpenHangarFloor]
			wait 30		
		}
		
		Me.Station:DoGetHangarItems[HangarCargo]
		
		variable iterator ThisCargo
		
		HangarCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		TotalOreVolumeRemaining:Set[0]
		do
		{
			variable int CategoryID
			variable string Name

			CategoryID:Set[${ThisCargo.Value.CategoryID}]
			Name:Set[${ThisCargo.Value.Name}]

			;echo "DEBUG: obj_Cargo:TransferToHangar: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"			
			switch ${CategoryID}
			{
				case 4
					CargoToTransfer:Insert[${ThisCargo.Value}]
					TotalOreVolumeRemaining:Inc[${Math.Calc[${ThisCargo.Value.Quantity} * ${ThisCargo.Value.Volume}]}]
					break
				case 25
					CargoToTransfer:Insert[${ThisCargo.Value}]
					TotalOreVolumeRemaining:Inc[${Math.Calc[${ThisCargo.Value.Quantity} * ${ThisCargo.Value.Volume}]}]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}
		
		echo "- There are ${TotalOreVolumeRemaining.Precision[2]} m3 of Ore remaining to be hauled."

		if ${CargoToTransfer.Used} > 0
		{
			variable iterator CargoIterator
			CargoToTransfer:GetIterator[CargoIterator]
			
			if ${CargoIterator:First(exists)}
			do
			{
			  ;echo "- Processing: ${CargoIterator.Value.Name}"
			  if (${CargoIterator.Value.Volume} > ${Math.Calc[${Me.Ship.CargoCapacity} - ${Me.Ship.UsedCargoCapacity}]})
			  {
			  	continue
				}
			
			  if (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]} > ${Math.Calc[${Me.Ship.CargoCapacity} - ${Me.Ship.UsedCargoCapacity}]})
			  {
				  CargoIterator.Value:MoveTo[MyShip,${Math.Calc[${Math.Calc[${Me.Ship.CargoCapacity} - ${Me.Ship.UsedCargoCapacity}]} / ${CargoIterator.Value.Volume}]}]
				  wait 20
				}
				else
				{
				  CargoIterator.Value:MoveTo[MyShip]
				  wait 20
				}				
			}
			while ((${CargoIterator:Next(exists)}) && (${Me.Ship.UsedCargoCapacity} < ${Me.Ship.CargoCapacity}))
			wait 10
		}

		CargoToTransfer:Clear[]
		
		Me.Ship:StackAllCargo
		wait 5
 
    ;;;;;;;;;;;;;;;;
    ; Now check to see if any ore is left...
    EverythingHauled:Set[TRUE]
 		Me.Station:DoGetHangarItems[HangarCargo]		
		HangarCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			CategoryID:Set[${ThisCargo.Value.CategoryID}]
			Name:Set[${ThisCargo.Value.Name}]

			switch ${CategoryID}
			{
				case 4
					EverythingHauled:Set[FALSE]
					break
				case 25
					EverythingHauled:Set[FALSE]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}
		
		if ${EverythingHauled}
			echo "- All Ore has been transferred. This will be your last trip."
		else 
		  echo "- Ore transfer complete -- Approx. ${Math.Calc[${TotalOreVolumeRemaining} / ${Me.Ship.CargoCapacity}].Round} round trips remaining."
		
 		;;;;;;;;;;;;;;;;;;;;
 		
 
    EVEWindow[MyShipCargo]:Close
    wait 10
    EVEWindow[hangarFloor]:Close
    wait 10
    
    ; Just in case...
    EVE:CloseAllMessageBoxes
    
    
}


function main(string Origin, string Destination, string ReturnToOrigin)
{
  if !${ISXEVE(exists)}
  {
     echo "- ISXEVE must be loaded to use this script."
     return
  }
  do
  {
     waitframe
  }
  while !${ISXEVE.IsReady}
  
	if !${EVE.Bookmark[${Origin}](exists)}
	{  
		echo "The 'Origin' bookmark was not found."
		return
	}
	elseif !${EVE.Bookmark[${Destination}](exists)}
	{  
		echo "The 'Destination' bookmark was not found."
		return
	}
  
  echo " \n \n \n** EVE Ore Hauler Script by Amadeus ** \n \n"

  ;;; Main Loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  do
  {
  	 	; We should be starting the script while in the "Origin" station... that's the responsibility of the user
  	 	call TransferOreToShip
  	 
  	  ; Leave station
	   	echo "- Undocking from station..."
	   	EVE:Execute[CmdExitStation]	
	   	wait 150
	   	if (${Me.InStation})
	   	{
	   		do
	   		{
	   			wait 20
	   		}
	   		while (${Me.InStation} || !${EVEWindow[Local](exists)})
	   	}
	   	wait 5
	   
	   	; Set autopilot and head to Destination station
	  	echo "- Setting autopilot destination: ${EVE.Bookmark[${Destination}]}"
			EVE.Bookmark[${Destination}]:SetDestination
			wait 5
			echo "- Activating autopilot and waiting until arrival..."
			EVE:Execute[CmdToggleAutopilot]
			do
			{
			   wait 50
			   if !${Me.AutoPilotOn(exists)}
			   {
			     do
			     {
			        wait 5
			     }
			     while !${Me.AutoPilotOn(exists)}
			   }
			}
			while ${Me.AutoPilotOn}
			wait 20
			do
			{
			   wait 10
			}
			while !${Me.ToEntity.IsCloaked}
			wait 5
			
			; Dock with Destination station
			echo "- Warping to destination station"	   
			EVE.Bookmark[${Destination}]:WarpTo
			wait 120
			do
			{
				wait 20
			}
			while (${Me.ToEntity.Mode} == 3)	
			wait 20
			echo "- Docking with destination station"
			if ${EVE.Bookmark[${Destination}].ToEntity(exists)}
			{
				if (${EVE.Bookmark[${Destination}].ToEntity.CategoryID} == 3)
				{
					EVE.Bookmark[${Destination}].ToEntity:Approach
					do
					{
						wait 20
					}
					while (${EVE.Bookmark[${Destination}].ToEntity.Distance} > 50)
					
					EVE.Bookmark[${Destination}].ToEntity:Dock			
					do
					{
					   wait 20
					   WaitCount:Inc[20]
					}
					while (!${Me.InStation} && ${WaitCount} < 200)
					WaitCount:Set[0]
					if (!${Me.InStation})
					{
					  echo "- First Attempt at docking with failed...trying again."
					  Entity[CategoryID,3]:Dock
						do
						{
					  	 wait 20
					  	 WaitCount:Inc[20]
						}
						while (!${Me.InStation} && ${WaitCount} < 200)
						WaitCount:Set[0]
					}							
				}
			}
			wait 20
			
			; We're inside the destination station -- unload cargo			
			echo "- Unloading Ore..."
			call TransferOreToHangar

			if (${EverythingHauled} && !${ReturnToOrigin.Equal[TRUE]})
			{
			   echo "- Finished Transporting Ore ... remaining at destination station."
			   return
			}
	
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Return to Origin ;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			
  	  ; Leave station
	   	echo "- Undocking from station..."
	   	EVE:Execute[CmdExitStation]	
	   	wait 150
	   	if (${Me.InStation})
	   	{
	   		do
	   		{
	   			wait 20
	   		}
	   		while (${Me.InStation} || !${EVEWindow[Local](exists)})
	   	}
	   	wait 5
	   
	   	; Set autopilot and head to Origin station
	  	echo "- Setting autopilot destination: ${EVE.Bookmark[${Origin}]}"
			EVE.Bookmark[${Origin}]:SetDestination
			wait 5
			echo "- Activating autopilot and waiting until arrival..."
			EVE:Execute[CmdToggleAutopilot]
			do
			{
			   wait 50
			   if !${Me.AutoPilotOn(exists)}
			   {
			     do
			     {
			        wait 5
			     }
			     while !${Me.AutoPilotOn(exists)}
			   }
			}
			while ${Me.AutoPilotOn}
			wait 20
			do
			{
			   wait 10
			}
			while !${Me.ToEntity.IsCloaked}
			wait 5
			
			; Dock with Origin station
			echo "- Warping to origin station"	   
			EVE.Bookmark[${Origin}]:WarpTo
			wait 120
			do
			{
				wait 20
			}
			while (${Me.ToEntity.Mode} == 3)	
			wait 20
			echo "- Docking with origin station"
			if ${EVE.Bookmark[${Origin}].ToEntity(exists)}
			{
				if (${EVE.Bookmark[${Origin}].ToEntity.CategoryID} == 3)
				{
					EVE.Bookmark[${Origin}].ToEntity:Approach
					do
					{
						wait 20
					}
					while (${EVE.Bookmark[${Origin}].ToEntity.Distance} > 50)
					
					EVE.Bookmark[${Origin}].ToEntity:Dock			
					do
					{
					   wait 20
					   WaitCount:Inc[20]
					}
					while (!${Me.InStation} && ${WaitCount} < 200)
					WaitCount:Set[0]
					if (!${Me.InStation})
					{
					  echo "- First Attempt at docking with failed...trying again."
					  Entity[CategoryID,3]:Dock
						do
						{
					  	 wait 20
					  	 WaitCount:Inc[20]
						}
						while (!${Me.InStation} && ${WaitCount} < 200)
						WaitCount:Set[0]
					}							
				}
			}
			wait 20
			echo "- Now docked within origin station."	
  }
  while !${EverythingHauled}
  
 
  return
}
