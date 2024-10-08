import PseudoRandomX "mo:xtended-random/PseudoRandomX";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Character "models/Character";
import Class "models/entities/Class";
import Race "models/entities/Race";

module {
    type Prng = PseudoRandomX.PseudoRandomGenerator;

    public func generate(
        class_ : Class.Class,
        race : Race.Race,
    ) : Character.Character {
        var gold : Nat = 0;
        var maxHealth : Nat = 100;
        var health : Nat = maxHealth;
        let inventorySize = 5; // TODO slot count?
        let inventorySlots : [var Character.InventorySlot] = Array.tabulateVar(inventorySize, func(_ : Nat) : Character.InventorySlot = { itemId = null });
        let skillActionIds = Buffer.Buffer<Text>(5);

        var i : Nat = 0;
        func addItemId(itemId : Text) {
            if (i >= inventorySlots.size()) {
                Debug.print("Inventory slot limit reached, " # itemId # " not added when generating character");
                return;
            };
            inventorySlots[i] := { itemId = ?itemId };
            i += 1;
        };

        for (startingItemId in class_.startingItemIds.vals()) {
            addItemId(startingItemId);
        };
        for (startingItemId in race.startingItemIds.vals()) {
            addItemId(startingItemId);
        };

        for (actionId in class_.startingSkillActionIds.vals()) {
            skillActionIds.add(actionId);
        };
        for (actionId in race.startingSkillActionIds.vals()) {
            skillActionIds.add(actionId);
        };

        {
            health = health;
            maxHealth = maxHealth;
            gold = gold;
            classId = class_.id;
            raceId = race.id;
            inventorySlots = Array.freeze(inventorySlots);
            weaponId = class_.weaponId;
            skillActionIds = Buffer.toArray(skillActionIds);
        };
    };

};
