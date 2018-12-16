{
  Script generates copies of selected WEAP/ARMO records for each record selected, adds enchantment, alters new records value, and adds sensible names
  All enchanted versions will have it's propper Temper COBJ records as well.
  Also, each selected WEAP/ARMO record will be added to a leveled list automatically
  NOTE: Not all of this code is original - Any code that is not mine has had due credit given on the modpage and within the script
}

unit GenerateEnchantedVersions;

uses SkyrimUtils;

var 
  LLfile: IwbFile; // These variables are set here so it doesn't prompt you every record
  LLplugin: WideString;

// =Settings
const
  setMagicDisallowEnchanting = false; // Disable the ability to 'Disenchant' items?
  enchantedValueMultiplier = 1; // Multiplier on enchantment strength
  chanceMultiplier = 8; // Chance 
  replaceOriginal = True; // Replaces the original item with a leveled list that contains a chance for the enchanted version of the item

// [FUNCTION LIST]

// Find if a file is loaded is xEdit
function DoesFileExist(aPluginName: String): String;
var
  i: Integer;
begin
  for i := 0 to Pred(FileCount) do begin
	if SameText(aPluginName, BaseName(FileByIndex(i))) then begin
	  Result := aPluginName;
	  Exit;
	end;
  end;
  Result := nil;
end;

// Find loaded plugin by name [mte Functions]
function FileByName(aPluginName: string): IInterface;
var
  i: Integer;
begin
  for i := 0 to Pred(FileCount) do begin
    if SameText(GetFileName(FileByIndex(i)), aPluginName) then begin
	  Result := FileByIndex(i);
      Exit;
	end;
  end;
  Result := nil;
end;

// Find the type of Item
function ArmorKeyword(selectedRecord: IInterface): String;
var
  i: Integer;
  AAkeywords: IwbElement;
  AAfile: IInterface;
begin
  AAkeywords := ElementByPath(selectedRecord, 'KWDA');
  for i := 0 to Pred(ElementCount(AAkeywords)) do begin
    AAfile := LinksTo(ElementByIndex(AAkeywords, i));

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ArmorHelmet') then begin
      Result := 'ArmorHelmet';
      Exit;
    end;

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ArmorCuirass') then begin
	  Result := 'ArmorCuirass';
      Exit;
    end;
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ArmorGauntlets') then begin
	  Result := 'ArmorGauntlets';
      Exit;
    end;

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ArmorBoots') then begin
      Result := 'ArmorBoots';
      Exit;
    end;
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ArmorShield') then begin
	  Result := 'ArmorShield';
      Exit;
	end;
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingHead') then begin
	  Result := 'ClothingHead';
      Exit;
    end;	

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingBody') then begin
	  Result := 'ClothingBody';
      Exit;
    end;	

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingHands') then begin
	  Result := 'ClothingHands';
      Exit;
	end;
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingFeet') then begin
	  Result := 'ClothingFeet';
      Exit;
    end;	
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingFeet') then begin
	  Result := 'ClothingFeet';
      Exit;
    end;	

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingCirclet') then begin
	  Result := 'ClothingCirclet';
      Exit;
    end;	
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingNecklace') then begin
	  Result := 'ClothingCirclet';
      Exit;
    end;	
	
    if SameText(GetElementEditValues(AAfile, 'EDID'), 'ClothingRing') then begin
	  Result := 'ClothingRing';
      Exit;
    end;

    if SameText(GetElementEditValues(AAfile, 'EDID'), 'WeapTypeBow') then begin
	  Result := 'WeapTypeBow';
      Exit;
    end;		
  end;
end;

// Checks to see if a string ends with an entered substring [mte functions]
function StrEndsWith(s1, s2: string): boolean;
var
  i, n1, n2: integer;
begin
  Result := false;
  
  n1 := Length(s1);
  n2 := Length(s2);
  if n1 < n2 then exit;
  
  Result := (Copy(s1, n1 - n2 + 1, n2) = s2);
end;

// Appends a string to the end of the input string if it's not already there [mte functions]
function AppendIfMissing(s1, s2: string): string;
begin
  Result := s1;
  if not StrEndsWith(s1, s2) then
    Result := s1 + s2;
end;

// Find the position of a substring in a string [mte functions]
function ItPos(substr: string; str: string; it: integer): integer;
var
  i, found: integer;
begin
  Result := -1;
  //AddMessage('Called ItPos('+substr+', '+str+', '+IntToStr(it)+')');
  if it = 0 then exit;
  found := 0;
  for i := 1 to Length(str) do begin
    //AddMessage('    Scanned substring: '+Copy(str, i, Length(substr)));
    if (Copy(str, i, Length(substr)) = substr) then begin
      //AddMessage('    Matched substring, iteration #'+IntToStr(found + 1));
      Inc(found);
    end;
    if found = it then begin
      Result := i;
      Break;
    end;
  end;
end;

// Find string following an input string
function StrFollowing(inputString: String; findString: String): String;
begin
  Result := Copy(inputString, (ItPos(findString, inputString, 1)), ((Length(inputString) + 1) - ItPos(findstring, inputstring, 1)));
end;

// Find if a file contains an EDID in a specific group
function DoesFileContain(aPlugin: IInterface; aGroupName: String; aRecord: IInterface): String;
var
  i: Integer;
begin
  if HasGroup(aPlugin, aGroupName) then begin																						// If the plugin has the group aGroupName 
    for i := 0 to Pred(ElementCount(GroupBySignature(aPlugin, aGroupName))) do begin												// For every record in aGroupName
      if GetLoadOrderFormID(ElementByIndex(GroupBySignature(aPlugin, aGroupName), i)) = GetLoadOrderFormID(aRecord) then begin   	// If the EDID of the record is the same as aEDID then
	    Result := 'True';																											// aPlugin does contain aRecordName; Return 'True'
		Exit;	
	  end;
    end;
    Result := 'False';																												// None of the records have the same EDID as aEDID; Return 'False'
    Exit;	
  end else begin
    Exit;
  end;
end;

// Find where the selected record is referenced in leveled lists and make a 'Copy as Override' into a specified file.  Then replace all instances of selectedRecord with aRecord in the override
function ReplaceInLeveledListAuto(selectedRecord: IInterface; aRecord: IInterface; aPlugin: IInterface; aLevel: Integer): Integer;  // The integer is unused because the function does not output a result
var
  LLrecord, LLentries, LLentry, LLcopy, masterRecord: IInterface;
  x, y, z: Integer;
begin
  masterRecord := MasterOrSelf(selectedRecord);																			// If the selected record is an override change the selected record to the original
  for x := 0 to Pred(ReferencedByCount(masterRecord)) do begin															// For every record that references the selected record
    LLrecord := ReferencedByIndex(masterRecord, x);																		// Set the record being examined to the current record in the 'for' loop
    if Signature(LLrecord) = 'LVLI' then begin																			// If the record being examined is a leveled list then
	  LLentries := ElementByName(LLrecord, 'Leveled List Entries');														// Set the element being examined to the Leveled List Entries of the leveled list
	  for y := 0 to Pred(ElementCount(LLentries)) do begin																// For every Leveled List Entry within the leveled list 
	    LLentry := LinksTo(ElementByPath(ElementByIndex(LLentries, y), 'LVLO\Reference'));								// A Leved List Entry contains a link to a record.  This follows that link and returns the Leveled List Entry's record
		if GetLoadOrderFormID(masterRecord) = GetLoadOrderFormID(LLentry) then begin									// Compares the FormID of selectedRecord and the Leveled List Entry.  If they are the same record then
		  AddRequiredElementMasters(GetFile(aRecord), aPlugin, False);	
		  if not ElementExists(GroupBySignature(aPlugin, 'LVLI'), GetElementEditValues(LLrecord, 'EDID')) then begin	// If aPlugin does not already contain a 'Copy as Override Into' of the leveled list
		    if HasGroup(aPlugin, 'LVLI') then begin																		// If aPlugin contains the LVLI group
		      LLcopy := wbCopyElementToFile(LLrecord, aPlugin, False, True);											// Makes a copy of the entire leveled list so it can be edited without affecting other mods
		    end else begin																								// If aPlugin does not contain the LVLI group
			  Add(aPlugin, 'LVLI', True);																				// Add the LVLI group
			  LLcopy := wbCopyElementToFile(LLrecord, aPlugin, False, True);											// Makes a copy of the entire Leveled List so it can be edited without affecting other mods
			end;
		  end else begin																								// If aPlugin already contains a 'Copy as Override Into' of the current leveled list
		    if HasGroup(aPlugin, 'LVLI') then begin																		// If aPlugin contains the LVLI group
			  LLcopy := ElementByName(GroupBySignature(aPlugin, 'LVLI'), GetElementEditValues(LLrecord, 'EDID'));		// Set LLcopy to the existing LLcopy in aPlugin
			end else begin																								// If aPlugin does not contain the LVLI group (this should never happen if ElementExists returns 'True' but I put it here anwyays)
			  Add(aPlugin, 'LVLI', True); 																				// Add the LVLI group to aPlugin 
			  LLcopy := ElementByName(GroupBySignature(aPlugin, 'LVLI'), GetElementEditValues(LLrecord, 'EDID'));		// Set LLcopy to the existing LLcopy in aPlugin
			end;				
		  end;
		  SetElementEditValues(ElementByIndex(ElementByName(LLcopy, 'Leveled List Entries'), y), 'LVLO\Reference', GetLoadOrderFormID(aRecord)); // Replace the Leveled List Entry (in LLcopy not LLrecord) of selectedRecord with aRecord 	 
		  end;
	  end;
	end;
  end;
end;

// Creates an enchanted copy of the item record and returns it; This is only a function.  The main portion of the script is further down
function createEnchantedVersion(baseRecord: IInterface; objEffect: IInterface; suffix: string; enchantmentAmount: integer): IInterface;
var
  enchRecord, enchantment, keyword: IInterface;
  enchCost: Integer;
begin
  enchRecord := wbCopyElementToFile(baseRecord, LLfile, true, true);		// Copies everything from the unenchanted item to the enchanted one
  enchCost := GetElementEditValues(objEffect, 'ENIT\Enchantment Cost');     // Get enchantment cost
  SetElementEditValues(enchRecord, 'EITM', GetEditValue(objEffect)); 		// Add object effect (enchantment)
  SetElementEditValues(enchRecord, 'EAMT', enchantmentAmount);  			// Set enchantment amount

  if enchCost = 0 then begin												// Make sure it does not divide by zero
    enchCost := 1;
  end;
  
  // Set value of enchanted version
  // Vanilla formula [Total Value] = [Base Item Value] + 0.12*[Charge] + [Enchantment Value]
  // credits: http://www.uesp.net/wiki/Skyrim_talk:Generic_Magic_Weapons
  // don't know how to make [Enchantment Value] without hardcoding everything, so made it just for similar results, suggestions are welcome :O)
  SetElementEditValues(
    enchRecord,
    'DATA\Value',
      round(
        GetElementEditValues(baseRecord, 'DATA\Value')
        + (0.12 * enchantmentAmount)
        + (1.4 * (enchantmentAmount / enchCost))  // 1.4 * <number of uses>
        * enchantedValueMultiplier
      )
  );


  SetElementEditValues(enchRecord, 'EDID', GetElementEditValues(baseRecord, 'EDID') + GetElementEditValues(objEffect, 'EDID')); 	// Change name of the item by adding a suffix
  SetElementEditValues(enchRecord, 'FULL', GetElementEditValues(baseRecord, 'FULL') + ' ' + suffix + ''); 							// Also change the FULL name for consistency
  makeTemperable(enchRecord); 																										// Make the enchanted item temperable
  if setMagicDisallowEnchanting = true then begin																					// If MagicDisallowEnchanting is set to true in 'Settings' at the very top of the script
    addKeyword(enchRecord, getRecordByFormID('000C27BD')); 																			// Add MagicDisallowEnchanting [KYWD:000C27BD] keyword if not present
  end;
  Result := enchRecord;   																											// Return the entire enchanted Recird as the output of the function
end;

function Initialize: integer; // runs on script start
begin
  addMessage('If you get an IwbImplementation error or an access violation error set the xEdit.exe to run as administrator.  The video on the mod page will show you how to do this and explain why.');
  AddMessage('---Starting Generator---');
  Result := 0;
end;

// For every record selected in xEdit run the following [MAIN SECTION OF THE SCRIPT]
// 'Process' is a special type of function that runs for every selected object (in this case the selected record defined in the '(selectedRecord: IInterface)' part).  
// in '(selectedRecord: IInterface)' selectedRecord is an arbitrary name of the object and IInterface is the type of object (the selected object in this case)
// the ': integer;' bit after '(selectedRecord: IInterface)' is what the function is expecting to return.  In this case it doesn't actually return anything; this bit is added just to complete the statement
function Process(selectedRecord: IInterface): integer; 
var
  enchFile, enchGroup, enchObjEffect, refRecord, newRecord: IInterface;
  enchLevelList, chanceLevelList, enchLevelListGroup: IInterface;
  i, q, x, y, z, enchLevel, enchWeapAmount, enchWeapBowAmount, enchArmorBootsAmount, enchArmorGlovesAmount, enchArmorHelmAmount, enchArmorTorsoAmount, 
  enchArmorRobesAmount, enchArmorShieldAmount, enchArmorCircletAmount, enchArmorNecklaceAmount, enchArmorRingAmount, filecount, filemastercount: Integer;
  recordSignature, LLplugin, enchWeap, enchWeapSuffix, enchWeapBow, enchWeapBowSuffix, enchArmorBoots, enchArmorBootsSuffix, enchArmorGloves, enchArmorGlovesSuffix, 
  enchArmorHelm, enchArmorHelmSuffix, enchArmorTorso, enchArmorTorsoSuffix, enchArmorRobes, enchArmorRobesSuffix, enchArmorShield, enchArmorShieldSuffix, 
  enchArmorCirclet, enchArmorCircletSuffix, enchArmorNecklace, enchArmorNecklaceSuffix, enchArmorRing, enchArmorRingSuffix: String;
  workingFile: IwbFile;
  slFiles, fileMasterList, recordMasterList: TStringList;
begin
  recordSignature := Signature(selectedRecord); 										// Sets the signature of the record (whether it's a weapon, armor, or other)
  if not ((recordSignature = 'WEAP') or (recordSignature = 'ARMO')) then begin			// Filter selected records, which are not valid
    addMessage('The record selected is not an ARMO or WEAP record'); 					// Debug message
    Exit;
  end;
  if not Assigned(LLfile) then begin // This whole thing just assigns and prepares the plugin the script outputs to
    if MessageDlg('Add to Custom Leveled Lists [RECOMMENDED] [YES] or add to another plugin [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then begin 		// Input [RECOMMENDED] or user specified plugin
	  LLplugin := 'Custom Leveled Lists.esp'; 																													// Default output plugin name
	  InputQuery('Enter', 'Enter Plugin Name [Plugin will be created if not detected]', LLplugin); 																// Enter the plugin you would like to use
	  AppendIfMissing(LLplugin, '.esp');
	  if DoesFileExist(LLplugin) = LLplugin then begin 																											// If the file exists then
	    addMessage('User specified file detected; Preparing file'); 																							// Debug message
	    LLfile := FileByName(LLplugin); 																														// Set the output file to the specified plugin
		  // Create the necessary groups																														// Create the necessary groups
		  if not HasGroup(LLfile, 'LVLI') then begin 
            Add(LLfile, 'LVLI', True)
	      end;
		  if not HasGroup(LLfile, 'ARMO') then begin
            Add(LLfile, 'ARMO', True)
	      end;
		  if not HasGroup(LLfile, 'WEAP') then begin
            Add(LLfile, 'WEAP', True)
	      end;
		  if not HasGroup(LLfile, 'COBJ') then begin
            Add(LLfile, 'COBJ', True)
	      end;
		  if not HasGroup(LLfile, 'KYWD') then begin
            Add(LLfile, 'KYWD', True)
	      end;
	  end else begin 																											// If the file does not exist
	    addMessage('The user specified plugin does not exist yet; Creating plugin using the name input into the prompt'); 		// Debug message
        LLfile := AddNewFileName(LLplugin); 																					// Create a file with the name specified
		// Create the necessary groups																							// Create the necessary groups
        Add(LLfile, 'LVLI', True); 
        Add(LLfile, 'ARMO', True);
	    Add(LLfile, 'WEAP', True);
	    Add(LLfile, 'COBJ', True);
	    Add(LLfile, 'KYWD', True);
	  end;
    end else begin
      if DoesFileExist('Custom Leveled Lists.esp') = 'Custom Leveled Lists.esp' then begin  					// This is the same as the above but for the default option
        addMessage('Custom Leveled Lists.esp detected; Preparing File'); 										// Debug Message
		LLfile := FileByName('Custom Leveled Lists.esp');														// Set the output file to the specified plugin
		  // Create the necessary groups
		  if not HasGroup(LLfile, 'LVLI') then begin 
            Add(LLfile, 'LVLI', True)
	      end;
		  if not HasGroup(LLfile, 'ARMO') then begin
            Add(LLfile, 'ARMO', True)
	      end;
		  if not HasGroup(LLfile, 'WEAP') then begin
            Add(LLfile, 'WEAP', True)
	      end;
		  if not HasGroup(LLfile, 'COBJ') then begin
            Add(LLfile, 'COBJ', True)
	      end;
		  if not HasGroup(LLfile, 'KYWD') then begin
            Add(LLfile, 'KYWD', True)
	      end;		
      end else begin 														// Create the file if it does not already exist
	    addMessage('Custom Leveled Lists Not Detected; Creating File');		// Debug message
        LLfile := AddNewFileName('Custom Leveled Lists.esp'); 				// Set the output file to the default option
		// Create the necessary groups										// Create the necessary groups
	    Add(LLfile, 'LVLI', True);
	    Add(LLfile, 'ARMO', True);
	    Add(LLfile, 'WEAP', True);
	    Add(LLfile, 'COBJ', True);
	    Add(LLfile, 'KYWD', True);
	  end;
	  if not Assigned(LLfile) then begin	// If, for some reason, the file is not assigned at this point it means that something went horribly wrong
	    addMessage('For some reason the plugin file was not assigned correctly.  This error message should not display unless the code was altered.  If you were not the one who altered to code make a post on the mod page.'); // Debug message
	    Exit;
      end;
    end;
  end;  
  
  addMessage('Adding record file to plugin as a master.'); 														// Debug message 
	AddMasterIfMissing(LLfile, GetFileName(GetFile(selectedRecord))); 											// Adds the file the selected record is from to the plugin you entered
	
	
  addMessage('Creating a Leveled List to contain all the generated enchanted versions'); 						// Debug message
    enchLevelList := createRecord(LLfile, 'LVLI'); 																// Create a Leveled List for proper distribution
	
  addMessage('Creating a Leveled List to implement a percent chance of normal weapon v enchanted weapon');
    chanceLevelList := createRecord(LLFile, 'LVLI'); 															// Create a Leveled List for percent chance of normal weapon v enchanted weapon
	
  addMessage('Preparing the Leveled Lists'); 																	// Debug message
    SetElementEditValues(enchLevelList, 'LVLF', 11); 															// Set the Flags; NOTE: 11 => Calculate from all levels, and for each item in count
    SetElementEditValues(chanceLevelList, 'LVLF', 11); 															// Set the Flags; NOTE: 11 => Calculate from all levels, and for each item in count
    Add(enchLevelList, 'Leveled List Entries', true);															// Add the Leveled List Entries section to the record
    Add(chanceLevelList, 'Leveled List Entries', true); 														// Add the Leveled List Entries section to the record 
    enchLevelListGroup := ElementByPath(enchLevelList, 'Leveled List Entries'); 								// Define items group inside the Leveled List
    removeInvalidEntries(enchLevelList); 																		// Remove automatic zero entry
    removeInvalidEntries(chanceLevelList); 																		// Remove automatic zero entry  
	
  addMessage('Adding enchanted leveled list to percent chance Leved List');										// Debug message
    addToLeveledList(chanceLevelList, enchLevelList, 1); 														// Adding enchanted leveled list to percent chance leveled list
	
  addMessage('Naming Leveled Lists');
  if Signature(selectedRecord) = 'WEAP' then begin
	SetElementEditValues(enchLevelList, 'EDID', 'LItemWeaponEnch' + GetElementEditValues(selectedRecord, 'EDID'));
    SetElementEditValues(chanceLevelList, 'EDID', 'LItemWeaponEnchChance' + GetElementEditValues(selectedRecord, 'EDID'));
  end;
  if Signature(selectedRecord) = 'ARMO' then begin
    SetElementEditValues(enchLevelList, 'EDID', 'LItemArmorEnch' + GetElementEditValues(selectedRecord, 'EDID'));
    SetElementEditValues(chanceLevelList, 'EDID', 'LItemArmorEnchChance' + GetElementEditValues(selectedRecord, 'EDID'));
  end;
  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //------------------------
  // =SKYRIM OBJECT EFFECTS
  //------------------------
    
	// The following is a breakdown of what each part of the each function is
    //
    //	addToLeveledList(				// Add to a Leveled List
    //    enchLevelList,				// Add to the Leveled List enchLevelList
    //    createEnchantedVersion(		// Calls the createEnchantedVersion function defined before the 'Process' part of the script
    //      selectedRecord, 			// The currently selected record in xEdit
    //      '00049BB7', 				// FormID of the object effect (the enchantment)
    //      'of Flames', 			 	// Name of the item generated
    //      800),						// enchantment amount
    //	  1);							// required player level for the item to appear
  
  // Add Files to TStringList
  slFiles := TStringList.Create;
  slFiles.Add('Skyrim.esm');
  if DoesFileExist('Summermyst - Enchantments of Skyrim.esp') = 'Summermyst - Enchantments of Skyrim.esp' then begin
    slFiles.Add('Summermyst - Enchantments of Skyrim.esp');
  end;

// Processes the record through the designated files

if enchFile = 99 then begin 
for filecount := 0 to slFiles.Count - 1 do begin 													// For every file in slFiles
  addMessage('Processing ' + slFiles[filecount] + ' Enchantments (This May Take A While)'); 		// Debug Message
  enchFile := FileByName(slFiles[filecount]);														// enchFile is the current file in slFiles
  fileMasterList := TStringList.Create; 															// This is a list created to contain ReportRequiredMasters' output			
  ReportRequiredMasters(enchFile, fileMasterList, False, True);										// Outputs masters to fileMasterList
  for filemastercount := 0 to fileMasterList.Count - 1 do begin 									// For every masters in fileMasterList
	AddMasterIfMissing(LLfile, fileMasterList[filemastercount]); 									// Add the current master in fileMasterList if missing
  end;
  fileMasterList.Free; 																				// Unallocate memory for the TStringList when we are finished with it 
  enchGroup := GroupBySignature(enchFile, 'ENCH'); 													// Designates the group being examined in the current file
  for y := 0 to Pred(ElementCount(enchGroup)) do begin 												// For each Object Effect
    enchObjEffect := ElementByIndex(enchGroup, y); 													// Designates the current enchantment
    enchObjEffect := WinningOverride(enchObjEffect); 												// Uses the last winning override so that any enchantment rebalances are used when generating enchanted versions
	
	// All Object Effects applied to items in the vanilla naming scheme end with a number.  There are 6 different tiers in the vanilla game and each one appears at a specific level
    if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '01') or StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '02') 
    or StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '03') or StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '04')
    or StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '05') or StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '06') then begin
	
	  // The level the enchantment appears for each tier is hardcoded; There is no standard for how enchanted items are added to leveled lists so there's no way to auto-detect it.
      if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '01') then begin
        enchLevel := 1;
	  end;
	  if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '02') then begin
	    enchLevel := 10;
	  end;
      if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '03') then begin
	    enchLevel := 20;
	  end;
      if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '04') then begin
	    enchLevel := 30;
	  end;
      if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '05') then begin
	    enchLevel := 35;
	  end;
      if StrEndsWith(GetElementEditValues(enchObjEffect, 'EDID'), '06') then begin
	    enchLevel := 40;
	  end;
	  
	  // This section detects what weapons and armor an enchantment is applied to
	  for z := 0 to Pred(ReferencedByCount(enchObjEffect)) do begin												// For every record that references the current enchantment
	    refRecord := ReferencedByIndex(enchObjEffect, z); 														// Designates the current record to be examined
	    if Signature(refRecord) = 'WEAP' then begin 															// If the record is a weapon record
          if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin 							// If the name of the record contains 'of'
	        if (ArmorKeyword(refRecord) = 'WeapTypeBow') then begin 											// If any of the keywords are WeapTypeBow
		      if not Assigned(enchWeapBow) then begin 															// Records that the enchantment is applied to bows
		        enchWeapBow := 'True';
		      end;
		      if not Assigned(enchWeapBowAmount) then begin                                                     // Record enchantment amount
		        enchWeapBowAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		      end;
		      if not Assigned(enchWeapBowSuffix) then begin
			    if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin
					enchWeapBowSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');           // Record the suffix
			    end;
		      end;
		    end else begin
		      if not Assigned(enchWeap) then begin
		        enchWeap := 'True';
		      end;
		      if not Assigned(enchWeapAmount) then begin
		        enchWeapAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		      end;
		      if not Assigned(enchWeapSuffix) then begin
			    if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		          enchWeapSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		        end;
		      end;
            end;
	      end;
		end;
	  
	    if Signature(refRecord) = 'ARMO' then begin
		  if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
	        if (ArmorKeyword(refRecord) = 'ArmorBoots') or (ArmorKeyword(refRecord) = 'ClothingFeet') then begin
			  if (ItPos('Boots', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorBoots) then begin
		          enchArmorBoots := 'True';
		        end;
		        if not Assigned(enchArmorBootsAmount) then begin
		          enchArmorBootsAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorBootsSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		            enchArmorBootsSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
			    end;
		      end;
			end;
		
	        if (ArmorKeyword(refRecord) = 'ArmorGauntlets') or (ArmorKeyword(refRecord) = 'ClothingHands') then begin
			  if (ItPos('Gauntlets', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) or (ItPos('Bracers', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorGloves) then begin
		          enchArmorGloves := 'True';
		        end;
		        if not Assigned(enchArmorGlovesAmount) then begin
		          enchArmorGlovesAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorGlovesSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		            enchArmorGlovesSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
			      end;
		        end;
		      end;
			end;

	        if (ArmorKeyword(refRecord) = 'enchArmorHelm') or (ArmorKeyword(refRecord) = 'ClothingHead') then begin
			  if (ItPos('Helmet', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) or (ItPos('Mask', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) or (ItPos('Headband', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) 
			  or (ItPos('Cowl', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorHelm) then begin
		          enchArmorHelm := 'True';
		        end;
		        if not Assigned(enchArmorHelmAmount) then begin
		          enchArmorHelmAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorHelmSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		            enchArmorHelmSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
			    end;
		      end;
			end;

	        if (ArmorKeyword(refRecord) = 'ArmorCuirass') or (ArmorKeyword(refRecord) = 'ClothingBody') then begin
			  if (ItPos('Robes', GetElementEditValues(refRecord, 'FULL'), 1) = -1) and (ItPos('Vampire Armor', GetElementEditValues(refRecord, 'FULL'), 1) = -1) then begin
			    if (ItPos('Cuirass', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) or (ItPos('Armor', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		          if not Assigned(enchArmorTorso) then begin
		            enchArmorTorso := 'True';
		          end;
		          if not Assigned(enchArmorTorsoAmount) then begin
		            enchArmorTorsoAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		          end;
		          if not Assigned(enchArmorTorsoSuffix) then begin
			        if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		              enchArmorTorsoSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		            end;
			      end;
		        end;
			  end;
			  if (ItPos('Robes', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) and (ItPos('Vampire Armor', GetElementEditValues(refRecord, 'FULL'), 1) = -1) then begin
		        if not Assigned(enchArmorRobes) then begin
		          enchArmorRobes := 'True';
		        end;
		        if not Assigned(enchArmorRobesAmount) then begin
		          enchArmorRobesAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorRobesSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		            enchArmorRobesSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
			    end;			    
			  end;
			end;
		
	        if (ArmorKeyword(refRecord) = 'ArmorShield') then begin
			  if (ItPos('Shield', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorShield) then begin
		          enchArmorShield := 'True';
		        end;
		        if not Assigned(enchArmorShieldAmount) then begin
		          enchArmorShieldAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorShieldSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin
		            enchArmorShieldSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
		        end;
			  end;
		    end;		

	        if (ArmorKeyword(refRecord) = 'ClothingCirclet') then begin
			  if (ItPos('Circlet', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorCirclet) then begin
		          enchArmorCirclet := 'True';
		        end;
		        if not Assigned(enchArmorCircletAmount) then begin
		          enchArmorCircletAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorCircletSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin			
		            enchArmorCircletSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
			    end;
		      end;
			end;

	        if (ArmorKeyword(refRecord) = 'ClothingNecklace') then begin
			  if (ItPos('Necklace', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorNecklace) then begin
		          enchArmorNecklace := 'True';
		        end;
		        if not Assigned(enchArmorNecklaceAmount) then begin
		          enchArmorNecklaceAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorNecklaceSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin
		            enchArmorNecklaceSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
		        end;
		      end;
			end;

	        if (ArmorKeyword(refRecord) = 'ClothingRing') then begin
			  if (ItPos('Ring', GetElementEditValues(refRecord, 'FULL'), 1) <> -1) then begin
		        if not Assigned(enchArmorRing) then begin
		          enchArmorRing := 'True';
		        end;
		        if not Assigned(enchArmorRingAmount) then begin
		          enchArmorRingAmount := GetElementEditValues(enchObjEffect, 'ENIT\Enchantment Amount');
		        end;
		        if not Assigned(enchArmorRingSuffix) then begin
			      if ItPos('of', GetElementEditValues(refRecord, 'FULL'), 1) <> -1 then begin
		            enchArmorRingSuffix := StrFollowing(GetElementEditValues(refRecord, 'FULL'), 'of');
		          end;
			    end;
		      end;			
	        end;
	      end;
	    end;
	  end;
	  // Applies an enchantment to the selectedRecord if and only if the enchantment has already been applied to the same type of weapon/armor as the enchantment
	  if (Signature(selectedRecord) = 'WEAP') then begin
	    if (ArmorKeyword(selectedRecord) <> 'WeapTypeBow') and (enchWeap = 'True') then begin
	      addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchWeapSuffix, enchWeapAmount), enchLevel);
	    end;
	    if (ArmorKeyword(selectedRecord) = 'WeapTypeBow') and (enchWeapBow = 'True') then begin
	      addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchWeapBowSuffix, enchWeapBowAmount), enchLevel);
	    end;
	  end;
	  if (Signature(selectedRecord) = 'ARMO') then begin
	    if (ArmorKeyword(selectedRecord) = 'ArmorBoots') or (ArmorKeyword(selectedRecord) = 'ClothingFeet') then begin
		  if enchArmorBoots = 'True' then begin
	        addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorBootsSuffix, enchArmorBootsAmount), enchLevel);
		  end;
	    end;
	    if (ArmorKeyword(selectedRecord) = 'ArmorGloves') or (ArmorKeyword(selectedRecord) = 'ClothingHands') then begin
		  if enchArmorGloves = 'True' then begin
	        addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorGlovesSuffix, enchArmorGlovesAmount), enchLevel);
		  end;
	    end;
	    if (ArmorKeyword(selectedRecord) = 'ArmorCuirass') or (ArmorKeyword(selectedRecord) = 'ClothingBody') then begin
		  if (ItPos('Robes', GetElementEditValues(selectedRecord, 'FULL'), 1) <> -1) then begin
		    if enchArmorRobes = 'True' then begin
			  addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorRobesSuffix, enchArmorRobesAmount), enchLevel);
			end;
		  end else if (ItPos('Robes', GetElementEditValues(selectedRecord, 'FULL'), 1) = -1) then begin
		    if enchArmorTorso = 'True' then begin
	          addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorTorsoSuffix, enchArmorTorsoAmount), enchLevel);
		    end;
		  end;
	    end;
	    if (ArmorKeyword(selectedRecord) = 'ArmorShield') and (enchArmorShield = 'True') then begin
	      addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorShieldSuffix, enchArmorShieldAmount), enchLevel);
	    end;
	    if (ArmorKeyword(selectedRecord) = 'ClothingCirclet') and (enchArmorCirclet = 'True') then begin
	      addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorCircletSuffix, enchArmorCircletAmount), enchLevel);
	    end;
	    if (ArmorKeyword(selectedRecord) = 'ClothingNecklace') and (enchArmorNecklace = 'True') then begin
	      addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorNecklaceSuffix, enchArmorNecklaceAmount), enchLevel);
	    end;
	    if (ArmorKeyword(selectedRecord) = 'ClothingRing') and (enchArmorRing = 'True') then begin
	      addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, enchObjEffect, enchArmorRingSuffix, enchArmorRingAmount), enchLevel);
	    end;
	  end;
	  // Resets all the weapon and armor keywords to nil before the loop begins examining the next enchantment
	  enchWeap := nil;
	  enchWeapSuffix := nil;
	  enchWeapAmount := nil;
	  enchWeapBow := nil;
	  enchWeapBowSuffix := nil;
	  enchWeapBowAmount := nil;
	  enchArmorBoots := nil;
	  enchArmorBootsSuffix := nil;
	  enchArmorBootsAmount := nil;	
	  enchArmorGloves := nil;
	  enchArmorGlovesSuffix := nil;
	  enchArmorGlovesAmount := nil;	
	  enchArmorTorso := nil;
	  enchArmorTorsoSuffix := nil;
	  enchArmorTorsoAmount := nil;	
	  enchArmorRobes := nil;
	  enchArmorRobesSuffix := nil;
	  enchArmorRobesAmount := nil;
	  enchArmorShield := nil;
	  enchArmorShieldSuffix := nil;
	  enchArmorShieldAmount := nil;		
	  enchArmorCirclet := nil;
	  enchArmorCircletSuffix := nil;
	  enchArmorCircletAmount := nil;
	  enchArmorNecklace := nil;
	  enchArmorNecklaceSuffix := nil;
	  enchArmorNecklaceAmount := nil;
	  enchArmorRing := nil;
	  enchArmorRingSuffix := nil;
	  enchArmorRingAmount := nil;	  
    end;
  end;
end;
end;	
  // Free TStringLists
  slFiles.Free;
 
  // Replace the original item with the chanceLevelList
  if replaceOriginal = True then begin
	addMessage('Replacing the original item with a Leveled List that has a chance for an Enchanted Version of the item');
  	ReplaceInLeveledListAuto(selectedRecord, chanceLevelList, LLfile, 1);
  end;
	
  // Add the percent chance to the chanceLevelList; 						// This must occur after ReplaceInLeveledListAuto so that it does not replace the entries in chanceLevelList
  addMessage('Adding original weapon to percent chance Leveled List'); 		// Debug message
  for x := 0 to chanceMultiplier do begin  									// This creates the percent chance to get a regular weapon v an enchanted one
    addToLeveledList(chanceLevelList, selectedRecord, 1); 					// Adding original Weapon to chance based Leveled List
  end;
end;


// Finalizes script
function Finalize: integer;
begin
  AddMessage('---Ending Generator---');
  Result := 0;
end;

end. // [END OF SCRIPT]
