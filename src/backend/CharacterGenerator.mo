import PseudoRandomX "mo:xtended-random/PseudoRandomX";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import Character "models/Character";
import CharacterModifier "models/CharacterModifier";
import Class "models/entities/Class";
import Race "models/entities/Race";
import Weapon "models/entities/Weapon";

module {
    type Prng = PseudoRandomX.PseudoRandomGenerator;

    public func generate(
        class_ : Class.Class,
        race : Race.Race,
        weapons : HashMap.HashMap<Text, Weapon.Weapon>,
    ) : Character.Character {
        var gold : Nat = 0;
        var maxHealth : Nat = 100;
        var health : Nat = maxHealth;
        var itemIds = TrieSet.empty<Text>();
        var traitIds = TrieSet.empty<Text>();
        var attack : Int = 0;
        var defense : Int = 0;
        var speed : Int = 0;
        var magic : Int = 0;

        func addItem(item : Text) {
            itemIds := TrieSet.put(itemIds, item, Text.hash(item), Text.equal);
        };

        func addTrait(trait : Text) {
            traitIds := TrieSet.put(traitIds, trait, Text.hash(trait), Text.equal);
        };

        func applyModifier(modifier : CharacterModifier.CharacterModifier) {
            switch (modifier) {
                case (#attack(delta)) attack += delta;
                case (#defense(delta)) defense += delta;
                case (#speed(delta)) speed += delta;
                case (#magic(delta)) magic += delta;
                case (#gold(amount)) gold += amount;
                case (#health(delta)) {
                    if (delta < 0) {
                        // min health is 1
                        health := Int.abs(Int.max(1, health + delta));
                    } else {
                        health += Int.abs(delta);
                    };
                };
                case (#maxHealth(delta)) {
                    if (delta < 0) {
                        // min health is 1
                        maxHealth := Int.abs(Int.max(1, health + delta));
                    } else {
                        maxHealth += Int.abs(delta);
                    };
                };
                case (#item(itemId)) addItem(itemId);
                case (#trait(traitId)) addTrait(traitId);
            };
        };

        for (effect in class_.modifiers.vals()) {
            applyModifier(effect);
        };

        for (effect in race.modifiers.vals()) {
            applyModifier(effect);
        };

        let ?weapon = weapons.get(class_.weaponId) else Debug.trap("Weapon not found: " # class_.weaponId);

        {
            health = health;
            maxHealth = maxHealth;
            gold = gold;
            classId = class_.id;
            raceId = race.id;
            attack = attack;
            defense = defense;
            speed = speed;
            magic = magic;
            itemIds = itemIds;
            traitIds = traitIds;
            weapon = weapon;
        };
    };

};
