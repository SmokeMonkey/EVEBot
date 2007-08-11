/* 
	Very basic combat file, will continue to develop as I have time.
   Hess   
*/

objectdef obj_Combat
{
	variable bool InCombat = FALSE
	variable bool Running = FALSE
	variable bool CombatPause = FALSE
	variable int FrameCounter
	variable index:entity TargetList
	variable iterator NextTargetIterator
		
	method Initialize()
	{	
		call UpdateHudStatus "obj_Combat: Initialized"
	}
	
	method Shutdown()
	{
		/* Nothing to shutdown */
	}
	
	method InCombatState()
	{
		Call UpdateHudStatus "Now In Combat"
		InCombat:Set[TRUE]
	}
	
	method ExitCombatState()
	{
		Call UpdateHudStatus "Debug: ExitCombatState"
		InCombat:Set[FALSE]
	}
	
	method Pause()
	{
		Call UpdateHudStatus "Pausing Bot to Deal with Combat"
		CombatPause:Set[TRUE]
	}
	
	method UnPause()
	{
		call UpdateHudStatus "Bot Resumed"
		CombatPause:Set[FALSE]
	}
	
	function UpdateList()
	{	
		This.TargetList:Clear
		Me:DoGetTargetedBy[TargetList]
		
		if ${This.TargetList.Used}
			{
					echo "DEBUG: obj_Combat:UpdateList - Found ${This.TargetList.Used}"
			}
	}
	
	method NextTarget()
	{
		TargetList:GetSettingIterator
	}
	
	function:bool TargetNext()
	{
		variable iterator TargetIterator
			
			
			if ${TargetList.Used} == 0
			{
			call This.UpdateList
			}
			
			This.TargetList:GetIterator[TargetIterator]		
		if ${TargetIterator:First(exists)}
		{
			do
			{
			  if ${Entity[${TargetIterator.Value}](exists)} && \
					!${TargetIterator.Value.IsLockedTarget} && \
					!${TargetIterator.Value.BeingTargeted} 
				{
						break
				}
			}
			while ${TargetIterator:Next(exists)}
			
			if ${Entity[${TargetIterator.Value}](exists)}
			{
				if ${TargetIterator.Value.IsLockedTarget} || \
					${TargetIterator.Value.BeingTargeted}
				{
					return TRUE
				}
				call UpdateHudStatus "Locking Target ${TargetIterator.Value.Name}: ${Misc.MetersToKM_Str[${TargetIterator.Value.Distance}]}"
				
				wait 20				
				TargetIterator.Value:LockTarget
				echo "Locking Target"
				wait 1200
				do
				{
				  wait 30
				  echo "Debug:... Test2"
				}
				while ${TargetIterator.Value.IsLockedTarget}== FALSE
				echo "Debug:..."
				call This.UpdateList
				return TRUE
			}
			return FALSE
		}
	}
	
	function Fight()
	{
		This:Pause
		
		
		
		
		call UpdateHudStatus "Test Test Test"
		
		if ${Math.Calc[${Me.GetTargets} + ${Me.GetTargeting}]} < ${Ship.SafeMaxLockedTargets}
			{
				call This.UpdateList
				wait 20
				call UpdateHudStatus "Debug: Getting Target"
				call This.TargetNext				
				wait 100
			}		
			
		call UpdateHudStatus "Test Test Test2"
		
		while (${Me.GetTargetedBy} > 0) && (${Me.Ship.ShieldPct} < 100)		
		{
				Me:DoGetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				if ${Target:First(exists)}
				do
				{
					if ${Target.Value.CategoryID} == ${Asteroids.AsteroidCategoryID}
					{
						continue
					}
					variable int TargetID
					TargetID:Set[${Target.Value.ID}]
					Target.Value:MakeActiveTarget
					wait 20
	
					call This.SendDrones
				}
				while ${Target:Next(exists)}
				
		}	
		
		This:UnPause
	
		while ${Me.GetTargetedBy} == 0 && \
			 ${Me.Ship.ShieldPct} < 100 && \
			 ${Me.GetTargeting} > 0
		{
				wait 10
		}
			
		This:ExitCombatState
			
		}
			
		function SendDrone()
			{
				if (${Ship.Drones.DronesInSpace} > 0)
				{
				Eve:DronesEngageMyTarget[Drones.DroneList]
				}
			}
			
		function Lasers()
		{
			/* Combat Lasers */
		}
			
	function SafeRun()
	{
		/* Not active yet */
		Call UpdateHudStatus "Overall Precentage of ship is to low, We will run back to base to repair"
		Running:Set[TRUE]
		return
	}
	
	function ResetRun()
	{
		Running:Set[FALSE]
	}
}