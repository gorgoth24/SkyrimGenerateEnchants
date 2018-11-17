{
  Script generates 31 enchanted copies of selected weapons per each, adds enchantment, alters new recoreds value, and adds respected Suffixes for easy parsing and replace.
  For armors script will make only one enchanted copy per each, for now.

  All enchanted versions will have it's propper Temper COBJ records as well.
  Also, for each selected WEAP/ARMO record, will be created a Leveled List, with Base Weapon + all it's enchanted versions. Each with count of 1, and based on enchantment level requirement
  NOTE: Should be applyed on records inside WEAPON/ARMOR (WEAP/ARMO) category of plugin you want to edit (script will not create new plugin)
  NOTE: So script works with Weapons/Shields/Bags/Bandanas/Armor/Clothing/Amulets/Wigs... every thing, but script won't find right item requirements for tempering wig or amulet... probably... However it will make a recipe, and it will log a message with link on that recipe, in this case, you can simply delete Tempering record or edit it... that is your Skyrim after all :O)
}

unit GenerateEnchantedVersions;

uses SkyrimUtils;

// =Settings
const
  // should generator add MagicDisallowEnchanting keyword to the enchanted versions? (boolean)
  setMagicDisallowEnchanting = false;
  // on how much the enchanted versions value should be multiplied (integer or real (aka float))
  enchantedValueMultiplier = 1;

// creates an enchanted copy of the weapon record and returns it
function createEnchantedVersion(baseRecord: IInterface; objEffect: string; suffix: string; enchantmentAmount: integer): IInterface;
var
  enchRecord, enchantment, keyword: IInterface;
begin
  enchRecord := wbCopyElementToFile(baseRecord, GetFile(baseRecord), true, true);

  // find record for Object Effect ID
  enchantment := getRecordByFormID(objEffect);

  // add object effect
  SetElementEditValues(enchRecord, 'EITM', GetEditValue(enchantment));

  // set enchantment amount
  SetElementEditValues(enchRecord, 'EAMT', enchantmentAmount);

  // set it's value, cause enchantments are more expensive
  // Vanilla formula [Total Value] = [Base Item Value] + 0.12*[Charge] + [Enchantment Value]
  // credits: http://www.uesp.net/wiki/Skyrim_talk:Generic_Magic_Weapons
  // don't know how to make [Enchantment Value] without hardcoding every thing, so made it just for similar results, suggestions are welcome :O)
  SetElementEditValues(
    enchRecord,
    'DATA\Value',
      round(
        GetElementEditValues(baseRecord, 'DATA\Value')
        + (0.12 * enchantmentAmount)
        + (1.4 * (enchantmentAmount / GetElementEditValues(enchantment, 'ENIT\Enchantment Cost')))  // 1.4 * <number of uses>
        * enchantedValueMultiplier
      )
  );

  // change name by adding suffix
  SetElementEditValues(enchRecord, 'EDID', GetElementEditValues(baseRecord, 'EDID') + 'Ench ' + suffix);

  // suffix the FULL, for easy finding and manual editing
  SetElementEditValues(enchRecord, 'FULL', GetElementEditValues(baseRecord, 'FULL') + ' ' + suffix + '');

  makeTemperable(enchRecord);

  if setMagicDisallowEnchanting = true then begin
    // add MagicDisallowEnchanting [KYWD:000C27BD] keyword if not present
    addKeyword(enchRecord, getRecordByFormID('000C27BD'));
  end;

  // return it
  Result := enchRecord;
end;


// runs on script start
function Initialize: integer;
begin
  AddMessage('---Starting Generator---');
  Result := 0;
end;

// for every record selected in xEdit
function Process(selectedRecord: IInterface): integer;
var
  newRecord: IInterface;
  enchLevelList, enchLevelListGroup: IInterface;
  armorkeywords: IInterface;
  i: Integer;
  keywordedid: IInterface;
  workingFile: IwbFile;
  recordSignature: string;
begin
  recordSignature := Signature(selectedRecord);

  // filter selected records, which are not valid
  // NOTE: only weapons and armors are exepted, for now
  if not ((recordSignature = 'WEAP') or (recordSignature = 'ARMO')) then
    exit;

  // create Leveled List for proper distribution
  enchLevelList := createRecord(
    GetFile(selectedRecord), // plugin
    'LVLI' // category
  );

  // set the flags
  SetElementEditValues(enchLevelList, 'LVLF', 11); // NOTE: 11 => Calculate from all levels, and for each item in count

  // define items group inside the Leveled List
  Add(enchLevelList, 'Leveled List Entries', true);

  enchLevelListGroup := ElementByPath(enchLevelList, 'Leveled List Entries');

  // add selected record for vanilish style of rare stuff
  addToLeveledList(enchLevelList, selectedRecord, 1);

  // remove automatic zero entry
  removeInvalidEntries(enchLevelList);

  //------------------------
  // =SKYRIM OBJECT EFFECTS
  //------------------------
  if recordSignature = 'WEAP' then begin
  
    SetElementEditValues(enchLevelList, 'EDID', 'LItemWeaponsEnch' + GetElementEditValues(selectedRecord, 'EDID'));

    // FireEffects
    //addToLeveledList(
    //  enchLevelList,
    //  createEnchantedVersion(
    //    selectedRecord, // baseRecord,
    //     '00049BB7', // EnchWeaponFireDamage01
    //    'Fire01', // suffix
    //    800 // enchantmentAmount
    //  ),
    //  1 // required level
    //);

	// Fire   
	addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00049BB7', 'of the Inferno', 800), 1); // EnchWeaponFireDamage01
	addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C2A', 'of the Inferno', 900), 3); // EnchWeaponFireDamage02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C2C', 'of the Inferno', 1000), 5); // EnchWeaponFireDamage03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C2D', 'of the Inferno', 1200), 10); // EnchWeaponFireDamage04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C30', 'of the Inferno', 1500), 15); // EnchWeaponFireDamage05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C35', 'of the Inferno', 2000), 20); // EnchWeaponFireDamage06

    // Frost
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C36', 'of the Blizzard', 800), 1); // EnchWeaponFrostDamage01
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C37', 'of the Blizzard', 900), 3); // EnchWeaponFrostDamage02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045C39', 'of the Blizzard', 1000), 5); // EnchWeaponFrostDamage03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045D4B', 'of the Blizzard', 1200), 10); // EnchWeaponFrostDamage04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045D56', 'of the Blizzard', 1500), 15); // EnchWeaponFrostDamage05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045D58', 'of the Blizzard', 2000), 20); // EnchWeaponFrostDamage06
	
	// Shock
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045D97', 'of the Tempest', 900), 3); // EnchWeaponShockDamage02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045F6F', 'of the Tempest', 1000), 5); // EnchWeaponShockDamage03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045F89', 'of the Tempest', 1200), 10); // EnchWeaponShockDamage04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045F8D', 'of the Tempest', 1500), 15); // EnchWeaponShockDamage05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00045F9E', 'of the Tempest', 2000), 20); // EnchWeaponShockDamage06

    // Magicka
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B453', 'of Aetherius', 800), 1); // EnchWeaponMagickaDamage01
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B454', 'of Aetherius', 900), 3); // EnchWeaponMagickaDamage02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B455', 'of Aetherius', 1000), 5); // EnchWeaponMagickaDamage03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B456', 'of Aetherius', 1200), 10); // EnchWeaponMagickaDamage04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B457', 'of Aetherius', 1500), 15); // EnchWeaponMagickaDamage05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B458', 'of Aetherius', 2000), 20); // EnchWeaponMagickaDamage06

	// Stamina
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B459', 'of Exhaustion', 800), 1); // EnchWeaponStaminaDamage01
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B45A', 'of Exhaustion', 900), 3); // EnchWeaponStaminaDamage02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B45B', 'of Exhaustion', 1000), 5); // EnchWeaponStaminaDamage03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B45C', 'of Exhaustion', 1200), 10); // EnchWeaponStaminaDamage04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B45D', 'of Exhaustion', 1500), 15); // EnchWeaponStaminaDamage05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B45E', 'of Exhaustion', 2000), 20); // EnchWeaponStaminaDamage06
	
    // Fear
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FBFF7', 'of Nightmares', 800), 1); // EnchWeaponFear01
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B466', 'of Nightmares', 900), 5); // EnchWeaponFear02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B467', 'of Nightmares', 1000), 10); // EnchWeaponFear03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B468', 'of Nightmares', 1200), 15); // EnchWeaponFear04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B469', 'of Nightmares', 1500), 20); // EnchWeaponFear05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B46A', 'of Nightmares', 2000), 25); // EnchWeaponFear06
	
	// Turn Undead
	addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B46C', 'of the Blessed', 800), 1); // EnchWeaponTurnUndead01
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B46D', 'of the Blessed', 900), 5); // EnchWeaponTurnUndead02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B46E', 'of the Blessed', 1000), 10); // EnchWeaponTurnUndead03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B46F', 'of the Blessed', 1200), 15); // EnchWeaponTurnUndead04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B470', 'of the Blessed', 1500), 20); // EnchWeaponTurnUndead05
	
	// Absorb Health
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA145', 'of Vampirism', 900), 5); // EnchWeaponAbsorbHealth02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA15A', 'of Vampirism', 1000), 10); // EnchWeaponAbsorbHealth03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA15B', 'of Vampirism', 1200), 15); // EnchWeaponAbsorbHealth04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA15C', 'of Vampirism', 1500), 20); // EnchWeaponAbsorbHealth05
	addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA15D', 'of Vampirism', 2000), 25); // EnchWeaponAbsorbHealth06
	
	// Absorb Magicka
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA158', 'of the Source', 900), 5); // EnchWeaponAbsorbMagicka02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA15E', 'of the Source', 1000), 10); // EnchWeaponAbsorbMagicka03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA15F', 'of the Source', 1200), 15); // EnchWeaponAbsorbMagicka04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA160', 'of the Source', 1500), 20); // EnchWeaponAbsorbMagicka05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA161', 'of the Source', 2000), 25); // EnchWeaponAbsorbMagicka06
	
	// Absorb Stamina
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA159', 'of Second Wind', 900), 5); // EnchWeaponAbsorbStamina02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA162', 'of Second Wind', 1000), 10); // EnchWeaponAbsorbStamina03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA163', 'of Second Wind', 1200), 15); // EnchWeaponAbsorbStamina04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA164', 'of Second Wind', 1500), 20); // EnchWeaponAbsorbStamina05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AA165', 'of Second Wind', 2000), 25); // EnchWeaponAbsorbStamina06
	
	// Banish
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000ACBB7', 'of the Exile', 1200), 15); // EnchWeaponBanish04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000ACBB8', 'of the Exile', 1500), 20); // EnchWeaponBanish05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000ACBB9', 'of the Exile', 2000), 25); // EnchWeaponBanish06
	
	// Paralysis
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000ACBBA', 'of the Snake', 1200), 15); // EnchWeaponParalysis04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000ACBBB', 'of the Snake', 1500), 20); // EnchWeaponParalysis05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000ACBBC', 'of the Snake', 2000), 25); // EnchWeaponParalysis06
	
    // Soul Trap
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B45F', 'of the Soul Cairn', 800), 1); // EnchWeaponSoulTrap01
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B460', 'of the Soul Cairn', 900), 5); // EnchWeaponSoulTrap02
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B461', 'of the Soul Cairn', 1000), 10); // EnchWeaponSoulTrap03
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B462', 'of the Soul Cairn', 1200), 15); // EnchWeaponSoulTrap04
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B463', 'of the Soul Cairn', 1500), 20); // EnchWeaponSoulTrap05
    addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0005B464', 'of the Soul Cairn', 2000), 25); // EnchWeaponSoulTrap06

    // Misc enchantments

    // =Adding enchantments for WEAP records


  end else if recordSignature = 'ARMO' then begin
  
    armorkeywords := ElementByPath(selectedRecord, 'KWDA');
	
	for i:= 0 to ElementCount(armorkeywords) do begin
	
		keywordedid := GetElementEditValues(LinksTo(ElementByIndex(armorkeywords, i+1)), 'EDID');
		
		if keywordedid = 'ArmorBoots' then
			
			SetElementEditValues(enchLevelList, 'EDID', 'LItemArmorEnch' + GetElementEditValues(selectedRecord, 'EDID'));

			// Fire Resistance Effects
			//addToLeveledList(
			//  enchLevelList,
			//  createEnchantedVersion(
			//    selectedRecord, // baseRecord,
			//    '0004950B', // EnchArmorResistFire01
			//    'Fire01', // suffix
			//    800 // enchantmentAmount
			//  ),
			//  1 // required level
			//);

			// Articulation
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F6905', 'of the Silver Tongue', 800), 1); // EnchArmorArticulation01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F6907', 'of the Silver Tongue', 900), 5); // EnchArmorArticulation02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F6908', 'of the Silver Tongue', 1000), 10); // EnchArmorArticulation03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F6909', 'of the Silver Tongue', 1200), 15); // EnchArmorArticulation04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F690A', 'of the Silver Tongue', 1500), 20); // EnchArmorArticulation05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F690B', 'of the Silver Tongue', 2000), 25); // EnchArmorArticulation06
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000F690C', 'of the Silver Tongue', 2200), 30); // EnchArmorArticulation07
			
			// Fortify Alchemy
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0008B65B', 'of the Alchemist', 800), 1); // EnchArmorFortifyAlchemy01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0008B65D', 'of the Alchemist', 900), 5); // EnchArmorFortifyAlchemy02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0008B65E', 'of the Alchemist', 1000), 10); // EnchArmorFortifyAlchemy03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0008B65F', 'of the Alchemist', 1200), 15); // EnchArmorFortifyAlchemy04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0008B660', 'of the Alchemist', 1500), 20); // EnchArmorFortifyAlchemy05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0008B661', 'of the Alchemist', 2000), 25); // EnchArmorFortifyAlchemy06
			
			// Waterbreathing
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00092A76', 'of the Sea', 800), 1); // EnchArmorWaterbreathing01
			
			// Muffle
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00092A77', 'of the Thief', 800), 1); // EnchMuffle01
			
			// Fortify Alteration
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A107', 'of the Elementalist', 800), 1); // EnchArmorFortifyAlteration01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD49F', 'of the Elementalist', 900), 5); // EnchArmorFortifyAlteration02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD4A0', 'of the Elementalist', 1000), 10); // EnchArmorFortifyAlteration03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE037', 'of the Elementalist', 1200), 15); // EnchArmorFortifyAlteration04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE038', 'of the Elementalist', 1500), 20); // EnchArmorFortifyAlteration05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE039', 'of the Elementalist', 2000), 25); // EnchArmorFortifyAlteration06
			
			// Fortify Block
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A108', 'of Bulwark', 800), 1); // EnchArmorFortifyBlock01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD4A1', 'of Bulwark', 900), 5); // EnchArmorFortifyBlock02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD4A2', 'of Bulwark', 1000), 10); // EnchArmorFortifyBlock03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE034', 'of Bulwark', 1200), 15); // EnchArmorFortifyBlock04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE035', 'of Bulwark', 1500), 20); // EnchArmorFortifyBlock05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE036', 'of Bulwark', 2000), 25); // EnchArmorFortifyBlock06
			
			// Fortify Carry Weight
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A109', 'of the Ox', 800), 1); // EnchArmorFortifyCarryWeight01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD44C', 'of the Ox', 900), 5); // EnchArmorFortifyCarryWeight02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD44D', 'of the Ox', 1000), 10); // EnchArmorFortifyCarryWeight03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD44E', 'of the Ox', 1200), 15); // EnchArmorFortifyCarryWeight04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD44F', 'of the Ox', 1500), 20); // EnchArmorFortifyCarryWeight05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD450', 'of the Ox', 2000), 25); // EnchArmorFortifyCarryWeight06
			
			// Fortify Conjuration
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A10A', 'of the Summoner', 800), 1); // EnchArmorFortifyConjuration01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD453', 'of the Summoner', 900), 5); // EnchArmorFortifyConjuration02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD454', 'of the Summoner', 1000), 10); // EnchArmorFortifyConjuration03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD455', 'of the Summoner', 1200), 15); // EnchArmorFortifyConjuration04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD456', 'of the Summoner', 1500), 20); // EnchArmorFortifyConjuration05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD457', 'of the Summoner', 2000), 25); // EnchArmorFortifyConjuration06
			
			// Fortify Destruction
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A10B', 'of Wrath', 800), 1); // EnchArmorFortifyDestruction01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD458', 'of Wrath', 900), 5); // EnchArmorFortifyDestruction02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD459', 'of Wrath', 1000), 10); // EnchArmorFortifyDestruction03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD45A', 'of Wrath', 1200), 15); // EnchArmorFortifyDestruction04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD45B', 'of Wrath', 1500), 20); // EnchArmorFortifyDestruction05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD45C', 'of Wrath', 2000), 25); // EnchArmorFortifyDestruction06
			
			// Fortify Heal Rate
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0010CF26', 'of Regeneration', 800), 1); // EnchArmorFortifyHealRate01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD460', 'of Regeneration', 1000), 10); // EnchArmorFortifyHealRate03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A10D', 'of Regeneration', 1200), 15); // EnchArmorFortifyHealRate04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD45F', 'of Regeneration', 1500), 20); // EnchArmorFortifyHealRate05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD493', 'of Regeneration', 2000), 25); // EnchArmorFortifyHealRate06	
			
			// Fortify Health
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A10E', 'of Constitution', 800), 1); // EnchArmorFortifyHealth01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD463', 'of Constitution', 900), 5); // EnchArmorFortifyHealth02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD464', 'of Constitution', 1000), 10); // EnchArmorFortifyHealth03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BDFFF', 'of Constitution', 1200), 15); // EnchArmorFortifyHealth04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE000', 'of Constitution', 1500), 20); // EnchArmorFortifyHealth05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE001', 'of Constitution', 2000), 25); // EnchArmorFortifyHealth06
			
			// Fortify Illusion
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A10E', 'of the Mystic', 800), 1); // EnchArmorFortifyIllusion01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD463', 'of the Mystic', 900), 5); // EnchArmorFortifyIllusion02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD464', 'of the Mystic', 1000), 10); // EnchArmorFortifyIllusion03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BDFFF', 'of the Mystic', 1200), 15); // EnchArmorFortifyIllusion04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE000', 'of the Mystic', 1500), 20); // EnchArmorFortifyIllusion05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE001', 'of the Mystic', 2000), 25); // EnchArmorFortifyIllusion06
			
			// Fortify Light Armor
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A110', 'of the Nimble', 800), 1); // EnchArmorFortifyLight01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD467', 'of the Nimble', 900), 5); // EnchArmorFortifyLight02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD468', 'of the Nimble', 1000), 10); // EnchArmorFortifyLight03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE005', 'of the Nimble', 1200), 15); // EnchArmorFortifyLight04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE006', 'of the Nimble', 1500), 20); // EnchArmorFortifyLight05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE007', 'of the Nimble', 2000), 25); // EnchArmorFortifyLight06
			
			// Fortify Lockpicking
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A111', 'of the Thief', 800), 1); // EnchArmorFortifyLockpicking01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD469', 'of the Thief', 900), 5); // EnchArmorFortifyLockpicking02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD46A', 'of the Thief', 1000), 10); // EnchArmorFortifyLockpicking03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE008', 'of the Thief', 1200), 15); // EnchArmorFortifyLockpicking04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE009', 'of the Thief', 1500), 20); // EnchArmorFortifyLockpicking05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE00A', 'of the Thief', 2000), 25); // EnchArmorFortifyLockpicking06
			
			// Fortify Magicka
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00049508', 'of Mana', 800), 1); // EnchArmorFortifyMagicka01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD46B', 'of Mana', 900), 5); // EnchArmorFortifyMagicka02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD46C', 'of Mana', 1000), 10); // EnchArmorFortifyMagicka03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000B7A31', 'of Mana', 1200), 15); // EnchArmorFortifyMagicka04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000B7A32', 'of Mana', 1500), 20); // EnchArmorFortifyMagicka05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000B7A33', 'of Mana', 2000), 25); // EnchArmorFortifyMagicka06
			
			// Fortify Magicka Regen
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD46E', 'of the Mage', 1000), 10); // EnchArmorFortifyMagickaRegen03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A112', 'of the Mage', 1200), 15); // EnchArmorFortifyMagickaRegen04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD46D', 'of the Mage', 1500), 20); // EnchArmorFortifyMagickaRegen05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE00B', 'of the Mage', 2000), 25); // EnchArmorFortifyMagickaRegen06
			
			// Fortify Marskman
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A113', 'of the Archer', 800), 1); // EnchArmorFortifyMarksman01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD46F', 'of the Archer', 900), 5); // EnchArmorFortifyMarksman02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD470', 'of the Archer', 1000), 10); // EnchArmorFortifyMarksman03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE00C', 'of the Archer', 1200), 15); // EnchArmorFortifyMarksman04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE00D', 'of the Archer', 1500), 20); // EnchArmorFortifyMarksman05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE00E', 'of the Archer', 2000), 25); // EnchArmorFortifyMarksman06
			
			// Fortify One-Handed
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A114', 'of the Duelist', 800), 1); // EnchArmorFortifyOneHanded01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD471', 'of the Duelist', 900), 5); // EnchArmorFortifyOneHanded02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD472', 'of the Duelist', 1000), 10); // EnchArmorFortifyOneHanded03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE00F', 'of the Duelist', 1200), 15); // EnchArmorFortifyOneHanded04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE010', 'of the Duelist', 1500), 20); // EnchArmorFortifyOneHanded05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE011', 'of the Duelist', 2000), 25); // EnchArmorFortifyOneHanded06
			
			// Fortify Pickpocket
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A115', 'of the Cutpurse', 800), 1); // EnchArmorFortifyPickpocket01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD473', 'of the Cutpurse', 900), 5); // EnchArmorFortifyPickpocket02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD474', 'of the Cutpurse', 1000), 10); // EnchArmorFortifyPickpocket03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE012', 'of the Cutpurse', 1200), 15); // EnchArmorFortifyPickpocket04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE013', 'of the Cutpurse', 1500), 20); // EnchArmorFortifyPickpocket05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE014', 'of the Cutpurse', 2000), 25); // EnchArmorFortifyPickpocket06
			
			// Fortify Restoration
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A116', 'of the Cleric', 800), 1); // EnchArmorFortifyRestoration01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD475', 'of the Cleric', 900), 5); // EnchArmorFortifyRestoration02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD476', 'of the Cleric', 1000), 10); // EnchArmorFortifyRestoration03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE015', 'of the Cleric', 1200), 15); // EnchArmorFortifyRestoration04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE016', 'of the Cleric', 1500), 20); // EnchArmorFortifyRestoration05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE017', 'of the Cleric', 2000), 25); // EnchArmorFortifyRestoration06
			
			// Fortify Smithing
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A117', 'of the Blacksmith', 800), 1); // EnchArmorFortifySmithing01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD477', 'of the Blacksmith', 900), 5); // EnchArmorFortifySmithing02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD478', 'of the Blacksmith', 1000), 10); // EnchArmorFortifySmithing03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE018', 'of the Blacksmith', 1200), 15); // EnchArmorFortifySmithing04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE019', 'of the Blacksmith', 1500), 20); // EnchArmorFortifySmithing05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE01A', 'of the Blacksmith', 2000), 25); // EnchArmorFortifySmithing06
			
			// Fortify Sneak
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A118', 'of Sneaking', 800), 1); // EnchArmorFortifySneaking01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD479', 'of Sneaking', 900), 5); // EnchArmorFortifySneaking02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD47A', 'of Sneaking', 1000), 10); // EnchArmorFortifySneaking03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE01B', 'of Sneaking', 1200), 15); // EnchArmorFortifySneaking04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE01C', 'of Sneaking', 1500), 20); // EnchArmorFortifySneaking05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE01D', 'of Sneaking', 2000), 25); // EnchArmorFortifySneaking06
			
			// Fortify Speechcraft
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A119', 'of Speechcraft', 800), 1); // EnchArmorFortifySpeechcraft01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD47B', 'of Speechcraft', 900), 5); // EnchArmorFortifySpeechcraft02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD47C', 'of Speechcraft', 1000), 10); // EnchArmorFortifySpeechcraft03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE01E', 'of Speechcraft', 1200), 15); // EnchArmorFortifySpeechcraft04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE01F', 'of Speechcraft', 1500), 20); // EnchArmorFortifySpeechcraft05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE020', 'of Speechcraft', 2000), 25); // EnchArmorFortifySpeechcraft06
			
			// Fortify Stamina
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0004950A', 'of Stamina', 800), 1); // EnchArmorFortifyStamina01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD47D', 'of Stamina', 900), 5); // EnchArmorFortifyStamina02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD47E', 'of Stamina', 1000), 10); // EnchArmorFortifyStamina03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE021', 'of Stamina', 1200), 15); // EnchArmorFortifyStamina04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE022', 'of Stamina', 1500), 20); // EnchArmorFortifyStamina05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE023', 'of Stamina', 2000), 25); // EnchArmorFortifyStamina06
			
			// Fortify Stamina Regen
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD480', 'of Stamina Regen', 1000), 10); // EnchArmorFortifyStaminaRegen03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A11A', 'of Stamina Regen', 1200), 15); // EnchArmorFortifyStaminaRegen04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD47F', 'of Stamina Regen', 1500), 20); // EnchArmorFortifyStaminaRegen05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE024', 'of Stamina Regen', 2000), 25); // EnchArmorFortifyStaminaRegen06
			
			// Fortify Two-Handed
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0007A11B', 'of Strength', 800), 1); // EnchArmorFortifyStrength01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD481', 'of Strength', 900), 5); // EnchArmorFortifyStrength02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD482', 'of Strength', 1000), 10); // EnchArmorFortifyStrength03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE025', 'of Strength', 1200), 15); // EnchArmorFortifyStrength04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE026', 'of Strength', 1500), 20); // EnchArmorFortifyStrength05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE027', 'of Strength', 2000), 25); // EnchArmorFortifyStrength06
			
			// Fortify Resist Disease
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00100E62', 'of Histskin', 800), 1); // EnchArmorFortifyResistDiseaseh01
			
			// Fortify Resist Fire
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0004950B', 'of the Dunmer', 800), 1); // EnchArmorFortifyResistFire01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD483', 'of the Dunmer', 900), 5); // EnchArmorFortifyResistFire01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD484', 'of the Dunmer', 1000), 10); // EnchArmorFortifyResistFire01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE028', 'of the Dunmer', 1200), 15); // EnchArmorFortifyResistFire01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE029', 'of the Dunmer', 1500), 20); // EnchArmorFortifyResistFire01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE02A', 'of the Dunmer', 2000), 25); // EnchArmorFortifyResistFire01
			
			// Fortify Resist Frost
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0004950C', 'of the Nords', 800), 1); // EnchArmorFortifyResistFrost01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD485', 'of the Nords', 900), 5); // EnchArmorFortifyResistFrost02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD486', 'of the Nords', 1000), 10); // EnchArmorFortifyResistFrost03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE02B', 'of the Nords', 1200), 15); // EnchArmorFortifyResistFrost04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE02C', 'of the Nords', 1500), 20); // EnchArmorFortifyResistFrost05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE02D', 'of the Nords', 2000), 25); // EnchArmorFortifyResistFrost06
			
			// Fortify Resist Poison
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00100E5D', 'of Black Marsh', 800), 1); // EnchArmorFortifyResistPoison01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '00100E5E', 'of Black Marsh', 900), 5); // EnchArmorFortifyResistPoison02
			
		end;
		
		if keywordedid = 'ArmorGauntlets' then
			
			SetElementEditValues(enchLevelList, 'EDID', 'LItemArmorEnch' + GetElementEditValues(selectedRecord, 'EDID'));
			
			// Fortify Resist Shock
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '0004950D', 'of Grounding', 800), 1); // EnchArmorFortifyResistGrounding01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD487', 'of Grounding', 900), 5); // EnchArmorFortifyResistGrounding02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000AD488', 'of Grounding', 1000), 10); // EnchArmorFortifyResistGrounding03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE02E', 'of Grounding', 1200), 15); // EnchArmorFortifyResistGrounding04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE02F', 'of Grounding', 1500), 20); // EnchArmorFortifyResistGrounding05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000BE030', 'of Grounding', 2000), 25); // EnchArmorFortifyResistGrounding06
			
		end; 
		
		if keywordedid = 'ArmorHelmet' then
			
			SetElementEditValues(enchLevelList, 'EDID', 'LItemArmorEnch' + GetElementEditValues(selectedRecord, 'EDID'));
			
			// Fortify Resist Magic
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FC05B', 'of High Rock', 800), 1); // EnchArmorFortifyResistMagic01
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FC05C', 'of High Rock', 900), 5); // EnchArmorFortifyResistMagic02
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FC05D', 'of High Rock', 1000), 10); // EnchArmorFortifyResistMagic03
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FC05E', 'of High Rock', 1200), 15); // EnchArmorFortifyResistMagic04
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FC05F', 'of High Rock', 1500), 20); // EnchArmorFortifyResistMagic05
			addToLeveledList(enchLevelList, createEnchantedVersion(selectedRecord, '000FC060', 'of High Rock', 2000), 25); // EnchArmorFortifyResistMagic06
			
		end;
		
		//if keywordedid = 'ArmorCuirass' then
		//	
		//	SetElementEditValues(enchLevelList, 'EDID', 'LItemArmorEnch' + GetElementEditValues(selectedRecord, 'EDID'));
		//	
		//end;	

	end.	
		
  // =Adding enchantments for ARMO records
  
  end;

  Result := 0;
end;

// runs in the end
function Finalize: integer;
begin
  AddMessage('---Ending Generator---');
  Result := 0;
end;

end.
